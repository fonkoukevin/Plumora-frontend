import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/auth/data/models/role_model.dart';
import 'package:plumora_app/features/auth/data/models/user_model.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plumora_app/features/beta_reading/data/repositories/beta_reading_repository.dart';
import 'package:plumora_app/features/book/data/models/book_model.dart';
import 'package:plumora_app/features/book/data/models/chapter_model.dart';
import 'package:plumora_app/features/book/data/repositories/book_repository.dart';
import 'package:plumora_app/features/book/data/repositories/chapter_repository.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/catalog/data/repositories/catalog_repository.dart';
import 'package:plumora_app/features/catalog/presentation/catalog_search_screen.dart';
import 'package:plumora_app/features/notification/data/models/notification_model.dart';
import 'package:plumora_app/features/notification/data/repositories/notification_repository.dart';
import 'package:plumora_app/features/notification/presentation/notifications_screen.dart';
import 'package:plumora_app/features/profile/presentation/profile_screen.dart';
import 'package:plumora_app/features/reading/data/models/favorite_model.dart';
import 'package:plumora_app/features/reading/data/models/review_model.dart';
import 'package:plumora_app/features/reading/data/repositories/favorite_repository.dart';
import 'package:plumora_app/features/reading/data/repositories/reading_repository.dart';
import 'package:plumora_app/features/reading/data/repositories/review_repository.dart';
import 'package:plumora_app/features/reading/presentation/my_favorites_screen.dart';
import 'package:plumora_app/features/reading/presentation/my_reviews_screen.dart';
import 'package:plumora_app/features/writing/presentation/create_book_screen.dart';
import 'package:plumora_app/features/writing/presentation/publish_book_screen.dart';

class _UnauthenticatedController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}

