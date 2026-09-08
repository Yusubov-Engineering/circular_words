import 'cefr_level.dart';
import 'level_score.dart';

/// {@template rosco_scoreboard}
/// Best results per level, readable by any module.
///
/// The game produces scores and the level picker displays them, so the
/// protocol belongs to `rosco` — the module that owns the outcome — and
/// `levels` reads it through `RoscoApi`. That keeps a single writer and
/// spares `levels` any knowledge of how a score is stored.
/// {@endtemplate}
abstract interface class RoscoScoreboard {
  /// The best recorded result for [level], or `null` if never played.
  Future<LevelScore?> best(CefrLevel level);

  /// Every level's best result, missing entries meaning "not played yet".
  Future<Map<CefrLevel, LevelScore>> all();

  /// Records [score] if it beats what is stored, and reports whether it did.
  Future<bool> record(CefrLevel level, LevelScore score);
}
