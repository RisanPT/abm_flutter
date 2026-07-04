import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'student_controller.g.dart';

@riverpod
class StudentController extends _$StudentController {
  @override
  FutureOr<List<StudentModel>> build() async {
    ref.watch(selectedInstituteProvider);
    return _fetchStudents();
  }

  Future<List<StudentModel>> _fetchStudents({String? query, String? classroom, String? shift}) {
    final instituteId = ref.read(selectedInstituteProvider).id;
    return ref.read(studentRepositoryProvider).getStudents(instituteId: instituteId, query: query, classroom: classroom, shift: shift);
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStudents(query: query));
  }

  Future<void> filter(String? classroom, String? shift) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStudents(classroom: classroom, shift: shift));
  }

  Future<void> filterByClassroom(String? classroom) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStudents(classroom: classroom));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStudents());
  }

  Future<void> addStudent(StudentModel student) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).addStudent(student);
      return _fetchStudents();
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).updateStudent(student);
      ref.invalidate(studentDetailsProvider(student.id));
      return _fetchStudents();
    });
  }

  Future<void> deleteStudent(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).deleteStudent(id);
      return _fetchStudents();
    });
  }
}

final studentDetailsProvider = FutureProvider.family<StudentModel, String>((
  ref,
  id,
) {
  return ref.read(studentRepositoryProvider).getStudentById(id);
});
