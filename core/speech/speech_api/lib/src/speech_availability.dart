/// Why the recogniser cannot be used.
///
/// Each value is a *normal* state rather than an error: a player who has
/// declined the microphone, or a device with no recogniser installed, still
/// gets a playable game through the text-input fallback.
enum SpeechUnavailableReason {
  /// The player declined the microphone or speech-recognition prompt.
  permissionDenied,

  /// No speech-recognition service exists on this device. Common on Android
  /// devices shipped without Google's app, and on the iOS Simulator.
  noRecognizer,

  /// Recognition is blocked by device policy or parental controls.
  restricted,

  /// The platform failed for a reason it did not explain.
  unknown,
}

/// The outcome of initialising the recogniser.
///
/// Sealed so that a new reason to be unavailable cannot be silently ignored:
/// every caller switches exhaustively.
sealed class SpeechAvailability {
  const SpeechAvailability();
}

/// The recogniser initialised and may be listened to.
final class SpeechReady extends SpeechAvailability {
  const SpeechReady({this.locales = const []});

  /// Locale ids the device can recognise, e.g. `en_US`. May be empty when the
  /// platform declines to enumerate them; treat that as "use the default".
  final List<String> locales;
}

/// The recogniser cannot be used. Fall back to text input.
final class SpeechUnavailable extends SpeechAvailability {
  const SpeechUnavailable({required this.reason});

  final SpeechUnavailableReason reason;
}
