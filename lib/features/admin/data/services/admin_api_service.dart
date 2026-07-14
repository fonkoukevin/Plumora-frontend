import 'package:dio/dio.dart';

import '../models/admin_ai_status_model.dart';
import '../models/admin_book_model.dart';
import '../models/admin_dashboard_model.dart';
import '../models/admin_import_result_model.dart';
import '../models/admin_report_model.dart';
import '../models/admin_user_model.dart';

class AdminApiService {
  const AdminApiService(this._dio);

  final Dio _dio;

  Future<AdminDashboardStats> getDashboard() async {
    final response = await _dio.get('/admin/dashboard');
    return AdminDashboardStats.fromJson(response.data);
  }

  Future<List<AdminUser>> getUsers({
    String? query,
    String? role,
    String? status,
  }) async {
    final response = await _dio.get(
      '/admin/users',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        'role': ?role,
        'status': ?status,
      },
    );
    return _readList(response.data).map(AdminUser.fromJson).toList();
  }

  Future<AdminUser> getUserDetail(String userId) async {
    final response = await _dio.get(
      '/admin/users/${Uri.encodeComponent(userId)}',
    );
    return AdminUser.fromJson(response.data);
  }

  Future<AdminUser> updateUserStatus(
    String userId,
    AdminUserStatus status, {
    String? reason,
  }) async {
    final response = await _dio.patch(
      '/admin/users/${Uri.encodeComponent(userId)}/status',
      data: {
        'status': status.apiValue,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return AdminUser.fromJson(response.data);
  }

  Future<AdminUser> updateUserRole(String userId, List<String> roles) async {
    final response = await _dio.patch(
      '/admin/users/${Uri.encodeComponent(userId)}/role',
      data: {'roles': roles},
    );
    return AdminUser.fromJson(response.data);
  }

  Future<List<AdminBook>> getBooks({
    String? query,
    String? type,
    String? status,
  }) async {
    final response = await _dio.get(
      '/admin/books',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        'type': ?type,
        'status': ?status,
      },
    );
    return _readList(response.data).map(AdminBook.fromJson).toList();
  }

  Future<AdminBook> getBookDetail(String bookId) async {
    final response = await _dio.get(
      '/admin/books/${Uri.encodeComponent(bookId)}',
    );
    return AdminBook.fromJson(response.data);
  }

  Future<AdminBook> updateBookStatus(
    String bookId,
    String status, {
    String? reason,
  }) async {
    final response = await _dio.patch(
      '/admin/books/${Uri.encodeComponent(bookId)}/status',
      data: {
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return AdminBook.fromJson(response.data);
  }

  Future<AdminBook> updateBookMetadata(
    String bookId, {
    String? title,
    List<String>? authors,
    String? summary,
    List<String>? subjects,
    List<String>? languages,
    String? coverUrl,
  }) async {
    final response = await _dio.patch(
      '/admin/books/${Uri.encodeComponent(bookId)}/metadata',
      data: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'authors': ?authors,
        'summary': ?summary,
        'subjects': ?subjects,
        'languages': ?languages,
        if (coverUrl != null && coverUrl.trim().isNotEmpty)
          'coverUrl': coverUrl.trim(),
      },
    );
    return AdminBook.fromJson(response.data);
  }

  Future<AdminImportResult> importGutendexBook(int gutendexId) async {
    final response = await _dio.post(
      '/admin/books/import/gutendex/$gutendexId',
    );
    return AdminImportResult.fromJson(response.data);
  }

  Future<List<AdminReport>> getReports() async {
    final response = await _dio.get('/admin/reports');
    return _readList(response.data).map(AdminReport.fromJson).toList();
  }

  Future<AdminReport> getReportDetail(String reportId) async {
    final response = await _dio.get(
      '/admin/reports/${Uri.encodeComponent(reportId)}',
    );
    return AdminReport.fromJson(response.data);
  }

  Future<AdminReport> resolveReport(String reportId, {String? reason}) async {
    final response = await _dio.patch(
      '/admin/reports/${Uri.encodeComponent(reportId)}/resolve',
      data: reason != null && reason.trim().isNotEmpty
          ? {'reason': reason.trim()}
          : null,
    );
    return AdminReport.fromJson(response.data);
  }

  Future<AdminReport> rejectReport(String reportId, {String? reason}) async {
    final response = await _dio.patch(
      '/admin/reports/${Uri.encodeComponent(reportId)}/reject',
      data: reason != null && reason.trim().isNotEmpty
          ? {'reason': reason.trim()}
          : null,
    );
    return AdminReport.fromJson(response.data);
  }

  /// The generic status-update endpoint (not `/admin/**`, but still
  /// ADMIN-only server-side) — used only for "mark as in review" since the
  /// dedicated `/admin/reports/{id}/resolve|reject` cover the other two
  /// transitions the product actually asks admins to make.
  Future<AdminReport> markReportInReview(String reportId) async {
    final response = await _dio.patch(
      '/reports/${Uri.encodeComponent(reportId)}/status',
      data: {'status': 'IN_REVIEW'},
    );
    return AdminReport.fromJson(response.data);
  }

  Future<AdminAiStatus> getAiStatus() async {
    final response = await _dio.get('/admin/ai/status');
    return AdminAiStatus.fromJson(response.data);
  }

  Future<AdminAiStatus> updateAiSettings(bool enabled, {String? reason}) async {
    final response = await _dio.patch(
      '/admin/ai/settings',
      data: {
        'enabled': enabled,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return AdminAiStatus.fromJson(response.data);
  }

  List<Object?> _readList(Object? data) {
    if (data is List) {
      return data;
    }
    if (data is Map) {
      for (final key in ['content', 'items', 'data', 'results']) {
        final value = data[key];
        if (value is List) {
          return value;
        }
      }
    }
    return const [];
  }
}
