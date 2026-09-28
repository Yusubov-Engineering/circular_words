# biometric_auth

Face ID / Touch ID biometric authentication, part of the [modular-flutter-template](../../README.md) core modules.

Two packages:

- **`biometric_auth_api`** — the abstract contract. Feature code and other `_api`
  packages depend on this, never on `biometric_auth_impl`.
- **`biometric_auth_impl`** — the concrete implementation. Only the app's composition
  root depends on this.

## Using it

Workspace packages: depend on them by name, with no source:

```yaml
dependencies:
  biometric_auth_api:
  biometric_auth_impl:   # the app's composition root only
```

## Local development

Resolved with the rest of the workspace: run `flutter pub get` at the repo
root. Tests run with the others through `dart run melos test`.
