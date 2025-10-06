import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme_mode_controller.dart';
import '../../../app_lock/application/app_lock_controller.dart';
import '../../../app_lock/presentation/pin_setup_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeControllerProvider);
    final appLockState = ref.watch(appLockControllerProvider);
    final appLockController = ref.read(appLockControllerProvider.notifier);
    final themeController = ref.read(themeModeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          DefaultTextStyle.merge(
            style: theme.textTheme.titleMedium,
            child: const Text('General'),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  enabled: false,
                  title: Text('Currency'),
                  subtitle: Text('₹ (INR)'),
                  trailing: Text('Fixed'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Theme'),
                  subtitle: Text(
                    'Choose how PaisaSplit follows your device',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {
                      themeMode == ThemeMode.dark
                          ? ThemeMode.dark
                          : ThemeMode.system,
                    },
                    onSelectionChanged: (selection) {
                      final mode = selection.first;
                      themeController.setThemeMode(mode);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DefaultTextStyle.merge(
            style: theme.textTheme.titleMedium,
            child: const Text('Security'),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: appLockState.isEnabled,
                  title: const Text('App Lock'),
                  subtitle: const Text(
                    'Require biometric or PIN after 30 seconds away and on launch',
                  ),
                  onChanged: (enabled) async {
                    if (enabled) {
                      final pin = await showAppLockPinSetupSheet(context);
                      if (pin == null) {
                        return;
                      }
                      if (!context.mounted) {
                        return;
                      }
                      await appLockController.enableWithPin(pin);
                    } else {
                      await appLockController.disable();
                    }
                  },
                ),
                if (appLockState.isEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'App Lock protects PaisaSplit after 30 seconds away.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DefaultTextStyle.merge(
            style: theme.textTheme.titleMedium,
            child: const Text('About'),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('About PaisaSplit'),
                  subtitle: Text('Details coming soon'),
                  enabled: false,
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Privacy Policy'),
                  subtitle: Text('Coming soon'),
                  enabled: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
