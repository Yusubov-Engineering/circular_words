/// {@template game_feedback_api}
/// Short, wordless confirmation that something happened.
///
/// Stated as a capability rather than "a sound player", because the sound is
/// only half of it: a correct answer is a blip *and* a tap on the wrist, and
/// on a silenced phone in a pocket the tap is the whole message. Callers ask
/// for the meaning and let this decide how to deliver it.
///
/// Every method is fire-and-forget. Feedback that fails — no speaker, no
/// vibrator, a codec that will not load — must never interrupt the thing it
/// was commenting on.
/// {@endtemplate}
abstract interface class GameFeedbackApi {
  /// Prepares the players. Safe to call more than once.
  Future<void> initialize();

  /// The answer was accepted.
  Future<void> correct();

  /// The answer was not accepted, and the letter is still live.
  ///
  /// Deliberately the faintest cue of the four. With speech, a rejection is
  /// not a mistake so much as a mishearing, and it happens often — a game that
  /// buzzed and chimed at every one would be exhausting to play.
  Future<void> rejected();

  /// The letter ran out of time and was lost.
  Future<void> wrong();

  /// The round is over.
  Future<void> finished();

  /// Whether sound is currently suppressed.
  ///
  /// Haptics are deliberately *not* covered by this: they are already governed
  /// by the system's own haptic setting, and a player who mutes a game in a
  /// quiet room usually still wants to feel it.
  bool get isMuted;

  /// Suppresses or restores sound, and remembers the choice.
  Future<void> setMuted({required bool muted});

  /// Releases players. The owning module calls this at teardown.
  Future<void> dispose();
}
