import 'package:flutter/animation.dart';

/// How things move.
///
/// Every duration and curve in the app comes from here, so the whole app
/// speeds up, slows down or stops moving from one place. Read it through
/// `context.motion`, which swaps in [AppMotionTokens.reduced] when the
/// platform asks for less motion — never construct durations inline.
final class const AppMotionTokens({
  /// Feedback that must feel attached to the finger: a press.
  required final Duration instant,

  /// Small state changes: a colour, an icon swap.
  required final Duration fast,

  /// Content changing in place: a new clue, a new letter.
  required final Duration medium,

  /// Things arriving: a screen's content, a count running up.
  required final Duration slow,

  /// The gap between consecutive items entering together.
  required final Duration stagger,

  /// Settling into place — decelerating, no overshoot.
  required final Curve standard,

  /// Arriving with a little life — a slight overshoot.
  required final Curve emphasized,

  /// Leaving — accelerating away.
  required final Curve exit,

  /// How far a pressed control shrinks, as a scale factor.
  required final double pressedScale,

  /// How far entering content travels, in logical pixels.
  required final double enterOffset,

  /// Whether motion is reduced. Anything that *loops* must check this: a
  /// zero duration makes a one-shot animation jump, but a repeating one
  /// has nothing sensible to do.
  required final bool isReduced,
}) {
  factory regular() {
    return const AppMotionTokens(
      instant: Duration(milliseconds: 100),
      fast: Duration(milliseconds: 180),
      medium: Duration(milliseconds: 280),
      slow: Duration(milliseconds: 450),
      stagger: Duration(milliseconds: 45),
      standard: Curves.easeOutCubic,
      emphasized: Curves.easeOutBack,
      exit: Curves.easeInCubic,
      pressedScale: 0.96,
      enterOffset: 16,
      isReduced: false,
    );
  }

  /// Everything arrives at once and nothing travels or scales. State still
  /// changes — only the movement between states is gone.
  factory reduced() {
    return const AppMotionTokens(
      instant: Duration.zero,
      fast: Duration.zero,
      medium: Duration.zero,
      slow: Duration.zero,
      stagger: Duration.zero,
      standard: Curves.linear,
      emphasized: Curves.linear,
      exit: Curves.linear,
      pressedScale: 1,
      enterOffset: 0,
      isReduced: true,
    );
  }
}
