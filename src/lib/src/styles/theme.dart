// lib/src/styles/theme.dart
import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Toggle this to switch between themes.
/// Set to `true` for the watercolor theme, `false` for the original green theme.
const bool useWatercolorTheme = false;

abstract class ChessPalsTheme {
  static ThemeData get light =>
      useWatercolorTheme ? _watercolor : _classic;

  // ── Original green theme ──────────────────────────────────────────────────

  static ThemeData get _classic => _buildTheme(
        seedColor: ChessPalsColors.primary,
        surface: ChessPalsColors.surface,
        error: ChessPalsColors.error,
        primary: ChessPalsColors.primary,
      );

  // ── Watercolor theme ──────────────────────────────────────────────────────

  static ThemeData get _watercolor => _buildTheme(
        seedColor: WatercolorColors.primary,
        surface: WatercolorColors.surface,
        error: WatercolorColors.error,
        primary: WatercolorColors.primary,
      );

  // ── Shared builder ────────────────────────────────────────────────────────

  static ThemeData _buildTheme({
    required Color seedColor,
    required Color surface,
    required Color error,
    required Color primary,
  }) =>
      ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          surface: surface,
          error: error,
        ),
        scaffoldBackgroundColor: surface,
        textTheme: ChessPalsTypography.textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: ChessPalsTypography.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          elevation: 2,
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      );
}
