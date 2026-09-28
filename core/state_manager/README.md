# state_manager

From-scratch State/Event/Effect state management, with no third-party
dependency. Part of the [modular-flutter-template](../../README.md)
core modules.

A single package (no `_api`/`_impl` split — there is nothing to swap an
implementation of).

## Using it

A workspace package: depend on it by name, with no source:

```yaml
dependencies:
  state_manager:
```

## Local development

Resolved with the rest of the workspace: run `flutter pub get` at the repo
root. Tests run with the others through `dart run melos test`.
