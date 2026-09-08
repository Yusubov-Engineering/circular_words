import 'dart:async';
import 'dart:math';

import 'package:rosco_api/rosco_api.dart';
import 'package:state_manager/state_manager.dart';

import '../domain/answer_validator.dart';
import '../domain/letter_slot.dart';
import '../domain/rosco_failure.dart';
import '../domain/word_bank_repository.dart';
import '../domain/word_set.dart';

/// The whole round's time, shared across all 26 letters.
const kPoolSeconds = 260;

/// The most any single letter may take out of the pool.
const kLetterCapSeconds = 10;

/// A source of one-second beats.
///
/// Injected so the round can be tested without waiting for a real clock: the
/// pool arithmetic, the pass queue and the lap counter are all decided here,
/// and none of it should need 260 seconds to verify.
typedef TickSource = Stream<void> Function();

Stream<void> _realTicks() => Stream<void>.periodic(const Duration(seconds: 1));

/// The observable state of a round.
final class const RoscoState({
  required final CefrLevel level,
  final String? setId,
  final List<LetterSlot> slots = const [],
  final int currentIndex = 0,
  final int remainingPool = kPoolSeconds,
  final int spentOnCurrentLetter = 0,
  final int lap = 1,
  final String? lastRejected,
  final RoscoFailure? failure,
  final bool isLoading = true,
  final bool isOver = false,
}) {
  /// The letter being played, or `null` before the words load and after the
  /// round ends.
  LetterSlot? get current => currentIndex >= 0 && currentIndex < slots.length
      ? slots[currentIndex]
      : null;

  /// Seconds left on this letter.
  ///
  /// **Derived, never stored.** `remainingPool` is the single source of truth;
  /// keeping a second countdown beside it lets the two drift, and the drift is
  /// specific and ugly — on the last letter the per-letter timer offers ten
  /// seconds the pool cannot pay for. Capped by the pool for exactly that
  /// reason.
  int get letterRemaining =>
      max(0, min(kLetterCapSeconds - spentOnCurrentLetter, remainingPool));

  int get correctCount =>
      slots.where((slot) => slot.status == LetterStatus.correct).length;

  /// Letters still in play — pending, active or passed.
  ///
  /// `passed` counts as unresolved, which is what keeps a second lap
  /// reachable.
  int get unresolvedCount => slots.where((slot) => !slot.isTerminal).length;

  LevelScore get score => LevelScore(
    correct: correctCount,
    total: slots.isEmpty ? WordSet.letterCount : slots.length,
    secondsRemaining: remainingPool,
  );

  RoscoState copyWith({
    String? setId,
    List<LetterSlot>? slots,
    int? currentIndex,
    int? remainingPool,
    int? spentOnCurrentLetter,
    int? lap,
    String? lastRejected,
    bool clearLastRejected = false,
    RoscoFailure? failure,
    bool? isLoading,
    bool? isOver,
  }) => RoscoState(
    level: level,
    setId: setId ?? this.setId,
    slots: slots ?? this.slots,
    currentIndex: currentIndex ?? this.currentIndex,
    remainingPool: remainingPool ?? this.remainingPool,
    spentOnCurrentLetter: spentOnCurrentLetter ?? this.spentOnCurrentLetter,
    lap: lap ?? this.lap,
    lastRejected: clearLastRejected
        ? null
        : (lastRejected ?? this.lastRejected),
    failure: failure ?? this.failure,
    isLoading: isLoading ?? this.isLoading,
    isOver: isOver ?? this.isOver,
  );
}

/// What the screen can ask the round to do.
sealed class RoscoEvent {
  const RoscoEvent();
}

/// One second of the pool has gone.
final class RoscoTicked extends RoscoEvent {
  const RoscoTicked();
}

/// The player offered an answer — typed, or transcribed.
///
/// [alternates] carries the recogniser's lower-ranked guesses. They are worth
/// scoring: the top-ranked transcript is frequently *not* the best one for a
/// non-native speaker, and on device the alternate list is where `albondant`
/// sits next to `abundant`. A typed answer simply has none.
final class const RoscoAnswered({
  required final String answer,
  final List<String> alternates = const [],

  /// Whether this answer is still in flight — a speech partial rather than a
  /// settled utterance.
  ///
  /// A tentative answer is *scored*, because a partial that already contains
  /// the word arrives about five seconds before the final that repeats it,
  /// and a ten second letter cannot pay for that wait. But it is never
  /// *rejected*: it only failed to be right so far. Recording a rejection per
  /// partial would flash red on every syllable of a word being spoken
  /// correctly.
  final bool tentative = false,
}) extends RoscoEvent {
  /// Every guess this answer offers, best first.
  Iterable<String> get candidates => [answer, ...alternates];
}

/// Defer this letter; it comes round again.
final class RoscoPassed extends RoscoEvent {
  const RoscoPassed();
}

/// Re-attempt loading the round's words.
final class RoscoRetried extends RoscoEvent {
  const RoscoRetried();
}

/// One-shot side effects. Not replayed.
sealed class RoscoEffect {
  const RoscoEffect();
}

/// The answer was accepted.
final class RoscoAccepted extends RoscoEffect {
  const RoscoAccepted();
}

/// The answer was not accepted — and the letter is still live.
final class RoscoRejected extends RoscoEffect {
  const RoscoRejected();
}

/// The letter ran out of time and was lost.
///
/// Distinct from [RoscoRejected] because it means something different to the
/// player: a rejection is a try that missed, this is a letter gone. They earn
/// different feedback.
final class RoscoTimedOut extends RoscoEffect {
  const RoscoTimedOut();
}

