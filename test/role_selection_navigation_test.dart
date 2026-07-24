import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/routing/app_router.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/core/storage/secure_token_storage.dart';
import 'package:plumora_app/features/auth/data/models/role_model.dart';
import 'package:plumora_app/features/auth/data/models/user_model.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/data/services/auth_api_service.dart';
import 'package:plumora_app/features/auth/data/services/google_auth_service.dart';
import 'package:plumora_app/features/book/data/models/book_model.dart';
import 'package:plumora_app/features/book/data/repositories/book_repository.dart';
import 'package:plumora_app/features/book/data/services/book_api_service.dart';

/// Uses the *real* app_router.dart and the *real* AuthController (only its
/// network-facing dependency is faked), so the real state transitions /
/// refreshListenable behavior run exactly as in production. Regression test
/// for a bug where AuthController.updateRoles() — which cycles through
/// AsyncLoading/AsyncData without changing auth status at all — made
/// go_router's refreshListenable re-run the redirect mid-navigation, and
/// the router's own idea of the current location snapped back to the
/// previous screen before this screen's own context.pop() could run,
/// leaving the stale role-selection screen on screen. Fixed by only
/// notifying refreshListenable when authentication/admin status actually
/// changes (see _AuthRedirectRefresh in app_router.dart).
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        apiService: AuthApiService(Dio()),
        tokenStorage: const SecureTokenStorage(),
        googleAuthService: GoogleAuthService(),
      );

  List<RoleModel> roles = const [RoleModel(name: 'READER')];

  @override
  Future<AuthSession> restoreSession() async => AuthSession(
    user: const UserModel(
      id: 'user-1',
      firstname: 'Ada',
      lastname: 'Lovelace',
      email: 'ada@example.com',
    ),
    roles: roles,
  );

  @override
  Future<List<RoleModel>> updateRoles(List<String> roleNames) async {
    roles = roleNames.map((name) => RoleModel(name: name)).toList();
    return roles;
  }
}

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
    'saving roles from the create-book permission link returns to create-book without bouncing back',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          bookRepositoryProvider.overrideWithValue(_ForbiddenBookRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              theme: PlumoraTheme.light,
              routerConfig: ref.watch(appRouterProvider),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate straight to the create-book screen, like a signed-in reader
      // clicking "Écrire" would.
      container.read(appRouterProvider).go(AppRoutes.createBook);
      await tester.pumpAndSettle();
      expect(find.text('Nouvelle histoire'), findsOneWidget);

      // Trigger the 403 by attempting to create a book.
      await tester.enterText(find.byType(TextField).first, 'Mon histoire');
      await tester.tap(find.text('Fantasy'));
      await tester.pump();
      final submitButton = find.text('Créer et commencer à écrire');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      final settingsLink = find.text('Aller dans les paramètres');
      expect(settingsLink, findsOneWidget, reason: '403 error should show');
      await tester.ensureVisible(settingsLink);
      await tester.tap(settingsLink);
      await tester.pumpAndSettle();

      expect(
        find.text('Modifier mes rôles'),
        findsOneWidget,
        reason: 'should have navigated to the edit-roles screen',
      );

      // Add AUTHOR to the pre-filled READER role, then save.
      await tester.tap(find.text('Auteur'));
      await tester.pump();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(
        find.text('Modifier mes rôles'),
        findsNothing,
        reason:
            'after saving, the app should have navigated away from the '
            'edit-roles screen, not stayed on (or bounced back to) it',
      );
      expect(find.text('Nouvelle histoire'), findsOneWidget);
    },
  );
}
