import 'package:dependency_injection_api/dependency_injection_api.dart';

import '../locale/app_locale.dart';
import '../locale/app_locale_notifier.dart';
import '../locale/app_locale_notifier_impl.dart';
import '../locale/locale_storage_delegate.dart';

/// {@template app_localization_module}
/// Registers the [AppLocaleNotifier] that every other module reads the
/// selected language from.
///
/// The module stays agnostic about *where* the language is kept: the host
/// application supplies the [LocaleStorageDelegate], which is why this
/// package needs no storage dependency of its own.
/// {@endtemplate}
final class AppLocalizationModule({
  required final LocaleStorageDelegate Function(DependencyLocator locator)
  _storageDelegateBuilder,
  final AppLocale _fallbackLocale = AppLocale.en,
}) implements DependencyModule {
  @override
  String get name => 'AppLocalization';

  @override
  Future<void> registerDependencies(DependencyContainer container) async {
    final localeNotifier = AppLocaleNotifierImpl(
      storageDelegate: _storageDelegateBuilder(container),
      fallbackLocale: _fallbackLocale,
    );

    // Awaited here so the container never hands out a notifier that is still
    // reporting the fallback language.
    await localeNotifier.restore();

    container.registerSingleton<AppLocaleNotifier>(localeNotifier);
  }
}
