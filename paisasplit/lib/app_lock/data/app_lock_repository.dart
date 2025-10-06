import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/prefs/shared_preferences_provider.dart';
import '../domain/pin_hasher.dart';

final appLockRepositoryProvider = Provider<AppLockRepository>((ref) {
  final prefsFactory = ref.watch(sharedPreferencesFactoryProvider);
  return AppLockRepository(prefsFactory: prefsFactory);
});

class AppLockRepository {
  AppLockRepository({
    required Future<SharedPreferences> Function() prefsFactory,
  }) : _prefsFactory = prefsFactory;

  static const _enabledKey = 'app_lock.enabled';
  static const _saltKey = 'app_lock.pin.salt';
  static const _hashKey = 'app_lock.pin.hash';

  final Future<SharedPreferences> Function() _prefsFactory;

  Future<AppLockConfig> load() async {
    final prefs = await _prefsFactory();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final salt = prefs.getString(_saltKey) ?? '';
    final hash = prefs.getString(_hashKey) ?? '';
    return AppLockConfig(
      enabled: enabled,
      secret: PinSecret(saltBase64: salt, hashBase64: hash),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await _prefsFactory();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> saveSecret(PinSecret secret) async {
    final prefs = await _prefsFactory();
    await prefs.setString(_saltKey, secret.saltBase64);
    await prefs.setString(_hashKey, secret.hashBase64);
  }

  Future<void> clearSecret() async {
    final prefs = await _prefsFactory();
    await prefs.remove(_saltKey);
    await prefs.remove(_hashKey);
  }
}

class AppLockConfig {
  const AppLockConfig({required this.enabled, required this.secret});

  final bool enabled;
  final PinSecret secret;

  bool get hasPin => !secret.isEmpty;
}
