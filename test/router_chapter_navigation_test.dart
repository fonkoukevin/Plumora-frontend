import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('a chapter opens without duplicating shell page keys', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/discover',
      routes: [
        ShellRoute(
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/discover',
              builder: (context, state) => TextButton(
                onPressed: () => context.push('/catalog/books/book-1'),
                child: const Text('Ouvrir le livre'),
              ),
            ),
            GoRoute(
              path: '/catalog/books/:bookId',
              builder: (context, state) => TextButton(
                onPressed: () => context.go(
                  '/books/${state.pathParameters['bookId']}/read'
                  '?chapterId=chapter-1',
                ),
                child: const Text('Ouvrir le chapitre'),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/books/:bookId/read',
          builder: (context, state) => const Scaffold(body: Text('Lecteur')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Ouvrir le livre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir le chapitre'));
    await tester.pumpAndSettle();

    expect(find.text('Lecteur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
