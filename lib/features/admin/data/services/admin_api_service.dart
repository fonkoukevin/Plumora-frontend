import 'package:dio/dio.dart';

import '../../../book/data/models/book_model.dart';
import '../models/admin_report_model.dart';
import '../models/admin_user_model.dart';

class AdminApiService {
  const AdminApiService(this._dio);

  final Dio _dio;

  Future<List<AdminUser>> getUsers() async {
    final response = await _dio.get('/admin/users');
    return _readList(response.data).map(AdminUser.fromJson).toList();
  }

  Future<AdminUser> disableUser(String userId) async {
    final response = await _dio.patch('/admin/users/${Uri.encodeComponent(userId)}/disable');
    return AdminUser.fromJson(response.data);
  }

  Future<AdminUser> enableUser(String userId) async {
    final response = await _dio.patch('/admin/users/${Uri.encodeComponent(userId)}/enable');
    return AdminUser.fromJson(response.data);
  }

  Future<List<BookModel>> getBooks() async {
    final response = await _dio.get('/admin/books');
    return _readList(response.data).map(BookModel.fromJson).toList();
  }

  Future<BookModel> archiveBook(String bookId) async {
    final response = await _dio.patch('/admin/books/${Uri.encodeComponent(bookId)}/archive');
    return BookModel.fromJson(response.data);
  }

  Future<List<AdminReport>> getReports() async {
    final response = await _dio.get('/admin/reports');
    return _readList(response.data).map(AdminReport.fromJson).toList();
  }

  Future<AdminReport> updateReportStatus(
    String reportId,
    AdminReportStatus status,
  ) async {
    final response = await _dio.patch(
      '/reports/${Uri.encodeComponent(reportId)}/status',
      data: {'status': status.apiValue},
    );
    return AdminReport.fromJson(response.data);
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
