import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../book/data/models/book_model.dart';
import '../models/admin_report_model.dart';
import '../models/admin_user_model.dart';
import '../services/admin_api_service.dart';

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService(ref.watch(dioProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(adminApiServiceProvider));
});

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) {
  return ref.watch(adminRepositoryProvider).getUsers();
});

final adminBooksProvider = FutureProvider<List<BookModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getBooks();
});

final adminReportsProvider = FutureProvider<List<AdminReport>>((ref) {
  return ref.watch(adminRepositoryProvider).getReports();
});

/// Dashboard metrics computed client-side from the three real admin list
/// endpoints — the backend has no `/admin/dashboard` endpoint today, so this
/// deliberately avoids inventing numbers that can't be backed by real data
/// (see [AdminDashboardStats] for exactly what is and isn't available).
final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((
  ref,
) async {
  final users = await ref.watch(adminUsersProvider.future);
  final books = await ref.watch(adminBooksProvider.future);
  final reports = await ref.watch(adminReportsProvider.future);

  final activeUsers = users.where((user) => user.active).length;
  final publishedPlumoraWorks = books
      .where((book) => !book.isPublicDomain && !book.isArchived)
      .length;
  final publicDomainBooks = books.where((book) => book.isPublicDomain).length;
  final archivedBooks = books.where((book) => book.isArchived).length;
  final pendingReports = reports
      .where((report) => report.status == AdminReportStatus.open)
      .length;

  final activity = <AdminActivityItem>[
    for (final book in books)
      if (book.createdAt != null)
        AdminActivityItem(
          label: book.isPublicDomain
              ? 'Livre importé : ${book.title}'
              : 'Livre créé : ${book.title}',
          date: book.createdAt!,
          kind: AdminActivityKind.book,
        ),
    for (final report in reports)
      if (report.createdAt != null)
        AdminActivityItem(
          label: 'Signalement reçu : ${report.bookTitle ?? report.reason}',
          date: report.createdAt!,
          kind: AdminActivityKind.report,
        ),
  ]..sort((a, b) => b.date.compareTo(a.date));

  return AdminDashboardStats(
    totalUsers: users.length,
    activeUsers: activeUsers,
    publishedPlumoraWorks: publishedPlumoraWorks,
    publicDomainBooks: publicDomainBooks,
    archivedBooks: archivedBooks,
    pendingReports: pendingReports,
    recentActivity: activity.take(8).toList(growable: false),
  );
});

class AdminRepository {
  const AdminRepository(this._apiService);

  final AdminApiService _apiService;

  Future<List<AdminUser>> getUsers() => _apiService.getUsers();

  Future<AdminUser> setUserActive(String userId, bool active) {
    return active
        ? _apiService.enableUser(userId)
        : _apiService.disableUser(userId);
  }

  Future<List<BookModel>> getBooks() => _apiService.getBooks();

  Future<BookModel> archiveBook(String bookId) =>
      _apiService.archiveBook(bookId);

  Future<List<AdminReport>> getReports() => _apiService.getReports();

  Future<AdminReport> resolveReport(String reportId) {
    return _apiService.updateReportStatus(reportId, AdminReportStatus.resolved);
  }

  Future<AdminReport> rejectReport(String reportId) {
    return _apiService.updateReportStatus(
      reportId,
      AdminReportStatus.dismissed,
    );
  }

  Future<AdminReport> markReportInReview(String reportId) {
    return _apiService.updateReportStatus(
      reportId,
      AdminReportStatus.inReview,
    );
  }
}

enum AdminActivityKind { book, report }

class AdminActivityItem {
  const AdminActivityItem({
    required this.label,
    required this.date,
    required this.kind,
  });

  final String label;
  final DateTime date;
  final AdminActivityKind kind;
}

/// Metrics genuinely backed by the admin API today. Fields the mockup shows
/// but the backend can't supply yet (Plumo AI call volume, an admin action
/// audit log) are intentionally left out rather than faked — see the
/// dashboard screen for how that's communicated in the UI.
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.publishedPlumoraWorks,
    required this.publicDomainBooks,
    required this.archivedBooks,
    required this.pendingReports,
    required this.recentActivity,
  });

  final int totalUsers;
  final int activeUsers;
  final int publishedPlumoraWorks;
  final int publicDomainBooks;
  final int archivedBooks;
  final int pendingReports;
  final List<AdminActivityItem> recentActivity;
}
