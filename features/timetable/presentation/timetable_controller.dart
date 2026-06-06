import 'package:abm_madrasa/features/timetable/data/timetable_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/timetable_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timetableDataProvider = FutureProvider<TimetableData>((ref) {
  return ref.read(timetableRepositoryProvider).getTimetable();
});
