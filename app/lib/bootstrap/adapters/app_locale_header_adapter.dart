import 'package:app_localization/app_localization.dart';
import 'package:network_api/network_api.dart';

/// Sends the selected language with every request, so the backend answers in
/// the language the app is showing.
///
/// The language is read from the notifier on each request rather than kept in
/// a field, which is what keeps the header correct after a switch.
final class AppLocaleHeaderAdapter({
  required final AppLocaleNotifier _localeNotifier,
}) implements NetworkHeaderProvider {
  static const _kAcceptLanguageHeader = 'Accept-Language';

  @override
  Map<String, String> get headers => {
    _kAcceptLanguageHeader: _localeNotifier.locale.languageTag,
  };
}
