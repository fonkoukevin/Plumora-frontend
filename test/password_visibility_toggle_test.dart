import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plumora_app/core/routing/app_router.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plumora_app/features/auth/presentation/login_screen.dart';
import 'package:plumora_app/features/auth/presentation/register_screen.dart';

class _TestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}

Future<void> _pumpAuthScreen(
  WidgetTester tester,
  String path,
  Widget screen,
) async {
  await tester.binding.setSurfaceSize(const Size(1366, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(path: path, builder: (context, state) => screen),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const Scaffold(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const Scaffold(),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const Scaffold(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(_TestAuthController.new)],
      child: MaterialApp.router(
        theme: PlumoraTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the login password field is obscured by default and can be revealed',
    (tester) async {
      await _pumpAuthScreen(tester, AppRoutes.login, const LoginScreen());

      final toggle = find.byTooltip('Afficher le mot de passe');
      expect(toggle, findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the register screen has independent toggles for password and confirmation',
    (tester) async {
      await _pumpAuthScreen(tester, AppRoutes.register, const RegisterScreen());

      // Two password fields (password + confirmation) => two toggles.
      expect(find.byTooltip('Afficher le mot de passe'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Afficher le mot de passe').first);
      await tester.pumpAndSettle();

      // Only the tapped field switched — the other one is still hidden.
      expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
      expect(find.byTooltip('Afficher le mot de passe'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
