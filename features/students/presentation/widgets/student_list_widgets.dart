import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StudentCard extends StatelessWidget {
  final StudentModel student;

  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return InkWell(
      onTap: () {
        context.pushNamed(
          RouteNames.studentProfile,
          pathParameters: {'id': student.id},
          extra: student,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'student_photo_${student.id}',
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                backgroundImage: student.photoUrl?.isNotEmpty == true
                    ? NetworkImage(student.photoUrl!)
                    : null,
                child: student.photoUrl?.isNotEmpty != true
                    ? Text(
                        student.fullName.isEmpty ? '?' : student.fullName[0].toUpperCase(),
                        style: typography.bodyLargeSemiBold.copyWith(color: colors.primary),
                      )
                    : null,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    '${student.admissionNumber} • ${student.classroom}',
                    style: typography.bodySmall.copyWith(color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(8),
            AbmStatusPill.status(context, student.isActive ? 'Active' : 'Inactive'),
            const Gap(6),
            Icon(LucideIcons.chevronRight, color: colors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class StudentSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const StudentSearchField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: typography.bodyMedium.copyWith(color: const Color(0xFF163D32)),
        decoration: InputDecoration(
          hintText: 'Search by name or admission number...',
          hintStyle: typography.bodyMedium.copyWith(color: const Color(0xFF7D857F)),
          prefixIcon: Icon(LucideIcons.search, color: colors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
