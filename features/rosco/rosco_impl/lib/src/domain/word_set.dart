import 'package:rosco_api/rosco_api.dart';

import 'word_entry.dart';

/// The 26 letters of one playable round.
///
/// A set is always a complete alphabet. The rules never relax the alphabet —
/// not even for X and Z — so a set with a missing letter is a *corrupt* set,
/// not a shorter round, and is rejected at load rather than played short.
final class const WordSet({
  required final String id,
  required final CefrLevel level,
  required final List<WordEntry> entries,
}) {
  /// The 26 letters, in order.
  static const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// How many letters a complete set has.
  static const letterCount = 26;

  /// The entry for [letter], or `null` if this set is incomplete — which a
  /// loaded set never is.
  WordEntry? entryFor(String letter) {
    final needle = letter.toUpperCase();
    for (final entry in entries) {
      if (entry.letter == needle) return entry;
    }
    return null;
  }

  @override
  String toString() => 'WordSet($id, ${entries.length} letters)';
}
