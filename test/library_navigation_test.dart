import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/beta_reading/data/repositories/beta_reading_repository.dart';
import 'package:plumora_app/features/beta_reading/presentation/beta_engagement_providers.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/reading/data/models/favorite_model.dart';
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

  testWidgets('library favorites use the same cover hover as Discover', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReadingProgressProvider.overrideWith((ref) async => const []),
          myFavoritesProvider.overrideWith(
            (ref) async => const [
              FavoriteModel(
                id: 'favorite-2',
                book: CatalogBookModel(
                  id: 'book-2',
                  title: 'Les Brumes de Cendre',
                  description: '',
                  authorName: 'Alice Morel',
                ),
              ),
            ],
          ),
          betaInvitationsProvider.overrideWith((ref) async => []),
          betaNewOpportunitiesCountProvider.overrideWithValue(0),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          home: const Scaffold(body: LibraryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();

    final tile = find.byKey(const ValueKey('library_favorite_tile_book-2'));
    final cover = find.byKey(const ValueKey('library_favorite_cover_book-2'));
    final coverAnimation = find.descendant(
      of: cover,
      matching: find.byType(AnimatedContainer),
    );
    final cta = find.byKey(const ValueKey('library_favorite_hover_cta_book-2'));
    expect(tester.widget<AnimatedOpacity>(cta).opacity, 0);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(tile));
    await tester.pump(const Duration(milliseconds: 260));

    final hoveredCover = tester.widget<AnimatedContainer>(coverAnimation);
    expect(hoveredCover.transform!.storage[13], lessThan(0));
    expect(tester.widget<AnimatedOpacity>(cta).opacity, 1);
    expect(find.text('Voir le livre'), findsOneWidget);
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });
}
