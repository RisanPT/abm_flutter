import 'package:abm_madrasa/core/theme/extensions/app_space_extensions.dart';
import 'package:abm_madrasa/core/theme/extensions/typography_extension.dart';
import 'package:abm_madrasa/core/theme/extensions/color_extension.dart';
import 'package:flutter/material.dart';

extension ThemeExtension on BuildContext {
  ColorExtension get colors {
    final extension = Theme.of(this).extension<ColorExtension>();
    if (extension == null) {
      throw Exception('ColorExtension not found in theme');
    }
    return extension;
  }

  TypographyExtension get typography {
    final extension = Theme.of(this).extension<TypographyExtension>();
    if (extension == null) {
      throw Exception('TypographyExtension not found in theme');
    }
    return extension;
  }

  AppSpaceExtension get space {
    final extension = Theme.of(this).extension<AppSpaceExtension>();
    if (extension == null) {
      throw Exception('AppSpaceExtension not found in theme');
    }
    return extension;
  }

  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;
}
