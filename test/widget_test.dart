import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plumora_app/core/theme/plumora_colors.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/core/theme/theme_mode_controller.dart';
import 'package:plumora_app/core/theme/theme_mode_storage.dart';
import 'package:plumora_app/core/widgets/figma_plumora.dart';
import 'package:plumora_app/core/widgets/plumora_ui.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plumora_app/features/beta_reading/data/repositories/beta_reading_repository.dart';
import 'package:plumora_app/features/book/data/repositories/book_repository.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/catalog/data/repositories/catalog_repository.dart';
import 'package:plumora_app/features/home/presentation/home_screen.dart';
import 'package:plumora_app/features/notification/data/repositories/notification_repository.dart';
import 'package:plumora_app/features/reading/data/models/reading_progress_model.dart';
import 'package:plumora_app/features/reading/data/repositories/reading_repository.dart';
import 'package:plumora_app/features/reading/presentation/reading_screen.dart';
import 'package:plumora_app/features/writing/presentation/author_dashboard_screen.dart';
import 'package:plumora_app/main.dart';

void main() {
  test('Dark palette matches the figma_sombre root tokens', () {
    const colors = PlumoraColors.dark;

    expect(colors.background, const Color(0xFF0E1117));
    expect(colors.textPrimary, const Color(0xFFF4F1EA));
    expect(colors.cards, const Color(0xFF1F2633));
    expect(colors.primary, const Color(0xFF7C5CFF));
    expect(colors.secondary, const Color(0xFF161B22));
    expect(colors.muted, const Color(0xFF1A2030));
    expect(colors.textSecondary, const Color(0xFFA8A8B3));
    expect(colors.accent, const Color(0xFFD6B25E));
    expect(colors.border, const Color(0xFF2A3142));
    expect(colors.inputBackground, const Color(0xFF1F2633));
    expect(colors.switchBackground, const Color(0xFF2A3142));
    expect(colors.sidebar, const Color(0xFF161B22));
    expect(colors.onPrimary, Colors.white);
    expect(colors.onAccent, const Color(0xFF0E1117));
  });

  test('Theme toggle updates and persists the selected mode', () async {
    final storage = _TestThemeModeStorage();
    final container = ProviderContainer(
      overrides: [
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        themeModeStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeControllerProvider), ThemeMode.light);
    await container.read(themeModeControllerProvider.notifier).toggle();

    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    expect(storage.savedMode, ThemeMode.dark);
  });

  testWidgets('Plumora starts on public landing page', (tester) async {
    await tester.pumpWidget(const PlumoraApp());
    await tester.pumpAndSettle();

    expect(find.text('Plumora'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Rejoindre gratuitement'), findsOneWidget);
  });

  testWidgets('Plumora starts directly with the restored dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(const PlumoraApp(initialThemeMode: ThemeMode.dark));
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      tester.element(find.text('Plumora').first).colors.background,
      PlumoraColors.dark.background,
    );
  });

  testWidgets('PlumoraBookCover resolves backend upload cover URLs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlumoraBookCover(
            colors: [Colors.black, Colors.white],
            imageUrl: 'uploads/book-covers/cover.png',
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image;

    expect(provider, isA<NetworkImage>());
    expect(
      (provider as NetworkImage).url,
      'http://localhost:8080/api/v1/uploads/book-covers/cover.png',
    );
  });

  testWidgets('Home keeps its reference layout on a narrow mobile screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(322, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          popularCatalogBooksProvider.overrideWith((ref) async => []),
          latestCatalogBooksProvider.overrideWith((ref) async => []),
          betaInvitationsProvider.overrideWith((ref) async => []),
          myNotificationsProvider.overrideWith((ref) async => []),
          unreadNotificationsCountProvider.overrideWith((ref) async => 1),
          myReadingProgressProvider.overrideWith(
            (ref) async => const [
              ReadingProgressModel(
                bookId: 'book-1',
                chapterId: 'chapter-3',
                bookTitle: 'La Nuit Rouge',
                chapterIndex: 2,
                progress: 0.35,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The shared AppHeader only shows the Plumora brand lockup on mobile
    // (no greeting text) -- the "Bonjour" subtitle is desktop-only, matching
    // the updated Figma `AppHeader` component.
    expect(find.text('Plumora'), findsOneWidget);
    expect(find.text('— Victor Hugo'), findsOneWidget);
    expect(find.text('Continuer la lecture'), findsOneWidget);
    expect(find.text('La Nuit Rouge'), findsOneWidget);
    expect(find.text('35% lu'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(488, 600));
    await tester.pumpAndSettle();

    final quoteCard = find.ancestor(
      of: find.text('— Victor Hugo'),
      matching: find.byType(FigmaCard),
    );
    final quoteCardSize = tester.getSize(quoteCard);

    expect(quoteCardSize.width, closeTo(456, 0.1));
    expect(quoteCardSize.height, closeTo(128, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home uses figma_sombre surfaces and dark controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.dark),
          authControllerProvider.overrideWith(_TestAuthController.new),
          popularCatalogBooksProvider.overrideWith((ref) async => []),
          latestCatalogBooksProvider.overrideWith((ref) async => []),
          betaInvitationsProvider.overrideWith((ref) async => []),
          myNotificationsProvider.overrideWith((ref) async => []),
          unreadNotificationsCountProvider.overrideWith((ref) async => 1),
          myReadingProgressProvider.overrideWith(
            (ref) async => const [
              ReadingProgressModel(
                bookId: 'book-1',
                chapterId: 'chapter-3',
                bookTitle: 'La Nuit Rouge',
                chapterIndex: 2,
                progress: 0.35,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          darkTheme: PlumoraTheme.dark,
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final quoteCard = find.ancestor(
      of: find.text('— Victor Hugo'),
      matching: find.byType(FigmaCard),
    );
    final card = tester.widget<AnimatedContainer>(
      find.descendant(of: quoteCard, matching: find.byType(AnimatedContainer)),
    );
    final decoration = card.decoration! as BoxDecoration;

    expect(decoration.color, PlumoraColors.dark.cards);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Author dashboard has no forced light structural surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [myBooksProvider.overrideWith((ref) async => [])],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          darkTheme: PlumoraTheme.dark,
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: AuthorDashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surfaceColors = tester
        .widgetList<Container>(find.byType(Container))
        .map((widget) => (widget.decoration as BoxDecoration?)?.color)
        .whereType<Color>()
        .toList();

    expect(surfaceColors, contains(PlumoraColors.dark.cards));
    expect(surfaceColors, isNot(contains(const Color(0xFFFFFEFC))));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reader uses the dark background and foreground tokens', (
    tester,
  ) async {
    const book = CatalogBookDetailModel(
      id: 'book-1',
      title: 'La Nuit Rouge',
      description: '',
      authorName: 'Kevin',
      chapters: [
        CatalogChapterModel(
          id: 'chapter-1',
          title: 'La rencontre',
          content: 'La nuit enveloppait doucement la ville.',
          order: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readableBookProvider.overrideWith((ref, id) async => book),
          readingProgressProvider.overrideWith((ref, id) async => null),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          darkTheme: PlumoraTheme.dark,
          themeMode: ThemeMode.dark,
          home: const ReadingScreen(bookId: 'book-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final paragraph = tester.widget<Text>(
      find.text('La nuit enveloppait doucement la ville.'),
    );

    expect(scaffold.backgroundColor, PlumoraColors.dark.background);
    expect(paragraph.style?.color, PlumoraColors.dark.textPrimary);
    expect(tester.takeException(), isNull);
  });
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}

class _TestThemeModeStorage extends ThemeModeStorage {
  _TestThemeModeStorage() : super.withStorage(const FlutterSecureStorage());

  ThemeMode? savedMode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    savedMode = mode;
  }
}
