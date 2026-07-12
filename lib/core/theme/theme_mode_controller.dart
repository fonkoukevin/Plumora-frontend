import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_mode_storage.dart';

final themeModeStorageProvider = Provider<ThemeModeStorage>((ref) {
  return const ThemeModeStorage();
});

final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.light;
});

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  bool _saving = false;

  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_saving || state == mode) {
      return;
    }

    _saving = true;
    final previous = state;
    state = mode;
    try {
      await ref.read(themeModeStorageProvider).saveThemeMode(mode);
    } catch (_) {
      state = previous;
      rethrow;
    } finally {
      _saving = false;
    }
  }
}
