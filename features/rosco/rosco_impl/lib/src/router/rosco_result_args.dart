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

  /// The set that was played. With [marks], enough to name every missed word
  /// without putting the words themselves in the URL.
  final String? setId,

  /// Whether each letter, A to Z, was answered — or `null` when the URL did
  /// not carry a usable record, in which case nothing is revealed.
  final List<bool>? marks,
}) {
  /// Parses `/rosco/:level/result?correct=12&total=26&left=165&set=b1-3&marks=ccw…`.
  factory RoscoResultArgs.fromRaw(AppRouteArguments raw) => RoscoResultArgs(
    level: CefrLevel.tryParse(raw.pathParameters['level']) ?? CefrLevel.a1,
    score: _scoreFrom(raw.queryParameters),
    setId: _setIdFrom(raw.queryParameters[_set]),
    marks: _marksFrom(raw.queryParameters[_marks]),
  );

  static const _correct = 'correct';
  static const _total = 'total';
  static const _left = 'left';
  static const _set = 'set';
  static const _marks = 'marks';

  /// One character per letter: `c` answered, `w` missed. Short enough for a
  /// URL, and readable when debugging one.
  static const _hit = 'c';
  static const _miss = 'w';

  Map<String, String> toQuery() => {
    _correct: '${score.correct}',
    _total: '${score.total}',
    _left: '${score.secondsRemaining}',
    if (setId case final id?) _set: id,
    if (marks case final letters? when letters.isNotEmpty)
      _marks: letters.map((hit) => hit ? _hit : _miss).join(),
  };

  static String? _setIdFrom(String? raw) {
    final id = raw?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  /// A full A–Z record or nothing: a short or garbled one could pin the
  /// wrong word on a letter, which is worse than naming none.
  static List<bool>? _marksFrom(String? raw) {
    if (raw == null || raw.length != WordSet.letterCount) return null;
    final marks = <bool>[];
    for (final char in raw.split('')) {
      if (char != _hit && char != _miss) return null;
      marks.add(char == _hit);
    }
    return marks;
  }

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
