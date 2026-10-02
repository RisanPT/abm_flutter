import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClassroomCard extends StatelessWidget {
  final String title;
  final int studentCount;
  final String? shift;
  final VoidCallback onViewStudents;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManageSubjects;
  final VoidCallback? onManageTimetable;

  const ClassroomCard({
    super.key,
    required this.title,
    required this.studentCount,
    this.shift,
    required this.onViewStudents,
    this.onEdit,
    this.onDelete,
    this.onManageSubjects,
    this.onManageTimetable,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final hasMenu = onEdit != null || onDelete != null || onManageSubjects != null || onManageTimetable != null;
    // Colour-code by shift so sections group visually at a glance.
    final accent = (shift == 'Shift-2') ? colors.secondary : colors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewStudents,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1 — icon + name + menu (name ellipsizes; menu is the only
                    // fixed trailing item so the row never overflows).
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(LucideIcons.layers, color: accent, size: 21),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            title,
                            style: typography.h4.copyWith(color: const Color(0xFF163D32), fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasMenu)
                          SizedBox(
                            height: 30,
                            width: 26,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Icon(LucideIcons.moreVertical, size: 18, color: colors.textSecondary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              itemBuilder: (context) => [
                                if (onEdit != null)
                                  const PopupMenuItem(value: 'edit', child: _MenuRow(icon: LucideIcons.pencil, label: 'Rename')),
                                if (onManageSubjects != null)
                                  const PopupMenuItem(value: 'subjects', child: _MenuRow(icon: LucideIcons.bookOpen, label: 'Define Subjects')),
                                if (onManageTimetable != null)
                                  const PopupMenuItem(value: 'timetable', child: _MenuRow(icon: LucideIcons.calendarDays, label: 'Manage Timetable')),
                                if (onDelete != null)
                                  const PopupMenuItem(value: 'delete', child: _MenuRow(icon: LucideIcons.trash2, label: 'Delete', danger: true)),
                              ],
                              onSelected: (val) {
                                if (val == 'edit') onEdit?.call();
                                if (val == 'subjects') onManageSubjects?.call();
                                if (val == 'timetable') onManageTimetable?.call();
                                if (val == 'delete') onDelete?.call();
                              },
                            ),
                          ),
                      ],
                    ),
                    const Gap(12),
                    // Row 2 — student count (fills the slack) + shift pill on the right.
                    Row(
                      children: [
                        Icon(LucideIcons.users, size: 14, color: colors.textSecondary),
                        const Gap(5),
                        Expanded(
                          child: Text(
                            studentCount == 1 ? '1 student' : '$studentCount students',
                            style: typography.bodySmall.copyWith(color: colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (shift != null && shift!.isNotEmpty) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: accent.withValues(alpha: 0.22)),
                            ),
                            child: Text(
                              shift!,
                              style: typography.caption.copyWith(color: accent, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Bottom: view students action.
                Material(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onViewStudents,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('View Students',
                              style: typography.bodyMediumSemiBold.copyWith(color: accent)),
                          const Gap(6),
                          Icon(LucideIcons.arrowRight, size: 16, color: accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.danger = false});
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.colors.red : context.colors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const Gap(10),
        Text(label, style: context.typography.bodyMedium.copyWith(color: color)),
      ],
    );
  }
}
