import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/website_management/domain/website_content_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import 'dart:convert';

part 'website_repository.g.dart';

@Riverpod(keepAlive: true)
WebsiteRepository websiteRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return WebsiteRepository(dio);
}

class WebsiteRepository {
  final Dio _dio;
  WebsiteRepository(this._dio);

  Future<WebsiteContentModel> getContent() async {
    final response = await _dio.get('/website-content');
    return WebsiteContentModel.fromJson(response.data);
  }

  Future<WebsiteContentModel> updateContent({
    required WebsiteContentModel content,
    List<MapEntry<String, File>>? images,
  }) async {
    // We must encode the entire content to JSON and pass it as 'payload'
    final jsonContent = content.toJson();
    final formData = FormData.fromMap({
      'payload': jsonEncode(jsonContent),
    });

    if (images != null) {
      for (final entry in images) {
        formData.files.add(MapEntry(
          entry.key,
          await MultipartFile.fromFile(entry.value.path),
        ));
      }
    }

    final response = await _dio.put('/website-content', data: formData);
    return WebsiteContentModel.fromJson(response.data);
  }
}
