import 'package:abm_madrasa/core/theme/color/color_palatte.dart';
import 'package:abm_madrasa/core/theme/extensions/app_space_extensions.dart';
import 'package:abm_madrasa/core/theme/extensions/color_extension.dart';
import 'package:abm_madrasa/core/theme/extensions/typography_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'package:abm_madrasa/core/theme/extensions/app_space_extensions.dart';
export 'package:abm_madrasa/core/theme/extensions/color_extension.dart';
export 'package:abm_madrasa/core/theme/extensions/typography_extension.dart';

extension ThemeContext on BuildContext {
  ColorExtension get colors {
    return Theme.of(this).extension<ColorExtension>() ?? ColorExtension.light;
  }

  TypographyExtension get typography {
    return Theme.of(this).extension<TypographyExtension>() ?? TypographyExtension.defaultTypography;
  }

  AppSpaceExtension get spaces {
    return Theme.of(this).extension<AppSpaceExtension>() ?? AppSpaceExtension.fromBaseSpace(8);
  }

  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;
}

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: ColorPalette.background,
  extensions: [
    const ColorExtension(
      primary: ColorPalette.primary,
      secondary: ColorPalette.secondary,
      tertiary: ColorPalette.tertiary,
      white: ColorPalette.white,
      black: ColorPalette.black,
      red: ColorPalette.red,
      green: ColorPalette.green,
      yellow: ColorPalette.yellow,
      warning: ColorPalette.warning,
      background: ColorPalette.background,
      cardBackground: ColorPalette.surface,
      textPrimary: ColorPalette.textPrimary,
      textSecondary: ColorPalette.textSecondary,
      accent: ColorPalette.accent,
      border: ColorPalette.border,
    ),
    TypographyExtension(
      h1: GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: ColorPalette.textPrimary,
      ),
      h2: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: ColorPalette.textPrimary,
      ),
      h3: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ColorPalette.textPrimary,
      ),
      h4: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ColorPalette.textPrimary,
      ),
      body: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: ColorPalette.textPrimary,
      ),
      bodySemiBold: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColorPalette.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ColorPalette.textPrimary,
      ),
      bodyMediumSemiBold: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColorPalette.textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ColorPalette.textSecondary,
      ),
      bodySmallSemiBold: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ColorPalette.textPrimary,
      ),
      bodySmallMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ColorPalette.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: ColorPalette.textPrimary,
      ),
      bodyLargeSemiBold: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ColorPalette.textPrimary,
      ),
      bodyLargeMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: ColorPalette.textPrimary,
      ),
      subtitle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: ColorPalette.textPrimary,
      ),
      caption: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ColorPalette.textSecondary,
      ),
      buttonTxt: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      button2: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    AppSpaceExtension.fromBaseSpace(8),
  ],
  
  colorScheme: ColorScheme.light(
    primary: ColorPalette.primary,
    onPrimary: Colors.white,
    secondary: ColorPalette.secondary,
    onSecondary: Colors.white,
    surface: ColorPalette.surface,
    error: ColorPalette.red,
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorPalette.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: ColorPalette.border, width: 1),
    ),
  ),
  
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: ColorPalette.textPrimary,
    ),
    iconTheme: const IconThemeData(color: ColorPalette.textPrimary),
  ),
);

// Dark theme implementation
final darkAppTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: ColorPalette.primary,
  extensions: [
    const ColorExtension(
      primary: ColorPalette.primary,
      secondary: ColorPalette.secondary,
      tertiary: ColorPalette.tertiary,
      white: ColorPalette.white,
      black: ColorPalette.black,
      red: ColorPalette.red,
      green: ColorPalette.green,
      yellow: ColorPalette.yellow,
      warning: ColorPalette.warning,
      background: ColorPalette.primary,
      cardBackground: Color(0xFF1E2E21), // Dark green card
      textPrimary: Colors.white,
      textSecondary: Colors.white70,
      accent: Color(0xFFFFD700),
      border: ColorPalette.border,
    ),
    TypographyExtension(
      h1: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: ColorPalette.white,
      ),
      h2: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: ColorPalette.white,
      ),
      h3: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ColorPalette.white,
      ),
      h4: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ColorPalette.white,
      ),
      body: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: ColorPalette.white,
      ),
      bodySemiBold: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColorPalette.white,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ColorPalette.white,
      ),
      bodyMediumSemiBold: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColorPalette.white,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ColorPalette.white,
      ),
      bodySmallSemiBold: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ColorPalette.white,
      ),
      bodySmallMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ColorPalette.white,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: ColorPalette.white,
      ),
      bodyLargeSemiBold: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ColorPalette.white,
      ),
      bodyLargeMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: ColorPalette.white,
      ),
      subtitle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: ColorPalette.white,
      ),
      caption: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ColorPalette.white,
      ),
      buttonTxt: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColorPalette.primary,
      ),
      button2: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ColorPalette.primary,
      ),
    ),
    AppSpaceExtension.fromBaseSpace(8),
  ],
  colorScheme: ColorScheme.dark(
    primary: ColorPalette.primary,
    secondary: ColorPalette.secondary,
    surface: ColorPalette.primary,
    error: ColorPalette.red,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorPalette.secondary,
      foregroundColor: ColorPalette.primary,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: ColorPalette.white,
    ),
    iconTheme: const IconThemeData(color: ColorPalette.white),
  ),
);
