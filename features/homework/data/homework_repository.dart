import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeworkRepositoryProvider =
    Provider<HomeworkRepository>((ref) => HomeworkRepository(ref.watch(dioProvider)));

class HomeworkQuery {
  const HomeworkQuery({this.classroom, this.shift, this.page = 1, this.mine = false, this.instituteId});
  final String? classroom;
  final String? shift; // staff filter: 'Shift-1' | 'Shift-2' (null/'All' = no filter)
  final int page;
  final bool mine;
  final String? instituteId;

  @override
  bool operator ==(Object other) =>
      other is HomeworkQuery &&
      classroom == other.classroom &&
      shift == other.shift &&
      page == other.page &&
      mine == other.mine &&
      instituteId == other.instituteId;

  @override
  int get hashCode => Object.hash(classroom, shift, page, mine, instituteId);
}

/// Paginated homework list, keyed by classroom & page.
final homeworkPageProvider =
    FutureProvider.autoDispose.family<PagedResult<Homework>, HomeworkQuery>((ref, q) {
  return ref.read(homeworkRepositoryProvider).getHomeworkPage(
        classroom: (q.classroom?.isEmpty ?? true) ? null : q.classroom,
        shift: (q.shift == null || q.shift == 'All') ? null : q.shift,
        page: q.page,
        mine: q.mine,
        instituteId: q.instituteId,
      );
});

/// Legacy unpaginated provider kept for backwards compatibility.
final homeworkListProvider =
    FutureProvider.autoDispose.family<List<Homework>, String>((ref, classroom) {
  return ref.read(homeworkRepositoryProvider).getHomework(classroom: classroom.isEmpty ? null : classroom);
});

class Homework {
  const Homework({
    required this.id,
    required this.classroom,
    this.shift = 'All',
    required this.subject,
    required this.title,
    required this.description,
    this.dueDate,
    this.attachmentUrl = '',
    this.assignedByName = '',
    this.assignedBy = '',
    this.createdAt,
    this.completedCount = 0,
    this.completed = false,
  });

  final String id;
  final String classroom;
  final String shift; // 'All' | 'Shift-1' | 'Shift-2' — which batch it targets
  final String subject;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String attachmentUrl;
  final String assignedByName;
  final String assignedBy;
  final DateTime? createdAt;
  final int completedCount;
  final bool completed;

  bool get hasAttachment => attachmentUrl.isNotEmpty;

  factory Homework.fromJson(Map<String, dynamic> j) => Homework(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        classroom: (j['classroom'] ?? '').toString(),
        shift: (j['shift'] ?? 'All').toString(),
        subject: (j['subject'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate'].toString()) : null,
        attachmentUrl: (j['attachmentUrl'] ?? '').toString(),
        assignedByName: (j['assignedByName'] ?? '').toString(),
        assignedBy: (j['assignedBy'] ?? '').toString(),
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
        completedCount: (j['completedCount'] as num?)?.toInt() ?? 0,
        completed: j['completed'] == true,
      );
}

class HomeworkRepository {
  HomeworkRepository(this._dio);
  final Dio _dio;

  Future<List<Homework>> getHomework({String? classroom, bool mine = false, String? instituteId}) async {
    final r = await _dio.get('/homework', queryParameters: {
      if (classroom != null && classroom.isNotEmpty) 'classroom': classroom,
      if (mine) 'mine': 'true',
      'instituteId': ?instituteId,
    });
    return (r.data as List).map((e) => Homework.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<PagedResult<Homework>> getHomeworkPage({
    String? classroom,
    String? shift,
    bool mine = false,
    required int page,
    int limit = 20,
    String? instituteId,
  }) async {
    final r = await _dio.get('/homework', queryParameters: {
      if (classroom != null && classroom.isNotEmpty) 'classroom': classroom,
      if (shift != null && shift.isNotEmpty) 'shift': shift,
      if (mine) 'mine': 'true',
      'instituteId': ?instituteId,
      'page': page,
      'limit': limit,
    });
    return PagedResult<Homework>.fromJson(
      r.data as Map<String, dynamic>,
      (json) => Homework.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<void> create({
    required String classroom,
    required String title,
    String shift = 'All',
    String subject = '',
    String description = '',
    DateTime? dueDate,
    String? attachment,
    String? instituteId,
  }) async {
    await _dio.post('/homework', data: {
      'classroom': classroom,
      'shift': shift,
      'title': title,
      'subject': subject,
      'description': description,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      if (attachment != null && attachment.isNotEmpty) 'attachment': attachment,
      'instituteId': ?instituteId,
    });
  }

  Future<void> update(
    String id, {
    String? classroom,
    String? shift,
    String? title,
    String? subject,
    String? description,
    DateTime? dueDate,
  }) async {
    await _dio.patch('/homework/$id', data: {
      'classroom': ?classroom,
      'shift': ?shift,
      'title': ?title,
      'subject': ?subject,
      'description': ?description,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    });
  }

  Future<void> delete(String id) => _dio.delete('/homework/$id');

  Future<void> toggleComplete(String id, bool done) =>
      _dio.post('/homework/$id/complete', data: {'done': done});
}
