# app_linter

The shared analysis-options ruleset for [modular-flutter-template](../../README.md)
and everything generated from it. Not a Dart library — it ships lint rule
sets under `lib/`, included by other packages' `analysis_options.yaml`.

## Using it

A workspace package: add it as a dev dependency by name, with no source,
then include its ruleset:

```yaml
dev_dependencies:
  app_linter:
```

```yaml
# analysis_options.yaml
include: package:app_linter/analysis_options.yaml
```

## Local development

Resolved with the rest of the workspace: run `flutter pub get` at the repo
root. Tests run with the others through `dart run melos test`.
