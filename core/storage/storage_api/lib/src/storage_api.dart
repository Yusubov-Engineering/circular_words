/// The base contract for all key-value storage operations.
abstract interface class StorageApi {
  Future<void> writeString({required String key, required String value});
  Future<String?> readString({required String key});

  Future<void> writeBool({required String key, required bool value});
  Future<bool?> readBool({required String key});

  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> json,
  });
  Future<Map<String, dynamic>?> readJson({required String key});

  Future<void> delete({required String key});
  Future<void> clearAll();
}
