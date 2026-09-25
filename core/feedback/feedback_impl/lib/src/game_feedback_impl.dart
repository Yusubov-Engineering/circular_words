import 'package:feedback_api/feedback_api.dart';
import 'package:storage_api/storage_api.dart';

import 'feedback_haptics.dart';
import 'feedback_sounds.dart';

/// Where the player's choice about sound is kept.
const kMutedStorageKey = 'feedback.muted';

/// {@template game_feedback_impl}
/// [GameFeedbackApi] over `audioplayers` and the platform's haptics.
///
/// Every cue is two channels, chosen so the game is still playable with either
/// one missing: a phone on silent still taps, and a phone with haptics off
/// still chimes. That is why muting covers only the sound — the two are not
/// the same message delivered twice, they are the same message delivered to
/// whichever sense is available.
///
/// **Nothing here may throw.** A cue is a comment on something that already
/// happened; a missing codec or an absent vibrator must not take down the
/// round it was commenting on. Every call is wrapped for that reason, and the
/// swallowing is deliberate rather than lazy.
/// {@endtemplate}
final class GameFeedbackImpl implements GameFeedbackApi {
  /// {@macro game_feedback_impl}
  GameFeedbackImpl({
    required this._storage,
    this._haptics = const PlatformHaptics(),
    FeedbackSounds? sounds,
  }) : _sounds = sounds ?? AudioPlayersSounds();

  final StandardStorageApi _storage;
  final FeedbackSounds _sounds;
  final FeedbackHaptics _haptics;

  bool _muted = false;
  bool _loaded = false;

  /// The in-flight decode, so a cue can wait for it and teardown cannot race
  /// it. Null until [initialize] has been called.
  Future<void>? _warming;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> initialize() async {
    if (_loaded) return;
    _loaded = true;

    try {
      _muted = await _storage.readBool(key: kMutedStorageKey) ?? false;
    } on Object {
      // An unreadable preference is "not muted": the game is meant to make a
      // noise, and a player who wants silence can say so again.
      _muted = false;
    }

    // Deliberately **not** awaited. Callers block on this method to learn the
    // player's preference — a cheap read — and blocking them on three audio
    // decodes as well means the UI showing that preference is stale for as
    // long as the codec takes. Observed on an emulator: the sound toggle came
    // up showing "on" for a player who had muted the game, because the decode
    // had not finished. The cues below wait for this; nobody else has to.
    _warming = _guard(_sounds.load);
  }

  @override
  Future<void> setMuted({required bool muted}) async {
    _muted = muted;

    try {
      await _storage.writeBool(key: kMutedStorageKey, value: muted);
    } on Object {
      // The setting applies for this session even if it cannot be stored.
    }
  }

  @override
  Future<void> correct({bool audible = true}) =>
      _cue(audible ? FeedbackSound.correct : null, HapticCue.firm);

  @override
  Future<void> rejected() => _cue(null, HapticCue.faint);

  @override
  Future<void> wrong({bool audible = true}) =>
      _cue(audible ? FeedbackSound.wrong : null, HapticCue.faint);

  @override
  Future<void> finished({bool audible = true}) =>
      _cue(audible ? FeedbackSound.finished : null, HapticCue.heavy);

  @override
  Future<void> dispose() async {
    // Tearing players down mid-decode is how you get a platform exception on
    // the way out of a screen.
    await _warming;
    await _guard(_sounds.dispose);

    _warming = null;
    _loaded = false;
  }

  /// Plays both halves of one cue. [sound] may be null for a cue that is felt
  /// but not heard.
  Future<void> _cue(FeedbackSound? sound, HapticCue haptic) async {
    // Haptics first, and always: they are the half that a muted phone in a
    // pocket can still deliver.
    await _guard(() => _haptics.play(haptic));

    if (sound == null || _muted) return;

    await _guard(() async {
      // A cue asked for before the decode finished waits for it rather than
      // going silently missing.
      await _warming;
      await _sounds.play(sound);
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // See the class doc: feedback never interrupts what it is commenting on.
    }
  }
}
