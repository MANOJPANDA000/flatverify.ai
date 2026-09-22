import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

abstract class BiometricDevice {
  Future<List<BiometricType>> available();
  Future<bool> authenticate(String reason);
}

class NativeBiometricDevice implements BiometricDevice {
  final LocalAuthentication _auth = LocalAuthentication();
  @override
  Future<List<BiometricType>> available() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return [];
    }
    if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) {
      return [];
    }
    return _auth.getAvailableBiometrics();
  }

  @override
  Future<bool> authenticate(String reason) => _auth.authenticate(
    localizedReason: reason,
    biometricOnly: true,
    persistAcrossBackgrounding: false,
  );
}

abstract class BiometricVault {
  Future<String?> read();
  Future<void> write(String uid);
  Future<void> clear();
}

class SecureBiometricVault implements BiometricVault {
  static const _key = 'flatverify_biometric_account_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String uid) => _storage.write(key: _key, value: uid);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class BiometricFailure implements Exception {
  const BiometricFailure(this.message);
  final String message;
}

/// Firebase owns the real authentication credentials and refresh lifecycle.
/// Secure storage contains only the opt-in account binding, never a password,
/// fingerprint, or a redundant copy of a Firebase bearer/refresh token.
class BiometricLoginService {
  BiometricLoginService({BiometricDevice? device, BiometricVault? vault})
    : device = device ?? NativeBiometricDevice(),
      vault = vault ?? SecureBiometricVault();
  final BiometricDevice device;
  final BiometricVault vault;
  bool _busy = false;
  Future<List<BiometricType>> available() async {
    try {
      return await device.available();
    } catch (_) {
      return [];
    }
  }

  Future<String?> buttonLabel(String? uid) async {
    if (uid == null) return null;
    try {
      if (await vault.read() != uid) return null;
      final types = await available();
      if (types.isEmpty) return null;
      return types.contains(BiometricType.fingerprint)
          ? 'Use Fingerprint'
          : 'Use Biometrics';
    } catch (_) {
      return null;
    }
  }

  Future<void> enable(String uid) async {
    await _authenticate(
      'Confirm your identity to enable biometric login for Flatverify.ai',
    );
    try {
      await vault.write(uid);
    } catch (_) {
      throw const BiometricFailure(
        'Secure storage is unavailable. Use password sign-in.',
      );
    }
  }

  Future<void> unlock(String uid) async {
    try {
      if (await vault.read() != uid) {
        throw const BiometricFailure(
          'Sign in with your password to enable biometrics again.',
        );
      }
    } on BiometricFailure {
      rethrow;
    } catch (_) {
      throw const BiometricFailure(
        'Secure storage is unavailable. Use password sign-in.',
      );
    }
    await _authenticate('Unlock your Flatverify.ai account');
  }

  Future<void> _authenticate(String reason) async {
    if (_busy) {
      throw const BiometricFailure('Authentication is already in progress.');
    }
    _busy = true;
    try {
      if ((await available()).isEmpty) {
        throw const BiometricFailure(
          'No enrolled biometrics are available. Use your password or enrol biometrics in device settings.',
        );
      }
      if (!await device.authenticate(reason)) {
        throw const BiometricFailure(
          'Biometric authentication was not completed. Try again or use your password.',
        );
      }
    } on LocalAuthException catch (e) {
      throw BiometricFailure(switch (e.code) {
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          'Biometrics are locked. Unlock your device and use password sign-in.',
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled =>
          'Biometric sign-in was cancelled. You can use your password.',
        _ => 'Biometrics are unavailable right now. Please use your password.',
      });
    } on BiometricFailure {
      rethrow;
    } catch (_) {
      throw const BiometricFailure(
        'Biometric authentication failed. Please use your password.',
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> disable() => vault.clear();
}
