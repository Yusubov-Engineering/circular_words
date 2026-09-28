# network

Envelope-agnostic REST client contract, with a dio-backed implementation. Part of the [modular-flutter-template](../../README.md) core modules.

Two packages:

- **`network_api`** — the abstract contract. Feature code and other `_api`
  packages depend on this, never on `network_impl`.
- **`network_impl`** — the concrete implementation. Only the app's composition
  root depends on this.

## Using it

Workspace packages: depend on them by name, with no source:

```yaml
dependencies:
  network_api:
  network_impl:   # the app's composition root only
```

## Local development

Resolved with the rest of the workspace: run `flutter pub get` at the repo
root. Tests run with the others through `dart run melos test`.
