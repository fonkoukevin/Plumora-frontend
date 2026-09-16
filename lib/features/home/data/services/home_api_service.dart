import 'package:dio/dio.dart';

import '../models/platform_stats_model.dart';

class HomeApiService {
  const HomeApiService(this._dio);

  final Dio _dio;

  Future<PlatformStatsModel> platformStats() async {
    final response = await _dio.get('/stats/platform');
    return PlatformStatsModel.fromJson(response.data);
  }
}
