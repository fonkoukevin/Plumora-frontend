import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_token_storage.dart';
import 'dio_client.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return const SecureTokenStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  return DioClient(tokenStorage: tokenStorage).dio;
});
