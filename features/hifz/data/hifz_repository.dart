import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hifzRepositoryProvider =
    Provider<HifzRepository>((ref) => HifzRepository(ref.watch(dioProvider)));

/// Logged-in student's own memorization log.
final myHifzProvider =
    FutureProvider.autoDispose<HifzHistory>((ref) => ref.read(hifzRepositoryProvider).getMine());

/// A specific student's log (staff/parent view).
final studentHifzProvider = FutureProvider.autoDispose.family<HifzHistory, String>(
    (ref, studentId) => ref.read(hifzRepositoryProvider).getStudent(studentId));

/// Today's records for a class (teacher review), keyed by classroom.
final classHifzTodayProvider = FutureProvider.autoDispose.family<List<HifzRecord>, String>(
    (ref, classroom) => ref.read(hifzRepositoryProvider).getClassDay(classroom: classroom));

class HifzRecord {
  const HifzRecord({
    required this.id,
    required this.studentId,
    required this.classroom,
    this.date,
    this.sabaqSurah = '',
    this.sabaqFrom = '',
    this.sabaqTo = '',
    this.sabaqLines = 0,
    this.sabqi = '',
    this.manzil = '',
    this.quality = '',
    this.notes = '',
    this.loggedByName = '',
  });

  final String id;
  final String studentId;
  final String classroom;
  final DateTime? date;
  final String sabaqSurah;
  final String sabaqFrom;
  final String sabaqTo;
  final int sabaqLines;
  final String sabqi;
  final String manzil;
  final String quality;
  final String notes;
  final String loggedByName;

  /// A readable one-line Sabaq label, e.g. "Al-Baqarah 1–20".
  String get sabaqLabel {
    if (sabaqSurah.isEmpty && sabaqFrom.isEmpty && sabaqTo.isEmpty) return '—';
    final range = [sabaqFrom, sabaqTo].where((s) => s.isNotEmpty).join('–');
    return [sabaqSurah, range].where((s) => s.isNotEmpty).join(' ');
  }

  factory HifzRecord.fromJson(Map<String, dynamic> j) => HifzRecord(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        studentId: (j['studentId'] ?? '').toString(),
        classroom: (j['classroom'] ?? '').toString(),
        date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) : null,
        sabaqSurah: (j['sabaqSurah'] ?? '').toString(),
        sabaqFrom: (j['sabaqFrom'] ?? '').toString(),
        sabaqTo: (j['sabaqTo'] ?? '').toString(),
        sabaqLines: (j['sabaqLines'] as num?)?.toInt() ?? 0,
        sabqi: (j['sabqi'] ?? '').toString(),
        manzil: (j['manzil'] ?? '').toString(),
        quality: (j['quality'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        loggedByName: (j['loggedByName'] ?? '').toString(),
      );
}

class HifzHistory {
  const HifzHistory({required this.records, required this.daysLogged, this.lastEntry});
  final List<HifzRecord> records;
  final int daysLogged;
  final HifzRecord? lastEntry;

  factory HifzHistory.fromJson(Map<String, dynamic> j) {
    final recs = (j['records'] as List? ?? [])
        .map((e) => HifzRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final summary = j['summary'] as Map<String, dynamic>?;
    final last = summary?['lastEntry'];
    return HifzHistory(
      records: recs,
      daysLogged: (summary?['daysLogged'] as num?)?.toInt() ?? recs.length,
      lastEntry: last != null ? HifzRecord.fromJson(Map<String, dynamic>.from(last as Map)) : null,
    );
  }
}

class HifzRepository {
  HifzRepository(this._dio);
  final Dio _dio;

  Future<HifzHistory> getMine({String? month}) async {
    final r = await _dio.get('/hifz/me', queryParameters: {if (month != null) 'month': month});
    return HifzHistory.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<HifzHistory> getStudent(String studentId, {String? month}) async {
    final r = await _dio.get('/hifz/student/$studentId', queryParameters: {if (month != null) 'month': month});
    return HifzHistory.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<List<HifzRecord>> getClassDay({required String classroom, DateTime? date}) async {
    final r = await _dio.get('/hifz', queryParameters: {
      if (classroom.isNotEmpty && classroom != 'All') 'classroom': classroom,
      if (date != null) 'date': date.toIso8601String(),
    });
    return (r.data as List).map((e) => HifzRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> upsert({
    required String studentId,
    DateTime? date,
    String sabaqSurah = '',
    String sabaqFrom = '',
    String sabaqTo = '',
    int sabaqLines = 0,
    String sabqi = '',
    String manzil = '',
    String quality = '',
    String notes = '',
  }) async {
    await _dio.post('/hifz', data: {
      'studentId': studentId,
      if (date != null) 'date': date.toIso8601String(),
      'sabaqSurah': sabaqSurah,
      'sabaqFrom': sabaqFrom,
      'sabaqTo': sabaqTo,
      'sabaqLines': sabaqLines,
      'sabqi': sabqi,
      'manzil': manzil,
      'quality': quality,
      'notes': notes,
    });
  }

  Future<void> delete(String id) => _dio.delete('/hifz/$id');
}
