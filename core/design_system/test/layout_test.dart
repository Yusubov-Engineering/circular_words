import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Size size = const Size(400, 800)}) => MediaQuery(
  data: MediaQueryData(size: size),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: AppThemeScope(
      appTheme: AppTheme.light(),
      appThemeMode: AppThemeMode.light,
      child: child,
    ),
  ),
);

/// Pumps [child] into a box of exactly [size].
Future<void> _pumpSized(WidgetTester tester, Size size, Widget child) =>
    tester.pumpWidget(
      _host(
        Center(
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );

Widget _adaptive() => AppAdaptiveLayout(
  portrait: (_) => const AppText(title: 'portrait'),
  landscape: (_) => const AppText(title: 'landscape'),
);

void main() {
  group('AppAdaptiveLayout', () {
    testWidgets('is landscape when clearly wider than tall', (tester) async {
      await _pumpSized(tester, const Size(780, 360), _adaptive());
      expect(find.text('landscape'), findsOneWidget);
    });

    testWidgets('is portrait when taller than wide', (tester) async {
      await _pumpSized(tester, const Size(360, 780), _adaptive());
      expect(find.text('portrait'), findsOneWidget);
    });

    // A near-square area — a tablet split view — keeps the stacked layout,
    // which degrades better than a two-pane one squeezed into a square.
    testWidgets('keeps portrait for a near-square area', (tester) async {
      await _pumpSized(tester, const Size(500, 460), _adaptive());
      expect(find.text('portrait'), findsOneWidget);
    });

    testWidgets('follows its own constraints, not the screen', (tester) async {
      // A landscape-shaped pane on a portrait screen is still laid out as
      // landscape: the decision is about the room, not the device.
      await tester.pumpWidget(
        _host(
          Center(child: SizedBox(width: 390, height: 200, child: _adaptive())),
        ),
      );
      expect(find.text('landscape'), findsOneWidget);
    });
  });

  group('AppFillScroll', () {
    testWidgets('fills the height when the content is short', (tester) async {
      await _pumpSized(
        tester,
        const Size(300, 400),
        const AppFillScroll(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(title: 'top'),
              AppText(title: 'bottom'),
            ],
          ),
        ),
      );

      final top = tester.getTopLeft(find.text('top')).dy;
      final bottom = tester.getBottomLeft(find.text('bottom')).dy;
      expect(bottom - top, closeTo(400, 1));
    });

    // The case landscape creates: more content than height. Without the
    // scroll this is a RenderFlex overflow and the controls are unreachable.
    testWidgets('scrolls instead of overflowing when the content is tall', (
      tester,
    ) async {
      await _pumpSized(
        tester,
        const Size(300, 200),
        AppFillScroll(
          child: Column(
            children: [
              for (var i = 0; i < 10; i++)
                SizedBox(height: 60, child: AppText(title: 'row $i')),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(
        find.text('row 9'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      expect(find.text('row 9'), findsOneWidget);
    });
  });

  group('AppScaffold', () {
    // The scaffold pays for the bottom inset itself. If the body can still
    // see it, a SafeArea inside pads for it again — the dead band this fixes.
    testWidgets('hides the bottom inset it has already padded for', (
      tester,
    ) async {
      late EdgeInsets bodyPadding;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(top: 40, bottom: 34),
            viewPadding: EdgeInsets.only(top: 40, bottom: 34),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AppThemeScope(
              appTheme: AppTheme.light(),
              appThemeMode: AppThemeMode.light,
              child: AppScaffold(
                body: Builder(
                  builder: (context) {
                    bodyPadding = MediaQuery.paddingOf(context);
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(bodyPadding.bottom, 0);
      // Only the bottom: the top notch is still the body's to avoid.
      expect(bodyPadding.top, 40);
    });
  });
}
