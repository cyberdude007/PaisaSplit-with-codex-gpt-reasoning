import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../domain/app_lock_authenticator.dart';

final localAuthenticationProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final appLockAuthenticatorProvider = Provider<AppLockAuthenticator>((ref) {
  final localAuth = ref.watch(localAuthenticationProvider);
  return LocalAuthAppLockAuthenticator(localAuth);
});

class LocalAuthAppLockAuthenticator implements AppLockAuthenticator {
  LocalAuthAppLockAuthenticator(this._localAuth);

  final LocalAuthentication _localAuth;

  @override
  Future<bool> canCheckBiometrics() {
    return _localAuth.canCheckBiometrics;
  }

  @override
  Future<bool> isDeviceSupported() {
    return _localAuth.isDeviceSupported();
  }

  @override
  Future<AppLockAuthResult> authenticate() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock PaisaSplit',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (didAuthenticate) {
        return const AppLockAuthResult.success();
      }
      return const AppLockAuthResult.failure(
        'Authentication failed. Try again.',
      );
    } on PlatformException catch (error) {
      final rawMessage = error.message?.trim();
      final message = (rawMessage == null || rawMessage.isEmpty)
          ? 'Authentication failed. Try again.'
          : rawMessage;
      return AppLockAuthResult.failure(message);
    }
  }
}
