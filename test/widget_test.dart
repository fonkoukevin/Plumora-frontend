import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plumora_app/core/widgets/figma_plumora.dart';
import 'package:plumora_app/core/widgets/plumora_ui.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plumora_app/features/beta_reading/data/repositories/beta_reading_repository.dart';
import 'package:plumora_app/features/catalog/data/repositories/catalog_repository.dart';
import 'package:plumora_app/features/home/presentation/home_screen.dart';
import 'package:plumora_app/features/notification/data/repositories/notification_repository.dart';
import 'package:plumora_app/features/reading/data/models/reading_progress_model.dart';
import 'package:plumora_app/features/reading/data/repositories/reading_repository.dart';
import 'package:plumora_app/main.dart';

void main() {
  testWidgets('Plumora starts on public landing page', (tester) async {
    await tester.pumpWidget(const PlumoraApp());
    await tester.pumpAndSettle();

    expect(find.text('Plumora'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Rejoindre gratuitement'), findsOneWidget);
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
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plumora'), findsOneWidget);
    expect(find.text('Bonjour, Plumora'), findsOneWidget);
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
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}
