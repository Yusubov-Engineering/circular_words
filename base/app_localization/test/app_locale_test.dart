import 'package:app_localization/app_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every AppLocale has a generated translation, and vice versa', () {
    final declared = {for (final l in AppLocale.values) l.locale.languageCode};
    final generated = {
      for (final l in AppLocalizations.supportedLocales) l.languageCode,
    };

    // Adding an enum value without its ARB, or an ARB without its enum
    // value, fails here rather than at runtime in the missing language.
    expect(generated, declared);
  });

  testWidgets('every language resolves and fills its placeholder', (
    tester,
  ) async {
    for (final appLocale in AppLocale.values) {
      expect(
        AppLocalizations.delegate.isSupported(appLocale.locale),
        isTrue,
        reason: 'no delegate for ${appLocale.name}',
      );

      final strings = await AppLocalizations.delegate.load(appLocale.locale);

      expect(strings.appTitle, isNotEmpty, reason: appLocale.name);
      expect(
        strings.scoreSummary(7, 26),
        allOf(contains('7'), contains('26')),
        reason: '${appLocale.name} dropped a score placeholder',
      );
    }
  });

  testWidgets('Arabic flips the app right-to-left', (tester) async {
    late TextDirection direction;

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        locale: AppLocale.ar.locale,
        supportedLocales: [
          for (final appLocale in AppLocale.values) appLocale.locale,
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        builder: (context, child) {
          direction = Directionality.of(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(direction, TextDirection.rtl);
  });

  test('next cycles through every language and wraps', () {
    final seen = <AppLocale>[];
    var appLocale = AppLocale.values.first;

    for (var i = 0; i < AppLocale.values.length; i++) {
      seen.add(appLocale);
      appLocale = appLocale.next;
    }

    expect(seen, AppLocale.values);
    expect(appLocale, AppLocale.values.first, reason: 'did not wrap around');
  });
}
