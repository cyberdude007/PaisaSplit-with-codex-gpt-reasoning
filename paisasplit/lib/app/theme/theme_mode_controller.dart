import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/prefs/shared_preferences_provider.dart';

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  final prefsFactory = ref.watch(sharedPreferencesFactoryProvider);
  final controller = ThemeModeController(prefsFactory);
  controller.initialize();
  return controller;
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefsFactory) : super(ThemeMode.system);

  static const _key = 'settings.theme';

  final Future<SharedPreferences> Function() _prefsFactory;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final prefs = await _prefsFactory();
    final stored = prefs.getString(_key);
    state = stored == 'dark' ? ThemeMode.dark : ThemeMode.system;
    _initialized = true;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await _prefsFactory();
    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'system');
  }
}
