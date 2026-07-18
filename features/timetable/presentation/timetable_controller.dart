import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/timetable/data/timetable_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/timetable_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auto-derive academic year from a calendar year + month.
/// If month >= 6 → current year to next year (e.g., 2026-2027).
/// If month < 6  → previous year to current year (e.g., 2025-2026).
String deriveAcademicYear(int year, int month) {
  if (month >= 6) {
    return '$year-${year + 1}';
  } else {
    return '${year - 1}-$year';
  }
}

/// Timetable data for a specific shift + month.
/// Arguments: (shift, year, month, academicYear)
final timetableDataProvider = FutureProvider.family<
    TimetableData,
    ({String shift, int year, int month, String academicYear})>((ref, args) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref.read(timetableRepositoryProvider).getTimetable(
        instituteId,
        args.shift,
        year: args.year,
        month: args.month,
        academicYear: args.academicYear,
      );
});

/// List of dates that have at least one timetable entry scheduled for this month.
/// Used by TimetableScreen to show only actual scheduled dates (not full calendar).
final scheduledDatesProvider = FutureProvider.family<
    List<DateTime>,
    ({String shift, int year, int month, String academicYear})>((ref, args) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref.read(timetableRepositoryProvider).getScheduledDates(
        instituteId,
        args.shift,
        year: args.year,
        month: args.month,
        academicYear: args.academicYear,
      );
});
