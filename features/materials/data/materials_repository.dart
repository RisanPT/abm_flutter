import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final materialsRepositoryProvider =
    Provider<MaterialsRepository>((ref) => MaterialsRepository(ref.watch(dioProvider)));

/// Staff view of all study materials for the current institute.
final materialsListProvider = FutureProvider.autoDispose<List<StudyMaterialItem>>((ref) {
  ref.watch(selectedInstituteProvider);
  return ref.read(materialsRepositoryProvider).list();
});

class StudyMaterialItem {
  const StudyMaterialItem({
    required this.id,
    required this.title,
    this.subject = '',
    this.description = '',
    required this.url,
    this.grade = 'all',
    this.postedByName = '',
  });

  final String id;
  final String title;
  final String subject;
  final String description;
  final String url;
  final String grade;
  final String postedByName;

  factory StudyMaterialItem.fromJson(Map<String, dynamic> j) => StudyMaterialItem(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        subject: (j['subject'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        grade: (j['grade'] ?? 'all').toString(),
        postedByName: (j['postedByName'] ?? '').toString(),
      );
}

class MaterialsRepository {
  MaterialsRepository(this._dio);
  final Dio _dio;

  Future<List<StudyMaterialItem>> list() async {
    final r = await _dio.get('/portal-content/materials');
    final data = (r.data is Map ? r.data['items'] : r.data) as List? ?? [];
    return data.map((e) => StudyMaterialItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> create({
    required String title,
    required String url,
    String subject = '',
    String description = '',
    String grade = 'all',
  }) async {
    await _dio.post('/portal-content/materials', data: {
      'title': title,
      'url': url,
      'subject': subject,
      'description': description,
      'grade': grade,
    });
  }

  Future<void> delete(String id) => _dio.delete('/portal-content/materials/$id');
}
