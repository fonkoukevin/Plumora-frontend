import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  const SecureTokenStorage() : _storage = const FlutterSecureStorage();

  const SecureTokenStorage.withStorage(this._storage);

  static const String _tokenKey = 'plumora_jwt';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() {
    return readToken();
  }

  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveAccessToken(String token) {
    return saveToken(token);
  }

  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearAccessToken() {
    return clearToken();
  }

  Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}
