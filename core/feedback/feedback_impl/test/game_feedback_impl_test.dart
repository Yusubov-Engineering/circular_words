import 'dart:async';

import 'package:feedback_impl/src/feedback_haptics.dart';
import 'package:feedback_impl/src/feedback_sounds.dart';
import 'package:feedback_impl/src/game_feedback_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_api/storage_api.dart';

final class FakeSounds implements FeedbackSounds {
  final played = <FeedbackSound>[];
  int loads = 0;
  bool throwOnPlay = false;

  /// Completed by the test to say "the codec has finished". Loading is slow
  /// and, on some devices, very slow — which is the whole reason `initialize`
  /// must not wait for it.
  final slowLoad = Completer<void>();
  bool loadIsSlow = false;

  @override
  Future<void> load() async {
    loads++;
    if (loadIsSlow) await slowLoad.future;
  }

  @override
  Future<void> play(FeedbackSound sound) async {
    if (throwOnPlay) throw StateError('no audio device');
    played.add(sound);
  }

  @override
  Future<void> dispose() async {}
}

final class FakeHaptics implements FeedbackHaptics {
  final played = <HapticCue>[];

  @override
  Future<void> play(HapticCue cue) async => played.add(cue);
}

/// Storage that can be told to misbehave, because a preference store on a real
/// device sometimes does.
final class FakeStorage implements StandardStorageApi {
  final bools = <String, bool>{};
  bool throwOnRead = false;
  bool throwOnWrite = false;

  @override
  Future<bool?> readBool({required String key}) async {
    if (throwOnRead) throw StateError('unreadable');
    return bools[key];
  }

  @override
  Future<void> writeBool({required String key, required bool value}) async {
    if (throwOnWrite) throw StateError('unwritable');
    bools[key] = value;
  }

  @override
  Future<void> writeString({
    required String key,
    required String value,
  }) async {}

  @override
  Future<String?> readString({required String key}) async => null;

  @override
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> json,
  }) async {}

  @override
  Future<Map<String, dynamic>?> readJson({required String key}) async => null;

  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<void> clearAll() async {}
}

void main() {
  late FakeSounds sounds;
  late FakeHaptics haptics;
  late FakeStorage storage;
  late GameFeedbackImpl feedback;

  setUp(() {
    sounds = FakeSounds();
    haptics = FakeHaptics();
    storage = FakeStorage();
    feedback = GameFeedbackImpl(
      storage: storage,
      sounds: sounds,
      haptics: haptics,
    );
  });

  group('cues', () {
    test('each one is a sound and a feeling', () async {
      await feedback.initialize();

      await feedback.correct();
      await feedback.wrong();
      await feedback.finished();

      expect(sounds.played, [
        FeedbackSound.correct,
        FeedbackSound.wrong,
        FeedbackSound.finished,
      ]);
      expect(haptics.played, [
        HapticCue.firm,
        HapticCue.faint,
        HapticCue.heavy,
      ]);
    });

    // With speech, a rejection is usually a mishearing rather than a mistake,
    // and it happens several times a letter. Chiming at each one would make
    // the game tiring to play badly — which is how a learner starts.
    test('a rejection is felt but not heard', () async {
      await feedback.initialize();
      await feedback.rejected();

      expect(sounds.played, isEmpty);
      expect(haptics.played, [HapticCue.faint]);
    });

    // On Android a sound played into an open microphone is recorded with the
    // player and breaks the session, so the round asks for silent cues while
    // it listens. The haptic is the whole message then, and must still come.
    test(
      'an inaudible cue is still felt, and never touches the speaker',
      () async {
        await feedback.initialize();
        await feedback.correct(audible: false);
        await feedback.wrong(audible: false);
        await feedback.finished(audible: false);

        expect(sounds.played, isEmpty);
        expect(haptics.played, [
          HapticCue.firm,
          HapticCue.faint,
          HapticCue.heavy,
        ]);
      },
    );
  });

  group('muting', () {
    test('silences sound and leaves the haptics alone', () async {
      await feedback.initialize();
      await feedback.setMuted(muted: true);

      await feedback.correct();
      await feedback.finished();

      // The point of the split: a muted phone in a pocket still tells the
      // player they got it.
      expect(sounds.played, isEmpty);
      expect(haptics.played, [HapticCue.firm, HapticCue.heavy]);
    });

    test('is remembered', () async {
      await feedback.initialize();
      await feedback.setMuted(muted: true);

      expect(storage.bools[kMutedStorageKey], isTrue);

      final next = GameFeedbackImpl(
        storage: storage,
        sounds: FakeSounds(),
        haptics: FakeHaptics(),
      );
      await next.initialize();

      expect(next.isMuted, isTrue);
    });

    test('can be turned back on', () async {
      await feedback.initialize();
      await feedback.setMuted(muted: true);
      await feedback.setMuted(muted: false);
      await feedback.correct();

      expect(feedback.isMuted, isFalse);
      expect(sounds.played, [FeedbackSound.correct]);
    });

    test('an unreadable preference is not muted', () async {
      storage.throwOnRead = true;
      await feedback.initialize();

      // A game is supposed to make a noise; silence is the surprising default.
      expect(feedback.isMuted, isFalse);
    });

    test('a preference that cannot be stored still applies now', () async {
      await feedback.initialize();
      storage.throwOnWrite = true;

      await feedback.setMuted(muted: true);
      await feedback.correct();

      expect(feedback.isMuted, isTrue);
      expect(sounds.played, isEmpty);
    });
  });

  // A cue is a comment on something that already happened. If the comment
  // fails, the thing it was commenting on must carry on regardless.
  group('failing quietly', () {
    test('a broken sound device does not throw at the caller', () async {
      await feedback.initialize();
      sounds.throwOnPlay = true;

      await expectLater(feedback.correct(), completes);
      // And the half that still works still works.
      expect(haptics.played, [HapticCue.firm]);
    });
  });

  // The bug this pins, seen on an emulator: the sound toggle came up showing
  // "on" for a player who had muted the game, because the stored preference
  // was behind three audio decodes in the same await.
  group('initialising does not wait for the codec', () {
    test('the preference is known before loading finishes', () async {
      storage.bools[kMutedStorageKey] = true;
      sounds.loadIsSlow = true;

      await feedback.initialize().timeout(const Duration(seconds: 1));

      expect(feedback.isMuted, isTrue);
      expect(sounds.loads, 1);

      sounds.slowLoad.complete();
    });

    test('a cue asked for mid-load still gets its sound', () async {
      sounds.loadIsSlow = true;
      await feedback.initialize();

      final cue = feedback.correct();
      // Nothing yet: the source is not ready.
      expect(sounds.played, isEmpty);

      sounds.slowLoad.complete();
      await cue;

      // Waited for, not dropped.
      expect(sounds.played, [FeedbackSound.correct]);
    });
  });

  test('initialising twice loads once', () async {
    await feedback.initialize();
    await feedback.initialize();

    expect(sounds.loads, 1);
  });
}
