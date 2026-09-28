import 'dart:async';

import 'package:biometric_auth_api/biometric_auth_api.dart';
import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:local_auth/local_auth.dart';

import 'biometric_auth_impl.dart';

final class BiometricAuthModule implements DependencyModule {
  @override
  String get name => 'Biometric Auth';

  @override
  FutureOr<void> registerDependencies(DependencyContainer container) {
    final localAuth = LocalAuthentication();
    container.registerLazySingleton<BiometricAuthApi>(
      (locator) =>
          BiometricAuthImpl(localAuth: localAuth, loggerApi: locator()),
    );
  }
}
