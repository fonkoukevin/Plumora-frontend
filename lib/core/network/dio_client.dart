import 'package:dio/dio.dart';

import '../storage/secure_token_storage.dart';
import 'api_config.dart';

class DioClient {
  DioClient({
    SecureTokenStorage? tokenStorage,
    String? baseUrl,
    List<Interceptor> interceptors = const [],
  }) : dio = Dio(
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
    if (tokenStorage != null) {
      dio.interceptors.add(_JwtInterceptor(tokenStorage));
    }
    dio.interceptors.addAll(interceptors);
  }

  final Dio dio;
}

class _JwtInterceptor extends QueuedInterceptor {
  _JwtInterceptor(this._tokenStorage);

  final SecureTokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}
