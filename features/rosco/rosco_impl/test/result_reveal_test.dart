import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:rosco_impl/src/domain/rosco_failure.dart';
import 'package:rosco_impl/src/domain/word_bank_repository.dart';
import 'package:rosco_impl/src/domain/word_entry.dart';
import 'package:rosco_impl/src/domain/word_set.dart';
import 'package:rosco_impl/src/result/result_controller.dart';
import 'package:rosco_impl/src/router/rosco_result_args.dart';
import 'package:rosco_impl/src/share/result_card.dart';
import 'package:router_api/router_api.dart';

import 'recording_analytics.dart';

import 'result_controller_test.dart' show FakeScoreboard, score;

WordSet alphabetSet(String id) => WordSet(
  id: id,
  level: CefrLevel.b1,
  entries: [
    for (final letter in WordSet.alphabet.split(''))
      WordEntry(
        letter: letter,
        word: '${letter.toLowerCase()}word',
        definition: 'Clue for $letter.',
      ),
  ],
);

final class SetsRepository implements WordBankRepository {
  SetsRepository(this.sets, {this.fails = false});

  final List<WordSet> sets;
  final bool fails;

  @override
  Future<WordSet> randomSet(CefrLevel level) async => sets.first;

  @override
  Future<List<WordSet>> setsFor(CefrLevel level) async {
    if (fails) throw RoscoLevelUnavailable(levelId: level.id);
    return sets;
  }
}

/// Every letter answered except those in [missed].
List<bool> marksMissing(Set<String> missed) => [
  for (final letter in WordSet.alphabet.split('')) !missed.contains(letter),
];

Future<ResultState> reveal({
  WordBankRepository? repository,
  String? setId = 'b1-2',
  List<bool>? marks,
}) async {
  final controller = ResultController(
    scoreboard: FakeScoreboard(),
    analytics: RecordingAnalytics(),
    repository:
        repository ??
        SetsRepository([alphabetSet('b1-1'), alphabetSet('b1-2')]),
    level: CefrLevel.b1,
    score: score(24),
    setId: setId,
    marks: marks ?? marksMissing({'C', 'X'}),
  );
  await controller.onInit();
  final state = controller.state;
  controller.dispose();
  return state;
}

AppRouteArguments raw(Map<String, String> query) => AppRouteArguments(
  matchedPath: '/rosco/:level/result',
  pathParameters: const {'level': 'b1'},
  queryParameters: query,
);

void main() {
  group('the result URL carries what was missed', () {
    test('set and marks survive the round trip', () {
      final args = RoscoResultArgs(
        level: CefrLevel.b1,
        score: score(24),
        setId: 'b1-2',
        marks: marksMissing({'C', 'X'}),
      );

      final parsed = RoscoResultArgs.fromRaw(raw(args.toQuery()));

      expect(parsed.setId, 'b1-2');
      expect(parsed.marks, args.marks);
    });

    // A short or garbled record could pin the wrong word on a letter.
    test('a partial or garbled record is dropped, not guessed at', () {
      for (final bad in ['ccw', 'x' * 26, '${'c' * 25}?', '']) {
        expect(
          RoscoResultArgs.fromRaw(raw({'marks': bad})).marks,
          isNull,
          reason: bad,
        );
      }
    });

    test('a URL from before this existed still opens', () {
      final parsed = RoscoResultArgs.fromRaw(raw({'correct': '3'}));

      expect(parsed.setId, isNull);
      expect(parsed.marks, isNull);
      expect(parsed.score.correct, 3);
    });
  });

  group('revealing the missed words', () {
    test('names exactly the letters that were not answered', () async {
      final state = await reveal();

      expect(state.missed?.map((l) => l.entry.word), ['cword', 'xword']);
      expect(state.letters, hasLength(WordSet.letterCount));
    });

    test('a perfect round has nothing to reveal', () async {
      final state = await reveal(marks: marksMissing({}));

      expect(state.missed, isEmpty);
    });

    // Naming the wrong word as *the* answer is the one thing a learning game
    // must not do, so every doubtful case reveals nothing.
    test('reveals nothing when the set is gone', () async {
      expect((await reveal(setId: 'b1-9')).missed, isNull);
    });

    test('reveals nothing when the set is unknown', () async {
      expect((await reveal(setId: null)).missed, isNull);
    });

    test('reveals nothing when the word bank fails', () async {
      final state = await reveal(
        repository: SetsRepository(const [], fails: true),
      );
      expect(state.missed, isNull);
    });

    test('reveals nothing when the marks do not cover the alphabet', () async {
      expect((await reveal(marks: [true, false])).missed, isNull);
    });
  });

  group('the share card', () {
    testWidgets('renders a PNG at the card size', (tester) async {
      final state = await reveal();
      late Uint8List png;

      await tester.runAsync(() async {
        png = await renderResultCard(
          result: state,
          colors: const ResultCardColors(
            background: Color(0xFFEEF4FF),
            surface: Color(0xFFFFFFFF),
            title: Color(0xFF181D27),
            muted: Color(0xFF535862),
            accentSolid: Color(0xFF444CE7),
            accentOnSolid: Color(0xFFFFFFFF),
            accentSoft: Color(0xFFEEF4FF),
            correct: Color(0xFF17B26A),
            missed: Color(0xFFF04438),
            neutral: Color(0xFFE9EAEB),
            onFill: Color(0xFFFFFFFF),
            track: Color(0xFFE9EAEB),
          ),
          typography: AppTypography.regular(),
          appName: 'Circular Words',
          caption: '24 of 26 correct',
        );
      });

      // PNG signature, then the IHDR chunk's width and height.
      expect(png.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final header = ByteData.sublistView(png, 16, 24);
      expect(header.getUint32(0), resultCardSize.width.toInt());
      expect(header.getUint32(4), resultCardSize.height.toInt());
    });
  });
}
