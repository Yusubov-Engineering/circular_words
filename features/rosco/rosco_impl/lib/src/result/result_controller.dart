import 'package:rosco_api/rosco_api.dart';
import 'package:state_manager/state_manager.dart';

/// The observable state of the result screen.
final class const ResultState({
  required final CefrLevel level,
  required final LevelScore score,

  /// The best result on record for this level once the save has settled —
  /// which may be this round, or a better one from before.
  final LevelScore? best,
  final bool isNewBest = false,
  final bool isSaving = true,
}) {
  ResultState copyWith({LevelScore? best, bool? isNewBest, bool? isSaving}) =>
      ResultState(
        level: level,
        score: score,
        best: best ?? this.best,
        isNewBest: isNewBest ?? this.isNewBest,
        isSaving: isSaving ?? this.isSaving,
      );
}

/// What the screen can ask the result to do.
sealed class ResultEvent {
  const ResultEvent();
}

/// Re-record and re-read. Runs once on entry, and again if a player retries a
/// save that storage refused.
final class ResultRefreshed extends ResultEvent {
  const ResultRefreshed();
}

/// Another round at the same level.
final class ResultReplayed extends ResultEvent {
  const ResultReplayed();
}

/// Back to the picker.
final class ResultDismissed extends ResultEvent {
  const ResultDismissed();
}

/// One-shot side effects. The controller only *asks*; the screen navigates.
sealed class ResultEffect {
  const ResultEffect();
}

final class const ReplayRound({required final CefrLevel level})
    extends ResultEffect;

final class LeaveResult extends ResultEffect {
  const LeaveResult();
}

/// {@template result_controller}
/// The end of a round: what it was worth, and whether it was the best yet.
///
/// **This screen is where a score is written**, not the round that earned it.
/// The round has no business knowing about storage, and putting the write here
/// keeps `RoscoController` a pure rules engine. The cost is a few milliseconds
/// of exposure — an app killed between the last letter and this screen loses
/// the score — which is the right trade for a game.
///
/// Recording is idempotent by construction: `record` only writes a score that
/// beats what is stored, so reopening this screen, or a link to it, cannot
/// inflate anything.
/// {@endtemplate}
final class ResultController
    extends AppStateController<ResultState, ResultEvent, ResultEffect> {
  /// {@macro result_controller}
  ResultController({
    required this._scoreboard,
    required CefrLevel level,
    required LevelScore score,
  }) : super(ResultState(level: level, score: score));

  final RoscoScoreboard _scoreboard;

  @override
  Future<void> onInit() => _save();

  @override
  Future<void> onEvent(ResultEvent event) async {
    switch (event) {
      case ResultRefreshed():
        await _save();
      case ResultReplayed():
        emitEffect(ReplayRound(level: state.level));
      case ResultDismissed():
        emitEffect(const LeaveResult());
    }
  }

  Future<void> _save() async {
    emit(state.copyWith(isSaving: true));

    // The scoreboard swallows its own storage failures and reports `false`,
    // so a lost write reads here as "not a new best" — the round still shows
    // its score, which is the part the player is waiting for.
    final isNewBest = await _scoreboard.record(state.level, state.score);
    final best = await _scoreboard.best(state.level);

    emit(state.copyWith(isNewBest: isNewBest, best: best, isSaving: false));
  }
}
