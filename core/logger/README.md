# logger

Structured logging, with a talker-backed implementation and an in-app log screen. Part of the [modular-flutter-template](../../README.md) core modules.

Two packages:

- **`logger_api`** — the abstract contract. Feature code and other `_api`
  packages depend on this, never on `logger_impl`.
- **`logger_impl`** — the concrete implementation. Only the app's composition
  root depends on this.

## Using it

Workspace packages: depend on them by name, with no source:

```yaml
dependencies:
  logger_api:
  logger_impl:   # the app's composition root only
```

## Local development

Resolved with the rest of the workspace: run `flutter pub get` at the repo
root. Tests run with the others through `dart run melos test`.
