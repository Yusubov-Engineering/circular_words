import 'dart:async';

import 'package:speech_api/speech_api.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'speech_error_mapping.dart';

/// How long a session must have been open before a stop is believed.
///
/// Status callbacks are global, not per session, and arrive late: a
/// `notListening` belonging to the session just torn down lands after the next
/// one has already started, and closing on it kills a session that was about
/// to work. Measured on a Samsung S25 Ultra those stale statuses arrive inside
/// ~300 ms, while a genuine silence timeout cannot fire before `pauseFor` —
/// seconds away. This sits well clear of both.
const _statusSettling = Duration(milliseconds: 700);

/// One listening session.
///
/// Sessions are explicit objects rather than a set of nullable fields because
/// a callback belonging to a finished session used to arrive after the next
/// session had started and close *its* stream. Every callback now acts on the
/// session it was given and checks that session is still current.
final class _Session {
  _Session(this.controller);

  final StreamController<SpeechResult> controller;

  Timer? capTimer;

  /// When the platform confirmed this session was listening.
  DateTime? listeningSince;

  /// Set when the platform confirms it is listening. Until then, a
  /// `notListening` status belongs to a *previous* session and must be
  /// ignored.
  bool started = false;
  bool closed = false;

  /// Whether a stop reported now would be this session's own.
  bool get isSettled {
    final since = listeningSince;
    return since != null && DateTime.now().difference(since) >= _statusSettling;
  }

  void cancelTimers() {
    capTimer?.cancel();
    capTimer = null;
  }
}

/// {@template speech_recognizer_impl}
/// [SpeechRecognizerApi] over the `speech_to_text` plugin.
///
/// The plugin is callback-shaped and single-session; this turns it into a
/// stream per listening session, which is what the game wants: one session per
/// letter, torn down and reopened on advance.
///
/// **Platform finals are not waited for.** An earlier version held each stream
/// open for 2.5 s after the platform stopped, so the plugin's synthesised
/// final could arrive. Measured on a Samsung S25 Ultra, that final carries the
/// same transcript and the same alternates as the partial that preceded it by
/// five seconds — it costs latency and buys nothing. Worse, the wait blocked
/// the caller from re-opening the microphone, which left it shut for 2.7 s of
/// every 3 s of silence. A session now ends when the platform says it ended,
/// and the caller settles on whatever it last heard.
/// {@endtemplate}
final class SpeechRecognizerImpl implements SpeechRecognizerApi {
  /// {@macro speech_recognizer_impl}
  SpeechRecognizerImpl({stt.SpeechToText? speech})
    : _speech = speech ?? stt.SpeechToText();

  final stt.SpeechToText _speech;

  _Session? _session;
  bool _initialized = false;

  /// True only while [initialize] is in flight, so the plugin's global error
  /// callback can be read as "this is why initialising failed" rather than as
  /// a problem with a listening session that does not exist yet.
  bool _initializing = false;

  /// The reason captured during the last [initialize].
  SpeechUnavailableReason? _initFailure;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<SpeechAvailability> initialize() async {
    _initFailure = null;
    _initializing = true;

    try {
      _initialized = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
    } on Object {
      return const SpeechUnavailable(reason: SpeechUnavailableReason.unknown);
    } finally {
      _initializing = false;
    }

    if (!_initialized) {
      // The plugin reports a bare `false` for every way this can go wrong, and
      // the two common ways need different sentences: "you declined the
      // microphone" is something the player can undo, "this device has no
      // recogniser" is not. `_onError` above captures the reason when the
      // platform gives one; when it does not, the permission is the question
      // worth asking, because a denial is by far the likelier of the two.
      return SpeechUnavailable(
        reason:
            _initFailure ??
            (await _permitted()
                ? SpeechUnavailableReason.noRecognizer
                : SpeechUnavailableReason.permissionDenied),
      );
    }

    if (!await _permitted()) {
      return const SpeechUnavailable(
        reason: SpeechUnavailableReason.permissionDenied,
      );
    }

    // Enumerating locales is best-effort: some platforms decline, and that is
    // not a reason to call the recogniser unavailable.
    var locales = <String>[];
    try {
      locales = [for (final locale in await _speech.locales()) locale.localeId];
    } on Object {
      locales = const [];
    }

    return SpeechReady(locales: locales);
  }

  @override
  Stream<SpeechResult> listen({
    Duration maxDuration = const Duration(seconds: 10),
    Duration pauseFor = const Duration(seconds: 3),
    String? localeId,
  }) {
    if (!_initialized) {
      return Stream.error(
        const SpeechUnavailable(reason: SpeechUnavailableReason.unknown),
      );
    }

    // Detach the previous session *synchronously* before anything can await.
    // Tearing it down asynchronously used to reach `_session` after this
    // method had already replaced it, closing the stream it had just handed
    // back to the caller.
    final previous = _session;
    final session = _Session(StreamController<SpeechResult>());
    _session = session;

    session.controller.onCancel = () => _end(session, cancelPlatform: true);

    unawaited(_start(session, previous, maxDuration, pauseFor, localeId));

    return session.controller.stream;
  }

  @override
  Future<void> stop() async {
    final session = _session;
    if (session == null || session.closed) return;

    if (_speech.isListening) await _speech.stop();
    await _end(session);
  }

  @override
  Future<void> cancel() async {
    final session = _session;
    _session = null;
    await _end(session, cancelPlatform: true);
  }

  @override
  Future<void> dispose() async {
    await cancel();
    _initialized = false;
  }

