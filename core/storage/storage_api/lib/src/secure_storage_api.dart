import 'storage_api.dart';

/// Explicit type for Dependency Injection indicating encrypted storage.
/// Use this for authentication tokens, PII, and financial data.
abstract interface class SecureStorageApi implements StorageApi;
