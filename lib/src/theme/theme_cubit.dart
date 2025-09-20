import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  static const _key = 'app_theme_mode'; // 'light' | 'dark' | 'system'

  /// Muat preferensi tema saat start
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      switch (raw) {
        case 'light':
          emit(ThemeMode.light);
          break;
        case 'dark':
          emit(ThemeMode.dark);
          break;
        default:
          emit(ThemeMode.system);
      }
    } catch (_) {
      emit(ThemeMode.system);
    }
  }

  /// Alias biar kompatibel kalau kepanggil loadTheme()
  Future<void> loadTheme() => load();

  /// Set & simpan tema
  Future<void> set(ThemeMode mode) async {
    emit(mode);
    try {
      final p = await SharedPreferences.getInstance();
      final v = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
      await p.setString(_key, v);
    } catch (_) {}
  }

  /// Toggle sederhana
  Future<void> toggleDark(bool on) => set(on ? ThemeMode.dark : ThemeMode.light);

  /// Opsional: cycling system -> light -> dark -> system
  Future<void> cycle() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    return set(next);
  }
}
