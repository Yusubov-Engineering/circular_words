# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## What this is

**Circular Words** — a voice-driven English vocabulary game. The player picks a
CEFR level, then works around a circle of 26 letters: each letter shows a
definition and the player *speaks* the word matching it that starts with that
letter. 260 seconds, shared as a pool across the whole circle.

**Read [PLAN.md](PLAN.md) first.** It holds the game rules, the package map,
the speech pipeline, the milestone order, and a decisions log recording why
each rule is the way it is. This file describes the *architecture*; PLAN.md
describes *what is being built with it*. When a decision in PLAN.md stops
matching the code, update it in the same commit.

Structurally it is a **package-per-capability monorepo** generated from
[`modular_app_template`](https://github.com/Yusubov-Engineering/modular_app_template).
Every capability is two packages: an `_api` package holding the contract, and
an `_impl` package holding the implementation. It is a Dart/Flutter **native
pub workspace** (the root `pubspec.yaml` lists every package under
`workspace:`) plus **Melos** for monorepo scripts.

Generation is one-way: template fixes do not flow here. Port anything that
matters deliberately.

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

A single `flutter pub get` at the root resolves every package — there is no
per-package `pub get`. `flutter test` at the root finds **nothing**; use
`dart run melos test`, which runs it in each package that has a `test/`
directory.

Before claiming work is done, `flutter analyze`, `dart run melos test` and
`modular doctor` must all pass.

### The CLI

`modular` ships from its own repo,
[`Yusubov-Engineering/modular_cli`](https://github.com/Yusubov-Engineering/modular_cli) —
a separate Dart package with its own resolution, versioned and released
independently of this template. It is **not** part of the workspace.

```bash
dart pub global activate --source git https://github.com/Yusubov-Engineering/modular_cli.git --git-ref v1.0.0
modular new feature <name>       # _api + _impl pair, fully wired
modular doctor                   # check the architecture rules
modular gen assets               # regenerate asset definitions
modular rename --bundle-id com.acme.app --name "My App"
```

## Architecture

Dependencies flow downward: `app` → `features` → `base`/`core`.

- **`app/`** — the only leaf. Owns the app widget, flavors, and all composition
  in `app/lib/bootstrap/`. It is the single place that knows about concrete
  `_impl` packages.
- **`features/<name>/<name>_api` and `_impl`** — one per business domain. This
  app has two: `levels` (the CEFR picker, and the app's initial route) and
  `rosco` (the game itself plus its result screen). `levels_impl` reaches
  `rosco` through `rosco_api`'s launcher and never imports `rosco_impl` — see
  [Routing](#routing).
- **`base/`** — cross-feature primitives: `app_localization` (ARB translations,
  locale scope), `app_network_contract` (`AppResponse` and its parser).
- **`core/`** — infrastructure. `design_system` (+ `design_system/assets`) and
  `speech` (`speech_api`/`speech_impl`, wrapping `speech_to_text`) live
  in-tree; speech is infrastructure rather than domain, which is why it gets
  the `_api`/`_impl` split and the game feature can fake it in tests. `network`, `router`, `logger`, `dependency_injection`,
  `storage`, `biometric_auth` (each an `_api`/`_impl` pair), `state_manager`
  and `app_linter` (analysis options only, not a Dart library) each live in
  their own `Yusubov-Engineering/<module>` repo and are pulled in as `git:`
  dependencies pinned to a `vX.Y.Z` tag — see `app/pubspec.yaml`. They are no
  longer pub workspace members: bumping one means cutting a new tag in its
  repo and moving every consumer's `ref:`, not editing a local path.

### The `_api` / `_impl` rule

**`_api` says what a capability can do; `_impl` says how it does it.**

- `_api` — abstract interfaces only. Feature code and other `_api` packages
  depend on these, never on an `_impl`.
- `_impl` — the concrete implementation. **Only `app` imports `_impl` packages.**
  `implementation_imports` is an analyzer **error**, so a package's `lib/src/` is
  genuinely unreachable from outside it.

Each feature `_api` exposes exactly one protocol — `<Feature>Api` — grouping
everything other modules may use, resolved with
`context.locator<RoscoApi>()`. Use case protocols belong there as they
appear.

Its `_impl` counterpart is laid out identically for every feature:

```
lib/<feature>_impl.dart                      # barrel: module + module router only
lib/src/router/<feature>_route_info.dart     # const addresses — NEVER exported
lib/src/router/<feature>_module_router.dart  # the route table
lib/src/di/<feature>_launcher_impl.dart
lib/src/di/<feature>_api_impl.dart
lib/src/di/<feature>_module.dart
```

**Do not create this by hand — run `modular new feature <name>`.** It also does
the wiring, which is the part that is easy to forget.

### Dependency injection

`dependency_injection_api` defines the abstraction independent of any DI
library: `DependencyLocator`/`DependencyContainer` and `DependencyModule`, which
every core capability and every feature implements.
`dependency_injection_impl` implements it over `get_it`.

`app/lib/bootstrap/dependency_injection_configuration.dart` is the single list of
modules registered at startup. **A feature missing from that list compiles fine
and fails at runtime** — `modular doctor` exists largely to catch this.

Module **order matters**: a module may resolve what an earlier one registered
(`StorageModule` precedes anything reading from storage). There is no dependency
declaration between modules, so keep new entries below what they depend on.

### Routing

- `router_api` defines the abstractions; `router_impl` implements them over
  `go_router`. No feature may import `go_router`.
- **Route addresses are private to `_impl`.** `<Feature>RouteInfo` holds plain
  `static const AppRouteInfo` values and is never exported from the barrel.
- **Cross-module navigation goes through the launcher, which returns a request
  rather than navigating**, so the caller picks the verb:

  ```dart
  // levels_screen.dart, handling a StartGame effect
  final rosco = context.locator<RoscoApi>();
  context.navigation.pushRoute(rosco.launcher.game(level: level)); // or goRoute
  ```

  `levels_impl` therefore depends on `rosco_api` and never on `rosco_impl`,
  and it names no path belonging to `rosco`.

- **Intra-module navigation skips the facade** — inside the owning package use
  the route info directly:

  ```dart
  // inside rosco_impl, going from the game to its own result screen
  context.navigation.pushRoute(
    const AppRouteRequest(routeInfo: RoscoRouteInfo.result),
  );
  ```

- `app/lib/bootstrap/router_configuration.dart` assembles all feature routers. It
  resolves `<Feature>Api` facades *before* `AppNavigationService` is registered,
  which is why a launcher must never hold one.

### State management

`state_manager` (own repo, git dependency) is a from-scratch State/Event/Effect implementation with no
third-party dependency. A controller extends
`AppStateController<S, E, F>`: `emit` for state, `emitEffect` for one-shot
effects, `onInit` for the screen's initial load. **Navigation is an effect**,
never something the controller performs — that keeps it free of `BuildContext`.
The game's round logic lives in `RoscoController` — the timer pool, the pass
queue and the lap counter — and it holds no `BuildContext` and no plugin, which
is what lets milestone 5 test a whole round with no microphone and no widget
tree.

A screen wires all of it through one widget:

```dart
AppStateProvider(
  create: RoscoController.new,     // creates, calls onInit, disposes
  onEffect: _onEffect,             // one effect handler per screen
  child: const _RoscoView(),
)
```

and rebuilds on state without passing the controller down:

```dart
AppControllerBuilder<RoscoController>(
  builder: (context, controller) => Text('${controller.state.remainingPool}'),
)
```

Use `AppControllerSelector<C, T>` instead when only one slice of the state
should trigger a rebuild. Both find the controller through the enclosing
provider; `context.controllerOf<C>()` gets it directly for dispatching.

Two things to get right:

- **Never write `AppStateProvider`'s type arguments.** All four are inferred
  from `create`, and naming only the controller is a compile error — Dart has
  no partial type arguments.
- **`context.controllerOf` does not work inside `onEffect`.** The provider
  passes its *own* context, which sits above the `_AppStateScope` it builds,
  so the lookup asserts rather than resolving. A screen whose effect handler
  must dispatch back into its controller has to hold the instance it created
  (see `levels_screen.dart`); the provider still owns the lifetime.
- **Give `onEffect` a named method**, `void _onEffect(BuildContext context,
  RoscoEffect effect)`, not an inline closure. A closure's parameter infers
  as `Object?`, which silently turns the exhaustive `switch` into a
  non-exhaustive one — and annotating a closure parameter to fix that trips
  `avoid_types_on_closure_parameters`, so the named method is the only form
  that is both correct and lint-clean.

Effects are not replayed. Emit them from a dispatched event or from `onInit` —
never from a constructor, where nothing is listening yet.

`RoscoController` starts a `Timer.periodic` and a speech `StreamSubscription`
in `onInit`, so it **must cancel both in an overridden `dispose()`**. A game
screen leaks more visibly than most.

### Design system

`core/design_system` owns tokens (colour, spacing, radius, size, typography),
theming, and a small set of example components.

- **Always use tokens, never raw values**: `context.spacing.spacingXl`, not
  `16.0`; `context.textColors.textPrimary`, not `Color(0xFF...)`.
- The token set is deliberately small. Adding a token means adding it to **both**
  the `light()` and `dark()` factories.
- Assets are referenced through the generated `AppVectorAssets` /
  `AppRasterAssets`, never by a raw path. After adding a file to
  `core/design_system/assets/{vectors,rasters}/`, run `modular gen assets` — those
  files are generated and committed, and CI checks they are current.

### The data layer

The `_api`/`_impl` split is about **module boundaries**, not about what happens
inside a module. Repositories, DTOs and error types live in `_impl/lib/src/`
and are invisible across every boundary above, so each feature shapes them as
its domain needs.

`rosco` is the worked example, and the layout to copy. Its data is bundled
JSON assets rather than a backend, but the shape is the same one a networked
feature would use:

```
rosco_impl/lib/src/
  domain/word_entry.dart           # one letter's word and clue
  domain/word_set.dart             # a complete A-Z round
  domain/word_bank_repository.dart # the feature's data contract
  domain/rosco_failure.dart        # sealed: unavailable / malformed / unknown
  data/word_entry_dto.dart         # the asset shape, decoded defensively
  data/word_bank_asset_data_source.dart  # the only place an asset path is named
  data/word_bank_repository_impl.dart    # DTO → model, exception → failure
  data/rosco_scoreboard_impl.dart        # best scores over standard storage
  shared/rosco_failure_l10n.dart         # failure → sentence, at the widget layer
```

Three rules hold it together:

- **The repository throws `RoscoFailure` and nothing else.** Mapping happens
  once, exhaustively over the sealed hierarchy — so a new failure kind fails to
  compile rather than quietly becoming "something went wrong".
- **Failures reach the widget as values, not strings.** A controller has no
  `BuildContext`, so it cannot localize; a `RoscoFailureL10n.message(context)`
  in `lib/src/shared/` turns the failure into a sentence at the only layer that
  can.
- **Controllers take their dependencies in.** `RoscoController({required
  this._repository, required this._recognizer})`, with the screen passing
  `context.locator()` from `AppStateProvider.create`. The container is never
  touched inside a controller — that is what makes the round testable with a
  fake repository and a fake recogniser.

Registration lives in the feature's module, under types declared in `lib/src/`
— shared container, private contracts:

```dart
container
  ..registerLazySingleton<WordBankDataSource>(...)
  ..registerLazySingleton<WordBankRepository>(...)
  ..registerLazySingleton<RoscoApi>((_) => const RoscoApiImpl());
```

Nothing about this is prescribed by the architecture. It is one example of what
`_impl/lib/src/` is *for* — see [PLAN.md](PLAN.md#7-word-bank) for the asset
schema itself.

### Startup flow

`main.dart` → `initializer()`:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `DependencyInjectionConfiguration.initialize()` → `DependencyContainer`
3. `RouterConfiguration.initialize(container)` → `AppRouterConfig`
4. `runApp` wraps `DependencyScope` → `RouterScope` → `AppThemeScopeWrapper` →
   `AppLocaleScopeWrapper` → `RootApp`

## Conventions

- **Primary-constructor class syntax**, e.g.
  `final class NetworkModule({final bool enableLogging = false}) implements ...`
  rather than a classic constructor body. Follow this in new classes.
- **`abstract interface class`** for protocols in `_api` packages, not
  `abstract class`.
- **Lint rules change only in the separate `app_linter` repo** (Yusubov-Engineering/app_linter), never per package. The ruleset
  is strict: `strict-casts`, `strict-inference`, `strict-raw-types`,
  `require_trailing_commas`, `prefer_relative_imports`, `sort_constructors_first`,
  `directives_ordering`.
- Configuration is read via `String.fromEnvironment` in
  `app/lib/bootstrap/flavor/app_config.dart`, supplied with
  `--dart-define-from-file`.

## Editing traps

- **Generator anchors.** `pubspec.yaml`, `dependency_injection_configuration.dart`
  and `router_configuration.dart` carry `// <generated:...>` comments that
  `modular new feature` inserts above. Do not remove them.
- **`modular new feature` only appends.** It adds the workspace entry, the DI
  module and the module router, but it never removes anything, and it does
  **not** add the new `<name>_impl:` dependency to `app/pubspec.yaml`. Do that
  by hand, then re-check the import ordering — `directives_ordering` is an
  error, and a hand-inserted import lands in the wrong place.
- **Generated localization** (`base/app_localization/lib/src/generated/`) is
  gitignored and rebuilt by `flutter pub get`. Edit the ARB files instead.
- **Adding a language** means two edits that must agree: a new
  `lib/src/l10n/app_<code>.arb` with every key from `app_en.arb`, and a value
  on the `AppLocale` enum. `supportedLocales` derives from that enum, so
  nothing else needs touching — and `base/app_localization/test` fails if the
  two ever drift apart. Ships with en, ar, az, es, ru, tr, zh.
- **`config/*.json` still points at JSONPlaceholder.** Inherited from the
  template and currently unused — the word bank ships as bundled assets, not
  over the network. Replace `API_BASE_URL` (and `AppResponseParser` with it)
  if and when a backend appears.
- **The timer is one clock.** `remainingPool` is the single source of truth;
  the per-letter countdown is *derived* from it. Storing both independently
  lets them drift, and the last letter ends up offered time the pool cannot
  pay for. See [PLAN.md](PLAN.md#the-pool-is-the-only-clock).
- **Speech needs a physical device.** The iOS Simulator cannot do speech
  recognition reliably, so CI never covers that path. Keep the game logic
  behind `SpeechRecognizerApi` and testable through the text-input fallback.
  `app/lib/speech_probe.dart` is a standalone entry point for exercising the
  recogniser on hardware — it is not part of the app and is never routed to.
- **Never wait for a final speech result.** Measured on device, the final
  lands ~5 s after a partial that already held the same transcript and the
  same alternates. Act on partials; the final adds latency, not accuracy.
- **On Android, `error.permanent` is always true.** The plugin writes the flag
  as a constant, so it cannot tell a fatal error from a routine one.
  `kBenignSpeechErrors` is the real decision, and anything missing from it
  kills the microphone. `error_client`/`error_busy` mean "the recogniser was
  still busy" — which this app provokes at every letter — and were once read
  as "this device has no speech recognition": one correct answer disabled
  speech for the rest of the round.
- **Speech callbacks are global, not per session.** Errors and statuses
  belonging to a session that has just been torn down arrive *after* the next
  session starts, and land on it. Both guards in `SpeechRecognizerImpl` exist
  for that: a session ignores a stop until the platform has confirmed it
  started, and ignores one that arrives within `_statusSettling` of starting.
- **Never wait for a platform "final".** The caller settles an utterance: a
  session ending means whatever was last heard is what was said. Waiting
  instead blocks re-opening the microphone, which measured as 2.7 s shut out
  of every 3 s of silence.
- **A closed speech stream does not mean the letter is over.** Re-open a
  session while the round is still running; only the round's clock ends a
  letter.
- **Do not restart the microphone on every letter.** A letter changing leaves
  a working session alone; `MicController` only opens one when none is running.
  Restarting per letter meant 26 teardowns a round, each an audible tone from
  the platform plus a gap with no microphone — landing exactly where the player
  speaks, right after a new clue.
- **`kMicSessionSeconds` is measured, and longer is not always better.** At
  60 s the app heard 9 words of 10; at the round's 260 s it heard 2, because a
  silence window that long puts the recogniser into a continuous mode the
  plugin drops on the floor (`_notifyResults` returns early once a session has
  produced a final). Symptom: the microphone looks open, no tone sounds, and
  nothing is heard. Do not raise it without re-measuring on hardware.
- **A speech partial is worth scoring but never worth rejecting.**
  `RoscoAnswered.tentative` says which. Scoring partials is what makes the
  game playable; *rejecting* them flashes the miss line on every syllable of a
  word being said correctly.
- **Nested `AppStateProvider`s reach outward, never inward.** `onEffect` is
  handed the provider's own `BuildContext`, which sits above the scope that
  provider builds and below every scope around it. So the mic provider's
  `onEffect` finds `RoscoController` — that lookup *is* the bridge between
  speech and gameplay — and cannot find `MicController`. Nesting order is
  therefore load-bearing, not cosmetic.
- **Capture a controller in `didChangeDependencies`, not `initState` or
  `dispose`.** `context.controllerOf` reads an inherited widget: `initState`
  is too early and `dispose` too late. `_RoundBody` holds the field it
  captured there, which is what lets it stop the microphone on the way out.
- **The microphone re-opens itself, but not forever.** Six sessions per
  prompt. Real play needs two or three; anything beyond that is the platform
  closing every session as it opens, and an uncapped retry would spin for the
  rest of the round.
- **`letterRemaining` is `min(cap - spent, pool)`, not `min(cap, pool - spent)`.**
  The pool is already decremented every tick, so subtracting the letter's
  spend from it again double-counts and the letter shows a full ten seconds
  however long it has been open.
- **A rejected answer must not advance the letter.** The obvious way to
  "handle a wrong answer" resolves the letter and moves on; here the letter
  stays `active` and the player retries until the 10 s cap expires. Likewise,
  nothing ends the round except an empty pool or an all-terminal board — not a
  wrong answer, not a lap with no answers. See
  [PLAN.md](PLAN.md#nothing-ends-the-round-early).
- **`enabled` and `status` on the microphone move together.** They disagreed
  once — the give-up path set `status: idle` and left `enabled: true` — and the
  result was a button that read as off whose tap turned it *further* off. Any
  state a control is drawn from must be the state its tap handler reads.
- **Distinguish "the player turned it off" from "it gave up."** A microphone
  that gave up is revived at the next letter; one the player switched off stays
  off. Without `_playerOff` there is no way to do the first without undoing the
  second.
- **The text scaler is bounded, not pinned.** `app/lib/app.dart` once passed
  the same value as both min and max, which silently discards the system font
  size. If you touch that clamp, keep the max above the min.
- **Feedback must never throw at its caller.** `GameFeedbackImpl` swallows
  everything on purpose: a cue comments on something that already happened, so
  a missing codec or absent vibrator must not take the round down with it.
- **Muting covers sound only.** Haptics follow the system's own setting, and a
  player who silences a game in a quiet room usually still wants to feel it.
- **Reserve space with a minimum height, never a fixed one.** A `SizedBox`
  around text clips it above roughly a 1.3 font scale. Use `ConstrainedBox`
  with `minHeight` so the row still cannot jump around.
- **A `CustomPaint` contributes nothing to the semantics tree.** The wheel, the
  mic button and the speaker icon all draw themselves, so each carries an
  explicit `Semantics` label. A painted control with no label is invisible to a
  screen reader however large it looks.
- **Sound assets are generated, not sourced.**
  `tool/sound_authoring/generate_sounds.py` writes them; regenerate rather than
  hand-editing, and keep the `packages/feedback_impl/` asset prefix — the same
  trap the word bank hit.
- **Word-bank content is generated, not hand-written.**
  `tool/word_bank_authoring/` drives Claude at *authoring* time and writes the
  bundled JSON; the app never calls an API and holds no key. Add words with
  that tool, review its output, then commit — do not hand-edit an asset
  without re-running `dart run melos test`.
- **Every word-bank asset is a complete A–Z set.** The alphabet is never
  relaxed, so a set with a missing letter is rejected as malformed rather than
  played short.
- **Package assets need the `packages/rosco_impl/` prefix.** Without it the
  path still resolves in that package's own tests and fails only in the app.
  `word_bank_real_assets_test.dart` pins the production path for that reason.
- **`FlutterError` is an `Error`, and the lints forbid catching it.** The
  bundle signals a missing asset with one, so `WordBankAssetDataSource`
  converts it into a plain exception at the boundary rather than letting that
  knowledge leak upward as a message match.

## What the architecture does not decide

The `_api`/`_impl` split is about **module boundaries**, not about what happens
inside a module. Repositories, DTOs, error types and networking conventions live
in `_impl/lib/src/` and are invisible across every boundary above.

So `rosco_impl` is free to arrange its internals as the domain needs — the
word-bank data source, the sealed `RoscoFailure`, and `AnswerValidator` are
that package's business and nothing outside it can see them. The layout
described under [The data layer](#the-data-layer) is one worked example
inherited from the template, not a mandated shape.

The one internal rule that *is* load-bearing: `AnswerValidator` and the game
state machine stay free of `BuildContext` and of any plugin, because milestone
5 tests the whole round with no microphone and no widget tree.
