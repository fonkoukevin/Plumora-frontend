import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_mode_storage.dart';

final themeModeStorageProvider = Provider<ThemeModeStorage>((ref) {
  return const ThemeModeStorage();
});

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light;
  }

  Future<void> _restore() async {
    final saved = await ref.read(themeModeStorageProvider).readThemeMode();
    state = saved;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await ref.read(themeModeStorageProvider).saveThemeMode(next);
  }
}
