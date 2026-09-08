# Contributing

## Before you open a PR

```bash
flutter pub get
dart format .
flutter analyze
dart run melos test
modular doctor
```

All five must pass — `modular` here is the globally-activated CLI (see
[The CLI](README.md#the-cli)); CI installs it from
[modular_cli](https://github.com/Yusubov-Engineering/modular_cli) the same way.

## Where the work is planned

[PLAN.md](PLAN.md) holds the game rules, the package map and the milestone
order. Work follows it. **When a decision in PLAN.md stops matching the code,
change PLAN.md in the same commit** — a plan that drifts from the code is worse
than no plan.

Milestone 5 (the game state machine, unit-tested with no UI) lands before
milestone 6 (the wheel) and milestone 7 (live speech). The pool arithmetic, the
pass queue and the lap logic are where the bugs are, and debugging them through
an animation is avoidable.

## Adding a feature

```bash
modular new feature <name>
```

That wires the workspace entry, the DI module and the module router. Two things
it does **not** do:

- add `<name>_impl:` to `app/pubspec.yaml` — do it by hand
- fix import ordering after a hand-inserted import — `directives_ordering` is
  an error, not a warning

A feature missing from `dependency_injection_configuration.dart` compiles fine
and fails at runtime. `modular doctor` exists largely to catch that.

## Things that are load-bearing

- **`remainingPool` is the only clock.** The per-letter countdown is derived
  from it, never stored alongside it. See
  [PLAN.md](PLAN.md#the-pool-is-the-only-clock).
- **A rejected answer leaves the letter `active`.** Only an accepted answer or
  an expired 10 s cap resolves one. Advancing on a wrong answer is the easiest
  rule here to break by accident.
- **Only two things end a round**: an empty pool, or every letter terminal.
  Not a wrong answer, not a lap with nothing answered.
- **Word-bank sets are complete A–Z or they are malformed.** The alphabet is
  never relaxed, not even for X and Z.
- **The game logic stays free of `BuildContext` and of any plugin.**
  `AnswerValidator` and `RoscoController` are testable with a fake repository
  and a fake recogniser, and they must stay that way — CI has no microphone.
- **Navigation is an effect**, never something a controller performs.
- **Speech is behind `SpeechRecognizerApi`.** Nothing in `features/` imports
  `speech_to_text`.
- **The text-input fallback stays reachable.** It is the degraded path for
  denied permissions, missing recognisers and offline devices, and it is also
  the test harness.

## Localization

Adding a language means two edits that must agree: a new
`base/app_localization/lib/src/l10n/app_<code>.arb` carrying every key from
`app_en.arb`, and a value on the `AppLocale` enum. `base/app_localization/test`
fails if the two drift apart.

UI chrome is localized. **Word definitions are not** — the English is the
subject being taught, not the interface.

## Style

- **Primary-constructor syntax** throughout, e.g.
  `final class NetworkModule({final bool enableLogging = false}) implements ...`
- **`abstract interface class`** for protocols in `_api` packages.
- **Lint rules change only in the separate `app_linter` repo**, never per package.
- **Design-system tokens, never raw values** — `context.spacing.spacingXl`, not `16.0`.
- A new colour token goes into **both** the `light()` and `dark()` factories.
