import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/auth/data/models/role_model.dart';
import 'package:plumora_app/features/auth/data/models/user_model.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/catalog/data/repositories/catalog_repository.dart';
import 'package:plumora_app/features/catalog/presentation/book_detail_screen.dart';
import 'package:plumora_app/features/reading/data/models/report_model.dart';
import 'package:plumora_app/features/reading/data/repositories/favorite_repository.dart';
import 'package:plumora_app/features/reading/data/repositories/report_repository.dart';
import 'package:plumora_app/features/reading/data/repositories/review_repository.dart';
import 'package:plumora_app/features/reading/data/services/report_api_service.dart';
import 'package:plumora_app/features/reading/presentation/report_book_dialog.dart';

class _FakeReportRepository extends ReportRepository {
  _FakeReportRepository({this.error, this.blockUntilCompleted})
    : super(ReportApiService(Dio()));

  /// If set, [createReport] throws this instead of succeeding.
  Object? error;

  /// If set, [createReport] waits on this future before resolving — used to
  /// assert on the in-flight (loading) state.
  Future<void>? blockUntilCompleted;

  int callCount = 0;
  String? createdForBookId;
  ReportCreateRequest? createdRequest;

  @override
  Future<ReportModel> createReport(
    String bookId,
    ReportCreateRequest request,
  ) async {
    callCount++;
    createdForBookId = bookId;
    createdRequest = request;
    if (blockUntilCompleted != null) {
      await blockUntilCompleted;
    }
    if (error != null) {
      throw error!;
    }
    return ReportModel(
      id: 'report-1',
      bookId: bookId,
      reason: request.reason.apiValue,
      status: 'OPEN',
      description: request.description,
    );
  }
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
    roles: [RoleModel(name: 'READER')],
  );
}

