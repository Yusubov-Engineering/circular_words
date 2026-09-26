import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:rosco_impl/src/result/result_controller.dart';

import 'recording_analytics.dart';

final class FakeScoreboard implements RoscoScoreboard {
  FakeScoreboard({this.stored});

  LevelScore? stored;
  final recorded = <LevelScore>[];

  /// Set to make a write fail the way real storage does — quietly, reporting
  /// that nothing was beaten.
  bool refuseWrites = false;

  @override
  Future<LevelScore?> best(CefrLevel level) async => stored;

  @override
  Future<Map<CefrLevel, LevelScore>> all() async =>
      stored == null ? {} : {CefrLevel.a1: stored!};

  @override
  Future<bool> record(CefrLevel level, LevelScore score) async {
    recorded.add(score);
    if (refuseWrites || !score.beats(stored)) return false;
    stored = score;
    return true;
  }
}

/// A round worth [correct] letters. Spelled out at every call site, because
/// which number is which is the whole point of these tests.
LevelScore score(int correct, {int total = 26, int left = 40}) =>
    LevelScore(correct: correct, total: total, secondsRemaining: left);

void main() {
  late FakeScoreboard scoreboard;
  late ResultController controller;
  late List<ResultEffect> effects;
  late StreamSubscription<ResultEffect> subscription;
  late RecordingAnalytics analytics;

  Future<void> build({LevelScore? stored, LevelScore? earned}) async {
    scoreboard = FakeScoreboard(stored: stored);
    analytics = RecordingAnalytics();
    controller = ResultController(
      scoreboard: scoreboard,
      analytics: analytics,
      level: CefrLevel.a1,
      score: earned ?? score(12),
    );
    effects = [];
    subscription = controller.effects.listen(effects.add);
    await controller.onInit();
  }

  tearDown(() async {
    await subscription.cancel();
    controller.dispose();
  });

  group('recording', () {
    test('a first result is written and reads as a new best', () async {
      await build();

      expect(scoreboard.recorded, hasLength(1));
      expect(controller.state.isNewBest, isTrue);
      expect(controller.state.best, score(12));
      expect(controller.state.isSaving, isFalse);
    });

    test('a worse round is recorded but does not claim the crown', () async {
      await build(stored: score(20), earned: score(12));

      expect(controller.state.isNewBest, isFalse);
      // The best on show is the one to beat, not the one just played.
      expect(controller.state.best?.correct, 20);
      expect(controller.state.score.correct, 12);
    });

    test('a better round takes it', () async {
      await build(stored: score(12), earned: score(20));

      expect(controller.state.isNewBest, isTrue);
      expect(controller.state.best?.correct, 20);
    });

    // The round is over and the score is on screen either way; a storage
    // failure must not turn that into an error state.
    test('a refused write still shows the round', () async {
      scoreboard = FakeScoreboard()..refuseWrites = true;
      analytics = RecordingAnalytics();
      controller = ResultController(
        scoreboard: scoreboard,
        analytics: analytics,
        level: CefrLevel.a1,
        score: score(9),
      );
      effects = [];
      subscription = controller.effects.listen(effects.add);
      await controller.onInit();

      expect(controller.state.isSaving, isFalse);
      expect(controller.state.isNewBest, isFalse);
      expect(controller.state.score.correct, 9);
    });

    // Reopening the screen, or a link to it, must not inflate anything.
    test('recording twice cannot beat itself', () async {
      await build();
      await controller.dispatch(const ResultRefreshed());

      expect(scoreboard.recorded, hasLength(2));
      expect(controller.state.isNewBest, isFalse);
      expect(controller.state.best, score(12));
    });
  });

  group('leaving', () {
    test('playing again asks for the same level', () async {
      await build();
      await controller.dispatch(const ResultReplayed());

      expect(effects, [isA<ReplayRound>()]);
      expect((effects.single as ReplayRound).level, CefrLevel.a1);
      expect(analytics.single('round_replayed').parameters, {'level': 'a1'});
    });

    test('dismissing asks to leave', () async {
      await build();
      await controller.dispatch(const ResultDismissed());

      expect(effects, [isA<LeaveResult>()]);
    });
  });

  test('sharing is reported with the level and the score', () async {
    await build(earned: score(21));
    await controller.dispatch(const ResultShared());

    expect(effects, [isA<ShareOutcome>()]);
    expect(analytics.single('result_shared').parameters, {
      'level': 'a1',
      'score': 21,
    });
  });
}
