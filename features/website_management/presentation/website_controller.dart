import 'package:abm_madrasa/features/website_management/data/website_repository.dart';
import 'package:abm_madrasa/features/website_management/domain/website_content_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';

part 'website_controller.g.dart';

@riverpod
class WebsiteController extends _$WebsiteController {
  @override
  FutureOr<WebsiteContentModel> build() async {
    return _fetchContent();
  }

  Future<WebsiteContentModel> _fetchContent() async {
    return ref.read(websiteRepositoryProvider).getContent();
  }

  Future<void> updateContent({
    required WebsiteContentModel content,
    List<MapEntry<String, File>>? images,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = await ref.read(websiteRepositoryProvider).updateContent(
            content: content,
            images: images,
          );
      return updated;
    });
  }
}
