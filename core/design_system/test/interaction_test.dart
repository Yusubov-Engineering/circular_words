import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The smallest tree the design system can render in: a theme, a direction,
/// and a media query whose motion setting the test controls.
Widget _host(Widget child, {AppTheme? theme, bool reduceMotion = false}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AppThemeScope(
          appTheme: theme ?? AppTheme.light(),
          appThemeMode: AppThemeMode.light,
          child: child,
        ),
      ),
    );

/// Captures whatever [read] returns from a context inside the tree.
Future<T> _read<T>(
  WidgetTester tester,
  T Function(BuildContext) read, {
  AppTheme? theme,
  bool reduceMotion = false,
  AppAccent? accent,
}) async {
  late T value;
  final probe = Builder(
    builder: (context) {
      value = read(context);
      return const SizedBox();
    },
  );
  await tester.pumpWidget(
    _host(
      accent == null ? probe : AppAccentScope(accent: accent, child: probe),
      theme: theme,
      reduceMotion: reduceMotion,
    ),
  );
  return value;
}

void main() {
  group('accent', () {
    testWidgets('is the brand accent with no scope', (tester) async {
      final tokens = await _read(tester, (context) => context.accentColors);

      expect(
        tokens.accentSolid,
        AppAccentColorTokens.light(AppAccent.brand).accentSolid,
      );
    });

    testWidgets('follows the nearest scope', (tester) async {
      final tokens = await _read(
        tester,
        (context) => context.accentColors,
        accent: AppAccent.teal,
      );

      expect(
        tokens.accentSolid,
        AppAccentColorTokens.light(AppAccent.teal).accentSolid,
      );
    });

    // The scope names a hue, not a colour, so the same scope has to come out
    // right in both themes — otherwise dark mode quietly gets light colours.
    testWidgets('resolves against the theme brightness', (tester) async {
      final tokens = await _read(
        tester,
        (context) => context.accentColors,
        theme: AppTheme.dark(),
        accent: AppAccent.orange,
      );

      expect(
        tokens.accentSolid,
        AppAccentColorTokens.dark(AppAccent.orange).accentSolid,
      );
    });

    test('every accent is its own colour, in both themes', () {
      for (final build in [
        AppAccentColorTokens.light,
        AppAccentColorTokens.dark,
      ]) {
        final solids = {for (final a in AppAccent.values) build(a).accentSolid};
        expect(solids, hasLength(AppAccent.values.length));
      }
    });
  });

  group('motion', () {
    testWidgets('is the theme motion by default', (tester) async {
      final motion = await _read(tester, (context) => context.motion);

      expect(motion.isReduced, isFalse);
      expect(motion.medium, greaterThan(Duration.zero));
    });

    // The single switch every animation in the app hangs off. If this breaks,
    // a player who asked the OS for less motion gets all of it.
    testWidgets('is reduced when the platform asks', (tester) async {
      final motion = await _read(
        tester,
        (context) => context.motion,
        reduceMotion: true,
      );

      expect(motion.isReduced, isTrue);
      expect(motion.slow, Duration.zero);
      expect(motion.pressedScale, 1);
      expect(motion.enterOffset, 0);
    });
  });

  group('AppPressable', () {
    testWidgets('taps, and shrinks while held', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: AppPressable(
              onTap: () => taps++,
              semanticsLabel: 'Go',
              child: const SizedBox.square(dimension: 48),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppPressable)),
      );
      await tester.pumpAndSettle();
      final held = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(held.scale, lessThan(1));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('does nothing when disabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: AppPressable(
              onTap: () => taps++,
              enabled: false,
              child: const SizedBox.square(dimension: 48),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppPressable));
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('reads as one labelled button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Center(
            child: AppPressable(
              onTap: () {},
              semanticsLabel: 'Microphone',
              toggled: true,
              child: const AppText(title: 'ignored'),
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(AppPressable)),
        matchesSemantics(
          label: 'Microphone',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('AppButton', () {
    testWidgets('does not fire without a handler or when disabled', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const AppButton(title: 'No handler'),
              AppButton(title: 'Off', enabled: false, onTap: () => taps++),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();
      expect(taps, 0);
    });
  });

  group('motion widgets', () {
    testWidgets('AppCountUp lands on its value', (tester) async {
      await tester.pumpWidget(_host(const AppCountUp(value: 21)));
      expect(find.text('21'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('21'), findsOneWidget);
    });

    testWidgets('AppCountUp is immediate under reduced motion', (tester) async {
      await tester.pumpWidget(
        _host(const AppCountUp(value: 21), reduceMotion: true),
      );
      await tester.pump();
      expect(find.text('21'), findsOneWidget);
    });

    testWidgets('AppEntrance ends fully shown, even late in a stagger', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AppEntrance(index: 5, child: AppText(title: 'hi'))),
      );
      await tester.pumpAndSettle();

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1);
    });

    testWidgets('AppPop settles back to rest after a change', (tester) async {
      Widget pop(int value) => _host(
        AppPop(trigger: value, child: const SizedBox.square(dimension: 10)),
      );

      await tester.pumpWidget(pop(1));
      await tester.pumpWidget(pop(2));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.widget<Transform>(find.byType(Transform));
      expect(mid.transform.getMaxScaleOnAxis(), greaterThan(1));

      await tester.pumpAndSettle();
      final rest = tester.widget<Transform>(find.byType(Transform));
      expect(rest.transform.getMaxScaleOnAxis(), closeTo(1, 1e-9));
    });
  });
}
