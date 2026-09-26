import 'dart:math' as math;

import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// ABM mobile design kit — the green + gold visual language shared across the
/// app. Colours come from the theme (primary = green, secondary/tertiary = gold)
/// so everything stays on-brand and theme-aware.

Color abmGreen(BuildContext c) => c.colors.primary;
Color abmGreenMid(BuildContext c) => Color.lerp(c.colors.primary, Colors.white, 0.16)!;
Color abmGold(BuildContext c) => c.colors.secondary;
Color abmGoldLight(BuildContext c) => c.colors.tertiary;

LinearGradient abmGreenGradient(BuildContext c) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [abmGreen(c), abmGreenMid(c)],
    );

/// Gradient hero header with a rounded bottom. `overlap` reserves space so a
/// card can float over the header's lower edge (Transform.translate).
class AbmGradientHeader extends StatelessWidget {
  const AbmGradientHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.leading,
    this.trailing,
    this.eyebrow,
    this.bottom,
    this.overlap = 0,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? eyebrow;
  final Widget? bottom;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final t = context.typography;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: abmGreenGradient(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        leading != null ? 8 : 20,
        MediaQuery.paddingOf(context).top + 14,
        12,
        20 + overlap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const Gap(6)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null && eyebrow!.isNotEmpty)
                      Text(eyebrow!, style: t.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.75))),
                    Text(title,
                        style: t.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: t.bodySmall.copyWith(color: abmGoldLight(context)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (bottom != null) ...[const Gap(16), bottom!],
        ],
      ),
    );
  }
}

/// Circular white icon button used in headers (over the gradient).
class AbmHeaderIconButton extends StatelessWidget {
  const AbmHeaderIconButton({super.key, required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(9), child: Icon(icon, color: Colors.white, size: 18)),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

/// Rounded white stat tile: tinted icon square, big value, label + optional sub.
class AbmStatTile extends StatelessWidget {
  const AbmStatTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
    this.sub,
    this.onTap,
  });
  final IconData icon;
  final Color tint;
  final String value, label;
  final String? sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: tint, size: 20),
          ),
          const Gap(12),
          Text(value, style: t.h3.copyWith(color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Gap(2),
          Text(label, style: t.bodyMediumSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (sub != null && sub!.isNotEmpty)
            Text(sub!, style: t.bodySmall.copyWith(color: colors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: card);
  }
}

/// White rounded section with an icon + title header and an optional trailing.
class AbmSectionCard extends StatelessWidget {
  const AbmSectionCard({super.key, required this.title, required this.icon, required this.child, this.trailing});
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: abmGreen(context)),
              const Gap(9),
              Expanded(child: Text(title, style: context.typography.bodyLargeSemiBold)),
              ?trailing,
            ],
          ),
          const Gap(12),
          child,
        ],
      ),
    );
  }
}

