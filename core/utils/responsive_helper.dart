import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// NOTE: Most of the responsive logic has been moved to [ThemeContext] in `app_theme.dart`.
/// This file remains for specific utility widgets or logic not covered by context extensions.

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return desktop;
    } else if (context.isTablet && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
