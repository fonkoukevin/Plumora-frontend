import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/admin_ai_status_model.dart';
import '../models/admin_book_model.dart';
import '../models/admin_dashboard_model.dart';
import '../models/admin_import_result_model.dart';
import '../models/admin_report_model.dart';
import '../models/admin_user_model.dart';
import '../services/admin_api_service.dart';

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService(ref.watch(dioProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(adminApiServiceProvider));
});

final adminDashboardProvider = FutureProvider<AdminDashboardStats>((ref) {
  return ref.watch(adminRepositoryProvider).getDashboard();
});

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) {
  return ref.watch(adminRepositoryProvider).getUsers();
});

final adminBooksProvider = FutureProvider<List<AdminBook>>((ref) {
  return ref.watch(adminRepositoryProvider).getBooks();
});

final adminReportsProvider = FutureProvider<List<AdminReport>>((ref) {
  return ref.watch(adminRepositoryProvider).getReports();
});

final adminAiStatusProvider = FutureProvider<AdminAiStatus>((ref) {
  return ref.watch(adminRepositoryProvider).getAiStatus();
});

class AdminRepository {
  const AdminRepository(this._apiService);

  final AdminApiService _apiService;

  Future<AdminDashboardStats> getDashboard() => _apiService.getDashboard();

  Future<List<AdminUser>> getUsers() => _apiService.getUsers();

  Future<AdminUser> getUserDetail(String userId) =>
      _apiService.getUserDetail(userId);

  Future<AdminUser> setUserActive(
    String userId,
    bool active, {
    String? reason,
  }) {
    return _apiService.updateUserStatus(
      userId,
      active ? AdminUserStatus.active : AdminUserStatus.disabled,
      reason: reason,
    );
  }

  Future<AdminUser> updateUserRole(String userId, String role) {
    return _apiService.updateUserRole(userId, [role]);
  }

  Future<List<AdminBook>> getBooks() => _apiService.getBooks();

  Future<AdminBook> getBookDetail(String bookId) =>
      _apiService.getBookDetail(bookId);

  Future<AdminBook> archiveBook(String bookId, {String? reason}) {
    return _apiService.updateBookStatus(bookId, 'ARCHIVED', reason: reason);
  }

  Future<AdminBook> restoreBook(String bookId) {
    return _apiService.updateBookStatus(bookId, 'PUBLISHED');
  }

  Future<List<AdminReport>> getReports() => _apiService.getReports();

  Future<AdminReport> resolveReport(String reportId, {String? reason}) {
    return _apiService.resolveReport(reportId, reason: reason);
  }

  Future<AdminReport> rejectReport(String reportId, {String? reason}) {
    return _apiService.rejectReport(reportId, reason: reason);
  }

  Future<AdminReport> markReportInReview(String reportId) {
    return _apiService.markReportInReview(reportId);
  }

  Future<AdminAiStatus> getAiStatus() => _apiService.getAiStatus();

  Future<AdminAiStatus> updateAiSettings(bool enabled, {String? reason}) {
    return _apiService.updateAiSettings(enabled, reason: reason);
  }

  Future<AdminImportResult> importGutendexBook(int gutendexId) {
    return _apiService.importGutendexBook(gutendexId);
  }
}
