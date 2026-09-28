import 'storage_api.dart';

/// Explicit type for Dependency Injection indicating standard unencrypted storage.
/// Use this for theme preferences, onboarding flags, and cache timestamps.
abstract interface class StandardStorageApi implements StorageApi;
