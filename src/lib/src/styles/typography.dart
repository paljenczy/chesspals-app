// lib/src/styles/typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class ChessPalsTypography {
  static TextTheme get textTheme => GoogleFonts.nunitoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 13),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
}
