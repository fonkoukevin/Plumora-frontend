import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/ai/data/models/ai_models.dart';
import 'package:plumora_app/features/ai/data/repositories/ai_repository.dart';
import 'package:plumora_app/features/ai/data/services/ai_api_service.dart';
import 'package:plumora_app/features/ai/presentation/plumo_recommendation_screen.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/catalog/data/repositories/catalog_repository.dart';
import 'package:plumora_app/features/reading/data/repositories/favorite_repository.dart';

void main() {
  testWidgets('Plumo recommendations match the two-action desktop layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const detail = CatalogBookDetailModel(
      id: 'night-train',
      title: 'Dernier Tram pour Lumen',
      description: 'Un thriller nocturne.',
      authorName: 'Bruno Kassel',
      genre: 'Thriller',
      rating: 4,
      readCount: 257,
      estimatedReadingMinutes: 150,
    );
    const recommendation = AiRecommendedBookModel(
      book: CatalogBookModel(
        id: 'night-train',
        title: 'Dernier Tram pour Lumen',
        description: '',
        authorName: 'Bruno Kassel',
      ),
      matchScore: 85,
      reasons: [
        'Correspond à ton envie de suspense.',
        'Lecture courte.',
        'Ambiance sombre.',
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiRepositoryProvider.overrideWithValue(
            _RecommendationTestRepository(const [recommendation]),
          ),
          catalogBookDetailProvider.overrideWith((ref, id) async => detail),
          favoriteStatusProvider.overrideWith((ref, id) async => false),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          home: const Scaffold(body: PlumoRecommendationScreen()),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Un thriller sombre');
    await tester.pump();
    final submit = find.widgetWithText(FilledButton, 'Me recommander');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Pourquoi ce livre ?'), findsOneWidget);
    expect(find.text('Correspond à ton envie de suspense.'), findsOneWidget);
    expect(find.text('Lecture courte.'), findsOneWidget);
    expect(find.text('Ambiance sombre.'), findsOneWidget);
    expect(find.text('2h30'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('En savoir plus'), findsOneWidget);
    expect(find.text('Ajouter à ma liste'), findsOneWidget);

    final cover = find.byKey(
      const ValueKey('plumo_recommendation_cover_night-train'),
    );
    expect(tester.getSize(cover), const Size(192, 360));

    final openButton = find.byKey(
      const ValueKey('plumo_recommendation_open_night-train'),
    );
    final favoriteButton = find.byKey(
      const ValueKey('plumo_recommendation_favorite_night-train'),
    );
    final openRect = tester.getRect(openButton);
    final favoriteRect = tester.getRect(favoriteButton);
    expect(openRect.height, 48);
    expect(favoriteRect.height, 48);
    expect(openRect.top, closeTo(favoriteRect.top, 0.1));
    expect(favoriteRect.width, 200);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(430, 900));
    await tester.pumpAndSettle();

    expect(tester.getSize(cover), const Size(180, 264));
    expect(
      tester.getRect(favoriteButton).top,
      greaterThan(tester.getRect(openButton).bottom),
    );
    expect(tester.takeException(), isNull);
  });
}

class _RecommendationTestRepository extends AiRepository {
  _RecommendationTestRepository(this.recommendations)
    : super(AiApiService(Dio()));

  final List<AiRecommendedBookModel> recommendations;

  @override
  Future<List<AiRecommendedBookModel>> recommendBooks(
    AiRecommendationRequest request,
  ) async {
    return recommendations;
  }
}
