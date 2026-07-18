import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/students/data/classroom_repository.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'classroom_controller.g.dart';

@riverpod
class ClassroomController extends _$ClassroomController {
  @override
  FutureOr<List<ClassroomModel>> build() async {
    final institute = ref.watch(selectedInstituteProvider);
    return ref.read(classroomRepositoryProvider).getClassrooms(instituteId: institute.id);
  }

  Future<void> addClassroom(String name, {String? description, String shift = 'Shift-1'}) async {
    final institute = ref.read(selectedInstituteProvider);
    // Don't touch the list state before the add succeeds — a failed add (e.g.
    // a duplicate name) must surface to the caller for a snackbar, while the
    // existing classroom list stays visible instead of being wiped to an error.
    await ref.read(classroomRepositoryProvider).addClassroom(
          name,
          description: description,
          instituteId: institute.id,
          shift: shift,
        );
    state = await AsyncValue.guard(
      () => ref.read(classroomRepositoryProvider).getClassrooms(instituteId: institute.id),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final institute = ref.read(selectedInstituteProvider);
      return ref.read(classroomRepositoryProvider).getClassrooms(instituteId: institute.id);
    });
  }

  Future<void> updateSubjects(String id, List<String> subjects) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final institute = ref.read(selectedInstituteProvider);
      await ref.read(classroomRepositoryProvider).updateClassroomSubjects(id, subjects);
      return ref.read(classroomRepositoryProvider).getClassrooms(instituteId: institute.id);
    });
  }
}
