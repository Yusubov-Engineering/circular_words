import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:rosco_impl/src/domain/word_set.dart';
import 'package:rosco_impl/src/router/rosco_result_args.dart';
import 'package:router_api/router_api.dart';

AppRouteArguments raw({
  String level = 'b1',
  Map<String, String> query = const {},
}) => AppRouteArguments(
  matchedPath: '/rosco/:level/result',
  pathParameters: {'level': level},
  queryParameters: query,
);

void main() {
  group('carrying a score through the URL', () {
    test('a round survives the round trip', () {
      const args = RoscoResultArgs(
        level: CefrLevel.b1,
        score: LevelScore(correct: 12, total: 26, secondsRemaining: 165),
      );

      final parsed = RoscoResultArgs.fromRaw(raw(query: args.toQuery()));

      expect(parsed.level, CefrLevel.b1);
      expect(parsed.score, args.score);
    });

    test('an unknown level opens the gentlest one', () {
      final parsed = RoscoResultArgs.fromRaw(raw(level: 'z9'));

      expect(parsed.level, CefrLevel.a1);
    });
  });

  // Every one of these is hand-editable and has to survive an app update.
  // This screen's whole job is to tell the player how they did, so it shows a
  // scoreless round rather than failing to build.
  group('a query string is never trusted', () {
    test('missing parameters read as a scoreless round', () {
      final parsed = RoscoResultArgs.fromRaw(raw());

      expect(parsed.score.correct, 0);
      expect(parsed.score.total, WordSet.letterCount);
      expect(parsed.score.secondsRemaining, 0);
    });

    test('nonsense reads as a scoreless round', () {
      final parsed = RoscoResultArgs.fromRaw(
        raw(query: {'correct': 'lots', 'total': '', 'left': '-4'}),
      );

      expect(parsed.score.correct, 0);
      expect(parsed.score.total, WordSet.letterCount);
      expect(parsed.score.secondsRemaining, 0);
    });

    test('more correct than there are letters is clamped, not believed', () {
      final parsed = RoscoResultArgs.fromRaw(
        raw(query: {'correct': '99', 'total': '26', 'left': '10'}),
      );

      expect(parsed.score.correct, 26);
      expect(parsed.score.total, 26);
    });

    test('a total of zero falls back to the alphabet', () {
      final parsed = RoscoResultArgs.fromRaw(
        raw(query: {'correct': '3', 'total': '0', 'left': '5'}),
      );

      expect(parsed.score.total, WordSet.letterCount);
      // And the answers survive it: a broken total must not zero the score.
      expect(parsed.score.correct, 3);
    });
  });
}
