import 'package:flutter/widgets.dart';

import '../components/app_logo.dart';
import '../ext/app_theme_ext.dart';

/// The logo's size in the intro, and in the native splash before it: the
/// splash image is 768 px treated as 4x, which shows at this size.
const appLaunchLogoSize = 192.0;

/// {@template app_launch_intro}
/// Plays once over [child] at launch: the brand, then the app.
///
/// Its first frame is identical to the native splash — the same ground, the
/// same mark, the same size — so the hand-over from platform to Flutter is
/// invisible. The white "active letter" then travels once round the ring,
/// the way a round moves round the wheel, and the intro lifts away to reveal
/// [child], which has been building underneath the whole time.
///
/// Under reduced motion there is no journey and no zoom, only a short fade.
/// Taps are held back until the intro starts to leave, so a tap meant for
/// the splash does not land on a level the player has not seen.
/// {@endtemplate}
class const AppLaunchIntro({
  required final Widget child,

  /// Called once, after the intro's first frame is on screen — the moment to
  /// take the native splash down.
  final VoidCallback? onFirstFrame,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppLaunchIntro> createState() => _AppLaunchIntroState();
}

class _AppLaunchIntroState extends State<AppLaunchIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener(_onStatus);

  /// Where the travelling highlight is, over the first part of the intro.
  late final Animation<double> _journey = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.62, curve: Curves.easeInOutCubic),
  );

  /// The lift-away, over the rest.
  late final Animation<double> _exit = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.62, 1, curve: Curves.easeInCubic),
  );

  bool _done = false;
  bool _started = false;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFirstFrame?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    _reduced = context.motion.isReduced;
    _controller
      ..duration = _reduced
          ? const Duration(milliseconds: 250)
          : const Duration(milliseconds: 1300)
      ..forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _done = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final leaving = _reduced ? _controller.value : _exit.value;

            return IgnorePointer(
              // Held until the intro starts to go; then the app is live.
              ignoring: leaving > 0,
              child: Opacity(
                opacity: 1 - leaving,
                child: ColoredBox(
                  color: appLogoGround,
                  child: Center(
                    child: Transform.scale(
                      scale: _reduced ? 1 : 1 + 0.25 * leaving,
                      child: AppLogo(
                        size: appLaunchLogoSize,
                        highlight: _reduced ? 0 : _journey.value,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
