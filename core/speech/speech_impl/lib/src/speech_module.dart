import 'dart:async';

import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:speech_api/speech_api.dart';

import 'speech_recognizer_impl.dart';

/// {@template speech_module}
/// Registers the speech recogniser.
///
/// Registered lazily and as a singleton: the plugin holds a platform channel
/// and one audio session, so a second instance is not something the device
/// can honour.
///
/// The module does **not** call `initialize()` — that prompts for the
/// microphone, and a permission dialog at app start, before the player has
/// asked to play anything, is the wrong moment. The game screen initialises
/// on entry instead.
/// {@endtemplate}
final class SpeechModule implements DependencyModule {
  @override
  String get name => 'Speech';

  @override
  FutureOr<void> registerDependencies(DependencyContainer container) {
    container.registerLazySingleton<SpeechRecognizerApi>(
      (_) => SpeechRecognizerImpl(),
    );
  }
}
