import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:feedback_impl/src/feedback_sounds.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Behaves like Android in low-latency mode: `SoundPool` accepts a seek but
/// never reports it complete. Every call is recorded.
final class SoundPoolLikePlatform extends AudioplayersPlatformInterface {
  final calls = <String>[];
  final _events = <String, StreamController<AudioEvent>>{};

  Future<void> _record(String call) async => calls.add(call);

  @override
  Stream<AudioEvent> getEventStream(String playerId) =>
      (_events[playerId] ??= StreamController<AudioEvent>.broadcast()).stream;

  @override
  Future<void> create(String playerId) => _record('create');
  @override
  Future<void> dispose(String playerId) => _record('dispose');
  @override
  Future<void> pause(String playerId) => _record('pause');
  @override
  Future<void> stop(String playerId) => _record('stop');
  @override
  Future<void> resume(String playerId) => _record('resume');
  @override
  Future<void> release(String playerId) => _record('release');

  /// Accepted, and never followed by a seek-complete event.
  @override
  Future<void> seek(String playerId, Duration position) => _record('seek');

  @override
  Future<void> setBalance(String playerId, double balance) => _record('');
  @override
  Future<void> setVolume(String playerId, double volume) => _record('');
  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) =>
      _record('');
  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) =>
      _record('');
  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) => _record('');
  @override
  Future<void> setSourceBytes(
    String playerId,
    Uint8List bytes, {
    String? mimeType,
  }) => _record('');
  @override
  Future<void> setAudioContext(String playerId, AudioContext audioContext) =>
      _record('');
  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) =>
      _record('');
  @override
  Future<int?> getDuration(String playerId) async => null;
  @override
  Future<int?> getCurrentPosition(String playerId) async => null;
  @override
  Future<void> emitLog(String playerId, String message) => _record('');
  @override
  Future<void> emitError(String playerId, String code, String message) =>
      _record('');
}

final class QuietGlobalPlatform implements GlobalAudioplayersPlatformInterface {
  @override
  Future<void> init() async {}
  @override
  Future<void> setGlobalAudioContext(AudioContext ctx) async {}
  @override
  Future<void> emitGlobalLog(String message) async {}
  @override
  Future<void> emitGlobalError(String code, String message) async {}
  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SoundPoolLikePlatform platform;

  setUp(() {
    platform = SoundPoolLikePlatform();
    AudioplayersPlatformInterface.instance = platform;
    GlobalAudioplayersPlatformInterface.instance = QuietGlobalPlatform();
  });

  // The Android bug: a cue that rewound with `seek` waited thirty seconds for
  // a completion SoundPool never sends, failed, and never played. Feedback
  // swallows its errors by design, so the only symptom was silence.
  test('playing a cue reaches the speaker without waiting on a seek', () async {
    final player = AudioPlayer();

    await AudioPlayersSounds.restart(player).timeout(
      const Duration(seconds: 1),
      onTimeout: () =>
          fail('restart waited on the platform — the Android hang'),
    );

    expect(platform.calls, isNot(contains('seek')));
    expect(platform.calls.where((call) => call == 'stop' || call == 'resume'), [
      'stop',
      'resume',
    ]);

    await player.dispose();
  });

  // The control: on this platform, as on Android, a seek never finishes —
  // which is exactly what the old rewind waited on.
  test('a seek on a SoundPool-like platform never completes', () async {
    final player = AudioPlayer();
    var completed = false;

    unawaited(
      player.seek(Duration.zero).then((_) => completed = true, onError: (_) {}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(completed, isFalse);
    await player.dispose();
  });
}
