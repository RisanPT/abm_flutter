import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(16),
          Text(
            value,
            style: typography.h3.copyWith(color: const Color(0xFF163D32)),
          ),
          Text(
            label,
            style: typography.bodySmall.copyWith(
              color: const Color(0xFF6F7A75),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const InfoSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const Gap(12),
              Expanded(
                child: Text(
                  title,
                  style: typography.bodyLargeSemiBold.copyWith(
                    color: const Color(0xFF163D32),
                  ),
                ),
              ),
            ],
          ),
          const Gap(20),
          ...children,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({super.key, required this.label, required this.value, this.valueColor});


  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final titleColor = const Color(0xFF163D32);
    final subtleColor = const Color(0xFF6F7A75);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: context.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: typography.bodyMedium.copyWith(color: subtleColor),
                ),
                const Gap(6),
                Text(
                  value,
                  style: typography.bodyLargeMedium.copyWith(color: valueColor ?? titleColor),
                ),

              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: typography.bodyMedium.copyWith(color: subtleColor),
                ),
                const Gap(16),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: typography.bodyLargeMedium.copyWith(color: valueColor ?? titleColor),
                  ),

                ),
              ],
            ),
    );
  }
}
