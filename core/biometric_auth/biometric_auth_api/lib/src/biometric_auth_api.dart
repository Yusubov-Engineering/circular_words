import 'biometric_auth_type.dart';

abstract interface class BiometricAuthApi {
  /// Checks hardware capability.
  Future<bool> canAuthenticate();

  /// Prompts the UI. On success, this should internally update the stream if it was a setup action.
  Future<bool> authenticate({required String localizedReason});

  /// gives the type of the biometric auth according to device settings
  Future<BiometricAuthType?> get biometricAuthType;
}
