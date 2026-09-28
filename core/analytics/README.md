# analytics

Product analytics and crash reporting, with a Firebase-backed implementation (Analytics + Crashlytics). Part of the [modular-flutter-template](../../README.md) core modules.

Two packages:

- **`analytics_api`** — the abstract contract, pure Dart: `AnalyticsApi`,
  `CrashReporterApi` and `AnalyticsEvent`. Feature code depends on this,
  never on `analytics_impl`.
- **`analytics_impl`** — the implementations, `AnalyticsModule` and
  `AnalyticsRouteObserver`. Only the app's composition root depends on this.

## Using it

Workspace packages: depend on them by name, with no source:

```yaml
dependencies:
  analytics_api:
  analytics_impl:   # the app's composition root only
```

### Registering

Pick a backend per flavor, and register the module **after `LoggerModule`**:

```dart
LoggerModule(),
AnalyticsModule(
  backend: config.isProd
      ? FirebaseAnalyticsBackend(options: DefaultFirebaseOptions.currentPlatform)
      : const LoggingAnalyticsBackend(),
),
```

| Backend | Events go to | Use for |
| ------- | ------------ | ------- |
| `FirebaseAnalyticsBackend` | Firebase Analytics; errors to Crashlytics | release builds |
| `LoggingAnalyticsBackend` | `LoggerApi` | development — watch events without counting them |
| `DisabledAnalyticsBackend` | nowhere | tests, builds that must not collect |

The Firebase backend initialises Firebase during registration, and routes
uncaught Flutter and platform errors to Crashlytics (turn that off with
`captureUncaughtErrors: false`). If Firebase cannot start, the app still
does: both contracts are registered as disabled and the failure is logged.

### Screen views

Hand the router an observer; every page route with a name becomes a screen
view. Dialogs and unnamed routes are skipped.

```dart
AppGoRouterConfig(
  observers: [AnalyticsRouteObserver(analytics: container.get<AnalyticsApi>())],
  ...
);
```

Map a route whose name carries user data to a fixed name with
`screenName:`.

### Events

Events belong to each app, not to this package — define them next to the
feature that fires them:

```dart
final class RoundFinished extends AnalyticsEvent {
  RoundFinished({required String level, required int score})
    : super('round_finished', parameters: {'level': level, 'score': score});
}

unawaited(context.locator<AnalyticsApi>().logEvent(RoundFinished(...)));
```

Names are `snake_case`, at most 40 characters; parameter values are
`String`, `num` or `bool`. The Firebase implementation checks Firebase's
rules before sending, so a bad name is a logged warning rather than an event
that silently never arrives: reserved names (`session_start`, `error`, …)
and prefixes (`firebase_`, `google_`, `ga_`) are rejected, a `bool` is sent
as `'true'`/`'false'`, and a string is cut to 100 characters.

**Never put what a user typed or said into an event.** It turns a count into
personal data, and your privacy policy and store data-safety forms with it.

### Guarantees

- **Nothing here throws at its caller.** Every call completes normally
  whatever the network or the SDK does; failures are logged. Fire and forget
  with `unawaited`.
- Tests fake `AnalyticsApi` directly — it is five methods — or register
  `DisabledAnalyticsBackend`.

## Firebase setup in the host app

The app owns its Firebase configuration; this repo holds none.

1. Create the Firebase project and register an Android and an iOS app for
   each flavor's application id.
2. Run `flutterfire configure` in the app to generate
   `lib/firebase_options.dart` (or place `google-services.json` and
   `GoogleService-Info.plist` natively and pass no `options`).
3. Android: apply the `com.google.gms.google-services` and
   `com.google.firebase.crashlytics` Gradle plugins.
4. iOS: add the Crashlytics dSYM upload run script to the Runner target.
5. Declare analytics and crash data in the store privacy forms (Play Data
   safety, App Store privacy labels).

## Local development

Resolved with the rest of the workspace: run `flutter pub get` at the repo
root. Tests run with the others through `dart run melos test`.
