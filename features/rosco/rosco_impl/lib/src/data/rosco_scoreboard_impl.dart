import 'package:rosco_api/rosco_api.dart';
import 'package:storage_api/storage_api.dart';

/// {@template rosco_scoreboard_impl}
/// [RoscoScoreboard] over unencrypted key-value storage.
///
/// A best score is a convenience, not a secret, so it uses standard storage.
/// Each level is stored under its own key rather than as one blob: a level
/// whose stored score is corrupt then reads as "not played yet" on its own,
/// instead of taking every other level's score down with it.
/// {@endtemplate}
final class RoscoScoreboardImpl({required final StandardStorageApi _storage})
    implements RoscoScoreboard {
  /// The stored key for [level]. Built from [CefrLevel.id], which is why that
  /// id must stay stable once scores exist on a device.
  static String keyFor(CefrLevel level) => 'rosco.best.${level.id}';

  @override
  Future<LevelScore?> best(CefrLevel level) async {
    try {
      return LevelScore.fromJson(await _storage.readJson(key: keyFor(level)));
    } on Object {
      // Unreadable storage is "no score", never a crash on the picker.
      return null;
    }
  }

  @override
  Future<Map<CefrLevel, LevelScore>> all() async {
    final entries = <CefrLevel, LevelScore>{};

    for (final level in CefrLevel.values) {
      final score = await best(level);
      if (score != null) entries[level] = score;
    }

    return entries;
  }

  @override
  Future<bool> record(CefrLevel level, LevelScore score) async {
    final current = await best(level);
    if (!score.beats(current)) return false;

    try {
      await _storage.writeJson(key: keyFor(level), json: score.toJson());
      return true;
    } on Object {
      // Failing to persist a score must not fail the round that earned it.
      return false;
    }
  }
}
