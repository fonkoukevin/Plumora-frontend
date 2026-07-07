import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/plumora_theme.dart';

void main() {
  runApp(const PlumoraApp());
}

class PlumoraApp extends StatelessWidget {
  const PlumoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _PlumoraMaterialApp());
  }
}

class _PlumoraMaterialApp extends ConsumerWidget {
  const _PlumoraMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Plumora',
      debugShowCheckedModeBanner: false,
      theme: PlumoraTheme.light,
      darkTheme: PlumoraTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
