import 'speech_availability.dart';
import 'speech_result.dart';

/// {@template speech_recognizer_api}
/// On-device speech recognition, stated without reference to any plugin.
///
/// This exists as a core capability rather than as part of the game so that
/// game logic depends on an interface it can fake. Nothing under `features/`
/// imports a speech plugin, and the whole round is therefore testable with no
/// microphone — which matters, because CI has none and the iOS Simulator
/// cannot recognise speech reliably.
/// {@endtemplate}
abstract interface class SpeechRecognizerApi {
  /// Prepares the recogniser, prompting for permission the first time.
  ///
  /// Safe to call more than once; later calls report the current state without
  /// prompting again. Returning [SpeechUnavailable] is an ordinary outcome,
  /// not an exception — the caller degrades to text input.
  Future<SpeechAvailability> initialize();

  /// Whether a listening session is currently open.
  bool get isListening;

  /// Opens one listening session and streams recognition updates.
  ///
  /// The stream closes when the platform gives up, when [maxDuration] elapses,
  /// or when [stop]/[cancel] is called.
  ///
  /// **Hold a session for as long as the caller can use it.** Re-listening is
  /// not free: the platform plays an audible tone as it opens, and there is a
  /// gap with no microphone at all while it does. Callers should size
  /// [maxDuration] to the whole span they want to hear, not to one prompt, and
  /// re-listen only when a session has actually ended.
  ///
  /// [pauseFor] is how long a silence must last before the platform decides
  /// the speaker finished — and on Android it doubles as the whole listening
  /// window, so a short value closes the microphone on a thinking speaker.
  /// Errors reaching the platform surface as a stream error carrying
  /// [SpeechUnavailable].
  Stream<SpeechResult> listen({
    Duration maxDuration = const Duration(seconds: 10),
    Duration pauseFor = const Duration(seconds: 3),
    String? localeId,
  });

  /// Ends the session, keeping whatever has been recognised so far.
  Future<void> stop();

  /// Ends the session and discards the result.
  Future<void> cancel();

  /// Releases platform resources. The owning module calls this at teardown.
  Future<void> dispose();
}
