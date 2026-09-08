import 'package:rosco_api/rosco_api.dart';
import 'package:router_api/router_api.dart';

import '../domain/word_set.dart';

/// The outcome of a round, carried in the URL.
///
/// Query parameters rather than an in-memory `extra`, because `extra` does not
/// survive the three things most likely to happen to this screen: the process
/// being killed behind it, a restore from that, and a link being reopened. A
/// result the player cannot get back to is a result they will assume was lost.
final class const RoscoResultArgs({
  required final CefrLevel level,
  required final LevelScore score,
}) {
  /// Parses `/rosco/:level/result?correct=12&total=26&left=165`.
  factory RoscoResultArgs.fromRaw(AppRouteArguments raw) => RoscoResultArgs(
    level: CefrLevel.tryParse(raw.pathParameters['level']) ?? CefrLevel.a1,
    score: _scoreFrom(raw.queryParameters),
  );

  static const _correct = 'correct';
  static const _total = 'total';
  static const _left = 'left';

  Map<String, String> toQuery() => {
    _correct: '${score.correct}',
    _total: '${score.total}',
    _left: '${score.secondsRemaining}',
  };

  /// Reads a score out of the query string, defensively.
  ///
  /// Every value here is hand-editable and survives across app versions, so
  /// nothing is trusted: a missing or nonsensical parameter yields a scoreless
  /// round rather than an exception on a screen whose whole job is to tell the
  /// player how they did.
  static LevelScore _scoreFrom(Map<String, String> query) {
    // The total is settled *before* it is used as a bound, or a nonsense
    // total silently takes the score down with it.
    final parsed = _readInt(query[_total]) ?? 0;
    final total = parsed <= 0 ? WordSet.letterCount : parsed;

    return LevelScore(
      correct: (_readInt(query[_correct]) ?? 0).clamp(0, total),
      total: total,
      secondsRemaining: _readInt(query[_left]) ?? 0,
    );
  }

  static int? _readInt(String? raw) {
    final value = int.tryParse(raw ?? '');
    return value == null || value < 0 ? null : value;
  }
}
