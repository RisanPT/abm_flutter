import 'package:flutter/material.dart';

class ColorExtension extends ThemeExtension<ColorExtension> {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color white;
  final Color black;
  final Color red;
  final Color green;
  final Color yellow;
  final Color warning;
  final Color background;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color border;

  static const ColorExtension light = ColorExtension(
    primary: Color(0xFF1B3D2F),
    secondary: Color(0xFFB8860B),
    tertiary: Color(0xFFE2B961),
    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
    red: Color(0xFFD32F2F),
    green: Color(0xFF2E7D32),
    yellow: Color(0xFFFFC107),
    warning: Color(0xFFD6A045),
    background: Color(0xFFF2F4F7),
    cardBackground: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1B3D2F),
    textSecondary: Color(0xFF6B7280),
    accent: Color(0xFFC0A040),
    border: Color(0xFFE5E7EB),
  );

  const ColorExtension({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.white,
    required this.black,
    required this.red,
    required this.green,
    required this.yellow,
    required this.warning,
    required this.background,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.border,
  });

  @override
  ThemeExtension<ColorExtension> copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? white,
    Color? black,
    Color? red,
    Color? green,
    Color? yellow,
    Color? warning,
    Color? background,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? border,
  }) {
    return ColorExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      white: white ?? this.white,
      black: black ?? this.black,
      red: red ?? this.red,
      green: green ?? this.green,
      yellow: yellow ?? this.yellow,
      warning: warning ?? this.warning,
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      border: border ?? this.border,
    );
  }

  @override
  ThemeExtension<ColorExtension> lerp(
      covariant ThemeExtension<ColorExtension>? other, double t) {
    if (other is! ColorExtension) {
      return this;
    }
    return ColorExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      white: Color.lerp(white, other.white, t)!,
      black: Color.lerp(black, other.black, t)!,
      red: Color.lerp(red, other.red, t)!,
      green: Color.lerp(green, other.green, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      background: Color.lerp(background, other.background, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
