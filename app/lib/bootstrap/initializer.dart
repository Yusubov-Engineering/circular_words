import 'package:app/app.dart';
import 'package:app_localization/app_localization.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:router_api/router_api.dart';

import 'adapters/app_theme_storage_adapter.dart';
import 'dependency_injection_configuration.dart';
import 'router_configuration.dart';

void initializer() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash up until the launch intro has drawn its first
  // frame. Without this the splash comes down on Flutter's *first* frame,
  // which is blank while the saved theme loads — a white flash between two
  // screens that are both dark.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  final globalContainer = await DependencyInjectionConfiguration.initialize();
  final routerConfig = RouterConfiguration.initialize(globalContainer);

  runApp(
    DependencyScope(
      locator: globalContainer,
      child: RouterScope(
        navigationService: globalContainer(),
        child: AppThemeScopeWrapper(
          storageDelegate: AppThemeStorageAdapter(
            standardStorage: globalContainer(),
          ),
          child: AppLocaleScopeWrapper(
            localeNotifier: globalContainer(),
            child: Builder(
              builder: (context) => RootApp(
                routerConfig: routerConfig.config,
                locale: context.appLocale.locale,
                supportedLocales: [
                  for (final appLocale in AppLocale.values) appLocale.locale,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
