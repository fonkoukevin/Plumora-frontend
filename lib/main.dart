import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/routing/app_router.dart';
import 'core/theme/plumora_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/theme/theme_mode_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path-based URLs on Flutter Web (no leading "#/"), so that a direct link
  // or a refresh on e.g. /author/manuscripts/42 resolves correctly. A no-op
  // on non-web platforms. Requires the host to fall back unknown paths to
  // index.html (see docs/deployment-frontend.md).
  usePathUrlStrategy();
  final initialThemeMode = await const ThemeModeStorage().readThemeMode();
  runApp(PlumoraApp(initialThemeMode: initialThemeMode));
}

class PlumoraApp extends StatelessWidget {
  const PlumoraApp({
    this.initialThemeMode = ThemeMode.light,
    this.overrides = const [],
    super.key,
  });

  final ThemeMode initialThemeMode;

  /// Extra Riverpod overrides, on top of [initialThemeMode]'s. Lets widget
  /// tests that pump the whole app (rather than a single screen under their
  /// own `ProviderScope`) stub network-backed providers — e.g.
  /// `platformStatsProvider` — instead of issuing a real HTTP call.
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        ...overrides,
      ],
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
