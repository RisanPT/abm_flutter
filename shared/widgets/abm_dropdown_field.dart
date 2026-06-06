import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ABMDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T)? labelMapper;
  final Function(T?) onChanged;
  final Widget? trailing;

  const ABMDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.labelMapper,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 56,
                decoration: BoxDecoration(
                  color: colors.background.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: typography.bodyLarge.copyWith(
                      color: const Color(0xFF163D32),
                    ),
                    items: items
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(labelMapper?.call(item) ?? item.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const Gap(12),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              height: 48,
              width: 48,
              child: trailing!,
            ),
          ),
        ],
      ],
    );
  }
}
