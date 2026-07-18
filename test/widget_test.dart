import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plumora_app/core/routing/app_router.dart';
import 'package:plumora_app/core/routing/main_shell.dart';
import 'package:plumora_app/core/theme/plumora_colors.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/core/theme/theme_mode_controller.dart';
import 'package:plumora_app/core/theme/theme_mode_storage.dart';
import 'package:plumora_app/core/widgets/app_shell_header.dart';
import 'package:plumora_app/core/widgets/figma_plumora.dart';
import 'package:plumora_app/core/widgets/plumora_ui.dart';
import 'package:plumora_app/features/ai/data/repositories/plumo_ai_repository.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plumora_app/features/beta_reading/data/repositories/beta_reading_repository.dart';
import 'package:plumora_app/features/book/data/models/book_model.dart';
import 'package:plumora_app/features/book/data/repositories/book_repository.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/catalog/data/models/external_book_model.dart';
import 'package:plumora_app/features/catalog/data/repositories/catalog_repository.dart';
import 'package:plumora_app/features/catalog/data/repositories/external_book_repository.dart';
import 'package:plumora_app/features/catalog/presentation/discover_screen.dart';
import 'package:plumora_app/features/home/presentation/home_screen.dart';
import 'package:plumora_app/features/notification/data/repositories/notification_repository.dart';
import 'package:plumora_app/features/reading/data/models/reading_progress_model.dart';
import 'package:plumora_app/features/reading/data/repositories/reading_repository.dart';
import 'package:plumora_app/features/reading/presentation/reading_screen.dart';
import 'package:plumora_app/features/writing/presentation/author_dashboard_screen.dart';
import 'package:plumora_app/main.dart';