/// Quick-action tile: coloured icon square + label. Use in a row/grid.
class AbmQuickTile extends StatelessWidget {
  const AbmQuickTile({super.key, required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colors.border)),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(8),
            Text(label, textAlign: TextAlign.center, style: context.typography.bodySmall.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// Lays quick tiles out in rows of [perRow].
class AbmQuickGrid extends StatelessWidget {
  const AbmQuickGrid({super.key, required this.tiles, this.perRow = 4});
  final List<AbmQuickTile> tiles;
  final int perRow;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int row = 0; row < tiles.length; row += perRow) ...[
          if (row > 0) const Gap(12),
          Row(
            children: [
              for (int i = row; i < row + perRow; i++) ...[
                if (i > row) const Gap(12),
                Expanded(child: i < tiles.length ? tiles[i] : const SizedBox()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Progress ring with an optional centre widget.
class AbmRing extends StatelessWidget {
  const AbmRing({super.key, required this.percent, required this.color, this.size = 76, this.stroke = 8, this.center});
  final double percent; // 0..100
  final Color color;
  final double size, stroke;
  final Widget? center;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(percent / 100, color, context.colors.border, stroke),
        child: center != null ? Center(child: center) : null,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.pct, this.color, this.track, this.stroke);
  final double pct;
  final Color color, track;
  final double stroke;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - stroke) / 2;
    final bg = Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = stroke;
    final fg = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * pct.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.pct != pct || o.color != color;
}

/// Custom bottom navigation in the green/gold style. When the item count is odd
/// (3 or 5), the middle item is raised into an elevated green circle.
class AbmNavItemData {
  const AbmNavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class AbmBottomNav extends StatelessWidget {
  const AbmBottomNav({super.key, required this.items, required this.selectedIndex, required this.onTap});
  final List<AbmNavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final centerIndex = items.length.isOdd ? items.length ~/ 2 : -1;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      padding: EdgeInsets.only(top: 8, bottom: 8 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < items.length; i++)
            i == centerIndex ? _center(context, i) : _item(context, i),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, int i) {
    final active = i == selectedIndex;
    final color = active ? abmGreen(context) : context.colors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(items[i].icon, size: 22, color: color),
              const Gap(4),
              Text(items[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.typography.bodySmall.copyWith(color: color, fontSize: 10.5, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _center(BuildContext context, int i) {
    final active = i == selectedIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(i),
        child: Transform.translate(
          offset: const Offset(0, -14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: abmGreenGradient(context),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: abmGreen(context).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  border: Border.all(color: active ? abmGoldLight(context) : Colors.transparent, width: 2),
                ),
                child: Icon(items[i].icon, color: Colors.white, size: 24),
              ),
              const Gap(2),
              Text(items[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.bodySmall.copyWith(color: active ? abmGreen(context) : context.colors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Foundation components (redesign kit) ────────────────────────────────────

/// A small circular initials avatar (tinted). Handy as an [AbmListRow] leading.
Widget abmInitialsAvatar(BuildContext context, String text, {Color? tint, double radius = 18}) {
  final c = tint ?? context.colors.primary;
  final letter = text.trim().isEmpty ? '?' : text.trim()[0].toUpperCase();
  return CircleAvatar(
    radius: radius,
    backgroundColor: c.withValues(alpha: 0.14),
    child: Text(letter, style: context.typography.bodyMediumSemiBold.copyWith(color: c)),
  );
}

/// A coloured status pill (green = good, amber = caution, red = bad, grey = idle).
class AbmStatusPill extends StatelessWidget {
  const AbmStatusPill({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  /// Maps a free-text status to the right semantic colour + label.
  factory AbmStatusPill.status(BuildContext context, String status, {IconData? icon}) {
    final s = status.trim().toLowerCase();
    final colors = context.colors;
    Color c;
    if (['present', 'paid', 'active', 'completed', 'approved', 'done'].contains(s)) {
      c = colors.green;
    } else if (['late', 'partial', 'partially paid', 'pending', 'due soon'].contains(s)) {
      c = colors.warning;
    } else if (['absent', 'due', 'overdue', 'unpaid', 'failed', 'rejected'].contains(s)) {
      c = colors.red;
    } else if (['inactive', 'cancelled', 'canceled', 'waived', 'holiday'].contains(s)) {
      c = colors.textSecondary;
    } else {
      c = colors.primary;
    }
    final label = status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1);
    return AbmStatusPill(label: label, color: c, icon: icon);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const Gap(4)],
          Text(label, style: context.typography.bodySmallSemiBold.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// A scannable list row: leading widget + title/subtitle + optional trailing.
/// Prefer this over chunky cards for dense lists (students, dues, activity…).
class AbmListRow extends StatelessWidget {
  const AbmListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          leading,
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const Gap(2),
                  Text(subtitle!, style: t.bodySmall.copyWith(color: colors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const Gap(10), trailing!],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: row);
  }
}

/// A friendly empty state: icon + title + message + optional call to action.
class AbmEmptyState extends StatelessWidget {
  const AbmEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
            const Gap(14),
            Text(title, textAlign: TextAlign.center,
                style: context.typography.bodyLargeSemiBold.copyWith(color: colors.textPrimary)),
            if (message != null && message!.isNotEmpty) ...[
              const Gap(6),
              Text(message!, textAlign: TextAlign.center,
                  style: context.typography.bodyMedium.copyWith(color: colors.textSecondary)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const Gap(16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A consistent error view with an optional retry.
class AbmErrorView extends StatelessWidget {
  const AbmErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 44, color: colors.red.withValues(alpha: 0.8)),
            const Gap(12),
            Text(message, textAlign: TextAlign.center,
                style: context.typography.bodyMedium.copyWith(color: colors.textSecondary)),
            if (onRetry != null) ...[
              const Gap(16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A page-based pagination control: ‹‹ ‹  Page X of Y  › ››  + a result count.
/// [page] is 1-based. Buttons disable at the bounds and while [loading].
class AbmPaginationBar extends StatelessWidget {
  const AbmPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPage,
    this.loading = false,
  });

  final int page;
  final int totalPages;
  final int total;
  final ValueChanged<int> onPage;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final canPrev = page > 1 && !loading;
    final canNext = page < totalPages && !loading;

    Widget btn(IconData icon, bool enabled, int target, String tip) => IconButton(
          icon: Icon(icon, size: 20),
          tooltip: tip,
          color: colors.primary,
          disabledColor: colors.textSecondary.withValues(alpha: 0.35),
          onPressed: enabled ? () => onPage(target) : null,
          visualDensity: VisualDensity.compact,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          btn(LucideIcons.chevronsLeft, canPrev, 1, 'First page'),
          btn(LucideIcons.chevronLeft, canPrev, page - 1, 'Previous'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Page $page of ${totalPages < 1 ? 1 : totalPages}',
                    style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
          ),
          btn(LucideIcons.chevronRight, canNext, page + 1, 'Next'),
          btn(LucideIcons.chevronsRight, canNext, totalPages, 'Last page'),
        ],
      ),
    );
  }
}
