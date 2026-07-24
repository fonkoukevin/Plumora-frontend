import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plumora_app/core/routing/app_router.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/book/data/models/book_model.dart';
import 'package:plumora_app/features/book/data/repositories/book_repository.dart';
import 'package:plumora_app/features/book/data/services/book_api_service.dart';
import 'package:plumora_app/features/writing/presentation/create_book_screen.dart';

/// A reader-only account gets a 403 from the backend when attempting to
/// create a book — this fake reproduces that without a real network call.
class _ForbiddenBookRepository extends BookRepository {
  _ForbiddenBookRepository() : super(BookApiService(Dio()));

  @override
  Future<BookModel> createBook(BookUpsertRequest request) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/books'),
      response: Response(
        requestOptions: RequestOptions(path: '/books'),
        statusCode: 403,
      ),
      type: DioExceptionType.badResponse,
    );
  }
}

void main() {
  testWidgets(
    'a 403 on book creation shows an explicit role message with a link to settings',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: AppRoutes.createBook,
        routes: [
          GoRoute(
            path: AppRoutes.createBook,
            builder: (context, state) =>
                const Scaffold(body: CreateBookScreen()),
          ),
          GoRoute(
            path: AppRoutes.editRoles,
            builder: (context, state) =>
                const Scaffold(body: Text('Écran des rôles')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookRepositoryProvider.overrideWithValue(
              _ForbiddenBookRepository(),
            ),
          ],
          child: MaterialApp.router(
            theme: PlumoraTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Mon histoire');
      await tester.tap(find.text('Fantasy'));
      await tester.pump();

      final submitButton = find.text('Créer et commencer à écrire');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Tu n'as pas les droits pour créer un livre : il te faut le rôle Auteur.",
        ),
        findsOneWidget,
      );
      final settingsLink = find.text('Aller dans les paramètres');
      expect(settingsLink, findsOneWidget);

      await tester.ensureVisible(settingsLink);
      await tester.tap(settingsLink);
      await tester.pumpAndSettle();

      expect(find.text('Écran des rôles'), findsOneWidget);
    },
  );
}
