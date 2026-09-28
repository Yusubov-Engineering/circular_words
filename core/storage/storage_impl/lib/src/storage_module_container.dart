import 'dart:async';

import 'package:dependency_injection_api/dependency_injection_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage_api/storage_api.dart';

import 'secure_storage_impl.dart';
import 'standart_storage_impl.dart';

final class StorageModule implements DependencyModule {
  @override
  String get name => 'Storage';

  @override
  FutureOr<void> registerDependencies(DependencyContainer container) {
    container.registerSingleton<StandardStorageApi>(
      StandardStorageImpl(prefs: SharedPreferencesAsync()),
    );

    container.registerSingleton<SecureStorageApi>(
      const SecureStorageImpl(secureStorage: FlutterSecureStorage()),
    );
  }
}
