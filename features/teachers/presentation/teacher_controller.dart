import 'package:abm_madrasa/features/teachers/data/teacher_repository.dart';
import 'package:abm_madrasa/features/teachers/domain/teacher_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teacherListProvider =
    FutureProvider.family<List<TeacherModel>, String>((ref, query) {
  return ref
      .read(teacherRepositoryProvider)
      .getTeachers(query: query.trim().isEmpty ? null : query.trim());
});
