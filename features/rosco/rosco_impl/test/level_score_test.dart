import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_api/rosco_api.dart';

void main() {
  group('LevelScore.beats', () {
    test('any score beats never having played', () {
      const score = LevelScore(correct: 0, total: 26, secondsRemaining: 0);

      expect(score.beats(null), isTrue);
    });

    test('more correct answers wins', () {
      const worse = LevelScore(correct: 10, total: 26, secondsRemaining: 90);
      const better = LevelScore(correct: 11, total: 26, secondsRemaining: 0);

      expect(better.beats(worse), isTrue);
      expect(worse.beats(better), isFalse);
    });

    // Answers rank above the clock deliberately: ranking speed first would
    // make passing on everything the fastest way to a "best" score.
    test('a faster round does not win on fewer answers', () {
      const slowAndRight = LevelScore(
        correct: 20,
        total: 26,
        secondsRemaining: 2,
      );
      const fastAndWrong = LevelScore(
        correct: 3,
        total: 26,
        secondsRemaining: 200,
      );

      expect(fastAndWrong.beats(slowAndRight), isFalse);
    });

    test('time breaks a tie on answers', () {
      const slower = LevelScore(correct: 15, total: 26, secondsRemaining: 12);
      const faster = LevelScore(correct: 15, total: 26, secondsRemaining: 40);

      expect(faster.beats(slower), isTrue);
      expect(slower.beats(faster), isFalse);
    });

    test('an equal score does not replace the stored one', () {
      const score = LevelScore(correct: 15, total: 26, secondsRemaining: 12);

      expect(score.beats(score), isFalse);
    });
  });

  group('LevelScore.fromJson', () {
    test('round-trips through toJson', () {
      const score = LevelScore(correct: 18, total: 26, secondsRemaining: 44);

      expect(LevelScore.fromJson(score.toJson()), score);
    });

    // This data has sat on a device across app versions, so a shape that no
    // longer parses must read as "not played yet" rather than crash the picker.
    test('rejects malformed stored data rather than throwing', () {
      expect(LevelScore.fromJson(null), isNull);
      expect(LevelScore.fromJson({}), isNull);
      expect(
        LevelScore.fromJson({
          'correct': '18',
          'total': 26,
          'secondsRemaining': 4,
        }),
        isNull,
      );
      expect(
        LevelScore.fromJson({'correct': 18, 'total': 0, 'secondsRemaining': 4}),
        isNull,
      );
    });

    test('rejects more correct answers than letters', () {
      expect(
        LevelScore.fromJson({
          'correct': 27,
          'total': 26,
          'secondsRemaining': 4,
        }),
        isNull,
      );
    });

    test('clamps a negative clock instead of discarding the score', () {
      final score = LevelScore.fromJson({
        'correct': 5,
        'total': 26,
        'secondsRemaining': -3,
      });

      expect(score?.secondsRemaining, 0);
      expect(score?.correct, 5);
    });
  });

  group('CefrLevel', () {
    test('parses its own ids, case-insensitively', () {
      for (final level in CefrLevel.values) {
        expect(CefrLevel.tryParse(level.id), level);
        expect(CefrLevel.tryParse(level.id.toUpperCase()), level);
      }
    });

    test('returns null for anything else, so a bad URL is not a crash', () {
      expect(CefrLevel.tryParse(null), isNull);
      expect(CefrLevel.tryParse(''), isNull);
      expect(CefrLevel.tryParse('d1'), isNull);
    });

    test('labels are the untranslated CEFR codes', () {
      expect(CefrLevel.b2.label, 'B2');
    });
  });
}
