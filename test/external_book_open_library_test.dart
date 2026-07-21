import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/core/widgets/plumora_ui.dart';
import 'package:plumora_app/features/ai/data/repositories/plumo_ai_repository.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plumora_app/features/catalog/data/models/external_book_model.dart';
import 'package:plumora_app/features/catalog/data/repositories/catalog_repository.dart';
import 'package:plumora_app/features/catalog/data/repositories/external_book_repository.dart';
import 'package:plumora_app/features/catalog/data/services/external_book_api_service.dart';
import 'package:plumora_app/features/catalog/presentation/discover_screen.dart';
import 'package:plumora_app/features/catalog/presentation/external_book_detail_screen.dart';
import 'package:plumora_app/features/catalog/presentation/public_domain_catalog_screen.dart';
import 'package:plumora_app/features/notification/data/repositories/notification_repository.dart';
import 'package:plumora_app/features/reading/data/repositories/review_repository.dart';

const _openLibraryBook = ExternalBook(
  externalId: 'OL123W',
  source: 'OPEN_LIBRARY',
  title: 'Fallback Fable',
  authors: ['Jane Doe'],
  summary: 'A book found only via the Open Library fallback.',
  downloadCount: 3,
);

const _gutendexBook = ExternalBook(
  externalId: '1342',
  source: 'GUTENDEX',
  title: 'Pride and Prejudice',
  authors: ['Jane Austen'],
  summary: 'A classic, actually importable from Gutendex.',
  downloadCount: 900,
);

class _FakeExternalBookRepository extends ExternalBookRepository {
  _FakeExternalBookRepository(this.page) : super(ExternalBookApiService(Dio()));

  final ExternalBookPage page;

  @override
  Future<ExternalBookPage> searchExternalBooks({
    String? search,
    String? language,
    String? topic,
    int page = 0,
  }) async => this.page;
}

