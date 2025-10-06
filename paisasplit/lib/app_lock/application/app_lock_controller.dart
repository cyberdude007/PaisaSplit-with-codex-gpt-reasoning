import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_lock_repository.dart';
import '../domain/app_lock_authenticator.dart';
import '../domain/pin_hasher.dart';
import 'app_lock_state.dart';
import 'clock.dart';
import '../infrastructure/local_auth_app_lock_authenticator.dart';

final pinHasherProvider = Provider<PinHasher>((ref) {
  return PinHasher();
});

final appLockControllerProvider =
    StateNotifierProvider<AppLockController, AppLockState>((ref) {
  final repository = ref.watch(appLockRepositoryProvider);
  final authenticator = ref.watch(appLockAuthenticatorProvider);
  final hasher = ref.watch(pinHasherProvider);
  final now = ref.watch(nowProvider);
  final controller = AppLockController(
    repository: repository,
    authenticator: authenticator,
    hasher: hasher,
    now: now,
  );
  unawaited(controller.initialize());
  return controller;
});

class AppLockController extends StateNotifier<AppLockState> {
  AppLockController({
    required AppLockRepository repository,
    required AppLockAuthenticator authenticator,
    required PinHasher hasher,
    required Now now,
  })  : _repository = repository,
        _authenticator = authenticator,
        _hasher = hasher,
        _now = now,
        super(const AppLockState.initial());

  static const Duration backgroundLockThreshold = Duration(seconds: 30);

  final AppLockRepository _repository;
  final AppLockAuthenticator _authenticator;
  final PinHasher _hasher;
  final Now _now;

  PinSecret _secret = const PinSecret(saltBase64: '', hashBase64: '');
  DateTime? _lastBackgrounded;
  bool _isInitializing = false;

  Future<void> initialize() async {
    if (_isInitializing) {
      return;
    }
    _isInitializing = true;
    final config = await _repository.load();
    _secret = config.secret;
    final canBiometric = await _checkBiometricSupport();
    state = state.copyWith(
      isInitialized: true,
      isEnabled: config.enabled,
      hasPin: config.hasPin,
      isLocked: config.enabled,
      canCheckBiometrics: canBiometric,
      showPinPad: config.enabled ? !canBiometric : false,
      shouldPromptBiometric: config.enabled && canBiometric,
      errorMessage: null,
    );
    _isInitializing = false;
  }

  Future<bool> _checkBiometricSupport() async {
    try {
      final canCheck = await _authenticator.canCheckBiometrics();
      final supported = await _authenticator.isDeviceSupported();
      return canCheck || supported;
    } catch (_) {
      return false;
    }
  }

  void lock() {
    if (!state.isEnabled) {
      return;
    }
    state = state.copyWith(
      isLocked: true,
      showPinPad: !state.canCheckBiometrics,
      shouldPromptBiometric: state.canCheckBiometrics,
      isAuthenticating: false,
      isVerifyingPin: false,
      errorMessage: null,
    );
  }

  void unlock() {
    if (!state.isLocked) {
      return;
    }
    state = state.copyWith(
      isLocked: false,
      showPinPad: false,
      isAuthenticating: false,
      isVerifyingPin: false,
      shouldPromptBiometric: false,
      errorMessage: null,
    );
    _lastBackgrounded = null;
  }

  void showPinPad() {
    state = state.copyWith(
      showPinPad: true,
      isAuthenticating: false,
      shouldPromptBiometric: false,
      errorMessage: null,
    );
  }

  void showBiometricPrompt() {
    if (!state.canCheckBiometrics) {
      return;
    }
    state = state.copyWith(
      showPinPad: false,
      shouldPromptBiometric: true,
      errorMessage: null,
    );
  }

  Future<void> authenticateWithBiometrics() async {
    if (!state.isEnabled || !state.canCheckBiometrics) {
      return;
    }
    state = state.copyWith(
      isAuthenticating: true,
      shouldPromptBiometric: false,
      errorMessage: null,
    );
    final result = await _authenticator.authenticate();
    switch (result.status) {
      case AppLockAuthStatus.success:
        unlock();
        break;
      case AppLockAuthStatus.failure:
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: result.message ?? 'Authentication failed. Try again.',
        );
        break;
      case AppLockAuthStatus.canceled:
        state = state.copyWith(isAuthenticating: false);
        break;
    }
  }

  Future<void> enableWithPin(String pin) async {
    final secret = _hasher.generate(pin);
    await _repository.saveSecret(secret);
    await _repository.setEnabled(true);
    _secret = secret;
    final canBiometric = await _checkBiometricSupport();
    state = state.copyWith(
      isEnabled: true,
      hasPin: true,
      canCheckBiometrics: canBiometric,
      errorMessage: null,
    );
    lock();
  }

  Future<void> disable() async {
    await _repository.setEnabled(false);
    await _repository.clearSecret();
    _secret = const PinSecret(saltBase64: '', hashBase64: '');
    state = state.copyWith(
      isEnabled: false,
      isLocked: false,
      hasPin: false,
      showPinPad: false,
      shouldPromptBiometric: false,
      isAuthenticating: false,
      isVerifyingPin: false,
      errorMessage: null,
    );
  }

  Future<bool> verifyPin(String pin) async {
    state = state.copyWith(isVerifyingPin: true, errorMessage: null);
    final isValid = !_secret.isEmpty && _hasher.verify(pin, _secret);
    if (isValid) {
      unlock();
      return true;
    }
    state = state.copyWith(
      isVerifyingPin: false,
      errorMessage: 'Incorrect PIN. Try again.',
    );
    return false;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void onAppBackgrounded() {
    if (!state.isEnabled) {
      return;
    }
    _lastBackgrounded = _now();
  }

  void onAppResumed() {
    if (!state.isEnabled) {
      return;
    }
    final backgroundedAt = _lastBackgrounded;
    _lastBackgrounded = null;
    if (backgroundedAt == null) {
      lock();
      return;
    }
    final elapsed = _now().difference(backgroundedAt);
    if (elapsed >= backgroundLockThreshold) {
      lock();
    }
  }
}
