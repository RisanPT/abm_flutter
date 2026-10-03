import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final examRepositoryProvider =
    Provider<ExamRepository>((ref) => ExamRepository(ref.watch(dioProvider)));

class ExamQuery {
  const ExamQuery({this.classroom, this.page = 1});
  final String? classroom;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is ExamQuery && classroom == other.classroom && page == other.page;

  @override
  int get hashCode => Object.hash(classroom, page);
}

final examsPageProvider =
    FutureProvider.autoDispose.family<PagedResult<Exam>, ExamQuery>((ref, q) {
  ref.watch(selectedInstituteProvider);
  return ref.read(examRepositoryProvider).getExamsPage(
        classroom: (q.classroom == null || q.classroom == 'All' || q.classroom!.isEmpty) ? null : q.classroom,
        page: q.page,
      );
});

final examsListProvider = FutureProvider.autoDispose.family<List<Exam>, String>((ref, classroom) {
  ref.watch(selectedInstituteProvider);
  return ref.read(examRepositoryProvider).getExams(classroom: classroom == 'All' ? null : classroom);
});

final examResultsProvider = FutureProvider.autoDispose.family<List<ExamResult>, String>(
    (ref, examId) => ref.read(examRepositoryProvider).getExamResults(examId));

final myResultsProvider =
    FutureProvider.autoDispose<List<ExamResult>>((ref) => ref.read(examRepositoryProvider).getMyResults());

class ExamSubject {
  const ExamSubject({required this.name, required this.maxMarks});
  final String name;
  final int maxMarks;
  factory ExamSubject.fromJson(Map<String, dynamic> j) =>
      ExamSubject(name: (j['name'] ?? '').toString(), maxMarks: (j['maxMarks'] as num?)?.toInt() ?? 100);
  Map<String, dynamic> toJson() => {'name': name, 'maxMarks': maxMarks};
}

class Exam {
  const Exam({
    required this.id,
    required this.name,
    required this.classroom,
    this.term = '',
    this.date,
    this.subjects = const [],
    this.createdByName = '',
  });
  final String id;
  final String name;
  final String classroom;
  final String term;
  final DateTime? date;
  final List<ExamSubject> subjects;
  final String createdByName;

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        classroom: (j['classroom'] ?? '').toString(),
        term: (j['term'] ?? '').toString(),
        date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) : null,
        subjects: (j['subjects'] as List? ?? [])
            .map((e) => ExamSubject.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdByName: (j['createdByName'] ?? '').toString(),
      );
}

class ExamMark {
  const ExamMark({required this.subject, required this.score});
  final String subject;
  final num score;
  factory ExamMark.fromJson(Map<String, dynamic> j) =>
      ExamMark(subject: (j['subject'] ?? '').toString(), score: (j['score'] as num?) ?? 0);
}

class ExamResult {
  const ExamResult({
    required this.id,
    required this.examId,
    required this.studentId,
    this.classroom = '',
    this.marks = const [],
    this.total = 0,
    this.maxTotal = 0,
    this.percentage = 0,
    this.grade = '',
    this.remarks = '',
    this.exam,
  });
  final String id;
  final String examId;
  final String studentId;
  final String classroom;
  final List<ExamMark> marks;
  final num total;
  final num maxTotal;
  final num percentage;
  final String grade;
  final String remarks;
  final Exam? exam;

  factory ExamResult.fromJson(Map<String, dynamic> j) => ExamResult(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        examId: (j['examId'] ?? '').toString(),
        studentId: (j['studentId'] ?? '').toString(),
        classroom: (j['classroom'] ?? '').toString(),
        marks: (j['marks'] as List? ?? [])
            .map((e) => ExamMark.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        total: (j['total'] as num?) ?? 0,
        maxTotal: (j['maxTotal'] as num?) ?? 0,
        percentage: (j['percentage'] as num?) ?? 0,
        grade: (j['grade'] ?? '').toString(),
        remarks: (j['remarks'] ?? '').toString(),
        exam: j['exam'] != null ? Exam.fromJson(Map<String, dynamic>.from(j['exam'] as Map)) : null,
      );
}

class ExamRepository {
  ExamRepository(this._dio);
  final Dio _dio;

  Future<List<Exam>> getExams({String? classroom}) async {
    final r = await _dio.get('/exams', queryParameters: {'classroom': ?classroom});
    return (r.data as List).map((e) => Exam.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<PagedResult<Exam>> getExamsPage({
    String? classroom,
    required int page,
    int limit = 20,
  }) async {
    final r = await _dio.get('/exams', queryParameters: {
      if (classroom != null && classroom.isNotEmpty && classroom != 'All') 'classroom': classroom,
      'page': page,
      'limit': limit,
    });
    return PagedResult<Exam>.fromJson(
      r.data as Map<String, dynamic>,
      (json) => Exam.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<Exam> createExam({
    required String name,
    required String classroom,
    String term = '',
    DateTime? date,
    required List<ExamSubject> subjects,
  }) async {
    final r = await _dio.post('/exams', data: {
      'name': name,
      'classroom': classroom,
      'term': term,
      if (date != null) 'date': date.toIso8601String(),
      'subjects': subjects.map((s) => s.toJson()).toList(),
    });
    return Exam.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<List<ExamResult>> getExamResults(String examId) async {
    final r = await _dio.get('/exams/$examId/results');
    return (r.data as List).map((e) => ExamResult.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> upsertResult(String examId, {
    required String studentId,
    required Map<String, num> marks,
    String remarks = '',
  }) async {
    await _dio.post('/exams/$examId/result', data: {
      'studentId': studentId,
      'marks': marks.entries.map((e) => {'subject': e.key, 'score': e.value}).toList(),
      'remarks': remarks,
    });
  }

  Future<void> deleteExam(String examId) => _dio.delete('/exams/$examId');

  Future<List<ExamResult>> getMyResults() async {
    final r = await _dio.get('/exams/results/me');
    return (r.data as List).map((e) => ExamResult.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<ExamResult>> getStudentResults(String studentId) async {
    final r = await _dio.get('/exams/results/student/$studentId');
    return (r.data as List).map((e) => ExamResult.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
