import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_lock/presentation/app_lock_lifecycle_listener.dart';
import '../app_lock/presentation/app_lock_screen.dart';
import 'app_router.dart';
import 'theme/theme.dart';
import 'theme/theme_mode_controller.dart';

class PaisaSplitApp extends ConsumerWidget {
  const PaisaSplitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return AppLockLifecycleListener(
      child: MaterialApp.router(
        title: 'PaisaSplit',
        debugShowCheckedModeBanner: false,
        theme: buildPaisaTheme(),
        darkTheme: buildPaisaTheme(),
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              const AppLockOverlay(),
            ],
          );
        },
      ),
    );
  }
}
