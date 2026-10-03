import 'dart:convert';
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
    this.resourceType = 'Document',
    this.postedByName = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String subject;
  final String description;
  final String url;
  final String grade;
  final String resourceType;
  final String postedByName;
  final DateTime? createdAt;

  bool get isPdf {
    final t = resourceType.toLowerCase();
    final u = url.toLowerCase();
    return t == 'pdf' || u.endsWith('.pdf') || u.contains('.pdf?');
  }

  bool get isVideo {
    final t = resourceType.toLowerCase();
    final u = url.toLowerCase();
    return t == 'video' ||
        u.contains('youtube.com') ||
        u.contains('youtu.be') ||
        u.contains('vimeo.com') ||
        u.endsWith('.mp4');
  }

  bool get isAudio {
    final t = resourceType.toLowerCase();
    final u = url.toLowerCase();
    return t == 'audio' || u.endsWith('.mp3') || u.endsWith('.wav');
  }

  bool get isDrive {
    final u = url.toLowerCase();
    return u.contains('drive.google.com') || u.contains('docs.google.com');
  }

  String get displayType {
    if (isPdf) return 'PDF';
    if (isVideo) return 'Video';
    if (isAudio) return 'Audio';
    if (isDrive) return 'Google Drive';
    if (resourceType.isNotEmpty && resourceType != 'Document') return resourceType;
    return 'Document';
  }

  factory StudyMaterialItem.fromJson(Map<String, dynamic> j) => StudyMaterialItem(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        subject: (j['subject'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        grade: (j['grade'] ?? 'all').toString(),
        resourceType: (j['resourceType'] ?? 'Document').toString(),
        postedByName: (j['postedByName'] ?? '').toString(),
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      );
}

class MaterialsRepository {
  MaterialsRepository(this._dio);
  final Dio _dio;

  Future<List<StudyMaterialItem>> list({String? grade, String? subject}) async {
    final r = await _dio.get('/portal-content/materials', queryParameters: {
      if (grade != null && grade != 'all' && grade != 'All') 'grade': grade,
      if (subject != null && subject != 'all' && subject != 'All') 'subject': subject,
    });
    dynamic raw = r.data;
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }
    final data = (raw is Map ? raw['items'] : raw) as List? ?? [];
    return data
        .whereType<Map>()
        .map((e) => StudyMaterialItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> create({
    required String title,
    required String url,
    String subject = '',
    String description = '',
    String grade = 'all',
    String resourceType = 'Document',
    String? fileData,
  }) async {
    await _dio.post('/portal-content/materials', data: {
      'title': title,
      'url': url,
      'subject': subject,
      'description': description,
      'grade': grade,
      'resourceType': resourceType,
      'fileData': ?fileData,
    });
  }

  Future<void> delete(String id) => _dio.delete('/portal-content/materials/$id');
}
