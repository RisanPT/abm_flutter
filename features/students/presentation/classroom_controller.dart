import 'package:abm_madrasa/features/students/data/classroom_repository.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'classroom_controller.g.dart';

@riverpod
class ClassroomController extends _$ClassroomController {
  @override
  FutureOr<List<ClassroomModel>> build() async {
    return ref.read(classroomRepositoryProvider).getClassrooms();
  }

  Future<void> addClassroom(String name, {String? description}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(classroomRepositoryProvider).addClassroom(name, description: description);
      return ref.read(classroomRepositoryProvider).getClassrooms();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(classroomRepositoryProvider).getClassrooms());
  }

  Future<void> updateSubjects(String id, List<String> subjects) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(classroomRepositoryProvider).updateClassroomSubjects(id, subjects);
      return ref.read(classroomRepositoryProvider).getClassrooms();
    });
  }
}
