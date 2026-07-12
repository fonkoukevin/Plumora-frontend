import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeStorage {
  const ThemeModeStorage() : _storage = const FlutterSecureStorage();

  const ThemeModeStorage.withStorage(this._storage);

  static const String _key = 'plumora_theme_mode';

  final FlutterSecureStorage _storage;

  Future<ThemeMode> readThemeMode() async {
    try {
      final raw = await _storage.read(key: _key);
      return switch (raw) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.light,
      };
    } catch (_) {
      return ThemeMode.light;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) {
    return _storage.write(
      key: _key,
      value: mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
