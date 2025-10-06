import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paisasplit/app_lock/application/app_lock_controller.dart';
import 'package:paisasplit/app_lock/domain/app_lock_authenticator.dart';
import 'package:paisasplit/app_lock/domain/pin_hasher.dart';
import 'package:paisasplit/app_lock/data/app_lock_repository.dart';

class _FakeAppLockAuthenticator implements AppLockAuthenticator {
  _FakeAppLockAuthenticator({
    required this.result,
    this.canCheck = true,
    this.isSupported = true,
  });

  AppLockAuthResult result;
  bool canCheck;
  bool isSupported;
  int authenticateCount = 0;

  @override
  Future<AppLockAuthResult> authenticate() async {
    authenticateCount += 1;
    return result;
  }

  @override
  Future<bool> canCheckBiometrics() async => canCheck;

  @override
  Future<bool> isDeviceSupported() async => isSupported;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_lock.enabled': true,
      'app_lock.pin.salt': 'c2FsdA==',
      'app_lock.pin.hash': 'aGFzaA==',
    });
  });

  AppLockController buildController({
    required _FakeAppLockAuthenticator authenticator,
    required DateTime Function() now,
  }) {
    final repository = AppLockRepository(
      prefsFactory: SharedPreferences.getInstance,
    );
    return AppLockController(
      repository: repository,
      authenticator: authenticator,
      hasher: PinHasher(),
      now: now,
    );
  }

  test('initialize locks immediately when enabled on cold start', () async {
    var currentNow = DateTime(2025, 1, 1, 10);
    final authenticator = _FakeAppLockAuthenticator(
      result: const AppLockAuthResult.success(),
      canCheck: true,
      isSupported: true,
    );
    final controller = buildController(
      authenticator: authenticator,
      now: () => currentNow,
    );

    await controller.initialize();

    expect(controller.state.isInitialized, isTrue);
    expect(controller.state.isEnabled, isTrue);
    expect(controller.state.isLocked, isTrue);
    expect(controller.state.shouldPromptBiometric, isTrue);
    expect(controller.state.showPinPad, isFalse);
  });

  test('resume within threshold keeps app unlocked', () async {
    var currentNow = DateTime(2025, 1, 1, 10, 0, 0);
    final authenticator = _FakeAppLockAuthenticator(
      result: const AppLockAuthResult.success(),
    );
    final controller = buildController(
      authenticator: authenticator,
      now: () => currentNow,
    );

    await controller.initialize();
    controller.unlock();

    controller.onAppBackgrounded();
    currentNow = currentNow.add(const Duration(seconds: 29));
    controller.onAppResumed();

    expect(controller.state.isLocked, isFalse);
    expect(controller.state.shouldPromptBiometric, isFalse);
  });

  test('resume after 30s in background relocks and prompts biometric', () async {
    var currentNow = DateTime(2025, 1, 1, 10, 0, 0);
    final authenticator = _FakeAppLockAuthenticator(
      result: const AppLockAuthResult.success(),
    );
    final controller = buildController(
      authenticator: authenticator,
      now: () => currentNow,
    );

    await controller.initialize();
    controller.unlock();

    controller.onAppBackgrounded();
    currentNow = currentNow.add(const Duration(seconds: 31));
    controller.onAppResumed();

    expect(controller.state.isLocked, isTrue);
    expect(controller.state.shouldPromptBiometric, isTrue);
    expect(controller.state.showPinPad, isFalse);
  });
}
