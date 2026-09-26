import 'dart:async';

import 'package:analytics_api/analytics_api.dart';
import 'package:rosco_api/rosco_api.dart';
import 'package:state_manager/state_manager.dart';

import '../analytics/rosco_analytics_events.dart';
import '../domain/rosco_failure.dart';
import '../domain/word_bank_repository.dart';
import '../domain/word_entry.dart';
import '../domain/word_set.dart';

/// One letter of the finished round: its word, and whether it was answered.
final class const ResultLetter({
  required final WordEntry entry,
  required final bool answered,
});

/// The observable state of the result screen.
final class const ResultState({
  required final CefrLevel level,
  required final LevelScore score,

  /// The best result on record for this level once the save has settled —
  /// which may be this round, or a better one from before.
  final LevelScore? best,
  final bool isNewBest = false,
  final bool isSaving = true,

  /// Every letter of the round, A to Z, once the played set has been read
  /// back — or `null` when it could not be, in which case the screen names no
  /// words rather than guessing at them.
  final List<ResultLetter>? letters,
}) {
  /// The words the player did not find — the reason to show the letters at
  /// all. Empty when every letter was answered, `null` when unknown.
  List<ResultLetter>? get missed =>
      letters?.where((letter) => !letter.answered).toList();

  ResultState copyWith({
    LevelScore? best,
    bool? isNewBest,
    bool? isSaving,
    List<ResultLetter>? letters,
  }) => ResultState(
    level: level,
    score: score,
    best: best ?? this.best,
    isNewBest: isNewBest ?? this.isNewBest,
    isSaving: isSaving ?? this.isSaving,
    letters: letters ?? this.letters,
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

/// The player wants to show someone how it went.
final class ResultShared extends ResultEvent {
  const ResultShared();
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

/// Open the platform's share sheet for this result. A plugin call, so the
/// screen performs it; the controller only asks.
final class const ShareOutcome({required final ResultState result})
    extends ResultEffect;

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
    required this._analytics,
    required CefrLevel level,
    required LevelScore score,
    this._repository,
    this._setId,
    this._marks,
  }) : super(ResultState(level: level, score: score));

  final RoscoScoreboard _scoreboard;
  final AnalyticsApi _analytics;
  final WordBankRepository? _repository;
  final String? _setId;
  final List<bool>? _marks;

  @override
  Future<void> onInit() async {
    // Independent, so neither waits on the other: the missed words should be
    // on screen as soon as the set is read, whatever storage is doing.
    await Future.wait([_save(), _revealLetters()]);
  }

  @override
  Future<void> onEvent(ResultEvent event) async {
    switch (event) {
      case ResultRefreshed():
        await _save();
      case ResultReplayed():
        unawaited(_analytics.logEvent(RoundReplayedEvent(level: state.level)));
        emitEffect(ReplayRound(level: state.level));
      case ResultDismissed():
        emitEffect(const LeaveResult());
      case ResultShared():
        unawaited(
          _analytics.logEvent(
            ResultSharedEvent(level: state.level, score: state.score),
          ),
        );
        emitEffect(ShareOutcome(result: state));
    }
  }

  /// Reads the played set back and pairs each word with its mark.
  ///
  /// Anything short of a clean match reveals nothing: a set that no longer
  /// ships, or marks that do not cover the alphabet, would otherwise pin the
  /// wrong word on a letter — and a wrong answer shown as *the* answer is the
  /// one thing a learning game must not do.
  Future<void> _revealLetters() async {
    final repository = _repository;
    final setId = _setId;
    final marks = _marks;
    if (repository == null || setId == null) return;
    if (marks == null || marks.length != WordSet.letterCount) return;

    final List<WordSet> sets;
    try {
      sets = await repository.setsFor(state.level);
    } on RoscoFailure {
      return;
    }

    final played = sets.where((set) => set.id == setId).firstOrNull;
    if (played == null) return;

    final letters = <ResultLetter>[];
    for (var index = 0; index < WordSet.letterCount; index++) {
      final entry = played.entryFor(WordSet.alphabet[index]);
      if (entry == null) return;
      letters.add(ResultLetter(entry: entry, answered: marks[index]));
    }

    emit(state.copyWith(letters: letters));
  }

  Future<void> _save() async {
    emit(state.copyWith(isSaving: true));

    // The scoreboard swallows its own storage failures and reports `false`,
    // so a lost write reads here as "not a new best" — the round still shows
    // its score, which is the part the player is waiting for.
    final recorded = await _scoreboard.record(state.level, state.score);
    final best = await _scoreboard.best(state.level);

    // A first round is always recorded — it is what marks the level as
    // played — but one with nothing right is not worth celebrating. "New
    // best!" over 0/26 read as mockery.
    final isNewBest = recorded && state.score.correct > 0;
    emit(state.copyWith(isNewBest: isNewBest, best: best, isSaving: false));
  }
}
