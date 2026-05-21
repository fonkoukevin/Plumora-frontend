import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/plumora_theme.dart';

void main() {
  runApp(const ProviderScope(child: PlumoraApp()));
}

class PlumoraApp extends StatelessWidget {
  const PlumoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Plumora',
      debugShowCheckedModeBanner: false,
      theme: PlumoraTheme.light,
      darkTheme: PlumoraTheme.dark,
      routerConfig: appRouter,
    );
  }
}
