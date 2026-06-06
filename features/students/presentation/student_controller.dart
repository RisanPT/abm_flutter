import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'student_controller.g.dart';

@riverpod
class StudentController extends _$StudentController {
  @override
  FutureOr<List<StudentModel>> build() async {
    return _fetchStudents();
  }

  Future<List<StudentModel>> _fetchStudents({String? query, String? classroom}) {
    return ref.read(studentRepositoryProvider).getStudents(query: query, classroom: classroom);
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStudents(query: query));
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
