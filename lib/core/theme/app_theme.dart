import 'package:flutter/material.dart';

/// Design tokens live here. Screens must use these (or the ambient
/// ColorScheme/TextTheme) — never raw hex values in screens/widgets.
///
/// Page backgrounds are strictly single-colour:
///   light mode -> pure white (0xFFFFFFFF)
///   dark mode  -> pure black (0xFF000000)
class AppTheme {
  static const _seed = Color(0xFF4F6BFF);
  static const _danger = Color(0xFFFF3B30);
  static const _lightBackground = Color(0xFFFFFFFF);
  static const _darkBackground = Color(0xFF000000);

  /// Fixed semantic tokens, identical in both themes.
  static const Color primary = _seed;
  static const Color online = Color(0xFF34C759);
  static const Color offline = Color(0xFF8E8E93);
  static const Color danger = _danger;
  static const Color slate = Color(0xFF6B7280);
  static const Color muted = Color(0xFF9CA3AF);
  static const Color subtleFill = Color(0xFFF3F4F6);
  static const Color darkNavy = Color(0xFF1A1F36);
  static const Color darkSurface = Color(0xFF0E0F2A);

  /// Call surfaces stay dark regardless of app theme.
  static const Color callBackground = _darkBackground;
  static const Color callForeground = Colors.white;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      error: _danger,
      surface: _lightBackground,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightBackground,
      cardColor: _lightBackground,
      canvasColor: _lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: darkNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _lightBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary);
          }
          return const TextStyle(fontSize: 12, color: muted);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightBackground,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: _lightBackground),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: _lightBackground),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      error: _danger,
      surface: _darkBackground,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBackground,
      cardColor: _darkBackground,
      canvasColor: _darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white);
          }
          return const TextStyle(fontSize: 12, color: Colors.white54);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkBackground,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: _darkBackground),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: _darkBackground),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
