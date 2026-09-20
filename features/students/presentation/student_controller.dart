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

  // Persisted filters so status + class + shift + search combine correctly.
  String? _query;
  String? _classroom;
  String? _shift;
  String _status = 'active'; // 'active' (default) | 'inactive' | 'all'

  String get status => _status;

  Future<List<StudentModel>> _fetchStudents() {
    final instituteId = ref.read(selectedInstituteProvider).id;
    return ref.read(studentRepositoryProvider).getStudents(
          instituteId: instituteId,
          query: _query,
          classroom: _classroom,
          shift: _shift,
          status: _status,
        );
  }

  Future<void> _apply() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchStudents);
  }

  Future<void> search(String query) async {
    _query = query.trim().isEmpty ? null : query.trim();
    await _apply();
  }

  Future<void> filter(String? classroom, String? shift) async {
    _classroom = (classroom == null || classroom == 'All') ? null : classroom;
    _shift = (shift == null || shift == 'All') ? null : shift;
    await _apply();
  }

  Future<void> filterByClassroom(String? classroom) async {
    _classroom = (classroom == null || classroom == 'All') ? null : classroom;
    await _apply();
  }

  Future<void> setStatus(String status) async {
    _status = status;
    await _apply();
  }

  /// Deactivate / reactivate, then refresh the current view.
  Future<void> setActive(String id, bool active) async {
    await ref.read(studentRepositoryProvider).setStudentActive(id, active);
    ref.invalidate(studentDetailsProvider(id));
    await _apply();
  }

  Future<void> refresh() async {
    await _apply();
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
