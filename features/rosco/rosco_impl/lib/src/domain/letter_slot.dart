import 'word_entry.dart';

/// Where one letter stands in a round.
///
/// `passed` is deliberately **not** terminal: a passed letter goes back into
/// the queue and the circle loops until the pool is empty or every letter is
/// answered. That is what makes a second lap reachable.
enum LetterStatus {
  /// Not reached yet on this lap.
  pending,

  /// The letter being answered right now.
  active,

  /// Answered acceptably. Terminal.
  correct,

  /// Still unanswered when the round ended. Terminal, and set only then:
  /// during play an unanswered letter is always `passed` or `active`.
  wrong,

  /// Deferred — by the player, or by its ten seconds running out. Comes
  /// round again.
  passed;

  /// Whether this letter is finished for the rest of the round.
  bool get isTerminal => this == correct || this == wrong;
}

/// One letter of the circle: its word, and how the player has done on it.
final class const LetterSlot({
  required final WordEntry entry,
  final LetterStatus status = LetterStatus.pending,
}) {
  String get letter => entry.letter;

  bool get isTerminal => status.isTerminal;

  LetterSlot copyWith({LetterStatus? status}) =>
      LetterSlot(entry: entry, status: status ?? this.status);

  @override
  String toString() => 'LetterSlot($letter, ${status.name})';
}
