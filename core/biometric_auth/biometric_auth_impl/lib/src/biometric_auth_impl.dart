import 'dart:async';

import 'package:biometric_auth_api/biometric_auth_api.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger_api/logger_api.dart';

final class BiometricAuthImpl implements BiometricAuthApi {
  BiometricAuthImpl({required this._localAuth, required LoggerApi loggerApi})
    : _logger = loggerApi.withTag('BiometricAuthImpl');

  final LocalAuthentication _localAuth;
  final LoggerApi _logger;

  @override
  Future<bool> canAuthenticate() async {
    _logger.info('checking if biometric auth is available');
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();

    _logger.info('is biometric available: $isAvailable');

    return isAvailable || isDeviceSupported;
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      _logger.info('authenticate with biometric');
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
      );
    } catch (e, stackTrace) {
      _logger.error('error while biometric auth', e, stackTrace);
      return false;
    }
  }

  @override
  Future<BiometricAuthType?> get biometricAuthType async {
    try {
      _logger.info('getting available biometric types');
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      final isFingerprint = availableBiometrics.contains(
        BiometricType.fingerprint,
      );

      if (isFingerprint) return BiometricAuthType.touchId;

      final isFace = availableBiometrics.contains(BiometricType.face);
      if (isFace) return BiometricAuthType.faceId;
    } catch (err, stackTrace) {
      _logger.error('error while getting biometricAuthType', err, stackTrace);
    }

    return null;
  }
}
