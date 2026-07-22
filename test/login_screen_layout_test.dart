import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:plumora_app/core/routing/app_router.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plumora_app/features/auth/presentation/login_screen.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.landing,
          builder: (context, state) => const Scaffold(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const Scaffold(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
        ],
        child: MaterialApp.router(
          theme: PlumoraTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login uses the purple split layout on desktop', (tester) async {
    await pumpLogin(tester, const Size(1920, 920));

    expect(find.byKey(const ValueKey('login_desktop_layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_mobile_layout')), findsNothing);
    expect(find.text('Plumora'), findsOneWidget);
    expect(find.text('Connexion'), findsNWidgets(2));
    expect(find.text('Connexion avec Google'), findsOneWidget);

    final brand = tester.getRect(
      find.byKey(const ValueKey('login_brand_panel')),
    );
    final form = tester.getRect(find.byKey(const ValueKey('login_form_panel')));
    final card = tester.getRect(find.byKey(const ValueKey('login_split_card')));
    final background = tester.getRect(
      find.byKey(const ValueKey('login_page_background')),
    );
    expect(brand.right, closeTo(form.left, 0.1));
    expect(brand.left, lessThan(form.left));
    expect(card.center.dx, closeTo(960, 0.1));
    expect(background.left, 0);
    expect(background.right, closeTo(1920, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('login stacks the brand and form on mobile', (tester) async {
    await pumpLogin(tester, const Size(390, 844));

    expect(find.byKey(const ValueKey('login_mobile_layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_desktop_layout')), findsNothing);

    final brand = tester.getRect(
      find.byKey(const ValueKey('login_brand_panel')),
    );
    final form = tester.getRect(find.byKey(const ValueKey('login_form_panel')));
    expect(brand.bottom, closeTo(form.top, 0.1));
    expect(brand.top, lessThan(form.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('login remains scrollable on a short desktop window', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(1024, 600));

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(find.byKey(const ValueKey('login_desktop_layout')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login still validates the required credentials', (tester) async {
    await pumpLogin(tester, const Size(390, 844));

    final submit = find.widgetWithText(FilledButton, 'Connexion');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Adresse email requise'), findsOneWidget);
    expect(find.text('Mot de passe requis'), findsOneWidget);
  });
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}
