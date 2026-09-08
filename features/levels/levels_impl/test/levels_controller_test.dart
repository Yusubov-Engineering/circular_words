import 'package:flutter_test/flutter_test.dart';
import 'package:levels_impl/src/levels/levels_controller.dart';
import 'package:rosco_api/rosco_api.dart';

final class _FakeScoreboard implements RoscoScoreboard {
  _FakeScoreboard([this._scores = const {}]);

  final Map<CefrLevel, LevelScore> _scores;
  bool failAll = false;
  int allCalls = 0;

  @override
  Future<Map<CefrLevel, LevelScore>> all() async {
    allCalls++;
    if (failAll) throw StateError('storage unavailable');
    return _scores;
  }

  @override
  Future<LevelScore?> best(CefrLevel level) async => _scores[level];

  @override
  Future<bool> record(CefrLevel level, LevelScore score) async => true;
}

void main() {
  test('onInit lists every level, played or not', () async {
    final controller = LevelsController(
      scoreboard: _FakeScoreboard(const {
        CefrLevel.b1: LevelScore(correct: 14, total: 26, secondsRemaining: 22),
      }),
    );

    await controller.onInit();

    expect(controller.state.isLoading, isFalse);
    // The six levels are a fixed alphabet: an unplayed level is a row without
    // a score, never a missing row.
    expect(controller.state.entries.length, CefrLevel.values.length);
    expect(controller.state.entries.map((e) => e.level), CefrLevel.values);

    final b1 = controller.state.entries.firstWhere(
      (e) => e.level == CefrLevel.b1,
    );
    expect(b1.isPlayed, isTrue);
    expect(b1.best?.correct, 14);

    expect(
      controller.state.entries
          .firstWhere((e) => e.level == CefrLevel.c2)
          .isPlayed,
      isFalse,
    );

    controller.dispose();
  });

  test('unreadable scores still produce a full, playable picker', () async {
    final scoreboard = _FakeScoreboard()..failAll = true;
    final controller = LevelsController(scoreboard: scoreboard);

    await controller.onInit();

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.entries.length, CefrLevel.values.length);
    expect(controller.state.entries.every((e) => !e.isPlayed), isTrue);

    controller.dispose();
  });

  test(
    'selecting a level asks to start a round rather than navigating',
    () async {
      final controller = LevelsController(scoreboard: _FakeScoreboard());
      await controller.onInit();

      final effects = <LevelsEffect>[];
      final subscription = controller.effects.listen(effects.add);

      await controller.onEvent(const LevelSelected(level: CefrLevel.c1));
      await Future<void>.delayed(Duration.zero);

      expect(effects, hasLength(1));
      expect((effects.single as StartRound).level, CefrLevel.c1);

      await subscription.cancel();
      controller.dispose();
    },
  );

  // A best score can only change while this screen exists by a round ending,
  // which is why the refresh hangs off the navigation result.
  test('refreshing re-reads the scoreboard', () async {
    final scoreboard = _FakeScoreboard();
    final controller = LevelsController(scoreboard: scoreboard);

    await controller.onInit();
    expect(scoreboard.allCalls, 1);

    await controller.onEvent(const LevelsRefreshed());
    expect(scoreboard.allCalls, 2);

    controller.dispose();
  });
}
