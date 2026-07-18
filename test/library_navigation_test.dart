import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/beta_reading/data/repositories/beta_reading_repository.dart';
import 'package:plumora_app/features/beta_reading/presentation/beta_engagement_providers.dart';
import 'package:plumora_app/features/reading/data/models/reading_progress_model.dart';
import 'package:plumora_app/features/reading/data/repositories/favorite_repository.dart';
import 'package:plumora_app/features/reading/data/repositories/reading_repository.dart';
import 'package:plumora_app/features/reading/presentation/library_screen.dart';

void main() {
  testWidgets('a library reading opens its book detail first', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          builder: (context, state) => const Scaffold(body: LibraryScreen()),
        ),
        GoRoute(
          path: '/catalog/books/:bookId',
          builder: (context, state) =>
              Scaffold(body: Text('detail-${state.pathParameters['bookId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReadingProgressProvider.overrideWith(
            (ref) async => const [
              ReadingProgressModel(
                bookId: 'book-1',
                chapterId: 'chapter-2',
                bookTitle: 'La Chambre 314',
                authorName: 'Idriss Ndao',
                progress: 0.4,
              ),
            ],
          ),
          myFavoritesProvider.overrideWith((ref) async => []),
          betaInvitationsProvider.overrideWith((ref) async => []),
          betaNewOpportunitiesCountProvider.overrideWithValue(0),
        ],
        child: MaterialApp.router(
          theme: PlumoraTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('La Chambre 314'));
    await tester.pumpAndSettle();

    expect(find.text('detail-book-1'), findsOneWidget);
    expect(find.byType(LibraryScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
