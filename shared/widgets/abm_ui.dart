import 'dart:math' as math;

import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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
