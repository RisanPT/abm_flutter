import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/notifications/presentation/bug_report.dart';
import 'package:abm_madrasa/features/notifications/presentation/notification_bell.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// When true, the header hosts the app-wide actions (report-a-bug + the
  /// notification bell) on its right, so the shell no longer needs to float them
  /// over the screen. Off by default until every screen adopts this header.
  final bool globalActions;

  /// When true, uses a space-efficient single-row layout where title/subtitle
  /// sit on the left and actions sit on the right, keeping height around 115-125px.
  final bool compact;

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
    this.globalActions = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final isMobile = context.isMobile;
    final bool hasBanner = instituteBanner != null;
    final bool hasBottomChild = bottomChild != null;
    final effectiveHeight = height ??
        (compact
            ? (isMobile ? 115.0 : 125.0)
            : (hasBanner
                ? (hasBottomChild ? (isMobile ? 350.0 : 390.0) : (isMobile ? 295.0 : 340.0))
                : (hasBottomChild ? (isMobile ? 290.0 : 315.0) : (isMobile ? 240.0 : 280.0))));

    return Container(
      width: double.infinity,
      height: effectiveHeight,
      decoration: BoxDecoration(
        gradient: abmGreenGradient(context),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(compact ? 24 : 40)),
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
                compact ? (isMobile ? 10 : 14) : (isMobile ? 12 : 20),
                isMobile ? 16 : 24,
                compact ? (isMobile ? 12 : 16) : (isMobile ? 20 : 24),
              ),
              child: compact
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (showBackButton) ...[
                          IconButton(
                            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                            onPressed: () => Navigator.of(context).maybePop(),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Gap(8),
                        ] else if (leading case final widget?) ...[
                          widget,
                          const Gap(8),
                        ] else if (isMobile) ...[
                          const SizedBox(width: 48),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: (isMobile ? typography.h3 : typography.h2).copyWith(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null) ...[
                                const Gap(2),
                                Text(
                                  subtitle!,
                                  style: typography.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (actions != null && actions!.isNotEmpty) ...[
                          const Gap(12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          ),
                          if (!globalActions) Gap(isMobile ? 120 : 156),
                        ] else if (!globalActions && isMobile) ...[
                          const SizedBox(width: 100),
                        ],
                        if (globalActions) ...[
                          const Gap(8),
                          const _HeaderGlobalActions(),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (showBackButton)
                              IconButton(
                                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                                onPressed: () => Navigator.of(context).maybePop(),
                              )
                            else if (leading == null && isMobile)
                              const SizedBox(width: 48)
                            else
                              ?leading,
                            const Spacer(),
                            ...?actions,
                            if (globalActions) ...[
                              if (actions != null && actions!.isNotEmpty) const Gap(4),
                              const _HeaderGlobalActions(),
                            ] else if (actions != null && actions!.isNotEmpty) ...[
                              Gap(isMobile ? 120 : 156),
                            ],
                          ],
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: (isMobile ? typography.h3 : typography.h2)
                                          .copyWith(color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (subtitle != null) ...[
                                      const Gap(4),
                                      Text(
                                        subtitle!,
                                        style: typography.bodyMedium.copyWith(
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (bottomChild != null) ...[
                                Gap(isMobile ? 12 : 16),
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

/// The app-wide header actions (report-a-bug + notification bell), rendered on a
/// coloured header. Used by [ABMPageHeader] when `globalActions` is on.
class _HeaderGlobalActions extends ConsumerWidget {
  const _HeaderGlobalActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AbmHeaderIconButton(
          icon: LucideIcons.bug,
          tooltip: 'Report a bug',
          onTap: () => showBugReportDialog(context, ref),
        ),
        const Gap(6),
        const NotificationBell(),
      ],
    );
  }
}
