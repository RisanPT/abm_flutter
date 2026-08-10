import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/students/data/classroom_repository.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'classroom_controller.g.dart';

@riverpod
class ClassroomController extends _$ClassroomController {
  @override
  FutureOr<List<ClassroomModel>> build() async {
    // Read everything synchronously up front, then hand back the future — so no
    // `ref` is touched after an await (the provider may be disposed by then).
    final instituteId = ref.watch(selectedInstituteProvider).id;
    final repo = ref.read(classroomRepositoryProvider);
    return repo.getClassrooms(instituteId: instituteId);
  }

  Future<void> addClassroom(String name, {String? description, String shift = 'Shift-1'}) async {
    // Capture ref-dependent objects before any await; using `ref` afterwards can
    // crash if the provider was disposed/invalidated while awaiting.
    final repo = ref.read(classroomRepositoryProvider);
    final instituteId = ref.read(selectedInstituteProvider).id;

    // Let a failed add (e.g. a duplicate name) surface to the caller for a
    // snackbar; the existing list stays intact.
    await repo.addClassroom(name, description: description, instituteId: instituteId, shift: shift);

    final result = await AsyncValue.guard(() => repo.getClassrooms(instituteId: instituteId));
    if (ref.mounted) state = result;
  }

  Future<void> refresh() async {
    final repo = ref.read(classroomRepositoryProvider);
    final instituteId = ref.read(selectedInstituteProvider).id;
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => repo.getClassrooms(instituteId: instituteId));
    if (ref.mounted) state = result;
  }

  Future<void> updateSubjects(String id, List<String> subjects) async {
    final repo = ref.read(classroomRepositoryProvider);
    final instituteId = ref.read(selectedInstituteProvider).id;
    state = const AsyncValue.loading();
    await repo.updateClassroomSubjects(id, subjects);
    final result = await AsyncValue.guard(() => repo.getClassrooms(instituteId: instituteId));
    if (ref.mounted) state = result;
  }
}
