import 'package:flutter/services.dart';

/// How emphatic a tap on the wrist should be.
enum HapticCue {
  /// Barely there. For things that happen often.
  faint,

  /// A definite tap. For a letter won.
  firm,

  /// The heaviest. For the end of a round.
  heavy,
}

/// {@template feedback_haptics}
/// The wordless half of the feedback.
///
/// An interface for the same reason the sounds are: the decision of *which*
/// cue to fire is worth testing, and a unit test has no vibrator. It is also
/// the half that survives a silenced phone, which is most phones.
/// {@endtemplate}
abstract interface class FeedbackHaptics {
  Future<void> play(HapticCue cue);
}

/// {@macro feedback_haptics}
final class PlatformHaptics implements FeedbackHaptics {
  const PlatformHaptics();

  @override
  Future<void> play(HapticCue cue) => switch (cue) {
    // `selectionClick` is the lightest thing the platform offers, and the one
    // it uses for scrolling through a picker — right for something that
    // happens several times a letter.
    HapticCue.faint => HapticFeedback.selectionClick(),
    HapticCue.firm => HapticFeedback.mediumImpact(),
    HapticCue.heavy => HapticFeedback.heavyImpact(),
  };
}
