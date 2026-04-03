// lib/src/styles/colors.dart
import 'package:flutter/material.dart';

/// Original green theme colors.
abstract class ChessPalsColors {
  static const primary = Color(0xFF4CAF50);       // Forest green
  static const primaryDark = Color(0xFF388E3C);
  static const accent = Color(0xFFFF9800);         // Warm orange
  static const surface = Color(0xFFF9FBF2);        // Off-white
  static const onPrimary = Colors.white;
  static const error = Color(0xFFF44336);
  static const success = Color(0xFF66BB6A);
}

/// Watercolor theme colors — derived from the avatar illustrations.
abstract class WatercolorColors {
  static const primary = Color(0xFF8B6B4A);        // Warm brown (avatar borders)
  static const primaryDark = Color(0xFF5C4033);    // Deep brown (eyes/details)
  static const accent = Color(0xFFD4A843);         // Warm gold/honey (bee, giraffe)
  static const surface = Color(0xFFF5ECD7);        // Parchment cream
  static const onPrimary = Colors.white;
  static const error = Color(0xFFB85C4A);          // Soft terracotta red
  static const success = Color(0xFF8BA87A);         // Muted sage green
}