/// Pumps a minimal host screen with a single button that opens the report
/// sheet via the real public entry point ([showReportBookDialog]) — mirrors
/// how `book_detail_screen.dart` actually calls it.
Future<void> _pumpSheetHost(
  WidgetTester tester, {
  required ReportRepository repository,
  Size surfaceSize = const Size(800, 1000),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: PlumoraTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showReportBookDialog(context, 'book-1'),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the "Signaler ce livre" action opens the sheet from the book detail screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogBookDetailProvider.overrideWith(
              (ref, id) async => const CatalogBookDetailModel(
                id: 'book-1',
                title: 'La Chambre 314',
                description: 'Un mystère.',
                authorName: 'Idriss Ndao',
              ),
            ),
            favoriteStatusProvider.overrideWith((ref, id) async => false),
            bookReviewsProvider.overrideWith((ref, id) async => []),
            reportRepositoryProvider.overrideWithValue(_FakeReportRepository()),
            authControllerProvider.overrideWith(_AuthenticatedController.new),
          ],
          child: MaterialApp(
            theme: PlumoraTheme.light,
            home: const Scaffold(body: BookDetailScreen(bookId: 'book-1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // authControllerProvider is only read on-demand (inside
      // _openReportDialog), never watched by BookDetailScreen itself — force
      // it to resolve before tapping, otherwise the tap would race a still
      // AsyncLoading state and wrongly treat the reader as unauthenticated.
      ProviderScope.containerOf(
        tester.element(find.byType(BookDetailScreen)),
      ).read(authControllerProvider);
      await tester.pumpAndSettle();

      final reportButton = find.text('Signaler ce livre');
      await tester.ensureVisible(reportButton);
      await tester.tap(reportButton);
      await tester.pumpAndSettle();

      expect(find.text('Signaler ce livre'), findsWidgets);
      expect(
        find.text('Votre signalement sera examiné par un administrateur.'),
        findsOneWidget,
      );
      expect(find.text('Motif'), findsOneWidget);
      for (final reason in ReportReason.values) {
        expect(find.text(reason.label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('submitting without a reason shows a validation error', (
    tester,
  ) async {
    await _pumpSheetHost(tester, repository: _FakeReportRepository());

    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();

    expect(find.text('Choisis un motif de signalement.'), findsOneWidget);
  });

  testWidgets('reason OTHER requires a description of at least 10 characters', (
    tester,
  ) async {
    await _pumpSheetHost(tester, repository: _FakeReportRepository());

    await tester.tap(find.text(ReportReason.other.label));
    await tester.pump();
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();

    expect(
      find.text('Précise ce motif (10 caractères minimum).'),
      findsOneWidget,
    );
  });

  testWidgets('the submit button is disabled and shows a spinner in flight', (
    tester,
  ) async {
    final blocker = Completer<void>();
    final repository = _FakeReportRepository(
      blockUntilCompleted: blocker.future,
    );
    await _pumpSheetHost(tester, repository: repository);

    await tester.tap(find.text(ReportReason.inappropriateContent.label));
    await tester.pump();
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pump();

    expect(find.text('Envoi...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.callCount, 1);

    // A second tap while in flight must not trigger a second call.
    await tester.tap(find.text('Envoi...'), warnIfMissed: false);
    await tester.pump();
    expect(repository.callCount, 1);

    blocker.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'a successful submission sends the right bookId/JSON and closes the sheet',
    (tester) async {
      final repository = _FakeReportRepository();
      await _pumpSheetHost(tester, repository: repository);

      await tester.tap(find.text(ReportReason.plagiarism.label));
      await tester.enterText(
        find.byType(TextField),
        'Ce texte reprend mot pour mot un autre livre.',
      );
      await tester.tap(find.text('Envoyer le signalement'));
      await tester.pumpAndSettle();

      expect(repository.callCount, 1);
      expect(repository.createdForBookId, 'book-1');
      expect(repository.createdRequest?.reason, ReportReason.plagiarism);
      expect(
        repository.createdRequest?.description,
        'Ce texte reprend mot pour mot un autre livre.',
      );
      // The sheet is gone (closed) after success.
      expect(find.text('Envoyer le signalement'), findsNothing);
    },
  );

  testWidgets('Escape closes the sheet without submitting', (tester) async {
    final repository = _FakeReportRepository();
    await _pumpSheetHost(tester, repository: repository);

    expect(find.text('Envoyer le signalement'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Envoyer le signalement'), findsNothing);
    expect(repository.callCount, 0);
  });

  testWidgets('the close (X) button is reachable and labelled for a11y', (
    tester,
  ) async {
    await _pumpSheetHost(tester, repository: _FakeReportRepository());

    final closeButtonFinder = find.bySemanticsLabel('Fermer');
    expect(closeButtonFinder, findsOneWidget);

    final handle = tester.ensureSemantics();
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('Envoyer le signalement'), findsNothing);
    handle.dispose();
  });

  for (final testCase in <(int, String)>[
    (401, 'Votre session a expiré. Veuillez vous reconnecter.'),
    (403, "Vous n'êtes pas autorisé à effectuer cette action."),
    (404, 'Ce livre n\'est plus disponible.'),
    (409, 'Vous avez déjà signalé ce livre.'),
  ]) {
    final (statusCode, expectedMessage) = testCase;
    testWidgets('a $statusCode error shows "$expectedMessage"', (tester) async {
      final repository = _FakeReportRepository(
        error: DioException(
          requestOptions: RequestOptions(path: '/books/book-1/reports'),
          response: Response(
            requestOptions: RequestOptions(path: '/books/book-1/reports'),
            statusCode: statusCode,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      await _pumpSheetHost(tester, repository: repository);

      await tester.tap(find.text(ReportReason.other.label));
      await tester.enterText(
        find.byType(TextField),
        'Un motif suffisamment détaillé.',
      );
      await tester.tap(find.text('Envoyer le signalement'));
      await tester.pumpAndSettle();

      expect(find.text(expectedMessage), findsOneWidget);
      // The sheet stays open so the user can retry.
      expect(find.text('Envoyer le signalement'), findsOneWidget);
    });
  }

  testWidgets('a network error shows the offline-specific message', (
    tester,
  ) async {
    final repository = _FakeReportRepository(
      error: DioException(
        requestOptions: RequestOptions(path: '/books/book-1/reports'),
        type: DioExceptionType.connectionError,
      ),
    );
    await _pumpSheetHost(tester, repository: repository);

    await tester.tap(find.text(ReportReason.harassment.label));
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Impossible de transmettre le signalement. Vérifiez votre connexion.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders without overflow on a narrow (mobile) surface', (
    tester,
  ) async {
    await _pumpSheetHost(
      tester,
      repository: _FakeReportRepository(),
      surfaceSize: const Size(390, 844),
    );

    expect(find.text('Signaler ce livre'), findsOneWidget);
    expect(find.text('Motif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on a wide (desktop) surface', (
    tester,
  ) async {
    await _pumpSheetHost(
      tester,
      repository: _FakeReportRepository(),
      surfaceSize: const Size(1600, 1000),
    );

    expect(find.text('Signaler ce livre'), findsOneWidget);
    expect(find.text('Motif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
