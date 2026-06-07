import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ABMPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottomChild;
  final double? height;
  final bool showBackButton;
  final Widget? instituteBanner;

  const ABMPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottomChild,
    this.height,
    this.showBackButton = true,
    this.instituteBanner,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isMobile = context.isMobile;
    final bool hasBanner = instituteBanner != null;
    final effectiveHeight = height ??
        (hasBanner
            ? (isMobile ? 295.0 : 340.0)
            : (isMobile ? 240.0 : 280.0));

    return Container(
      width: double.infinity,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AbmPatternPainter(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 12 : 20,
                isMobile ? 16 : 24,
                isMobile ? 20 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showBackButton)
                        IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      else if (leading != null)
                        leading!,
                      const Spacer(),
                      if (actions != null) ...actions!,
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: typography.h2.copyWith(color: Colors.white),
                        ),
                        if (subtitle != null) ...[
                          const Gap(4),
                          Text(
                            subtitle!,
                            style: typography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        if (bottomChild != null) ...[
                          const Gap(16),
                          bottomChild!,
                        ],
                      ],
                    ),
                  ),
                  if (instituteBanner != null) ...[
                    const Gap(8),
                    instituteBanner!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
