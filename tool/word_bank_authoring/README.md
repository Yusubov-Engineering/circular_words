# Word bank authoring

Generates a Circular Words word set with Claude, puts it through mechanical
quality gates, and writes it into `features/rosco/rosco_impl/assets/words/`.

**Nothing here ships in the app.** The word bank stays a bundled asset; this
only changes how the content gets written. The runtime keeps every property
that form buys — offline, deterministic, no API key on a device, no rate limit
— and `WordBankRepositoryImpl` is untouched by any of it.

## Why

PLAN.md §7 records that the real cost of this project is content, not code:
six levels × 26 letters × N sets. Hand-authoring that is the bottleneck. This
attacks the bottleneck without giving up anything at runtime.

## Use

```bash
python3 -m venv .venv && ./.venv/bin/pip install -r requirements.txt
export ANTHROPIC_API_KEY=...            # or: ant auth login

./.venv/bin/python generate_word_bank.py --level c1            # add one set
./.venv/bin/python generate_word_bank.py --level c1 --sets 2   # add two
./.venv/bin/python generate_word_bank.py --level c1 --dry-run  # print only
```

Then **read what it wrote**, and run `dart run melos test` from the repo root.

## The gates

`word_bank_gates.py` rejects a set unless:

- it has 26 distinct letters, A–Z with none missing;
- every word begins with its own letter;
- every answer is a single word (hyphens allowed, phrases not);
- no definition contains its answer or an inflection of it;
- no word repeats inside the set, or appears in another set at that level.

A set that fails is returned to the model with its specific problems and
regenerated, up to `--max-attempts`. A set that still fails is **discarded, not
written** — a half-correct round is worse than a missing level, and a missing
level is already a handled state (`RoscoLevelUnavailable`).

## What the gates cannot check

Whether a word actually belongs at its CEFR level, and whether a definition
teaches the word well. Both are judgement, and both need a human read before
the JSON is committed. The gates exist to make that read short, not to replace
it.

## Two layers, on purpose

These gates run at *authoring* time and stop bad content being written.
`rosco_impl/test/word_bank_assets_test.dart` runs in CI against the committed
assets and stops bad content *staying*. The overlap is deliberate: content can
also be edited by hand, and the CI test is what catches that.
