"""Authors a Circular Words word set with Claude, gates it, and writes it.

The word bank stays a bundled asset — this only changes how the *content* gets
written, not how the game reads it. Nothing here ships in the app: it runs on a
developer's machine, and its output is reviewed and committed like any other
source file.

Why generation rather than hand-authoring: PLAN.md §7 records that the real
cost of this project is content, not code — six levels x 26 letters x N sets.
This attacks that cost while keeping every runtime property the bundled form
buys (offline, deterministic, no key in the app, no rate limit).

Usage:

    export ANTHROPIC_API_KEY=...        # or: ant auth login
    pip install -r requirements.txt

    python generate_word_bank.py --level b2               # add one set
    python generate_word_bank.py --level c1 --sets 2      # add two
    python generate_word_bank.py --level a2 --dry-run     # print, write nothing

Every generated set must pass `word_bank_gates.check_set` before it is written.
A set that fails is sent back to the model with its specific problems, up to
--max-attempts times; a set that still fails is discarded rather than written,
because a half-correct round is worse than a missing level (an unauthored level
is a real, handled state — see RoscoLevelUnavailable).
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys

import anthropic
from pydantic import BaseModel, Field

from word_bank_gates import ALPHABET, check_set

MODEL = "claude-opus-5"

# Where the app reads its word banks from. Kept in one place here and in
# WordBankAssetDataSource.assetPathFor on the Dart side.
ASSETS = (
    pathlib.Path(__file__).resolve().parents[2]
    / "features"
    / "rosco"
    / "rosco_impl"
    / "assets"
    / "words"
)

LEVEL_BRIEFS = {
    "a1": "absolute beginner. The 500 most frequent English words: concrete "
          "nouns, colours, family, food, everyday objects.",
    "a2": "elementary. Everyday vocabulary beyond the basics: routines, travel, "
          "shopping, simple feelings and simple past-tense verbs.",
    "b1": "intermediate. Words an independent user needs: opinions, work, "
          "plans, common abstract nouns and phrasal-free verbs.",
    "b2": "upper intermediate. Abstract and evaluative vocabulary: argument, "
          "consequence, nuance, academic and workplace register.",
    "c1": "advanced. Precise, less frequent words a fluent speaker chooses "
          "deliberately, including formal and academic register.",
    "c2": "proficient. Rare, literary, technical or highly nuanced vocabulary "
          "that a near-native speaker would recognise.",
}


class WordEntry(BaseModel):
    letter: str = Field(description="A single uppercase letter, A-Z.")
    word: str = Field(
        description="The answer. A single word (hyphens allowed, no spaces) "
        "beginning with `letter`."
    )
    definition: str = Field(
        description="The clue shown to the player. One plain sentence that "
        "MUST NOT contain the answer or any inflection of it."
    )
    synonyms: list[str] = Field(
        default_factory=list,
        description="Other answers that should be accepted. May be empty.",
    )


class GeneratedSet(BaseModel):
    entries: list[WordEntry] = Field(
        description="Exactly 26 entries, one per letter A through Z, in order."
    )


SYSTEM = """You author vocabulary rounds for an English learning game.

The player sees a definition and must SAY the word aloud, so every answer must
be a word a learner can pronounce and a speech recogniser can transcribe.

Hard rules, all of which are checked mechanically:

1. Exactly 26 entries, one for each letter A-Z, in alphabetical order.
2. Every word begins with its own letter.
3. A definition must NEVER contain its answer or an inflection of it. Write the
   clue as a dictionary would define the word without naming it.
4. One word per answer. Hyphenated words are fine; phrases are not.
5. Definitions are one plain sentence, understandable at the target level even
   when the answer is not.

X and Z are the hard letters. Do not skip them and do not substitute a word
that merely contains the letter — the alphabet is never relaxed. Prefer a
genuinely different X word over reusing "x-ray" when the level allows one."""


def load_document(level: str) -> dict:
    path = ASSETS / f"{level}.json"
    if path.exists():
        return json.loads(path.read_text())
    return {"level": level, "sets": []}


def existing_words(document: dict) -> set[str]:
    """Every word already used at this level, so a new set does not repeat it."""
    return {
        str(entry["word"]).lower()
        for word_set in document.get("sets", [])
        for entry in word_set.get("entries", [])
    }


def generate_set(
    client: anthropic.Anthropic,
    level: str,
    avoid: set[str],
    max_attempts: int,
) -> list[dict] | None:
    """One gated set, or None if it never passed."""
    brief = LEVEL_BRIEFS[level]
    avoid_line = (
        f"\n\nThese words are already used at this level — choose different "
        f"ones: {', '.join(sorted(avoid))}."
        if avoid
        else ""
    )
    prompt = (
        f"Write one complete A-Z round for CEFR level {level.upper()}: {brief}"
        f"{avoid_line}"
    )
    messages: list[dict] = [{"role": "user", "content": prompt}]

    for attempt in range(1, max_attempts + 1):
        response = client.messages.parse(
            model=MODEL,
            max_tokens=16000,
            system=SYSTEM,
            messages=messages,
            output_format=GeneratedSet,
        )

        entries = [entry.model_dump() for entry in response.parsed_output.entries]
        for entry in entries:
            entry["letter"] = entry["letter"].strip().upper()
            entry["word"] = entry["word"].strip()
            entry["definition"] = entry["definition"].strip()

        entries.sort(key=lambda e: e["letter"])
        problems = check_set(entries, seen_words=avoid)

        if not problems:
            print(f"  attempt {attempt}: passed all gates", file=sys.stderr)
            return entries

        print(
            f"  attempt {attempt}: {len(problems)} problem(s) — retrying",
            file=sys.stderr,
        )
        for problem in problems:
            print(f"    - {problem}", file=sys.stderr)

        # Feed the failures back rather than re-rolling blind: the model fixes
        # the named entries and leaves the rest alone.
        messages += [
            {"role": "assistant", "content": json.dumps({"entries": entries})},
            {
                "role": "user",
                "content": "That set failed these checks:\n"
                + "\n".join(f"- {p}" for p in problems)
                + "\n\nReturn the complete corrected set of 26 entries.",
            },
        ]

    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--level", required=True, choices=sorted(LEVEL_BRIEFS))
    parser.add_argument("--sets", type=int, default=1, help="how many to add")
    parser.add_argument("--max-attempts", type=int, default=3)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print the generated sets and write nothing",
    )
    args = parser.parse_args()

    client = anthropic.Anthropic()
    document = load_document(args.level)
    avoid = existing_words(document)
    added = 0

    for index in range(args.sets):
        number = len(document["sets"]) + 1
        print(f"{args.level}: generating set {number}", file=sys.stderr)

        entries = generate_set(client, args.level, avoid, args.max_attempts)
        if entries is None:
            print(
                f"  giving up on set {number} after {args.max_attempts} "
                f"attempts — nothing written",
                file=sys.stderr,
            )
            continue

        document["sets"].append(
            {"id": f"{args.level}-{number}", "entries": entries}
        )
        avoid |= {entry["word"].lower() for entry in entries}
        added += 1

    if args.dry_run:
        json.dump(document, sys.stdout, indent=2, ensure_ascii=False)
        print()
        return 0

    if not added:
        print("nothing passed the gates; no file written", file=sys.stderr)
        return 1

    path = ASSETS / f"{args.level}.json"
    path.write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n")

    print(
        f"wrote {path} — {added} new set(s), "
        f"{len(document['sets'])} total. Review before committing, then run "
        f"`dart run melos test`.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
