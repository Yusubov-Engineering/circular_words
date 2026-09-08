import '../domain/word_entry.dart';

/// The wire shape of one word bank entry, decoded defensively.
///
/// Assets are authored by hand, so this assumes nothing about them: every
/// field is checked, and anything malformed returns `null` for the caller to
/// turn into a failure. Throwing here would give a `TypeError` at the top of
/// the stack instead of a sentence saying which entry is wrong.
final class WordEntryDto {
  const WordEntryDto._();

  /// Reads one entry, or `null` if it is not usable.
  static WordEntry? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    final letter = json['letter'];
    final word = json['word'];
    final definition = json['definition'];

    if (letter is! String || word is! String || definition is! String) {
      return null;
    }

    final normalisedLetter = letter.trim().toUpperCase();
    final normalisedWord = word.trim();
    final normalisedDefinition = definition.trim();

    if (normalisedLetter.length != 1) return null;
    if (normalisedWord.isEmpty || normalisedDefinition.isEmpty) return null;

    // The clue promises a word starting with this letter. An entry that
    // breaks that promise is unplayable, however well-formed it looks.
    if (normalisedWord[0].toUpperCase() != normalisedLetter) return null;

    final synonyms = json['synonyms'];

    return WordEntry(
      letter: normalisedLetter,
      word: normalisedWord,
      definition: normalisedDefinition,
      synonyms: switch (synonyms) {
        final List<dynamic> raw => [
          for (final value in raw)
            if (value is String && value.trim().isNotEmpty) value.trim(),
        ],
        // Absent is normal; a wrong type is ignored rather than fatal —
        // losing a synonym costs the player one accepted answer, while
        // rejecting the entry costs them the letter.
        _ => const [],
      },
    );
  }
}
