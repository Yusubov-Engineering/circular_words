import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:storage_api/storage_api.dart';

final class const SecureStorageImpl({
  required final FlutterSecureStorage _secureStorage,
}) implements SecureStorageApi {
  @override
  Future<void> writeString({required String key, required String value}) =>
      _secureStorage.write(key: key, value: value);

  @override
  Future<String?> readString({required String key}) =>
      _secureStorage.read(key: key);

  @override
  Future<void> writeBool({required String key, required bool value}) =>
      _secureStorage.write(key: key, value: value.toString());

  @override
  Future<bool?> readBool({required String key}) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  @override
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> json,
  }) async {
    final jsonString = await Isolate.run(() => jsonEncode(json));
    await _secureStorage.write(key: key, value: jsonString);
  }

  @override
  Future<Map<String, dynamic>?> readJson({required String key}) async {
    final jsonString = await _secureStorage.read(key: key);
    if (jsonString == null) return null;

    final result = await Isolate.run(
      () => jsonDecode(jsonString) as Map<String, dynamic>,
    );

    return result;
  }

  @override
  Future<void> delete({required String key}) async {
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
