import 'dart:async';

import 'package:speech_api/speech_api.dart';
import 'package:state_manager/state_manager.dart';

/// How long to wait before opening the next session after one closes.
///
/// The platform holds a single recogniser and releases it asynchronously;
/// re-listening in the same beat that a session ended is how you get a
/// `listen()` the platform refuses — and a refusal looks exactly like a
/// session ending, so refusals feed each other. Measured on a Samsung S25
/// Ultra, 300 ms was not enough after a session that had actually recognised
/// something: six sessions opened and died inside 1.5 s. This is sized to be
/// unnoticeable to a player and still leave the platform time to let go.
const _defaultRestartDelay = Duration(milliseconds: 800);

/// How long one listening session runs before it is rolled over.
///
/// Measured on a Samsung S25 Ultra, saying ten to twenty words into a round.
/// The number matters more than it looks, and it is not monotonic:
///
/// | `pauseFor` | heard | microphone opened |
/// | ---------- | ----- | ----------------- |
/// | 3 s        | —     | every 3 s, mostly shut |
/// | 10 s       | good  | every 10 s |
/// | **60 s**   | **9/10, then 9 more after the rollover** | **twice in 80 s** |
/// | 260 s      | 2/10  | once |
///
/// Longer is better right up until it collapses. A round-length session puts
/// Google's service into a continuous mode that `speech_to_text` does not
/// forward — `_notifyResults` drops everything once a session has produced one
/// final — so the platform went on hearing utterances that never reached the
/// app. A minute is comfortably inside the working range and costs one
/// rollover a minute.
const kMicSessionSeconds = 60;

/// How many sessions one letter may open before the microphone gives up.
///
/// Real play needs two or three: a silent session ends after about five and a
/// half seconds, so a ten second letter spent thinking costs two. A number
/// far above that is not a player pausing — it is the platform closing every
/// session the instant it opens, and re-opening forever would spin for as
/// long as the round lasts.
const _maxSessionsPerPrompt = 6;

/// What the microphone is doing.
enum MicStatus {
  /// Off, and available to be turned on.
  idle,

  /// A session is open and the player may speak.
  listening,

  /// Unusable on this device or in this app — the text fallback is the game.
  unavailable,
}

/// The observable state of the microphone.
final class const MicState({
  /// Whether the player wants the microphone on. Distinct from [status]: a
  /// session closing between letters leaves this true.
  final bool enabled = false,
  final MicStatus status = MicStatus.idle,

  /// Why the microphone is unavailable, when it is.
  final SpeechUnavailableReason? reason,

  /// The recogniser's current best guess, for showing the player that they
  /// are being heard. Cleared when the letter changes.
  final String heard = '',
}) {
  MicState copyWith({
    bool? enabled,
    MicStatus? status,
    SpeechUnavailableReason? reason,
    bool clearReason = false,
    String? heard,
  }) => MicState(
    enabled: enabled ?? this.enabled,
    status: status ?? this.status,
    reason: clearReason ? null : (reason ?? this.reason),
    heard: heard ?? this.heard,
  );
}

/// What the screen can ask the microphone to do.
sealed class MicEvent {
  const MicEvent();
}

/// Turn the microphone on, prompting for permission the first time.
final class MicRequested extends MicEvent {
  const MicRequested();
}

/// Turn the microphone off, and leave it off.
final class MicDismissed extends MicEvent {
  const MicDismissed();
}

/// The letter moved on: forget what was heard and start a fresh session.
final class MicPromptChanged extends MicEvent {
  const MicPromptChanged();
}

/// One-shot side effects.
sealed class MicEffect {
  const MicEffect();
}

/// The recogniser produced a guess.
final class const MicTranscribed({
  required final String transcript,
  required final List<String> alternates,

  /// True for a partial result: worth scoring, not worth rejecting.
  required final bool tentative,
}) extends MicEffect;

