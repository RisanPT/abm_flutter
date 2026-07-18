import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/timetable/data/timetable_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/class_timetable_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'class_timetable_controller.g.dart';

@riverpod
class ClassTimetableController extends _$ClassTimetableController {
  @override
  FutureOr<ClassTimetable> build(
    String className,
    String shift,
    String academicYear,
    int year,
    int month,
  ) async {
    final instituteId = ref.watch(selectedInstituteProvider).id;
    return ref.read(timetableRepositoryProvider).getClassroomTimetable(
          className,
          instituteId,
          shift,
          year: year,
          month: month,
          academicYear: academicYear,
        );
  }

  Future<void> updateTimetable(List<ClassTimetableEntry> schedule) async {
    final instituteId = ref.read(selectedInstituteProvider).id;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(timetableRepositoryProvider).updateClassroomTimetable(
            className,
            instituteId,
            shift,
            academicYear,
            year,
            month,
            schedule,
          );
      return ref.read(timetableRepositoryProvider).getClassroomTimetable(
            className,
            instituteId,
            shift,
            year: year,
            month: month,
            academicYear: academicYear,
          );
    });
  }
}
