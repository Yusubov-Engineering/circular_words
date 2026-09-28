# speech

On-device speech recognition, with a `speech_to_text`-backed implementation. Part of the [modular-flutter-template](../../README.md) core modules.

Two packages:

- **`speech_api`** — the abstract contract: `SpeechRecognizerApi`, the sealed
  `SpeechAvailability` and `SpeechResult`. Feature code and other `_api`
  packages depend on this, never on `speech_impl`.
- **`speech_impl`** — the concrete implementation over `speech_to_text`, and
  `SpeechModule`. Only the app's composition root depends on this.

## Using it

Workspace packages: depend on them by name, with no source:

```yaml
dependencies:
  speech_api:
  speech_impl:   # the app's composition root only
```

The host app still owns the platform setup `speech_to_text` needs: the
microphone and speech-recognition usage descriptions in `Info.plist`, and the
`RECORD_AUDIO` permission in `AndroidManifest.xml`.

## Local development

Resolved with the rest of the workspace: run `flutter pub get` at the repo
root. Tests run with the others through `dart run melos test`.

Speech recognition needs a physical device; the iOS Simulator cannot do it
reliably, so the tests here cover only the platform-free parts.
