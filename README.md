# Circular Words

A voice-driven English vocabulary game. Pick a CEFR level, then work your way
around a circle of 26 letters: each letter shows a definition, and you **speak**
the word that matches it and starts with that letter.

Built on
[`modular_app_template`](https://github.com/Yusubov-Engineering/modular_app_template) —
a package-per-capability Flutter monorepo where every capability is an `_api`
package holding the contract and an `_impl` package holding the implementation.

> **The build plan lives in [PLAN.md](PLAN.md).** Game rules, package map,
> speech pipeline, milestones and the decisions log are all there. Read it
> before starting work; update it in the same commit when a decision changes.

## The game

| Rule | Value |
| ---- | ----- |
| Letters | 26 (A–Z) |
| Total time | 260 s, a shared pool |
| Per letter | 10 s soft cap |
| Passing | Allowed — passed letters come back on a later lap |
| Wrong answer | Never ends the round — you play on |
| Alphabet | Always A–Z, rare letters included |
| Levels | CEFR A1, A2, B1, B2, C1, C2 |

The 260 s is a **pool**, not 26 separate timers. Answer in 3 s and the other
7 s stays available for later letters — that banked time is what makes a second
lap possible, and what makes the circle more than decoration.

Nothing ends a round early. A wrong answer costs you time, not the game; you
can keep trying a letter until its 10 s runs out; and the round plays on until
the pool is empty or every letter is resolved.

## Commands

Run everything from the repo root.

| Task | Command |
| ---- | ------- |
| Resolve all packages | `flutter pub get` |
| Analyze everything | `flutter analyze` |
| Format | `dart format .` |
| Test | `dart run melos test` |
| Architecture rules | `modular doctor` |
| Run the app | `cd app && flutter run --flavor dev --dart-define-from-file=../config/dev.json` |

One `flutter pub get` at the root resolves every package — there is no
per-package `pub get`. `flutter test` at the root finds **nothing**; use
`dart run melos test`, which runs tests in each package that has a `test/`
directory.

Before calling work done, `flutter analyze`, `dart run melos test` and
`modular doctor` must all pass.

> **Speech needs a physical device.** The iOS Simulator cannot do speech
> recognition reliably, so CI never covers that path. The game is playable
> through the text-input fallback everywhere else.

## Layout

```
app/                          composition root — the only package that
                              imports _impl packages
base/
  app_localization/           ARB translations (en, ar, az, es, ru, tr, zh)
  app_network_contract/       AppResponse and its parser
core/
  design_system/              tokens, theming, components
features/
  levels/                     levels_api + levels_impl  — level picker
  rosco/                      rosco_api  + rosco_impl   — the game
config/                       dev.json / prod.json, read via --dart-define-from-file
```

Dependencies flow downward: `app` → `features` → `base`/`core`. Only `app`
imports an `_impl`; everything else depends on the `_api` contract.
`implementation_imports` is an analyzer **error**, so a package's `lib/src/` is
genuinely unreachable from outside it.

Core infrastructure — `network`, `router`, `logger`, `storage`,
`dependency_injection`, `biometric_auth`, `speech`, `state_manager`, `app_linter` — lives
in its own `Yusubov-Engineering/<module>` repo and is pulled in as a `git:`
dependency pinned to a tag. See `app/pubspec.yaml`.

## The CLI

```bash
dart pub global activate --source git https://github.com/Yusubov-Engineering/modular_cli.git --git-ref v1.0.0

modular new feature <name>    # _api + _impl pair, wired into the app
modular doctor                # check the architecture rules
modular gen assets            # regenerate asset definitions
```

`modular new feature` also does the wiring — workspace entry, DI module, module
router. That is the part that is easy to forget: a feature missing from
`dependency_injection_configuration.dart` compiles fine and fails at runtime.

Two things it does **not** do, which you must handle by hand:

- add the new `<name>_impl:` dependency to `app/pubspec.yaml`
- remove anything — it only appends

## Working here

[CLAUDE.md](CLAUDE.md) documents the architecture in full: the `_api`/`_impl`
rule, dependency injection, routing, `state_manager`, the design system, and
the editing traps worth knowing before touching generated wiring or ARB files.
