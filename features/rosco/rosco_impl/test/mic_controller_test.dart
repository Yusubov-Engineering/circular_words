import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rosco_impl/src/rosco/mic_controller.dart';
import 'package:speech_api/speech_api.dart';

/// One listening session, driven by hand.
///
/// The point of these tests is what happens *between* sessions, so a test has
/// to be able to end one the way the platform does — quietly, with the letter
/// still running.
final class FakeSession {
  final controller = StreamController<SpeechResult>();

  bool get isOpen => !controller.isClosed;

  void hear(
    String transcript, {
    List<String> alternates = const [],
    bool isFinal = false,
  }) => controller.add(
    SpeechResult(
      transcript: transcript,
      alternates: alternates,
      isFinal: isFinal,
    ),
  );

  /// The platform gave up — `NO_SPEECH_DETECTED`, or a final delivered.
  Future<void> end() => controller.close();

  void fail(Object error) => controller.addError(error);
}

final class FakeRecognizer implements SpeechRecognizerApi {
  FakeRecognizer({this.availability = const SpeechReady()});

  SpeechAvailability availability;
  int initializeCalls = 0;
  final sessions = <FakeSession>[];
  final requestedMaxDurations = <Duration>[];
  final requestedPauses = <Duration>[];

  FakeSession get session => sessions.last;

  @override
  Future<SpeechAvailability> initialize() async {
    initializeCalls++;
    return availability;
  }

  @override
  bool get isListening => sessions.isNotEmpty && sessions.last.isOpen;

