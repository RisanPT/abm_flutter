import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
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
    const cardTitleColor = Color(0xFF163D32);
    const cardSubtleColor = Color(0xFF6F7A75);

    return InkWell(
      onTap: () {
        context.pushNamed(
          RouteNames.studentProfile,
          pathParameters: {'id': student.id},
          extra: student,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'student_photo_${student.id}',
              child: CircleAvatar(
                radius: 30,
                backgroundColor: colors.primary.withValues(alpha: 0.1),
                backgroundImage: student.photoUrl?.isNotEmpty == true
                    ? NetworkImage(student.photoUrl!)
                    : null,
                child: student.photoUrl?.isNotEmpty != true
                    ? Text(
                        student.fullName[0],
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: typography.bodyLargeSemiBold.copyWith(
                      color: cardTitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    '${student.admissionNumber} • ${student.classroom}',
                    style: typography.bodySmall.copyWith(
                      color: cardSubtleColor,
                    ),
                  ),
                  const Gap(8),
                  _StatusTag(isActive: student.isActive),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: cardSubtleColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final bool isActive;
  const _StatusTag({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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
