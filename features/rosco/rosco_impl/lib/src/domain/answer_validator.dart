import 'word_entry.dart';

/// Decides whether what the player said counts as the answer.
///
/// Pure Dart: no plugin, no `BuildContext`, no clock. Every rule here is
/// reachable from a unit test, which matters because this is where a learner
/// game is won or lost — exact string equality would feel broken, and an
/// English learner's pronunciation is exactly what speech recognition handles
/// worst.
///
/// Two kinds of answer, judged differently:
///
/// - **Authored** — the entry's own `word` and its `synonyms`. Accepted as
///   written, because the person who authored the clue is the authority on
///   what answers it. This is what lets `x-ray` accept the recogniser's
///   "ex ray", and what lets a set accept a near-synonym if its author chose
///   to allow one.
/// - **Inferred** — a fuzzy or homophone match the validator worked out for
///   itself. These must still begin with the letter being played, so that
///   tolerance for misheard syllables never turns into accepting a different
///   word entirely.
final class AnswerValidator {
  const AnswerValidator();

  /// Words that add nothing and that recognisers love to prepend.
  static const _articles = {'a', 'an', 'the'};

  /// Pairs a recogniser confuses that a player should not be punished for.
  ///
  /// Small and curated on purpose: every entry here weakens the game slightly,
  /// so it earns its place only when the two words are genuinely
  /// indistinguishable in speech.
  static const _homophones = <String, String>{
    'flour': 'flower',
    'flower': 'flour',
    'their': 'there',
    'there': 'their',
    'theyre': 'there',
    'to': 'too',
    'too': 'to',
    'wear': 'where',
    'where': 'wear',
    'principal': 'principle',
    'principle': 'principal',
  };

  /// Whether [spoken] answers [entry].
  ///
  /// [spoken] may be a whole utterance — recognisers return "the abundant" and
  /// "um abundant" — so each word of it is considered as well as the whole.
  bool accepts({required WordEntry entry, required String spoken}) {
    final candidates = _candidatesOf(spoken);
    if (candidates.isEmpty) return false;

    final authored = {
      for (final answer in entry.acceptedAnswers) _squash(_normalise(answer)),
    }..removeWhere((answer) => answer.isEmpty);

    // 1-3: the answer as authored, however the recogniser spaced or
    // hyphenated it.
    for (final candidate in candidates) {
      if (authored.contains(candidate)) return true;
    }

    final letter = entry.letter.toLowerCase();
    final target = _squash(_normalise(entry.word));

    for (final candidate in candidates) {
      // An inferred match must still be a word for *this* letter. Without
      // this, fuzzy tolerance quietly starts accepting the wrong word.
      if (!candidate.startsWith(letter)) continue;

      // 4: a misheard syllable or two, scaled to how much word there is to
      // get wrong.
      if (_withinEditDistance(candidate, target)) return true;

      // 5: a pair the recogniser cannot tell apart.
      if (_homophones[candidate] == target) return true;
    }

    return false;
  }

  /// The whole utterance plus each word in it, normalised.
  Iterable<String> _candidatesOf(String spoken) {
    final normalised = _normalise(spoken);
    if (normalised.isEmpty) return const [];

    final words = normalised.split(' ').where((word) => word.isNotEmpty);

    return {_squash(normalised), for (final word in words) word}
      ..removeWhere((candidate) => candidate.isEmpty);
  }

  /// Lowercase, unaccented, punctuation-free, article-free, single-spaced.
  String _normalise(String raw) {
    final buffer = StringBuffer();

    for (final rune in raw.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final folded = _diacritics[char] ?? char;

      if (RegExp(r'[a-z0-9]').hasMatch(folded)) {
        buffer.write(folded);
      } else {
        // Hyphens, apostrophes and stray punctuation all become breaks, so
        // "x-ray", "x ray" and "xray" converge once squashed.
        buffer.write(' ');
      }
    }

    final words = buffer
        .toString()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    // Strip leading articles only: a trailing "a" is more likely a syllable
    // the recogniser split off than a word the player meant.
    while (words.length > 1 && _articles.contains(words.first)) {
      words.removeAt(0);
    }

    return words.join(' ');
  }

  /// Spaces removed, so spacing never decides a match.
  String _squash(String normalised) => normalised.replaceAll(' ', '');

  /// How wrong an inferred answer may be, by how long the target is.
  ///
  /// A short word has no room for error — one edit turns "zoo" into "too" —
  /// while a long one is mostly still itself after a slip or two.
  bool _withinEditDistance(String candidate, String target) {
    final tolerance = switch (target.length) {
      >= 8 => 2,
      >= 5 => 1,
      _ => 0,
    };

    if (tolerance == 0) return candidate == target;
    if ((candidate.length - target.length).abs() > tolerance) return false;

    return _editDistance(candidate, target, tolerance) <= tolerance;
  }

  /// Levenshtein distance, abandoned once it cannot come in under [limit].
  int _editDistance(String a, String b, int limit) {
    if (a == b) return 0;

    var previous = List<int>.generate(b.length + 1, (index) => index);

    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i;
      var best = current[0];

      for (var j = 1; j <= b.length; j++) {
        final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;

        current[j] = substitution < deletion
            ? (substitution < insertion ? substitution : insertion)
            : (deletion < insertion ? deletion : insertion);

        if (current[j] < best) best = current[j];
      }

      // Every remaining row can only add to the best score on this one.
      if (best > limit) return limit + 1;
      previous = current;
    }

    return previous[b.length];
  }

  /// Accented forms a recogniser may return for a loan word.
  static const _diacritics = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
}