void main() {
  test('Light palette uses white page and navigation backgrounds', () {
    const colors = PlumoraColors.light;

    expect(colors.background, Colors.white);
    expect(colors.sidebar, Colors.white);
  });

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

  testWidgets(
    'Desktop sidebar can be toggled and dragged into icon-only mode',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_TestAuthController.new),
          ],
          child: MaterialApp(
            theme: PlumoraTheme.light,
            home: const MainShell(
              location: AppRoutes.home,
              child: ColoredBox(
                key: ValueKey('shell_content'),
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sidebar = find.byKey(const ValueKey('desktop_sidebar'));
      final resizeHandle = find.byKey(
        const ValueKey('desktop_sidebar_resize_handle'),
      );
      final toggleButton = find.byKey(
        const ValueKey('desktop_sidebar_toggle_button'),
      );
      final content = find.byKey(const ValueKey('shell_content'));

      expect(tester.getSize(sidebar).width, 240);
      expect(tester.getSize(content).width, 1040);
      expect(find.text('Plumora'), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Écrire'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(tester.getSize(sidebar).width, 76);
      expect(tester.getSize(content).width, 1204);
      expect(find.text('Plumora'), findsNothing);
      expect(find.text('Accueil'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(tester.getSize(sidebar).width, 240);
      expect(tester.getSize(content).width, 1040);
      expect(find.text('Plumora'), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      await tester.drag(resizeHandle, const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(tester.getSize(sidebar).width, 76);
      expect(tester.getSize(content).width, 1204);
      expect(find.text('Plumora'), findsNothing);
      expect(find.text('Accueil'), findsNothing);
      expect(find.text('Écrire'), findsNothing);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
      expect(
        tester
            .widgetList<Tooltip>(find.byType(Tooltip))
            .map((tooltip) => tooltip.message),
        containsAll(['Accueil', 'Écrire', 'Découvrir']),
      );

      await tester.drag(resizeHandle, const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(tester.getSize(sidebar).width, 240);
      expect(tester.getSize(content).width, 1040);
      expect(find.text('Plumora'), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Écrire'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home matches the reference layouts on mobile and desktop', (
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
    final continueReadingCard = find.byKey(
      const ValueKey('home_continue_reading_card'),
    );
    final readingProgress = find.byKey(const ValueKey('home_reading_progress'));
    final writeAction = find.byKey(const ValueKey('home_quick_action_Écrire'));
    final mobileQuoteCard = find.ancestor(
      of: find.text('— Victor Hugo'),
      matching: find.byType(FigmaCard),
    );
    final mobileContinueDecoration =
        tester.widget<Container>(continueReadingCard).decoration!
            as BoxDecoration;

    expect(tester.getSize(continueReadingCard), const Size(290, 156));
    expect(tester.getSize(readingProgress).width, lessThanOrEqualTo(140));
    expect(tester.getSize(writeAction).height, 72);
    expect(mobileContinueDecoration.borderRadius, BorderRadius.circular(20));
    expect(
      tester.getTopLeft(find.byType(PlumoraAppHeader)).dx,
      closeTo(tester.getTopLeft(mobileQuoteCard).dx, 0.1),
    );
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(768, 700));
    await tester.pumpAndSettle();

    expect(tester.getSize(continueReadingCard), const Size(736, 180));
    expect(tester.getSize(readingProgress).width, closeTo(360, 0.1));
    expect(tester.getSize(writeAction).height, 80);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(1280, 600));
    await tester.pumpAndSettle();

    final quoteCard = find.byKey(const ValueKey('home_quote_card'));
    final quoteCardSize = tester.getSize(quoteCard);
    final quoteCardWidget = tester.widget<AnimatedContainer>(
      find.descendant(of: quoteCard, matching: find.byType(AnimatedContainer)),
    );
    final quoteCardDecoration = quoteCardWidget.decoration! as BoxDecoration;
    final quoteIcon = find.byIcon(Icons.format_quote_rounded);
    final quoteIconContainer = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.child is Icon &&
          (widget.child! as Icon).icon == Icons.format_quote_rounded,
    );
    final quoteIconDecoration =
        tester.widget<Container>(quoteIconContainer).decoration!
            as BoxDecoration;
    final quoteGradient = quoteCardDecoration.gradient! as LinearGradient;
    final desktopContinueDecoration =
        tester.widget<Container>(continueReadingCard).decoration!
            as BoxDecoration;
    final firstSeeAllButton = find
        .widgetWithText(TextButton, 'Tout voir')
        .first;
    final firstSeeAllText = find.descendant(
      of: firstSeeAllButton,
      matching: find.text('Tout voir'),
    );
    final firstSeeAllChevron = find.descendant(
      of: firstSeeAllButton,
      matching: find.byIcon(Icons.chevron_right),
    );
    final highlightsRow = find.byKey(const ValueKey('home_highlights_row'));
    final quoteCardRect = tester.getRect(quoteCard);
    final continueReadingRect = tester.getRect(continueReadingCard);

    expect(tester.getSize(highlightsRow), const Size(1248, 180));
    expect(quoteCardSize, const Size(408, 180));
    expect(tester.getSize(continueReadingCard), const Size(816, 180));
    expect(quoteCardRect.top, closeTo(continueReadingRect.top, 0.1));
    expect(quoteCardRect.bottom, closeTo(continueReadingRect.bottom, 0.1));
    expect(continueReadingRect.left - quoteCardRect.right, closeTo(24, 0.1));
    expect(find.text('— Victor Hugo'), findsOneWidget);
    expect(tester.getSize(readingProgress).width, closeTo(360, 0.1));
    expect(tester.getSize(writeAction).height, 80);
    expect(desktopContinueDecoration.borderRadius, BorderRadius.circular(24));
    expect(
      tester.getTopLeft(firstSeeAllChevron).dx,
      greaterThan(tester.getTopLeft(firstSeeAllText).dx),
    );
    expect(quoteCardDecoration.color, isNull);
    expect(quoteGradient.colors.first, PlumoraColors.light.cards);
    expect(
      quoteGradient.colors.last,
      Color.lerp(PlumoraColors.light.cards, PlumoraColors.light.primary, 0.06),
    );
    expect(
      (quoteCardDecoration.border! as Border).top.color,
      Color.lerp(PlumoraColors.light.border, PlumoraColors.light.primary, 0.25),
    );
    expect(quoteCardDecoration.borderRadius, BorderRadius.circular(16));
    expect(tester.getSize(quoteIconContainer), const Size.square(40));
    expect(tester.getSize(quoteIcon), const Size.square(18));
    expect(
      quoteIconDecoration.color,
      PlumoraColors.light.primary.withValues(alpha: 0.12),
    );
    expect(quoteIconDecoration.borderRadius, BorderRadius.circular(14));
    expect(
      tester.getCenter(quoteIconContainer).dx,
      closeTo(tester.getCenter(quoteCard).dx, 0.1),
    );
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

  testWidgets('Desktop page titles are black in light and violet in dark', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Widget app(ThemeMode mode) {
      return ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          darkTheme: PlumoraTheme.dark,
          themeMode: mode,
          home: const Scaffold(
            body: PlumoraAppHeader(
              title: 'Accueil',
              subtitle: 'Bienvenue',
              gradient: [Color(0xFF7C5CFF), Color(0xFF9B6FD4)],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(app(ThemeMode.light));
    await tester.pumpAndSettle();

    var title = find.text('Accueil');
    expect(tester.widget<Text>(title).style?.color, Colors.black);
    expect(
      find.ancestor(of: title, matching: find.byType(ShaderMask)),
      findsNothing,
    );

    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pumpAndSettle();

    title = find.text('Accueil');
    expect(
      find.ancestor(of: title, matching: find.byType(ShaderMask)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Discover aligns search and Plumo on desktop only', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final plumoraBooks = List.generate(
      15,
      (index) => CatalogBookModel(
        id: 'plumora-$index',
        title: 'Livre Plumora $index',
        description: '',
        authorName: 'Auteur Plumora',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
          plumoraCatalogBooksProvider.overrideWith(
            (ref, query) async => plumoraBooks,
          ),
          plumoBookRecommendationsProvider.overrideWith((ref) async => []),
          externalBookSearchProvider.overrideWith(
            (ref, query) async => const ExternalBookPage(
              content: [],
              page: 0,
              size: 0,
              totalElements: 0,
              totalPages: 0,
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

    final header = find.byKey(const ValueKey('discover_header'));
    final search = find.byKey(const ValueKey('discover_search_field'));
    final plumoBanner = find.byKey(const ValueKey('discover_plumo_banner'));
    var searchRect = tester.getRect(search);
    var plumoRect = tester.getRect(plumoBanner);

    expect(tester.getSize(header).height, 150);
    expect(searchRect.height, 50);
    expect(plumoRect.height, 50);
    expect(searchRect.width, closeTo(plumoRect.width, 0.1));
    expect(searchRect.top, closeTo(plumoRect.top, 0.1));
    expect(plumoRect.left - searchRect.right, closeTo(12, 0.1));
    expect(find.byKey(const ValueKey('plumora_books_next')), findsOneWidget);
    final railRect = tester.getRect(
      find.byKey(const ValueKey('plumora_books_scroll')),
    );
    final nextButton = find.byKey(const ValueKey('plumora_books_next'));
    expect(tester.widget<AnimatedOpacity>(nextButton).opacity, 0);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(railRect.center);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(nextButton).opacity, 1);
    final nextButtonRect = tester.getRect(nextButton);
    expect(nextButtonRect.right, closeTo(railRect.right, 0.1));
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.text('Livre Plumora 14'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('plumora_books_previous')),
      findsOneWidget,
    );
    final previousButtonRect = tester.getRect(
      find.byKey(const ValueKey('plumora_books_previous')),
    );
    expect(previousButtonRect.left, closeTo(railRect.left, 0.1));
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('plumora_books_previous')),
          )
          .opacity,
      0,
    );

    await tester.binding.setSurfaceSize(const Size(700, 700));
    await tester.pumpAndSettle();

    searchRect = tester.getRect(search);
    plumoRect = tester.getRect(plumoBanner);

    expect(tester.getSize(header).height, 234);
    expect(plumoRect.top, greaterThan(searchRect.bottom));
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
    expect(
      find.ancestor(
        of: find.text('Mes manuscrits'),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Author dashboard keeps a compact three-column desktop grid', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const books = [
      BookModel(
        id: 'book-1',
        title: 'Les lumières du soir',
        description: '',
        status: BookStatus.draft,
        genre: 'Fantasy',
        chapterCount: 3,
        wordCount: 4200,
      ),
      BookModel(
        id: 'book-2',
        title: 'La ville silencieuse',
        description: '',
        status: BookStatus.inBetaReading,
        genre: 'Romance',
        chapterCount: 5,
        wordCount: 7800,
      ),
      BookModel(
        id: 'book-3',
        title: 'Une autre histoire',
        description: '',
        status: BookStatus.published,
        genre: 'Fiction',
        chapterCount: 8,
        wordCount: 12300,
      ),
      BookModel(
        id: 'book-4',
        title: 'Le dernier manuscrit',
        description: '',
        status: BookStatus.archived,
        chapterCount: 2,
        wordCount: 1900,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [myBooksProvider.overrideWith((ref) async => books)],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          home: const Scaffold(body: AuthorDashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstCard = find.byKey(const ValueKey('manuscript_card_book-1'));
    final secondCard = find.byKey(const ValueKey('manuscript_card_book-2'));
    final thirdCard = find.byKey(const ValueKey('manuscript_card_book-3'));
    final fourthCard = find.byKey(const ValueKey('manuscript_card_book-4'));
    final firstCardDecoration =
        tester.widget<AnimatedContainer>(firstCard).decoration!
            as BoxDecoration;
    final firstCardBorder = firstCardDecoration.border! as Border;
    final firstCardLink = find.byKey(
      const ValueKey('manuscript_card_link_book-1'),
    );
    final hoverArrow = find.byKey(
      const ValueKey('manuscript_card_hover_arrow_book-1'),
    );
    final storiesStat = find.byKey(const ValueKey('manuscript_stat_Histoires'));
    final storiesStatDecoration =
        tester.widget<Container>(storiesStat).decoration! as BoxDecoration;
    final storiesStatBorder = storiesStatDecoration.border! as Border;
    final manuscriptsTitle = find.text('Mes manuscrits');

    expect(tester.getSize(firstCard).width, closeTo(382.7, 0.1));
    expect(tester.widget<Text>(manuscriptsTitle).style?.color, Colors.black);
    expect(
      find.ancestor(of: manuscriptsTitle, matching: find.byType(ShaderMask)),
      findsNothing,
    );
    expect(
      tester.getTopLeft(firstCard).dy,
      closeTo(tester.getTopLeft(secondCard).dy, 0.1),
    );
    expect(
      tester.getTopLeft(secondCard).dy,
      closeTo(tester.getTopLeft(thirdCard).dy, 0.1),
    );
    expect(
      tester.getTopLeft(fourthCard).dy,
      greaterThan(tester.getBottomLeft(firstCard).dy),
    );
    expect(firstCardBorder.top.width, 0.8);
    expect(firstCardDecoration.borderRadius, BorderRadius.circular(18));
    expect(tester.getSize(storiesStat).height, 80);
    expect(storiesStatDecoration.gradient, isA<LinearGradient>());
    expect(storiesStatDecoration.borderRadius, BorderRadius.circular(18));
    expect(storiesStatBorder.top.width, 0.8);
    expect(
      find.byKey(const ValueKey('manuscript_stat_watermark_Histoires')),
      findsOneWidget,
    );
    expect(tester.widget<InkWell>(firstCardLink).onTap, isNotNull);
    expect(
      tester.widget<InkWell>(firstCardLink).mouseCursor,
      SystemMouseCursors.click,
    );
    expect(tester.widget<AnimatedOpacity>(hoverArrow).opacity, 0);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getTopLeft(firstCard) + const Offset(180, 50));
    await tester.pump(const Duration(milliseconds: 200));

    final hoveredCard = tester.widget<AnimatedContainer>(firstCard);
    final hoveredDecoration = hoveredCard.decoration! as BoxDecoration;
    final hoveredBorder = hoveredDecoration.border! as Border;

    expect(hoveredBorder.top.width, 1.1);
    expect(
      hoveredBorder.top.color,
      PlumoraColors.light.primary.withValues(alpha: 0.55),
    );
    expect(hoveredCard.transform!.storage[13], -4);
    expect(tester.widget<AnimatedOpacity>(hoverArrow).opacity, 1);
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
