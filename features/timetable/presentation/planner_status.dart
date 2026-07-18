import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Visual mapping for the seven calendar day states.
class PlannerStatusStyle {
  const PlannerStatusStyle(this.color, this.icon, this.label);
  final Color color;
  final IconData icon;
  final String label;
}

const _empty = PlannerStatusStyle(Color(0xFF94A3B8), LucideIcons.plus, 'Empty');

PlannerStatusStyle plannerStatusStyle(String status) {
  switch (status) {
    case 'Planned':
      return const PlannerStatusStyle(Color(0xFFB7791F), LucideIcons.calendarPlus, 'Planned');
    case 'Draft':
      return const PlannerStatusStyle(Color(0xFFDD6B20), LucideIcons.fileEdit, 'Draft');
    case 'Published':
      return const PlannerStatusStyle(Color(0xFF2F855A), LucideIcons.checkCircle2, 'Published');
    case 'Holiday':
      return const PlannerStatusStyle(Color(0xFFC53030), LucideIcons.ban, 'Holiday');
    case 'Completed':
      return const PlannerStatusStyle(Color(0xFF4A5568), LucideIcons.checkCheck, 'Completed');
    case 'Cancelled':
      return const PlannerStatusStyle(Color(0xFF9CA3AF), LucideIcons.xCircle, 'Cancelled');
    case 'Empty':
    default:
      return _empty;
  }
}
