import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/core/widgets/not_found_screen.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/home',
      errorBuilder: (context, state) => const NotFoundScreen(),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Accueil')),
        ),
        GoRoute(
          path: '/author/manuscripts/:bookId',
          builder: (context, state) => Scaffold(
            body: Text('Manuscrit ${state.pathParameters['bookId']}'),
          ),
        ),
      ],
    );
  }

  testWidgets('a direct/refreshed link to a known deep route resolves directly '
      '(simulates opening /author/manuscripts/42 straight in the browser)', (
    tester,
  ) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    router.go('/author/manuscripts/42');

    await tester.pumpWidget(
      MaterialApp.router(theme: PlumoraTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manuscrit 42'), findsOneWidget);
  });

  testWidgets(
    'an unknown URL shows the internal 404 page instead of a bare error',
    (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);
      router.go('/this/route/does/not/exist');

      await tester.pumpWidget(
        MaterialApp.router(theme: PlumoraTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page introuvable'), findsOneWidget);
      expect(find.text("Retour à l'accueil"), findsOneWidget);
    },
  );

  testWidgets('tapping the 404 page action navigates back to the home route', (
    tester,
  ) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    router.go('/this/route/does/not/exist');

    await tester.pumpWidget(
      MaterialApp.router(theme: PlumoraTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Retour à l'accueil"));
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsOneWidget);
  });
}