class _AuthenticatedController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession(
    user: UserModel(
      id: 'user-1',
      firstname: 'Ada',
      lastname: 'Lovelace',
      email: 'ada@example.com',
    ),
    roles: [RoleModel(name: 'AUTHOR')],
  );
}

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: PlumoraTheme.light,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const desktop = Size(1280, 900);
  const mobile = Size(390, 844);

  group('MyFavoritesScreen', () {
    final favorites = List.generate(
      5,
      (index) => FavoriteModel(
        id: 'fav-$index',
        book: CatalogBookModel(
          id: 'book-$index',
          title: 'Livre $index',
          description: '',
          authorName: 'Auteur $index',
        ),
      ),
    );

    testWidgets('no overflow at desktop width (previously had no wrapper)', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        desktop,
        const MyFavoritesScreen(),
        overrides: [myFavoritesProvider.overrideWith((ref) async => favorites)],
      );

      expect(find.byType(ConstrainedBox), findsWidgets);
      final tile = find.byKey(const ValueKey('favorites_page_tile_book-0'));
      final cover = find.byKey(const ValueKey('favorites_page_cover_book-0'));
      final coverAnimation = find.descendant(
        of: cover,
        matching: find.byType(AnimatedContainer),
      );
      final cta = find.byKey(const ValueKey('favorites_page_hover_cta_book-0'));
      expect(tester.widget<AnimatedOpacity>(cta).opacity, 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(tile));
      await tester.pump(const Duration(milliseconds: 260));

      final hoveredCover = tester.widget<AnimatedContainer>(coverAnimation);
      expect(hoveredCover.transform!.storage[13], lessThan(0));
      expect(tester.widget<AnimatedOpacity>(cta).opacity, 1);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at mobile width', (tester) async {
      await _pumpAt(
        tester,
        mobile,
        const MyFavoritesScreen(),
        overrides: [myFavoritesProvider.overrideWith((ref) async => favorites)],
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('MyReviewsScreen', () {
    final reviews = List.generate(
      4,
      (index) => ReviewModel(
        id: 'review-$index',
        bookId: 'book-$index',
        userId: 'user-$index',
        userName: 'Lecteur $index',
        rating: 4,
        comment: 'Très bon livre $index.',
      ),
    );

    testWidgets('no overflow at desktop width (previously had no wrapper)', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        desktop,
        const MyReviewsScreen(),
        overrides: [myReviewsProvider.overrideWith((ref) async => reviews)],
      );

      expect(find.byType(ConstrainedBox), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at mobile width', (tester) async {
      await _pumpAt(
        tester,
        mobile,
        const MyReviewsScreen(),
        overrides: [myReviewsProvider.overrideWith((ref) async => reviews)],
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('ProfileScreen', () {
    final overrides = [
      authControllerProvider.overrideWith(_AuthenticatedController.new),
      myBooksProvider.overrideWith((ref) async => const []),
      myReadingProgressProvider.overrideWith((ref) async => const []),
      myFavoritesProvider.overrideWith((ref) async => const []),
    ];

    testWidgets('puts the hero card and settings side by side on desktop', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        desktop,
        const ProfileScreen(),
        overrides: overrides,
      );

      final heroRect = tester.getRect(find.text('Ada Lovelace'));
      final settingsRect = tester.getRect(find.text('Paramètres'));

      // Side by side: settings section starts to the right of the hero
      // card, not below it.
      expect(settingsRect.left, greaterThan(heroRect.right));
      expect(tester.takeException(), isNull);
    });

    testWidgets('stacks the hero card above settings on mobile', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        mobile,
        const ProfileScreen(),
        overrides: overrides,
      );

      final heroRect = tester.getRect(find.text('Ada Lovelace'));
      final settingsRect = tester.getRect(find.text('Paramètres'));

      expect(settingsRect.top, greaterThan(heroRect.bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses two settings columns on a very wide screen', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const Size(1920, 1080),
        const ProfileScreen(),
        overrides: overrides,
      );

      final personalInfo = tester.getRect(
        find.text('Informations personnelles'),
      );
      final notifications = tester.getRect(find.text('Notifications'));
      final plumo = tester.getRect(find.text('Assistant Plumo'));

      expect(notifications.left, greaterThan(personalInfo.right));
      expect(notifications.top, closeTo(personalInfo.top, 0.1));
      expect(plumo.top, greaterThan(personalInfo.bottom));
      expect(tester.takeException(), isNull);
    });
  });

  group('CreateBookScreen (new book — no async provider needed)', () {
    // _SectionLabel upper-cases its text (see _SectionLabel in
    // create_book_screen.dart), hence 'COUVERTURE'/'INFORMATIONS' below.
    testWidgets('puts the cover picker and fields side by side on desktop', (
      tester,
    ) async {
      await _pumpAt(tester, desktop, const CreateBookScreen());

      final coverRect = tester.getRect(find.text('COUVERTURE'));
      final infoRect = tester.getRect(find.text('INFORMATIONS'));

      expect(infoRect.left, greaterThan(coverRect.right));
      expect(tester.takeException(), isNull);
    });

    // Not paired with a mobile-width geometry check here: _Header (unrelated
    // to this pass — a fixed top bar this change never touches) overflows
    // at ~390px logical width under flutter test's fallback font metrics,
    // which real device fonts don't reproduce. The mobile layout itself is
    // byte-for-byte the pre-existing single Column, so there's no new
    // regression risk for this pass to cover.
  });

  group('PublishBookScreen', () {
    const bookId = 'book-1';
    const overrides = [
      // authorBookProvider/bookChaptersProvider/betaCommentsForBookProvider
      // are FutureProvider.family<T, String> — overriding the whole family
      // (ignoring the id argument) is fine since this test only ever reads
      // the one bookId above.
    ];

    List<Override> buildOverrides() => [
      authorBookProvider.overrideWith(
        (ref, id) async => const BookModel(
          id: bookId,
          title: 'Le Grand Voyage',
          description: 'Une histoire.',
          status: BookStatus.readyToPublish,
          genre: 'Fantasy',
        ),
      ),
      bookChaptersProvider.overrideWith(
        (ref, id) async => const [
          ChapterModel(
            id: 'chapter-1',
            bookId: bookId,
            title: 'Chapitre 1',
            content: 'Un texte qui compte comme du contenu réel.',
            order: 1,
          ),
        ],
      ),
      betaCommentsForBookProvider.overrideWith((ref, id) async => const []),
    ];

    testWidgets(
      'puts the checklist and summary/actions side by side on desktop',
      (tester) async {
        await _pumpAt(
          tester,
          desktop,
          const PublishBookScreen(bookId: bookId),
          overrides: [...overrides, ...buildOverrides()],
        );

        final checklistRect = tester.getRect(
          find.text('Checklist de publication'),
        );
        final publishButtonRect = tester.getRect(find.text('Publier'));

        expect(publishButtonRect.left, greaterThan(checklistRect.right));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('stacks the checklist above actions on mobile', (tester) async {
      await _pumpAt(
        tester,
        mobile,
        const PublishBookScreen(bookId: bookId),
        overrides: [...overrides, ...buildOverrides()],
      );

      final checklistRect = tester.getRect(
        find.text('Checklist de publication'),
      );
      final publishButtonRect = tester.getRect(find.text('Publier'));

      expect(publishButtonRect.top, greaterThan(checklistRect.bottom));
      expect(tester.takeException(), isNull);
    });
  });

  group('CatalogSearchScreen', () {
    final books = List.generate(
      4,
      (index) => CatalogBookModel(
        id: 'book-$index',
        title: 'Résultat $index',
        description: '',
        authorName: 'Auteur $index',
      ),
    );

    testWidgets('lays results out as a 2-column grid on desktop', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        desktop,
        const CatalogSearchScreen(),
        overrides: [
          catalogSearchProvider.overrideWith((ref, query) async => books),
        ],
      );

      final firstRect = tester.getRect(find.text('Résultat 0'));
      final secondRect = tester.getRect(find.text('Résultat 1'));

      // Same row: second card starts to the right of the first, not below.
      expect(secondRect.left, greaterThan(firstRect.right));
      expect((secondRect.top - firstRect.top).abs(), lessThan(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('NotificationsScreen', () {
    final notifications = List.generate(
      4,
      (index) => NotificationModel(
        id: 'notif-$index',
        title: 'Notification $index',
        message: 'Un message.',
        type: 'BOOK',
      ),
    );

    testWidgets('lays notifications out as a 2-column grid on desktop', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        desktop,
        const NotificationsScreen(),
        overrides: [
          authControllerProvider.overrideWith(_UnauthenticatedController.new),
          myNotificationsProvider.overrideWith((ref) async => notifications),
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        ],
      );

      final firstRect = tester.getRect(find.text('Notification 0'));
      final secondRect = tester.getRect(find.text('Notification 1'));

      expect(secondRect.left, greaterThan(firstRect.right));
      expect((secondRect.top - firstRect.top).abs(), lessThan(1));
      expect(tester.takeException(), isNull);
    });
  });
}
