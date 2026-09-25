import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: AppThemeScope(
      appTheme: AppTheme.light(),
      appThemeMode: AppThemeMode.light,
      child: child,
    ),
  ),
);

void main() {
  group('AppLaunchIntro', () {
    testWidgets('covers the app, then gets out of the way entirely', (
      tester,
    ) async {
      var firstFrames = 0;
      await tester.pumpWidget(
        _host(
          AppLaunchIntro(
            onFirstFrame: () => firstFrames++,
            child: const AppText(title: 'app'),
          ),
        ),
      );

      // Its first frame is the splash: the logo, over an app that is already
      // building underneath.
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('app'), findsOneWidget);

      await tester.pumpAndSettle();

      // Gone — not merely transparent, so it costs nothing for the rest of
      // the session and blocks no taps.
      expect(find.byType(AppLogo), findsNothing);
      expect(find.text('app'), findsOneWidget);
      expect(firstFrames, 1);
    });

    testWidgets('is a short fade under reduced motion', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppLaunchIntro(child: AppText(title: 'app')),
          reduceMotion: true,
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AppLogo), findsNothing);
    });

    testWidgets('holds taps back until it starts to leave', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          AppLaunchIntro(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(10, 10));
      expect(taps, 0);

      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      expect(taps, 1);
    });
  });

  group('AppLogoPainter', () {
    // The icon and splash are rendered from this painter; a change that made
    // it repaint on every frame, or never, would show up there first.
    test('repaints only when what it draws changes', () {
      final logo = AppLogoPainter(highlight: 0.2);

      expect(logo.shouldRepaint(AppLogoPainter(highlight: 0.2)), isFalse);
      expect(logo.shouldRepaint(AppLogoPainter(highlight: 0.3)), isTrue);
      expect(
        logo.shouldRepaint(AppLogoPainter(highlight: 0.2, withGround: true)),
        isTrue,
      );
    });
  });
}
