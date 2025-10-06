abstract class AppLockAuthenticator {
  Future<bool> canCheckBiometrics();

  Future<bool> isDeviceSupported();

  Future<AppLockAuthResult> authenticate();
}

class AppLockAuthResult {
  const AppLockAuthResult.success()
    : status = AppLockAuthStatus.success,
      message = null;

  const AppLockAuthResult.failure([this.message])
    : status = AppLockAuthStatus.failure;

  const AppLockAuthResult.canceled()
    : status = AppLockAuthStatus.canceled,
      message = null;

  final AppLockAuthStatus status;
  final String? message;

  bool get isSuccess => status == AppLockAuthStatus.success;
}

enum AppLockAuthStatus { success, failure, canceled }
