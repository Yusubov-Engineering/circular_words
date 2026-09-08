/// One recognition update.
///
/// Partial results arrive while the player is still speaking; the final one
/// arrives when the platform decides the utterance ended. Both are worth
/// scoring — waiting only for finals can cost a second or more of a ten
/// second budget.
final class SpeechResult {
  const SpeechResult({
    required this.transcript,
    required this.isFinal,
    this.alternates = const [],
    this.confidence = 0,
  });

  /// The recogniser's best guess.
  final String transcript;

  /// Lower-ranked guesses, best first, excluding [transcript].
  ///
  /// The top-ranked guess is frequently *not* the right one, especially for
  /// non-native pronunciation, so validation reads [candidates] rather than
  /// [transcript] alone.
  final List<String> alternates;

  /// Whether the platform considers the utterance complete.
  final bool isFinal;

  /// Platform confidence in [transcript], 0..1. Zero when not reported.
  final double confidence;

  /// Every guess, best first — what an answer check should iterate.
  Iterable<String> get candidates => [transcript, ...alternates];
}
