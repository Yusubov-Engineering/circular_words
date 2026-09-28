import 'dart:convert';
import 'dart:isolate';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage_api/storage_api.dart';

final class StandardStorageImpl({required final SharedPreferencesAsync _prefs})
    implements StandardStorageApi {
  @override
  Future<void> writeString({required String key, required String value}) =>
      _prefs.setString(key, value);

  @override
  Future<String?> readString({required String key}) => _prefs.getString(key);

  @override
  Future<void> writeBool({required String key, required bool value}) =>
      _prefs.setBool(key, value);

  @override
  Future<bool?> readBool({required String key}) => _prefs.getBool(key);

  @override
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> json,
  }) async {
    // Heavy encoding moved off the UI thread
    final jsonString = await Isolate.run(() => jsonEncode(json));
    await _prefs.setString(key, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> readJson({required String key}) async {
    final jsonString = await _prefs.getString(key);
    if (jsonString == null) return null;

    final result = await Isolate.run(
      () => jsonDecode(jsonString) as Map<String, dynamic>,
    );

    return result;
  }

  @override
  Future<void> delete({required String key}) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
