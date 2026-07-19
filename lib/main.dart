import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/plumora_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/theme/theme_mode_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialThemeMode = await const ThemeModeStorage().readThemeMode();
  runApp(PlumoraApp(initialThemeMode: initialThemeMode));
}

class PlumoraApp extends StatelessWidget {
  const PlumoraApp({this.initialThemeMode = ThemeMode.light, super.key});

  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(initialThemeMode)],
      child: const _PlumoraMaterialApp(),
    );
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
      themeMode: ref.watch(themeModeControllerProvider),
      themeAnimationDuration: const Duration(milliseconds: 200),
      themeAnimationCurve: Curves.easeInOutCubic,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
