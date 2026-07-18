import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plumora_app/core/routing/app_router.dart';

void main() {
  testWidgets('Retour restores the exact previous page', (tester) async {
    final router = GoRouter(
      initialLocation: '/source',
      routes: [
        GoRoute(
          path: '/source',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/detail'),
              child: const Text('Ouvrir le détail'),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => returnToPreviousOr(context, '/fallback'),
              child: const Text('Retour'),
            ),
          ),
        ),
        GoRoute(
          path: '/fallback',
          builder: (context, state) =>
              const Scaffold(body: Text('Page de secours')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Ouvrir le détail'));
    await tester.pumpAndSettle();
    expect(find.text('Retour'), findsOneWidget);

    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir le détail'), findsOneWidget);
    expect(find.text('Page de secours'), findsNothing);
  });

  testWidgets('Retour uses its fallback after a direct opening', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/detail',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => returnToPreviousOr(context, '/fallback'),
              child: const Text('Retour'),
            ),
          ),
        ),
        GoRoute(
          path: '/fallback',
          builder: (context, state) =>
              const Scaffold(body: Text('Page de secours')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();

    expect(find.text('Page de secours'), findsOneWidget);
  });
}
