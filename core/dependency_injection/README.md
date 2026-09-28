# dependency_injection

DependencyContainer / DependencyModule abstraction, with a get_it-backed implementation. Part of the [modular-flutter-template](../../README.md) core modules.

Two packages:

- **`dependency_injection_api`** — the abstract contract. Feature code and other `_api`
  packages depend on this, never on `dependency_injection_impl`.
- **`dependency_injection_impl`** — the concrete implementation. Only the app's composition
  root depends on this.

## Using it

Workspace packages: depend on them by name, with no source:

```yaml
dependencies:
  dependency_injection_api:
  dependency_injection_impl:   # the app's composition root only
```

## Local development

Resolved with the rest of the workspace: run `flutter pub get` at the repo
root. Tests run with the others through `dart run melos test`.
