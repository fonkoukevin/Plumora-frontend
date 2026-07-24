import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/report_model.dart';

class ReportApiService {
  const ReportApiService(this._dio);

  final Dio _dio;

  Future<ReportModel> createReport(
    String bookId,
    ReportCreateRequest request,
  ) async {
    final response = await _dio.post(
      '/books/${Uri.encodeComponent(bookId)}/reports',
      data: request.toJson(),
    );
    return ReportModel.fromJson(_readPayloadMap(response.data));
  }

  Map<String, dynamic> _readPayloadMap(Object? data) {
    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const AppException('La réponse du signalement est invalide.');
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      for (final key in ['data', 'result', 'payload', 'report']) {
        final value = data[key];
        if (value != null) {
          return _unwrap(value);
        }
      }
    }

    return data;
  }
}
