import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'theme/theme.dart';

class PaisaSplitApp extends ConsumerWidget {
  const PaisaSplitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PaisaSplit',
      debugShowCheckedModeBanner: false,
      theme: buildPaisaTheme(),
      routerConfig: router,
    );
  }
}
