"""Mechanical quality gates for a generated word set.

These run at *authoring* time, before anything is written to the repo. They are
deliberately mechanical: they catch the failures a generator actually makes —
a missing letter, a word filed under the wrong initial, a clue that contains
its own answer — and they say nothing about whether a word is well chosen for
its CEFR level. That judgement is the human spot-check.

The shipped assets are guarded separately by the Dart tests in
`features/rosco/rosco_impl/test/word_bank_assets_test.dart`. The two overlap on
purpose: these gates stop bad content being written, those tests stop bad
content staying.
"""

from __future__ import annotations

import re

ALPHABET = [chr(c) for c in range(ord("A"), ord("Z") + 1)]
MIN_DEFINITION_CHARS = 15

# A word may be hyphenated ("x-ray") but is never a phrase: the player has to
# say it in a few seconds, and the answer check compares single utterances.
WORD_PATTERN = re.compile(r"^[A-Za-z]+(?:-[A-Za-z]+)*$")


def _stem(word: str) -> str:
    """A crude stem, enough to catch a definition echoing its own answer.

    "A place where wild animals are kept" is a fine clue for *zoo*; "Something
    that is abundant" is not a clue for *abundant*. Inflections are the common
    case, so compare on a stem rather than the exact word.
    """
    lowered = word.lower()
    for suffix in ("ing", "ed", "es", "s"):
        if len(lowered) > len(suffix) + 3 and lowered.endswith(suffix):
            return lowered[: -len(suffix)]
    return lowered


def check_set(entries: list[dict], *, seen_words: set[str] | None = None) -> list[str]:
    """Returns a list of problems; an empty list means the set is publishable.

    `seen_words` are words already used by other sets at this level — passing
    them in is what keeps a second set from repeating the first.
    """
    problems: list[str] = []
    letters = [str(e.get("letter", "")).upper() for e in entries]

    missing = [letter for letter in ALPHABET if letter not in letters]
    if missing:
        problems.append(f"missing letters: {', '.join(missing)}")

    duplicated = {letter for letter in letters if letters.count(letter) > 1}
    if duplicated:
        problems.append(f"duplicated letters: {', '.join(sorted(duplicated))}")

    words_in_set: set[str] = set()

    for entry in entries:
        letter = str(entry.get("letter", "")).upper()
        word = str(entry.get("word", "")).strip()
        definition = str(entry.get("definition", "")).strip()

        if not WORD_PATTERN.match(word):
            problems.append(f"{letter}: {word!r} is not a single word")
            continue

        if not word.upper().startswith(letter):
            problems.append(f"{letter}: {word!r} does not start with {letter}")

        if word.lower() in words_in_set:
            problems.append(f"{letter}: {word!r} appears twice in this set")
        words_in_set.add(word.lower())

        if seen_words and word.lower() in seen_words:
            problems.append(f"{letter}: {word!r} already used by another set")

        if len(definition) < MIN_DEFINITION_CHARS:
            problems.append(f"{letter}: definition for {word!r} is too short")

        if _stem(word) in definition.lower():
            problems.append(f"{letter}: definition for {word!r} contains its answer")

        for synonym in entry.get("synonyms", []) or []:
            if str(synonym).strip().lower() == word.lower():
                problems.append(f"{letter}: {word!r} lists itself as a synonym")

    return problems
