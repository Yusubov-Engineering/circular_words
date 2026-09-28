import 'package:speech_api/speech_api.dart';

/// Maps a plugin error code onto the reason the API speaks in.
///
/// The codes are raw platform strings — Android's documented
/// `SpeechRecognizer` set plus a handful iOS emits undocumented — so this is a
/// string match by necessity. Anything unrecognised becomes
/// [SpeechUnavailableReason.unknown] rather than being guessed at.
SpeechUnavailableReason speechReasonOf(String errorCode) {
  switch (errorCode) {
    case 'error_permission':
    case 'error_permission_denied':
      return SpeechUnavailableReason.permissionDenied;
    case 'error_speech_recognizer_disabled':
    case 'error_language_not_supported':
    case 'error_language_unavailable':
      return SpeechUnavailableReason.restricted;
    case _:
      return SpeechUnavailableReason.unknown;
  }
}

/// Error codes that must not end a session.
///
/// **On Android this list is the only thing standing between normal play and a
/// dead microphone**, because the plugin reports *every* Android error with
/// `permanent: true` — see `SpeechToTextPlugin.kt`, which writes that flag as
/// a constant. There is no such thing as a transient error on that platform as
/// far as the plugin is concerned, so transience has to be decided here, by
/// code.
///
/// Two kinds qualify:
///
/// - **Nothing was heard.** `error_no_match` and `error_speech_timeout` arrive
///   constantly during normal play; a player thinking for eight seconds
///   produces one.
/// - **The recogniser was still busy.** `error_client` and `error_busy` are
///   what Android says when a session is opened while the previous one is
///   still letting go — which is exactly what this app does at every letter,
///   deliberately. Measured on a Samsung S25 Ultra: answering a letter by
///   voice advanced the round, the new session raced the old one's teardown,
///   and `error_client` came back and was read as "this device has no speech
///   recognition". One correct answer disabled the microphone for the rest of
///   the round.
const kBenignSpeechErrors = {
  'error_no_match',
  'error_speech_timeout',
  'error_retry',
  'error_client',
  'error_busy',
};
