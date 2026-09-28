import 'package:analytics_impl/analytics_impl.dart';
import 'package:app/bootstrap/adapters/app_locale_header_adapter.dart';
import 'package:app/bootstrap/adapters/app_locale_storage_adapter.dart';
import 'package:app/bootstrap/composition_root.dart';
import 'package:app/bootstrap/flavor/app_config.dart';
import 'package:app/firebase_options_dev.dart' as firebase_dev;
import 'package:app/firebase_options_prod.dart' as firebase_prod;
import 'package:app_localization/app_localization.dart';
import 'package:app_network_contract/app_network_contract.dart';
import 'package:biometric_auth_impl/biometric_auth_impl.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:feedback_impl/feedback_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:levels_impl/levels_impl.dart';
import 'package:logger_api/logger_api.dart';
import 'package:logger_impl/logger_impl.dart';
import 'package:network_impl/network_impl.dart';
import 'package:rosco_impl/rosco_impl.dart';
import 'package:speech_impl/speech_impl.dart';
import 'package:storage_impl/storage_impl.dart';

/// {@template dependency_injection_configuration}
/// The one list that says which modules exist at startup.
///
/// Order matters: a module may resolve what an earlier module registered.
/// `StorageModule` therefore precedes anything that reads from storage.
/// {@endtemplate}
final class DependencyInjectionConfiguration._() {
  static Future<DependencyContainer> initialize() {
    return CompositionRoot.initialize(
      enableLogging: !kReleaseMode,
      modules: [
        // ── Core ──────────────────────────────────────────────────────────
        LoggerModule(),
        AnalyticsModule(
          backend: FirebaseAnalyticsBackend(
            options: AppConfig.isProd
                ? firebase_prod.DefaultFirebaseOptions.currentPlatform
                : firebase_dev.DefaultFirebaseOptions.currentPlatform,
          ),
        ),
        StorageModule(),
        AppLocalizationModule(
          storageDelegateBuilder: (locator) =>
              AppLocaleStorageAdapter(standardStorage: locator()),
        ),
        // The network module knows nothing about the backend's envelope:
        // `AppResponse` and its parser live in base/app_network_contract, and
        // that is the seam you replace for your own API.
        NetworkModule<AppResponse>(
          baseUrl: AppConfig.baseUrl,
          responseParser: AppResponseParser(),
          headerProviderBuilder: (locator) =>
              AppLocaleHeaderAdapter(localeNotifier: locator()),
          enableLogging: AppConfig.enableLogs || kDebugMode,
        ),
        BiometricAuthModule(),
        // Registered lazily and never initialised here: touching the
        // recogniser prompts for the microphone, and app start is the wrong
        // moment to ask. The game screen initialises it on entry.
        SpeechModule(),
        FeedbackModule(),

        // ── Features ──────────────────────────────────────────────────────
        // Add each new feature's module here. A feature missing from this
        // list compiles fine and fails at runtime.
        LevelsModule(),
        RoscoModule(),
        // <generated:feature-modules>
      ],
      onLog: (message, locator) {
        try {
          locator.get<LoggerApi>().info(message);
        } catch (_) {}
      },
    );
  }
}
