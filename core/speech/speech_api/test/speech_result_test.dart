import 'package:speech_api/speech_api.dart';
import 'package:test/test.dart';

void main() {
  group('SpeechResult.candidates', () {
    test('puts the best transcript first, then the alternates', () {
      const result = SpeechResult(
        transcript: 'abundant',
        alternates: ['a bundant', 'abandoned'],
        isFinal: true,
      );

      expect(result.candidates, ['abundant', 'a bundant', 'abandoned']);
    });

    test('is the transcript alone when nothing else was offered', () {
      const result = SpeechResult(transcript: 'zebra', isFinal: false);

      expect(result.candidates, ['zebra']);
    });

    // The whole point of exposing `candidates`: an answer check that reads
    // only `transcript` throws away the alternate that was actually right.
    test('reaches an answer the top-ranked guess missed', () {
      const result = SpeechResult(
        transcript: 'flower',
        alternates: ['flour'],
        isFinal: true,
      );

      expect(result.candidates.contains('flour'), isTrue);
    });
  });
}
