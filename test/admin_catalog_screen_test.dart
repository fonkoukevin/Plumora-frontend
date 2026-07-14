import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:plumora_app/core/routing/app_router.dart';
import 'package:plumora_app/core/widgets/plumora_ui.dart';
import 'package:plumora_app/features/admin/data/models/admin_book_model.dart';
import 'package:plumora_app/features/admin/data/models/admin_dashboard_model.dart';
import 'package:plumora_app/features/admin/data/repositories/admin_repository.dart';
import 'package:plumora_app/features/admin/presentation/admin_catalog_screen.dart';
import 'package:plumora_app/features/admin/presentation/admin_route_guard.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  testWidgets('admin catalog follows the compact mobile card layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(345, 823));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: AppRoutes.adminCatalog,
      routes: [
        GoRoute(
          path: AppRoutes.adminCatalog,
          builder: (context, state) => const AdminCatalogScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          adminDashboardProvider.overrideWith(
            (ref) async => const AdminDashboardStats(
              totalUsers: 0,
              activeUsers: 0,
              totalBooks: 2,
              plumoraBooks: 1,
              publicDomainBooks: 1,
              pendingReports: 0,
              resolvedReports: 0,
              archivedBooks: 0,
              aiCallsCount: 0,
            ),
          ),
          adminBooksProvider.overrideWith(
            (ref) async => const [
              AdminBook(
                id: 'book-1',
                title: 'La Nuit Rouge',
                type: AdminBookType.plumoraWork,
                status: 'PUBLISHED',
                authors: ['Kevin Moreau'],
              ),
              AdminBook(
                id: 'book-2',
                title: "Sang d'Encre",
                type: AdminBookType.plumoraWork,
                status: 'PUBLISHED',
                authors: ['Kevin Moreau'],
                reportsCount: 4,
              ),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 œuvres au total'), findsOneWidget);
    expect(find.text('Œuvres Plumora'), findsOneWidget);
    expect(find.text('La Nuit Rouge'), findsOneWidget);
    expect(find.text('Publié'), findsOneWidget);
    expect(find.text('Signalé'), findsOneWidget);
    expect(find.text('4 signalements'), findsOneWidget);
    expect(find.text('Détail'), findsNWidgets(2));
    expect(find.text('Archiver'), findsNWidgets(2));
    expect(find.text('Déconnexion'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);

    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.decoration?.filled, isTrue);
    expect(searchField.decoration?.prefixIcon, isA<Icon>());
    expect(searchField.decoration?.border, isA<OutlineInputBorder>());
    expect(
      tester.getCenter(find.text('Archivés')).dy,
      closeTo(tester.getCenter(find.byType(TextField)).dy, 3),
    );
    expect(tester.takeException(), isNull);
  });

  test('admin routes remain restricted to ADMIN accounts', () {
    expect(
      AdminRouteGuard.redirect(
        location: AppRoutes.adminCatalog,
        isAuthenticated: false,
        roleNames: const [],
      ),
      AppRoutes.login,
    );
    expect(
      AdminRouteGuard.redirect(
        location: AppRoutes.adminCatalog,
        isAuthenticated: true,
        roleNames: const ['READER'],
      ),
      AppRoutes.adminAccessDenied,
    );
    expect(
      AdminRouteGuard.redirect(
        location: AppRoutes.adminCatalog,
        isAuthenticated: true,
        roleNames: const ['ADMIN'],
      ),
      isNull,
    );
  });

  test('admin book covers accept backend aliases and relative URLs', () {
    final book = AdminBook.fromJson(const {
      'id': 'book-cover',
      'title': 'Livre illustré',
      'type': 'PLUMORA_WORK',
      'status': 'PUBLISHED',
      'coverImageUrl': 'uploads/book-covers/illustration.jpg',
    });

    expect(book.coverUrl, 'uploads/book-covers/illustration.jpg');
    expect(
      resolvePlumoraImageUrl(book.coverUrl),
      'http://localhost:8080/api/v1/uploads/book-covers/illustration.jpg',
    );
  });
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}