/// {@template mic_controller}
/// The microphone, for the length of one round.
///
/// It exists apart from `RoscoController` for two reasons. The round's rules —
/// the pool, the pass queue, the laps — must stay testable without a plugin,
/// and they are: nothing here reaches into them. And the microphone's own
/// lifecycle is not a rule but a negotiation with the platform, with its own
/// failure modes, which deserves tests of its own against a fake recogniser.
///
/// The two meet in exactly one place: the screen turns a [MicTranscribed]
/// effect into a `RoscoAnswered` event.
///
/// ### A letter is not a session
///
/// The obvious design — open the microphone when a letter starts, close it
/// when the letter ends — does not survive contact with the device, and it
/// fails twice over.
///
/// It closes the microphone the player is using. Android applies `pauseFor` as
/// the whole listening window, so a value sized to a letter shuts the
/// microphone on anyone who pauses to think. And it *re-opens* it constantly:
/// twenty-six teardowns a round at the very least, each one an audible tone
/// from the platform and a stretch with no microphone at all — falling exactly
/// where a player speaks, just after reading a new clue. A player who says the
/// word twice and is heard neither time is not mispronouncing it.
///
/// So the session is sized in minutes and a letter changing does not touch it:
/// measured on device, nine words in a row through one microphone, then a
/// clean rollover and nine more — twice opened in eighty seconds, where the
/// per-letter design opened it fifteen times in forty-five. What remains is a
/// floor, not a plan: if a session does end while the round is still running,
/// another replaces it. Only the round's clock ends a letter.
/// {@endtemplate}
final class MicController
    extends AppStateController<MicState, MicEvent, MicEffect> {
  /// {@macro mic_controller}
  MicController({
    required this._recognizer,
    required this._sessionLength,
    this._restartDelay = _defaultRestartDelay,
  }) : super(const MicState());

  final SpeechRecognizerApi _recognizer;

  /// How long one session may stay open — and, just as importantly, how much
  /// silence it tolerates before the platform gives up.
  ///
  /// Sized in minutes rather than letters. Android treats the silence timeout
  /// as the listening window, so a value sized to a letter shuts the
  /// microphone on anyone who pauses to think. See [kMicSessionSeconds] for
  /// why it is not sized to the round either — longer is better only up to a
  /// point, past which the platform changes mode and the plugin stops
  /// forwarding what it hears.
  final Duration _sessionLength;

  /// Injected for the same reason the round's clock is: a test should be able
  /// to watch six sessions come and go without spending two seconds doing it.
  final Duration _restartDelay;

  StreamSubscription<SpeechResult>? _session;
  Timer? _restart;

  /// Bumped whenever a session stops being the current one, so a callback
  /// from a session that has been replaced cannot restart the microphone or
  /// report a transcript against the wrong letter.
  int _generation = 0;

  int _sessionsForPrompt = 0;
  bool _disposed = false;

  /// Whether the microphone is off because the *player* turned it off.
  ///
  /// The difference matters more than it looks. A microphone the player
  /// switched off must stay off; a microphone that gave up on its own must
  /// not, or a single bad patch retires it for the rest of the round and the
  /// only way back is a tap the player has no reason to expect.
  bool _playerOff = false;

  /// The last thing the open session heard, held so it can be settled when
  /// that session ends.
  SpeechResult? _lastHeard;

  /// A transcript that belonged to the previous letter and must not be scored
  /// again against this one. Cleared as soon as the player says anything new.
  String? _stale;

  /// Whether a session is currently open. A letter changing must not disturb
  /// one that is working.
  bool _sessionOpen = false;

  @override
  void dispose() {
    _disposed = true;
    _sessionOpen = false;
    _generation++;
    _restart?.cancel();
    unawaited(_session?.cancel());
    _session = null;
    super.dispose();
  }

  @override
  Future<void> onEvent(MicEvent event) async {
    switch (event) {
      case MicRequested():
        await _enable();
      case MicDismissed():
        await _disable();
      case MicPromptChanged():
        await _nextPrompt();
    }
  }

  Future<void> _enable() async {
    if (state.enabled || _disposed) return;

    // This is the moment the permission prompt appears — the player has
    // reached a round and a letter is waiting, which is a far better time to
    // ask than app start.
    final availability = await _recognizer.initialize();
    if (_disposed) return;

    _playerOff = false;

    switch (availability) {
      case SpeechUnavailable(:final reason):
        // Not an error. The text field below is a complete way to play.
        emit(
          state.copyWith(
            enabled: false,
            status: MicStatus.unavailable,
            reason: reason,
          ),
        );
      case SpeechReady():
        emit(state.copyWith(enabled: true, clearReason: true));
        _sessionsForPrompt = 0;
        await _listen();
    }
  }

  Future<void> _disable() async {
    _playerOff = true;
    _generation++;
    _restart?.cancel();
    _restart = null;

    _sessionOpen = false;
    emit(state.copyWith(enabled: false, status: MicStatus.idle, heard: ''));

    // Cancelling the subscription is what closes the platform session: the
    // recogniser tears down on `onCancel`.
    await _session?.cancel();
    _session = null;
  }

  Future<void> _nextPrompt() async {
    _sessionsForPrompt = 0;
    // Belongs to the letter just left; never settle it against this one.
    _lastHeard = null;
    _stale = state.heard.isEmpty ? null : state.heard;
    emit(state.copyWith(heard: ''));

    if (_disposed) return;

    // A new letter is the natural moment to give up on having given up. A
    // microphone that stopped on its own — the restart budget spent on a bad
    // patch — comes back here, which is what stops a player being stranded
    // with a dead button and no idea they are expected to press it.
    if (!state.enabled) {
      // Except when the player switched it off, or the device genuinely
      // cannot do this: neither is going to change because a letter did.
      if (_playerOff || state.status == MicStatus.unavailable) return;
      await _enable();
      return;
    }

    // **An open session is deliberately left alone.** Restarting on every
    // letter meant at least twenty-six teardowns a round — each one an audible
    // beep from the platform and a gap with no microphone, and that gap falls
    // exactly where a player speaks: just after reading a new clue. A session
    // that is working survives the letter changing; only one that has already
    // ended is replaced.
    if (_sessionOpen) return;
    await _listen();
  }

  Future<void> _listen() async {
    if (!state.enabled || _disposed) return;

    _restart?.cancel();
    _restart = null;

    final generation = ++_generation;
    _sessionsForPrompt++;

    // The previous subscription is deliberately *not* cancelled here. The
    // recogniser tears the old session down inside `listen()` and closes its
    // stream, which reaches the old subscription as `onDone` and is ignored by
    // the generation guard. Cancelling as well opened a second teardown path
    // racing the first, and the platform answered the race with `error_client`.

    // A session is sized to a letter so that, on a platform that honours it,
    // one session covers one letter and the microphone never blinks. The
    // re-opening below stays as the safety net for platforms that cut early
    // anyway — it is a floor under the behaviour, not the plan.
    _sessionOpen = true;
    _session = _recognizer
        .listen(maxDuration: _sessionLength, pauseFor: _sessionLength)
        .listen(
          (result) => _onResult(generation, result),
          onError: (Object error) => _onError(generation, error),
          onDone: () => _onDone(generation),
        );

    emit(state.copyWith(status: MicStatus.listening));
  }

  void _onResult(int generation, SpeechResult result) {
    if (generation != _generation || _disposed) return;

    // Words still in flight from the previous letter. The recogniser keeps
    // building one utterance across a letter change, and re-offering it would
    // read as the player answering a clue they never saw.
    if (result.transcript == _stale) return;
    _stale = null;

    // A session producing results is a session working. Whatever it took to
    // get here does not count against the letter's budget of restarts.
    _sessionsForPrompt = 1;
    _lastHeard = result;

    emit(state.copyWith(heard: result.transcript));
    // Always tentative while the session is open. Whether the platform calls
    // a result final is not worth trusting — it synthesises them, late — so
    // the end of the session settles the utterance instead.
    emitEffect(
      MicTranscribed(
        transcript: result.transcript,
        alternates: result.alternates,
        tentative: true,
      ),
    );
  }

  void _onDone(int generation) {
    if (generation == _generation) _sessionOpen = false;
    if (generation != _generation || !state.enabled || _disposed) return;

    // The session is over, so whatever it last heard is what the player said:
    // no better version of it is coming. Settling here — rather than on a
    // platform "final" — is what lets a miss be shown to the player at all.
    final heard = _lastHeard;
    _lastHeard = null;
    if (heard != null) {
      emitEffect(
        MicTranscribed(
          transcript: heard.transcript,
          alternates: heard.alternates,
          tentative: false,
        ),
      );
    }

    // The letter is still live — see the class doc. Open another session.
    if (_sessionsForPrompt >= _maxSessionsPerPrompt) {
      // `enabled` goes false with the status, and the two must move together.
      // Leaving it true while the status said idle put the button and its own
      // tap handler into disagreement: the button read as off, so a player
      // tapped it, and the tap — reading `enabled` — switched off a
      // microphone that had already stopped. It took two taps to get a
      // microphone back, and the first one appeared to do nothing.
      emit(state.copyWith(enabled: false, status: MicStatus.idle));
      return;
    }

    _restart = Timer(_restartDelay, () => unawaited(_listen()));
  }

  void _onError(int generation, Object error) {
    if (generation == _generation) _sessionOpen = false;
    if (generation != _generation || _disposed) return;

    // Transient errors never reach here: the recogniser swallows `no match`
    // and `speech timeout`, which a thinking player produces constantly. An
    // error on this stream is the microphone being gone for the rest of the
    // round.
    _generation++;
    _restart?.cancel();
    _restart = null;

    emit(
      state.copyWith(
        enabled: false,
        status: MicStatus.unavailable,
        reason: error is SpeechUnavailable
            ? error.reason
            : SpeechUnavailableReason.unknown,
        heard: '',
      ),
    );
  }
}
