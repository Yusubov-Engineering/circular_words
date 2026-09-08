/// The best result a player has recorded for one level.
///
/// "Best" is decided by [correct] first and [secondsRemaining] second: a
/// faster round only wins when it answered at least as much. Scoring the clock
/// ahead of the answers would reward passing on everything.
final class const LevelScore({
  required final int correct,
  required final int total,
  required final int secondsRemaining,
}) {
  /// Whether this result should replace [other] as the recorded best.
  bool beats(LevelScore? other) {
    if (other == null) return true;
    if (correct != other.correct) return correct > other.correct;
    return secondsRemaining > other.secondsRemaining;
  }

  Map<String, dynamic> toJson() => {
    'correct': correct,
    'total': total,
    'secondsRemaining': secondsRemaining,
  };

  /// Reads a stored score, returning `null` for anything malformed.
  ///
  /// Decoded defensively: this data has been on a device across app versions,
  /// and a stored score that no longer parses should read as "not played yet"
  /// rather than take the level picker down.
  static LevelScore? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final correct = json['correct'];
    final total = json['total'];
    final secondsRemaining = json['secondsRemaining'];

    if (correct is! int || total is! int || secondsRemaining is! int) {
      return null;
    }
    if (correct < 0 || total <= 0 || correct > total) return null;

    return LevelScore(
      correct: correct,
      total: total,
      secondsRemaining: secondsRemaining < 0 ? 0 : secondsRemaining,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LevelScore &&
      correct == other.correct &&
      total == other.total &&
      secondsRemaining == other.secondsRemaining;

  @override
  int get hashCode => Object.hash(correct, total, secondsRemaining);

  @override
  String toString() => 'LevelScore($correct/$total, ${secondsRemaining}s left)';
}
