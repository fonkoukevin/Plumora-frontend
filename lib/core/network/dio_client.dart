import 'package:dio/dio.dart';

import 'api_config.dart';

class DioClient {
  DioClient({String? baseUrl, List<Interceptor> interceptors = const []})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    dio.interceptors.addAll(interceptors);
  }

  final Dio dio;
}