/// The round is over. The controller only *asks*; the screen navigates.
final class const RoscoFinished({required final LevelScore score})
    extends RoscoEffect;

/// {@template rosco_controller}
/// A round of the game.
///
/// Everything that decides the outcome lives here and nowhere else: the pool,
/// the pass queue, the lap counter and the end conditions. It holds no
/// `BuildContext` and no plugin, so a whole round can be played out in a unit
/// test with no microphone and no widget tree — which is the point, because CI
/// has neither.
/// {@endtemplate}
final class RoscoController
    extends AppStateController<RoscoState, RoscoEvent, RoscoEffect> {
  /// {@macro rosco_controller}
  RoscoController({
    required CefrLevel level,
    required this._repository,
    this._validator = const AnswerValidator(),
    this._tickSource = _realTicks,
  }) : super(RoscoState(level: level));

  final WordBankRepository _repository;
  final AnswerValidator _validator;
  final TickSource _tickSource;

  StreamSubscription<void>? _ticks;

  @override
  Future<void> onInit() => _load();

  @override
  void dispose() {
    // The clock outlives the widget unless it is cancelled here. A game screen
    // leaks more visibly than most.
    unawaited(_ticks?.cancel());
    _ticks = null;
    super.dispose();
  }

  @override
  Future<void> onEvent(RoscoEvent event) async {
    switch (event) {
      case RoscoTicked():
        _tick();
      case RoscoAnswered():
        _answer(event);
      case RoscoPassed():
        _pass();
      case RoscoRetried():
        await _load();
    }
  }

  Future<void> _load() async {
    emit(RoscoState(level: state.level));

    try {
      final wordSet = await _repository.randomSet(state.level);

      emit(
        state.copyWith(
          setId: wordSet.id,
          slots: [
            for (final entry in wordSet.entries) LetterSlot(entry: entry),
          ],
          isLoading: false,
        ),
      );

      _activate(0);
      _startClock();
    } on RoscoFailure catch (failure) {
      // The repository throws `RoscoFailure` and nothing else, so this is
      // exhaustive over everything that can go wrong below.
      emit(state.copyWith(failure: failure, isLoading: false));
    }
  }

  void _startClock() {
    unawaited(_ticks?.cancel());
    _ticks = _tickSource().listen((_) => dispatch(const RoscoTicked()));
  }

  void _tick() {
    if (state.isOver || state.isLoading || state.slots.isEmpty) return;

    final pool = state.remainingPool - 1;
    final spent = state.spentOnCurrentLetter + 1;

    emit(
      state.copyWith(remainingPool: max(0, pool), spentOnCurrentLetter: spent),
    );

    // The pool is authoritative. When it and the letter cap expire on the same
    // beat, the round is over — there is no time left to score the letter
    // against.
    if (pool <= 0) {
      _finish();
      return;
    }

    if (spent >= kLetterCapSeconds) {
      // Only here does a letter become `wrong`: the cap ran out. A rejected
      // answer never does this.
      _resolveCurrent(LetterStatus.wrong);
      emitEffect(const RoscoTimedOut());
      _advance();
    }
  }

  void _answer(RoscoAnswered event) {
    final current = state.current;
    if (state.isOver || current == null) return;

    // Any guess will do. The recogniser ranks by acoustic confidence, which is
    // not the same thing as being the word the clue wanted.
    for (final candidate in event.candidates) {
      if (_validator.accepts(entry: current.entry, spoken: candidate)) {
        _resolveCurrent(LetterStatus.correct);
        emitEffect(const RoscoAccepted());
        _advance();
        return;
      }
    }

    // Still mid-utterance: nothing has been got wrong yet, so nothing is
    // shown and nothing buzzes.
    if (event.tentative) return;

    // A rejected answer costs time, never the letter. The letter stays
    // `active` and the player may try again until the cap expires — speech
    // recognition is unreliable enough that one-shot answering would punish
    // recognition failures as if they were vocabulary failures.
    emit(state.copyWith(lastRejected: event.answer));
    emitEffect(const RoscoRejected());
  }

  void _pass() {
    if (state.isOver || state.current == null) return;

    _resolveCurrent(LetterStatus.passed);
    _advance();
  }

  void _resolveCurrent(LetterStatus status) {
    final slots = [...state.slots];
    slots[state.currentIndex] = slots[state.currentIndex].copyWith(
      status: status,
    );
    emit(state.copyWith(slots: slots));
  }

  /// Marks [index] active and restarts its share of the clock.
  void _activate(int index) {
    final slots = [...state.slots];
    slots[index] = slots[index].copyWith(status: LetterStatus.active);

    emit(
      state.copyWith(
        slots: slots,
        currentIndex: index,
        spentOnCurrentLetter: 0,
        clearLastRejected: true,
      ),
    );
  }

  /// Moves to the next unresolved letter, wrapping around the circle.
  void _advance() {
    final slots = state.slots;
    final count = slots.length;

    for (var step = 1; step <= count; step++) {
      final index = (state.currentIndex + step) % count;
      if (slots[index].isTerminal) continue;

      // Wrapping past the end of the alphabet starts another lap. This is the
      // only place `lap` moves, and it is what a passed letter comes back on.
      if (index <= state.currentIndex) {
        emit(state.copyWith(lap: state.lap + 1));
      }

      _activate(index);
      return;
    }

    // Nothing unresolved is left: every letter is correct or wrong.
    _finish();
  }

  void _finish() {
    if (state.isOver) return;

    unawaited(_ticks?.cancel());
    _ticks = null;

    emit(state.copyWith(isOver: true));
    emitEffect(RoscoFinished(score: state.score));
  }
}
