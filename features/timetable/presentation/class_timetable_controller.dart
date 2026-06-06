import 'package:abm_madrasa/features/timetable/data/timetable_repository.dart';
import 'package:abm_madrasa/features/timetable/domain/class_timetable_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'class_timetable_controller.g.dart';

@riverpod
class ClassTimetableController extends _$ClassTimetableController {
  @override
  FutureOr<ClassTimetable> build(String className) async {
    return ref.read(timetableRepositoryProvider).getClassroomTimetable(className);
  }

  Future<void> updateTimetable(List<ClassTimetableEntry> schedule) async {
    final className = this.className;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(timetableRepositoryProvider).updateClassroomTimetable(className, schedule);
      return ref.read(timetableRepositoryProvider).getClassroomTimetable(className);
    });
  }
}
