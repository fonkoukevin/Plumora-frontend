import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/report_model.dart';
import '../services/report_api_service.dart';

final reportApiServiceProvider = Provider<ReportApiService>((ref) {
  return ReportApiService(ref.watch(dioProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(reportApiServiceProvider));
});

class ReportRepository {
  const ReportRepository(this._apiService);

  final ReportApiService _apiService;

  Future<ReportModel> createReport(String bookId, ReportCreateRequest request) {
    return _apiService.createReport(bookId, request);
  }
}
