import 'package:flutter/material.dart';

import 'palette.dart';

class AppTheme {
  const AppTheme._();

  /// Tema utama aplikasi: **dark mode** dengan palet dari moodboard desain.
  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: Palette.sage,
      brightness: Brightness.dark,
    );

    final scheme = base.copyWith(
      primary: Palette.sage,
      onPrimary: Palette.ink,
      primaryContainer: Palette.moss,
      onPrimaryContainer: Palette.mist,
      secondary: Palette.rust,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF7A3810),
      onSecondaryContainer: Color(0xFFFFDBC8),
      tertiary: Palette.info,
      onTertiary: Palette.ink,
      tertiaryContainer: Palette.deep,
      onTertiaryContainer: Palette.mist,
      surface: Palette.ink,
      onSurface: Palette.mist,
      onSurfaceVariant: Palette.mistDim,
      surfaceContainerLowest: Palette.containerLowest,
      surfaceContainerLow: Palette.containerLow,
      surfaceContainer: Palette.container,
      surfaceContainerHigh: Palette.deep,
      surfaceContainerHighest: Palette.containerHighest,
      outline: Palette.outline,
      outlineVariant: Palette.outlineVariant,
      error: Palette.danger,
      onError: Colors.white,
      inverseSurface: Palette.mist,
      onInverseSurface: Palette.ink,
    );

    return _base(scheme, Palette.ink);
  }

  /// Varian terang (opsional, bisa diaktifkan dari Pengaturan).
  static ThemeData light() {
    final base = ColorScheme.fromSeed(seedColor: Palette.moss);
    final scheme = base.copyWith(
      primary: Palette.moss,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFCCDDCC),
      onPrimaryContainer: const Color(0xFF1B2A1B),
      secondary: Palette.rust,
      onSecondary: Colors.white,
      surface: Palette.lightSurface,
      onSurface: Palette.ink,
      onSurfaceVariant: const Color(0xFF55665D),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Palette.lightSurface,
      surfaceContainer: Palette.lightSurfaceVariant,
      surfaceContainerHigh: const Color(0xFFD8E1DA),
      surfaceContainerHighest: const Color(0xFFCFDAD1),
      outline: const Color(0xFF7C8C83),
      outlineVariant: const Color(0xFFC3CFC6),
      error: Palette.danger,
      onError: Colors.white,
    );

    return _base(scheme, Palette.lightSurface);
  }

  static ThemeData _base(ColorScheme scheme, Color background) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 70,
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: 0.22),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: scheme.primary,
        inactiveTrackColor: scheme.outlineVariant,
        valueIndicatorColor: scheme.secondary,
      ),
    );
  }
}
