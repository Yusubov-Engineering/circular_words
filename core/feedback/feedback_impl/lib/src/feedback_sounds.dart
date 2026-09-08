import 'package:audioplayers/audioplayers.dart';

/// The sounds the game can make.
enum FeedbackSound {
  correct('correct.wav'),
  wrong('wrong.wav'),
  finished('finished.wav');

  const FeedbackSound(this.fileName);

  final String fileName;
}

/// {@template feedback_sounds}
/// Plays the game's short cues.
///
/// An interface so that what *decides* to play a sound can be tested without a
/// speaker — unit tests have no audio device, and a plugin that throws in a
/// test is a plugin that fails the build for the wrong reason.
/// {@endtemplate}
abstract interface class FeedbackSounds {
  Future<void> load();
  Future<void> play(FeedbackSound sound);
  Future<void> dispose();
}

/// {@template audio_players_sounds}
/// [FeedbackSounds] over `audioplayers`.
///
/// One player per sound, each holding its own loaded source. Sharing a player
/// would mean a cue cutting off the one before it, and the two that overlap
/// most — an answer accepted as the round ends — are exactly the pair worth
/// hearing together.
/// {@endtemplate}
final class AudioPlayersSounds implements FeedbackSounds {
  /// {@macro audio_players_sounds}
  AudioPlayersSounds({AudioPlayer Function()? createPlayer})
    : _createPlayer = createPlayer ?? AudioPlayer.new;

  /// Package assets are addressed from the app's root bundle, so the
  /// `packages/<name>/` prefix is not optional — without it these resolve in
  /// this package's own tests and nowhere else.
  static const assetPrefix = 'packages/feedback_impl/assets/sounds/';

  final AudioPlayer Function() _createPlayer;
  final _players = <FeedbackSound, AudioPlayer>{};

  @override
  Future<void> load() async {
    for (final sound in FeedbackSound.values) {
      if (_players.containsKey(sound)) continue;

      final player = _createPlayer()
        // Stop rather than release, so the decoded source stays warm: these
        // are answered a second apart and a reload between them is audible.
        ..audioCache = AudioCache(prefix: assetPrefix);

      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setSource(AssetSource(sound.fileName));

      _players[sound] = player;
    }
  }

  @override
  Future<void> play(FeedbackSound sound) async {
    final player = _players[sound];
    if (player == null) return;

    // Rewind first: a cue asked for twice in quick succession should sound
    // twice, not be ignored because the player is still busy.
    await player.seek(Duration.zero);
    await player.resume();
  }

  @override
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
