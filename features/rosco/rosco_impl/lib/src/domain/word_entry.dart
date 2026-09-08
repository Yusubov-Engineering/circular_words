/// One letter's word, with the clue the player is shown.
final class const WordEntry({
  required final String letter,
  required final String word,
  required final String definition,
  final List<String> synonyms = const [],
}) {
  /// Answers that count as correct besides [word].
  ///
  /// Speech recognition is imprecise and English has near-synonyms, so a
  /// player who says "plentiful" for *abundant* has demonstrated the thing the
  /// game is testing. Fuzzy spelling tolerance is a separate concern, handled
  /// when an answer is checked.
  Iterable<String> get acceptedAnswers => [word, ...synonyms];

  @override
  String toString() => 'WordEntry($letter: $word)';
}
