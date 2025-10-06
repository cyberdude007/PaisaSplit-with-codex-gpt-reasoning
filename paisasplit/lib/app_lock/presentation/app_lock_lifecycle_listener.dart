import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/app_lock_controller.dart';

class AppLockLifecycleListener extends ConsumerStatefulWidget {
  const AppLockLifecycleListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockLifecycleListener> createState() =>
      _AppLockLifecycleListenerState();
}

class _AppLockLifecycleListenerState
    extends ConsumerState<AppLockLifecycleListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(appLockControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        controller.onAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        controller.onAppResumed();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
