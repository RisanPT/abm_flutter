import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClassroomCard extends StatelessWidget {
  final String title;
  final int studentCount;
  final VoidCallback onViewStudents;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManageSubjects;
  final VoidCallback? onManageTimetable;

  const ClassroomCard({
    super.key,
    required this.title,
    required this.studentCount,
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewStudents,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(LucideIcons.home, color: colors.primary, size: 24),
                    ),
                    if (onEdit != null || onDelete != null)
                      PopupMenuButton(
                        icon: const Icon(LucideIcons.moreVertical, size: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          if (onManageSubjects != null)
                            const PopupMenuItem(value: 'subjects', child: Text('Define Subjects')),
                          if (onManageTimetable != null)
                            const PopupMenuItem(value: 'timetable', child: Text('Manage Timetable')),
                          if (onDelete != null)
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (val) {
                          if (val == 'edit') onEdit?.call();
                          if (val == 'subjects') onManageSubjects?.call();
                          if (val == 'timetable') onManageTimetable?.call();
                          if (val == 'delete') onDelete?.call();
                        },
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: typography.h3.copyWith(color: const Color(0xFF163D32)),
                ),
                const Gap(4),
                Row(
                  children: [
                    Icon(LucideIcons.users, size: 16, color: colors.secondary),
                    const Gap(6),
                    Text(
                      '$studentCount Students',
                      style: typography.bodyMedium.copyWith(
                        color: const Color(0xFF6F7A75),
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onViewStudents,
                    child: const Text('View Students'),
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
