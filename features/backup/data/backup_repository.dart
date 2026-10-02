import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupRepositoryProvider =
    Provider<BackupRepository>((ref) => BackupRepository(ref.watch(dioProvider)));

final backupStatusProvider =
    FutureProvider.autoDispose<BackupStatus>((ref) => ref.read(backupRepositoryProvider).getStatus());

final backupSchemasProvider =
    FutureProvider.autoDispose<BackupOverview>((ref) => ref.read(backupRepositoryProvider).getSchemas());

class BackupStatus {
  const BackupStatus({
    required this.currentMonth,
    required this.needsMonthlyBackup,
    this.lastMonth,
    this.lastAt,
    this.lastRecords = 0,
    this.lastBy = '',
  });

  final String currentMonth;
  final bool needsMonthlyBackup;
  final String? lastMonth;
  final DateTime? lastAt;
  final int lastRecords;
  final String lastBy;

  factory BackupStatus.fromJson(Map<String, dynamic> j) {
    final last = j['lastBackup'] as Map<String, dynamic>?;
    return BackupStatus(
      currentMonth: (j['currentMonth'] ?? '').toString(),
      needsMonthlyBackup: j['needsMonthlyBackup'] == true,
      lastMonth: last?['monthLabel']?.toString(),
      lastAt: last?['at'] != null ? DateTime.tryParse(last!['at'].toString()) : null,
      lastRecords: (last?['records'] as num?)?.toInt() ?? 0,
      lastBy: last?['by']?.toString() ?? '',
    );
  }
}

class BackupSchemaInfo {
  const BackupSchemaInfo({required this.key, required this.name, required this.category, required this.count});
  final String key;
  final String name;
  final String category;
  final int count;

  factory BackupSchemaInfo.fromJson(Map<String, dynamic> j) => BackupSchemaInfo(
        key: (j['key'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

class BackupOverview {
  const BackupOverview({required this.schemas, required this.totalRecords});
  final List<BackupSchemaInfo> schemas;
  final int totalRecords;
}

class BackupRepository {
  BackupRepository(this._dio);
  final Dio _dio;

  Future<BackupStatus> getStatus() async {
    final r = await _dio.get('/admin/backup/status');
    return BackupStatus.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<BackupOverview> getSchemas() async {
    final r = await _dio.get('/admin/backup/schemas');
    final list = (r.data['schemas'] as List? ?? [])
        .map((e) => BackupSchemaInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return BackupOverview(
      schemas: list,
      totalRecords: (r.data['totalRecords'] as num?)?.toInt() ?? 0,
    );
  }

  /// Full backup of every schema as one pretty JSON string.
  Future<String> exportAllJson() async {
    final r = await _dio.post(
      '/admin/backup/export',
      data: {'collections': 'all', 'format': 'json', 'pretty': true},
      // Keep the server's pretty-printed JSON verbatim instead of re-decoding it.
      options: Options(responseType: ResponseType.plain),
    );
    return r.data.toString();
  }

  Future<void> markMonthly({required int records, required int collections}) async {
    await _dio.post('/admin/backup/mark-monthly', data: {
      'records': records,
      'collections': collections,
      'format': 'json',
    });
  }
}
