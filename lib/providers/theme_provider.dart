// ============================================================
// PROVIDER: TEMA (GELAP / TERANG)
// Pilihan pengguna disimpan di Hive box 'settings'
// sehingga bertahan setelah aplikasi ditutup.
// ============================================================
import 'package:flutter/material.dart';
import 'package:premium_todo/core/theme/app_theme.dart';
import 'package:premium_todo/data/hive_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final HiveRepository _repo;
  ThemeProvider(this._repo);

  /// true = mode gelap, false = mode terang.
  late bool _isDark =
      _repo.getSetting<bool>('isDarkMode', defaultValue: false) ?? false;

  bool get isDark => _isDark;

  Future<void> reloadFromStorage() async {
    _isDark =
        _repo.getSetting<bool>('isDarkMode', defaultValue: false) ?? false;
    notifyListeners();
  }

  ThemeData get theme => _isDark ? AppTheme.dark() : AppTheme.light();

  /// Toggle dan simpan preferensi tema.
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _repo.setSetting('isDarkMode', _isDark);
    notifyListeners();
  }

  /// Set eksplisit (dipakai tombol segmented di halaman Pengaturan).
  Future<void> setDark(bool value) async {
    if (value == _isDark) return;
    _isDark = value;
    await _repo.setSetting('isDarkMode', _isDark);
    notifyListeners();
  }
}