  @override
  Stream<SpeechResult> listen({
    Duration maxDuration = const Duration(seconds: 10),
    Duration pauseFor = const Duration(seconds: 3),
    String? localeId,
  }) {
    requestedMaxDurations.add(maxDuration);
    requestedPauses.add(pauseFor);
    final session = FakeSession();
    sessions.add(session);
    return session.controller.stream;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

/// Lets pending timers and stream events run.
///
/// The restart delay is zero in these tests, but a zero timer still lands
/// after the microtask queue, so a plain await is not enough on its own.
Future<void> settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeRecognizer recognizer;
  late MicController controller;
  late List<MicEffect> effects;
  late StreamSubscription<MicEffect> subscription;

  void build({SpeechAvailability availability = const SpeechReady()}) {
    recognizer = FakeRecognizer(availability: availability);
    controller = MicController(
      recognizer: recognizer,
      sessionLength: const Duration(seconds: kMicSessionSeconds),
      restartDelay: Duration.zero,
    );
    effects = [];
    subscription = controller.effects.listen(effects.add);
  }

  setUp(build);

  tearDown(() async {
    await subscription.cancel();
    controller.dispose();
  });

  group('turning on', () {
    test('opens a session and reports listening', () async {
      await controller.dispatch(const MicRequested());

      expect(recognizer.initializeCalls, 1);
      expect(recognizer.sessions, hasLength(1));
      expect(controller.state.enabled, isTrue);
      expect(controller.state.status, MicStatus.listening);
    });

    test('a refused microphone is a state, not an error', () async {
      build(
        availability: const SpeechUnavailable(
          reason: SpeechUnavailableReason.permissionDenied,
        ),
      );

      await controller.dispatch(const MicRequested());

      expect(controller.state.status, MicStatus.unavailable);
      expect(controller.state.reason, SpeechUnavailableReason.permissionDenied);
      expect(controller.state.enabled, isFalse);
      // Nothing was opened, so there is nothing to close.
      expect(recognizer.sessions, isEmpty);
    });

    test('asking twice does not open a second session', () async {
      await controller.dispatch(const MicRequested());
      await controller.dispatch(const MicRequested());

      expect(recognizer.sessions, hasLength(1));
    });

    test(
      'a refusal can be retried — the player may fix it in Settings',
      () async {
        build(
          availability: const SpeechUnavailable(
            reason: SpeechUnavailableReason.noRecognizer,
          ),
        );

        await controller.dispatch(const MicRequested());
        recognizer.availability = const SpeechReady();
        await controller.dispatch(const MicRequested());

        expect(controller.state.status, MicStatus.listening);
        expect(controller.state.reason, isNull);
      },
    );
  });

  group('hearing', () {
    test('everything heard mid-session is tentative', () async {
      await controller.dispatch(const MicRequested());

      recognizer.session.hear('abundant', alternates: ['albondant']);
      await settle();
      // Even one the platform calls final. It synthesises those, late, from
      // the partial before it — the word is not settled just because the
      // platform says so.
      recognizer.session.hear('abundant', isFinal: true);
      await settle();

      expect(effects, hasLength(2));
      expect(effects.map((e) => (e as MicTranscribed).tentative), [true, true]);

      final first = effects.first as MicTranscribed;
      expect(first.transcript, 'abundant');
      expect(first.alternates, ['albondant']);
    });

    test('the end of a session settles what it last heard', () async {
      await controller.dispatch(const MicRequested());

      recognizer.session.hear('a bun');
      await settle();
      recognizer.session.hear('a bun dance', alternates: ['abundance']);
      await settle();
      await recognizer.session.end();
      await settle();

      // The utterance is over, so the last thing heard is what was said —
      // which is what lets the player be shown a miss.
      final settled = effects.last as MicTranscribed;
      expect(settled.tentative, isFalse);
      expect(settled.transcript, 'a bun dance');
      expect(settled.alternates, ['abundance']);
    });

    test('a session that heard nothing settles nothing', () async {
      await controller.dispatch(const MicRequested());

      await recognizer.session.end();
      await settle();

      // Silence is not a wrong answer, and must never be shown as one.
      expect(effects, isEmpty);
    });

    test('what one letter heard is never settled against the next', () async {
      await controller.dispatch(const MicRequested());

      recognizer.session.hear('arm');
      await settle();
      await controller.dispatch(const MicPromptChanged());
      await settle();
      await recognizer.session.end();
      await settle();

      expect(
        effects.whereType<MicTranscribed>().where((e) => !e.tentative),
        isEmpty,
      );
    });

    test('the best guess is shown to the player', () async {
      await controller.dispatch(const MicRequested());

      recognizer.session.hear('abundant');
      await settle();

      expect(controller.state.heard, 'abundant');
    });

    test('a transcript from the previous letter is not scored again', () async {
      await controller.dispatch(const MicRequested());
      recognizer.session.hear('arm');
      await settle();
      effects.clear();

      await controller.dispatch(const MicPromptChanged());
      // The session is still open and the recogniser still mid-utterance, so
      // it repeats itself. Offering that to the new clue would look like the
      // player answering something they never saw.
      recognizer.session.hear('arm');
      await settle();

      expect(effects, isEmpty);
      expect(controller.state.heard, isEmpty);
    });

    test('but anything new is', () async {
      await controller.dispatch(const MicRequested());
      recognizer.session.hear('arm');
      await settle();
      await controller.dispatch(const MicPromptChanged());
      recognizer.session.hear('arm');
      await settle();
      effects.clear();

      recognizer.session.hear('book');
      await settle();

      expect(effects, hasLength(1));
      expect(controller.state.heard, 'book');
    });
  });

  group('a session ending is not the letter ending', () {
    test('a session that closes while enabled is replaced', () async {
      await controller.dispatch(const MicRequested());

      // What Android does 5.5 s into a letter the player is still thinking
      // about: NO_SPEECH_DETECTED, and the microphone is gone.
      await recognizer.session.end();
      await settle();

      expect(recognizer.sessions, hasLength(2));
      expect(controller.state.status, MicStatus.listening);
      expect(controller.state.enabled, isTrue);
    });

    test('and replaced again, for as long as the letter lasts', () async {
      await controller.dispatch(const MicRequested());

      for (var i = 0; i < 3; i++) {
        await recognizer.session.end();
        await settle();
      }

      expect(recognizer.sessions, hasLength(4));
    });

    // The bug this pins, reported from play: after a bad patch the microphone
    // stopped and would not come back. The button read as off — so a player
    // tapped it — but `enabled` was still true underneath, so that tap turned
    // *off* a microphone that had already stopped, and it took a second tap
    // to get one back.
    test('giving up turns it off properly, not halfway', () async {
      await controller.dispatch(const MicRequested());

      for (var i = 0; i < 12; i++) {
        await recognizer.session.end();
        await settle();
      }

      expect(controller.state.status, MicStatus.idle);
      // The state the button is drawn from and the state its tap reads must
      // agree, or one tap does the opposite of what the button says.
      expect(controller.state.enabled, isFalse);
    });

    // The other half of the same report: having given up, it stayed given up.
    test('a new letter revives a microphone that gave up', () async {
      await controller.dispatch(const MicRequested());
      for (var i = 0; i < 12; i++) {
        await recognizer.session.end();
        await settle();
      }
      expect(controller.state.enabled, isFalse);

      await controller.dispatch(const MicPromptChanged());
      await settle();

      // No tap required: a new letter is a new chance.
      expect(controller.state.enabled, isTrue);
      expect(controller.state.status, MicStatus.listening);
    });

    test('but a microphone the player switched off stays off', () async {
      await controller.dispatch(const MicRequested());
      await controller.dispatch(const MicDismissed());

      await controller.dispatch(const MicPromptChanged());
      await settle();

      // The distinction that matters: giving up is recoverable, a decision
      // is not.
      expect(controller.state.enabled, isFalse);
      expect(recognizer.sessions, hasLength(1));
    });

    test('and one the device cannot provide is not retried', () async {
      await controller.dispatch(const MicRequested());
      recognizer.session.fail(
        const SpeechUnavailable(reason: SpeechUnavailableReason.noRecognizer),
      );
      await settle();

      await controller.dispatch(const MicPromptChanged());
      await settle();

      // A letter changing does not install a speech recogniser.
      expect(controller.state.status, MicStatus.unavailable);
      expect(recognizer.sessions, hasLength(1));
    });

    test(
      'but not forever — a platform closing every session gives up',
      () async {
        await controller.dispatch(const MicRequested());

        for (var i = 0; i < 12; i++) {
          await recognizer.session.end();
          await settle();
        }

        // Bounded, and stopped in a state the next letter can recover from.
        expect(recognizer.sessions.length, lessThanOrEqualTo(6));
        expect(controller.state.status, MicStatus.idle);
      },
    );

    test('a session that produced a result renews the budget', () async {
      await controller.dispatch(const MicRequested());

      for (var i = 0; i < 12; i++) {
        recognizer.session.hear('still here');
        await settle();
        await recognizer.session.end();
        await settle();
      }

      // A player who keeps talking is never cut off by the spin guard.
      expect(recognizer.sessions, hasLength(13));
      expect(controller.state.status, MicStatus.listening);
    });

    test('a new letter clears the guard and the transcript', () async {
      await controller.dispatch(const MicRequested());

      for (var i = 0; i < 12; i++) {
        await recognizer.session.end();
        await settle();
      }
      expect(controller.state.status, MicStatus.idle);

      recognizer.sessions.clear();
      await controller.dispatch(const MicPromptChanged());
      await settle();

      expect(recognizer.sessions, hasLength(1));
      expect(controller.state.status, MicStatus.listening);
      expect(controller.state.heard, isEmpty);
    });
  });

  group('turning off', () {
    test('closes the session and does not re-open it', () async {
      await controller.dispatch(const MicRequested());
      await controller.dispatch(const MicDismissed());
      await settle();

      expect(controller.state.enabled, isFalse);
      expect(controller.state.status, MicStatus.idle);
      expect(controller.state.heard, isEmpty);
      expect(recognizer.sessions, hasLength(1));
    });

    test(
      'a new letter does not wake a microphone the player turned off',
      () async {
        await controller.dispatch(const MicRequested());
        await controller.dispatch(const MicDismissed());
        await controller.dispatch(const MicPromptChanged());
        await settle();

        expect(recognizer.sessions, hasLength(1));
        expect(controller.state.enabled, isFalse);
      },
    );
  });

  group('a session outlives a letter', () {
    // Android applies the silence timeout as the whole listening window: a
    // three second `pauseFor` shut the microphone 3.0 s after opening it,
    // every time, whether or not anyone was speaking. A minute is the
    // measured sweet spot — see `kMicSessionSeconds`.
    test('the silence it tolerates is a minute, not a letter', () async {
      await controller.dispatch(const MicRequested());

      expect(
        recognizer.requestedPauses.single,
        const Duration(seconds: kMicSessionSeconds),
      );
      expect(
        recognizer.requestedMaxDurations.single,
        const Duration(seconds: kMicSessionSeconds),
      );
    });

    // Restarting on every letter cost at least twenty-six teardowns a round,
    // each an audible beep and a gap with no microphone — and the gap lands
    // exactly where the player speaks, just after reading a new clue.
    test('a letter changing leaves a working session alone', () async {
      await controller.dispatch(const MicRequested());

      await controller.dispatch(const MicPromptChanged());
      await controller.dispatch(const MicPromptChanged());
      await settle();

      expect(recognizer.sessions, hasLength(1));
      expect(controller.state.status, MicStatus.listening);
    });

    test('a letter changing does not stack a second session on top', () async {
      await controller.dispatch(const MicRequested());
      await recognizer.session.end();
      await settle();
      expect(recognizer.sessions, hasLength(2));

      await controller.dispatch(const MicPromptChanged());
      await settle();

      // The restart already gave this letter a microphone; opening another
      // would take it straight back off the player.
      expect(recognizer.sessions, hasLength(2));
    });
  });

  group('failing', () {
    test('an error on the stream ends the microphone for the round', () async {
      await controller.dispatch(const MicRequested());

      recognizer.session.fail(
        const SpeechUnavailable(reason: SpeechUnavailableReason.restricted),
      );
      await settle();

      expect(controller.state.status, MicStatus.unavailable);
      expect(controller.state.reason, SpeechUnavailableReason.restricted);
      expect(controller.state.enabled, isFalse);
      // Crucially, it does not restart: this is not a session ending, it is
      // the microphone being gone.
      expect(recognizer.sessions, hasLength(1));
    });

    // The bug this pins, measured on device: answering a letter by voice
    // advanced the round, the next session raced the previous one's teardown,
    // and Android's `error_client` arrived attributed to the new session. One
    // correct answer turned the microphone off for the rest of the round.
    test('an unrecognised error still reads as unavailable', () async {
      await controller.dispatch(const MicRequested());

      recognizer.session.fail(StateError('something else'));
      await settle();

      expect(controller.state.status, MicStatus.unavailable);
      expect(controller.state.reason, SpeechUnavailableReason.unknown);
    });
  });

  test('disposing stops everything', () async {
    await controller.dispatch(const MicRequested());
    controller.dispose();

    await recognizer.session.end();
    await settle();

    expect(recognizer.sessions, hasLength(1));
  });

  // On Android the microphone records the loudspeaker. A chime played into an
  // open session is transcribed with the player, and a session that opens
  // while one sounds calibrates to it and then hears speech as silence.
  group('making room for a cue', () {
    const cue = Duration(milliseconds: 40);

    Future<void> waitOut() async {
      await Future<void>.delayed(cue * 2);
      await settle();
    }

    test('closes the open session and opens one after the cue', () async {
      await controller.dispatch(const MicRequested());
      expect(recognizer.sessions, hasLength(1));

      await controller.dispatch(const MicCueing(length: cue));
      await settle();
      // Nothing opens while the cue sounds.
      expect(recognizer.sessions, hasLength(1));

      await waitOut();
      expect(recognizer.sessions, hasLength(2));
      expect(controller.state.status, MicStatus.listening);
    });

    test('a letter changing mid-cue does not open a session early', () async {
      await controller.dispatch(const MicRequested());
      await controller.dispatch(const MicCueing(length: cue));

      await controller.dispatch(const MicPromptChanged());
      await settle();
      expect(recognizer.sessions, hasLength(1));

      await waitOut();
      // One session after the cue — not one for the letter and one for the
      // cue.
      expect(recognizer.sessions, hasLength(2));
    });

    test('what the closed session heard is not settled afterwards', () async {
      await controller.dispatch(const MicRequested());
      recognizer.session.hear('abundant');
      await settle();
      effects.clear();

      await controller.dispatch(const MicCueing(length: cue));
      await recognizer.sessions.first.end();
      await waitOut();

      // The chime comments on an answer already scored; replaying the
      // transcript as a settled answer would score or reject it again.
      expect(effects, isEmpty);
    });

    test('turning the microphone off mid-cue keeps it off', () async {
      await controller.dispatch(const MicRequested());
      await controller.dispatch(const MicCueing(length: cue));
      await controller.dispatch(const MicDismissed());

      await waitOut();
      expect(recognizer.sessions, hasLength(1));
      expect(controller.state.enabled, isFalse);
    });

    test('a cue with the microphone off turns nothing on', () async {
      await controller.dispatch(const MicCueing(length: cue));

      await waitOut();
      expect(recognizer.sessions, isEmpty);
      expect(controller.state.enabled, isFalse);
    });
  });
}