  Future<void> _start(
    _Session session,
    _Session? previous,
    Duration maxDuration,
    Duration pauseFor,
    String? localeId,
  ) async {
    // The platform holds one recogniser: the previous session must be fully
    // torn down before the next `listen` call, or the plugin rejects it.
    await _end(previous, cancelPlatform: true);
    if (session.closed) return;

    try {
      await _speech.listen(
        onResult: (result) => _onResult(session, result),
        // `partialResults`, `listenMode` and `cancelOnError` are left at
        // their defaults (true / confirmation / false) deliberately, not by
        // omission.
        //
        // Partials are what let a correct answer land in two seconds instead
        // of waiting for the platform to detect silence, and confirmation
        // mode is tuned for the short utterances this game asks for.
        //
        // `cancelOnError` is the one that looks wrong and is not. Turning it
        // on reads as "be strict"; on Android it is catastrophic, because
        // errors arrive unattributed and late. Measured on a Samsung S25
        // Ultra: a `NO_SPEECH_DETECTED` belonging to the session just torn
        // down landed 40 ms after the *next* session opened its microphone,
        // and the plugin cancelled that innocent session. Every session died
        // inside a tenth of a second, leaving a game whose microphone was
        // open about a third of the time. Off, `_onError` below decides —
        // benign codes end nothing, and a real failure ends the session and
        // the platform with it.
        listenOptions: stt.SpeechListenOptions(
          pauseFor: pauseFor,
          listenFor: maxDuration,
          localeId: localeId,
        ),
      );
    } on Object catch (error, stackTrace) {
      _fail(session, error, stackTrace);
      return;
    }

    if (session.closed) return;

    // The plugin's own `listenFor` is advisory on some platforms, and the
    // round's clock is not: stop the session ourselves at the cap, then allow
    // the usual grace for the final result.
    session.capTimer = Timer(maxDuration, () {
      if (_speech.isListening) unawaited(_speech.stop());
      unawaited(_end(session));
    });
  }

  void _onResult(_Session session, SpeechRecognitionResult result) {
    if (session.closed || !identical(session, _session)) return;

    // Any result proves the session is alive and is its own.
    session.started = true;
    session.listeningSince ??= DateTime.now();

    final words = [
      for (final alternate in result.alternates) alternate.recognizedWords,
    ]..removeWhere((word) => word.trim().isEmpty);

    if (words.isNotEmpty) {
      session.controller.add(
        SpeechResult(
          transcript: words.first,
          alternates: words.skip(1).toList(),
          isFinal: result.finalResult,
          // The plugin reports -1 when the platform gave no confidence; the
          // API promises 0..1, so clamp rather than leak the sentinel.
          confidence: result.confidence < 0 ? 0 : result.confidence,
        ),
      );
    }

    if (result.finalResult) unawaited(_end(session));
  }

  void _onStatus(String status) {
    final session = _session;
    if (session == null || session.closed) return;

    switch (status) {
      case 'listening':
        session.started = true;
        session.listeningSince ??= DateTime.now();
      case 'notListening' || 'done':
        // Two ways a stop can belong to somebody else: this session has not
        // started yet, or it started so recently that the platform cannot
        // have listened and given up in between. Either way the status is the
        // previous session's, arriving late.
        if (!session.started || !session.isSettled) return;
        unawaited(_end(session));
    }
  }

  /// Whether the microphone has been granted, treating an unanswerable
  /// question as "no".
  Future<bool> _permitted() async {
    try {
      return await _speech.hasPermission;
    } on Object {
      return false;
    }
  }

  void _onError(SpeechRecognitionError error) {
    // "Nothing was heard" is an ordinary event during play, not a failure:
    // a player thinking for eight seconds produces error_speech_timeout.
    if (kBenignSpeechErrors.contains(error.errorMsg)) return;

    // During `initialize` there is no session to fail — this *is* the answer
    // the caller is waiting for.
    if (_initializing) {
      _initFailure ??= speechReasonOf(error.errorMsg);
      return;
    }
    // Meaningful on iOS. On Android the plugin hardcodes `permanent: true` for
    // every error it forwards, so this decides nothing there — which is why
    // `kBenignSpeechErrors` exists and why the check below does the rest.
    if (!error.permanent) return;

    final session = _session;
    if (session == null || session.closed) return;

    final reason = speechReasonOf(error.errorMsg);

    // The plugin's error callback is *global*, not per session, so an error
    // provoked by tearing the previous session down arrives once the next one
    // already exists and would kill a session that never did anything wrong.
    // Before the platform has confirmed this session is listening, an
    // unattributable error belongs to the one before it.
    //
    // A recognised reason is exempt: "you denied the microphone" is true of
    // the device, not of a session, and must reach the player straight away
    // rather than waiting out the session cap.
    if (!session.started && reason == SpeechUnavailableReason.unknown) return;

    _fail(session, SpeechUnavailable(reason: reason), StackTrace.current);
  }

  void _fail(_Session session, Object error, StackTrace stackTrace) {
    if (session.closed) return;
    session.closed = true;
    session.cancelTimers();
    if (identical(session, _session)) _session = null;

    // Nothing else will stop the platform now that the plugin no longer
    // cancels on error, and a recogniser left running holds the microphone.
    if (_speech.isListening) unawaited(_speech.cancel());

    if (!session.controller.isClosed) {
      session.controller.addError(
        error is SpeechRecognitionError
            ? SpeechUnavailable(reason: speechReasonOf(error.errorMsg))
            : error,
        stackTrace,
      );
      unawaited(session.controller.close());
    }
  }

  Future<void> _end(_Session? session, {bool cancelPlatform = false}) async {
    if (session == null || session.closed) return;
    session.closed = true;
    session.cancelTimers();
    if (identical(session, _session)) _session = null;

    if (cancelPlatform && _speech.isListening) {
      try {
        await _speech.cancel();
      } on Object {
        // Cancelling a session the platform already ended is not a failure.
      }
    }

    if (!session.controller.isClosed) await session.controller.close();
  }
}
