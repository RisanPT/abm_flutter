import 'package:flutter/material.dart';

abstract class ColorPalette {
  static const Color primary = Color(0xFF1B3D2F);
  static const Color secondary = Color(0xFFB8860B);
  static const Color tertiary = Color(0xFFE2B961); // Lighter gold
  static const Color accent = Color(0xFFC0A040); // For highlight
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color red = Color(0xFFD32F2F);
  static const Color green = Color(0xFF2E7D32);
  static const Color yellow = Color(0xFFFFC107);
  static const Color warning = Color(0xFFD6A045);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF2F4F7);
  
  // Neutral colors
  static const Color textPrimary = Color(0xFF1B3D2F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}
