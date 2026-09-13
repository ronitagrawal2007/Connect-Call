import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme state: light (white) <-> dark (black), persisted.
///
/// Persisted as a bool (`true` = dark) so the choice survives restarts.
/// Defaults to light (white) on first launch.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'is_dark_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider({ThemeMode initial = ThemeMode.light}) : _themeMode = initial;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isLightMode => !isDarkMode;

  /// Load saved choice before the app builds (call in `main()`).
  static Future<ThemeProvider> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_key) ?? false;
      return ThemeProvider(
        initial: isDark ? ThemeMode.dark : ThemeMode.light,
      );
    } catch (_) {
      return ThemeProvider();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, isDarkMode);
    } catch (_) {
      // Persistence is best-effort; theme still applies in-memory.
    }
  }

  Future<void> setDarkMode(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // Normalize `system` to light so every page stays pure white/black.
    final normalized = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    await setDarkMode(normalized == ThemeMode.dark);
  }

  Future<void> toggleTheme() => setDarkMode(!isDarkMode);

  /// Backwards-compat for any legacy int-based value (`theme_mode`).
  Future<void> migrateLegacyIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_key)) return;
      final legacy = prefs.getInt('theme_mode');
      if (legacy == null) return;
      // ThemeMode.values = [system, light, dark]
      final isDark = legacy == ThemeMode.dark.index;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
      await _persist();
    } catch (_) {}
  }
}