void main() {
  group('ExternalBook.isOpenLibrary / canOpenExternalDetail', () {
    test('flags Open Library sourced results', () {
      expect(_openLibraryBook.isOpenLibrary, isTrue);
      expect(_gutendexBook.isOpenLibrary, isFalse);
    });

    test('is case/whitespace insensitive', () {
      expect(
        _openLibraryBook.copyWith(source: 'open_library').isOpenLibrary,
        isTrue,
      );
      expect(
        _openLibraryBook.copyWith(source: ' Open_Library ').isOpenLibrary,
        isTrue,
      );
    });

    test('an un-imported Open Library result cannot open the external detail '
        'screen (it has no real Gutendex id to fetch)', () {
      expect(_openLibraryBook.canOpenExternalDetail, isFalse);
      expect(_gutendexBook.canOpenExternalDetail, isTrue);
    });

    test('an imported Open Library result is always safe to open', () {
      final imported = _openLibraryBook.copyWith(
        imported: true,
        internalBookId: 'book-1',
      );
      expect(imported.canOpenExternalDetail, isTrue);
    });
  });

  group('PublicDomainCatalogScreen — Open Library results', () {
    testWidgets(
      'hides the "read" affordance and never navigates for an un-imported '
      'Open Library card',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              externalBookRepositoryProvider.overrideWithValue(
                _FakeExternalBookRepository(
                  const ExternalBookPage(
                    content: [_openLibraryBook],
                    page: 0,
                    size: 1,
                    totalElements: 1,
                    totalPages: 1,
                    first: true,
                    last: true,
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: PlumoraTheme.light,
              home: const Scaffold(body: PublicDomainCatalogScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Fallback Fable'), findsOneWidget);
        expect(
          find.widgetWithText(PlumoraBadge, 'Bientôt disponible'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(PlumoraBadge, 'Domaine public'),
          findsNothing,
        );
        expect(find.text('Détails'), findsNothing);

        // No GoRouter is set up in this widget tree, so if the card's
        // onTap were still wired (regression), tapping it would throw
        // trying to call context.push — confirming it's truly inert.
        await tester.tap(find.text('Fallback Fable'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('keeps the normal "read" affordance for a Gutendex card', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            externalBookRepositoryProvider.overrideWithValue(
              _FakeExternalBookRepository(
                const ExternalBookPage(
                  content: [_gutendexBook],
                  page: 0,
                  size: 1,
                  totalElements: 1,
                  totalPages: 1,
                  first: true,
                  last: true,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: PlumoraTheme.light,
            home: const Scaffold(body: PublicDomainCatalogScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pride and Prejudice'), findsOneWidget);
      expect(
        find.widgetWithText(PlumoraBadge, 'Domaine public'),
        findsOneWidget,
      );
      expect(find.text('Détails'), findsOneWidget);
      expect(
        find.widgetWithText(PlumoraBadge, 'Bientôt disponible'),
        findsNothing,
      );
    });
  });

  group('ExternalBookDetailScreen — Open Library results', () {
    testWidgets(
      'replaces "Importer dans Plumora" with a disabled, explanatory state',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              externalBookDetailProvider.overrideWith(
                (ref, id) async => _openLibraryBook,
              ),
              externalBookReviewsProvider.overrideWith((ref, id) async => []),
            ],
            child: MaterialApp(
              theme: PlumoraTheme.light,
              home: const Scaffold(
                body: ExternalBookDetailScreen(gutendexId: 'OL123W'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Importer dans Plumora'), findsNothing);
        final button = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text('Bientôt disponible sur Plumora'),
            matching: find.byType(FilledButton),
          ),
        );
        expect(button.onPressed, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Discover rails — every result is an Open Library fallback', () {
    testWidgets(
      'replaces the tile row with a plain "coming soon" notice instead of '
      'a row of inert cards',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(_TestAuthController.new),
              unreadNotificationsCountProvider.overrideWith((ref) async => 0),
              plumoraCatalogBooksProvider.overrideWith(
                (ref, query) async => [],
              ),
              plumoBookRecommendationsProvider.overrideWith((ref) async => []),
              externalBookSearchProvider.overrideWith(
                (ref, query) async => const ExternalBookPage(
                  content: [_openLibraryBook],
                  page: 0,
                  size: 1,
                  totalElements: 1,
                  totalPages: 1,
                  first: true,
                  last: true,
                ),
              ),
            ],
            child: MaterialApp(
              theme: PlumoraTheme.light,
              home: const Scaffold(body: DiscoverScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Fallback Fable'), findsNothing);
        expect(
          find.text(
            'Ces livres seront bientôt disponibles à la lecture. '
            'Reviens plus tard !',
          ),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('still shows the row when at least one result is readable', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_TestAuthController.new),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            plumoraCatalogBooksProvider.overrideWith((ref, query) async => []),
            plumoBookRecommendationsProvider.overrideWith((ref) async => []),
            externalBookSearchProvider.overrideWith(
              (ref, query) async => const ExternalBookPage(
                content: [_openLibraryBook, _gutendexBook],
                page: 0,
                size: 2,
                totalElements: 2,
                totalPages: 1,
                first: true,
                last: true,
              ),
            ),
          ],
          child: MaterialApp(
            theme: PlumoraTheme.light,
            home: const Scaffold(body: DiscoverScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pride and Prejudice'), findsWidgets);
      expect(
        find.text(
          'Ces livres seront bientôt disponibles à la lecture. '
          'Reviens plus tard !',
        ),
        findsNothing,
      );
    });
  });

  group(
    'PublicDomainCatalogScreen — every result is an Open Library fallback',
    () {
      testWidgets('shows a notice banner above the (still visible) grid', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              externalBookRepositoryProvider.overrideWithValue(
                _FakeExternalBookRepository(
                  const ExternalBookPage(
                    content: [_openLibraryBook],
                    page: 0,
                    size: 1,
                    totalElements: 1,
                    totalPages: 1,
                    first: true,
                    last: true,
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: PlumoraTheme.light,
              home: const Scaffold(body: PublicDomainCatalogScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Ces livres seront bientôt disponibles à la lecture. '
            'Reviens plus tard !',
          ),
          findsOneWidget,
        );
        // The grid itself still renders — this is a browse page, unlike the
        // homepage rails, so the entry stays visible with its own
        // "Bientôt disponible" badge rather than being hidden outright.
        expect(find.text('Fallback Fable'), findsOneWidget);
      });
    },
  );
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}
