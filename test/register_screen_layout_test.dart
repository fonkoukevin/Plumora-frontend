import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:plumora_app/core/routing/app_router.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plumora_app/features/auth/presentation/register_screen.dart';

void main() {
  Future<void> pumpRegister(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: AppRoutes.register,
      routes: [
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
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

  testWidgets('registration is centered with a full-width background', (
    tester,
  ) async {
    await pumpRegister(tester, const Size(1440, 900));

    final card = tester.getRect(find.byKey(const ValueKey('register_card')));
    final background = tester.getRect(
      find.byKey(const ValueKey('register_page_background')),
    );

    expect(card.center.dx, closeTo(720, 0.1));
    expect(background.left, 0);
    expect(background.right, closeTo(1440, 0.1));
    expect(find.text('Plumora'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('register_name_email_row')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('register_password_row')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration fields stack cleanly on mobile', (tester) async {
    await pumpRegister(tester, const Size(390, 844));

    final card = tester.getRect(find.byKey(const ValueKey('register_card')));
    expect(card.center.dx, closeTo(195, 0.1));
    expect(find.byKey(const ValueKey('register_name_email_row')), findsNothing);
    expect(find.byKey(const ValueKey('register_password_row')), findsNothing);
    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration remains scrollable in a short window', (
    tester,
  ) async {
    await pumpRegister(tester, const Size(1024, 600));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byKey(const ValueKey('register_card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration keeps its existing validation', (tester) async {
    await pumpRegister(tester, const Size(390, 844));

    final submit = find.widgetWithText(FilledButton, 'Créer mon compte');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Nom complet requis'), findsOneWidget);
    expect(find.text('Email requis'), findsOneWidget);
    expect(find.text('8 caractères minimum'), findsOneWidget);
  });
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}
