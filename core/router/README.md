# router

Route/guard/shell navigation abstractions, with a go_router-backed implementation. Part of the [modular-flutter-template](../../README.md) core modules.

Two packages:

- **`router_api`** — the abstract contract. Feature code and other `_api`
  packages depend on this, never on `router_impl`.
- **`router_impl`** — the concrete implementation. Only the app's composition
  root depends on this.

## Using it

Workspace packages: depend on them by name, with no source:

```yaml
dependencies:
  router_api:
  router_impl:   # the app's composition root only
```

## Transitions

A route is presented natively unless it says otherwise. Set the app-wide
transition once, on the config, and let routes override it only when they
need to:

```dart
AppGoRouterConfig(
  routerModules: [...],
  initialLocation: ...,
  defaultPresentationMode: CustomPresentationMode(
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
);
```

`NativePresentationMode` and `NoTransitionPresentationMode` are the other
two modes. Before `v1.1.0` a route's `presentationMode` defaulted to native
directly; it is now `null` by default and falls back to the router's
`defaultPresentationMode`, which is itself native unless set.

## Local development

Resolved with the rest of the workspace: run `flutter pub get` at the repo
root. Tests run with the others through `dart run melos test`.
