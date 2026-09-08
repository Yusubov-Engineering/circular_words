import 'package:flutter_test/flutter_test.dart';
import 'package:speech_api/speech_api.dart';
import 'package:speech_impl/src/speech_error_mapping.dart';

void main() {
  group('speechReasonOf', () {
    test('recognises the permission codes', () {
      expect(
        speechReasonOf('error_permission'),
        SpeechUnavailableReason.permissionDenied,
      );
      expect(
        speechReasonOf('error_permission_denied'),
        SpeechUnavailableReason.permissionDenied,
      );
    });

    test('treats a disabled or unsupported recogniser as restricted', () {
      expect(
        speechReasonOf('error_speech_recognizer_disabled'),
        SpeechUnavailableReason.restricted,
      );
      expect(
        speechReasonOf('error_language_not_supported'),
        SpeechUnavailableReason.restricted,
      );
    });

    // An unknown code must not be guessed into a specific reason: the player
    // sees a different fallback message for "you denied the microphone" than
    // for "something went wrong".
    test('falls back to unknown rather than guessing', () {
      expect(speechReasonOf(''), SpeechUnavailableReason.unknown);
      expect(
        speechReasonOf('error_something_new'),
        SpeechUnavailableReason.unknown,
      );
    });
  });

  group('kBenignSpeechErrors', () {
    // These arrive during normal play — a player thinking for eight seconds
    // produces error_speech_timeout. Tearing the session down on one would
    // end a letter that is going fine.
    test('covers the codes that mean "nothing was heard"', () {
      expect(kBenignSpeechErrors, contains('error_no_match'));
      expect(kBenignSpeechErrors, contains('error_speech_timeout'));
      expect(kBenignSpeechErrors, contains('error_retry'));
    });

    // The bug this pins: answering a letter by voice advances the round, the
    // next session races the previous one's teardown, and Android answers with
    // error_client. Read as fatal, one correct answer killed the microphone
    // for the rest of the round.
    test('covers the codes that mean "the recogniser was still busy"', () {
      expect(kBenignSpeechErrors, contains('error_client'));
      expect(kBenignSpeechErrors, contains('error_busy'));
    });

    test('does not swallow a permission failure', () {
      expect(kBenignSpeechErrors, isNot(contains('error_permission')));
      expect(kBenignSpeechErrors, isNot(contains('error_permission_denied')));
    });

    // Every code that is survivable must be listed as such, because the
    // plugin's own `permanent` flag is hardcoded true on Android and cannot
    // be used to tell the difference.
    test('a busy recogniser is not reported as a missing one', () {
      expect(
        speechReasonOf('error_client'),
        isNot(SpeechUnavailableReason.noRecognizer),
      );
      expect(
        speechReasonOf('error_busy'),
        isNot(SpeechUnavailableReason.noRecognizer),
      );
    });
  });
}
