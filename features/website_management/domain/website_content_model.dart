import 'package:freezed_annotation/freezed_annotation.dart';

part 'website_content_model.freezed.dart';
part 'website_content_model.g.dart';

@freezed
abstract class WebsiteContentModel with _$WebsiteContentModel {
  const factory WebsiteContentModel({
    @Default('default') String singletonId,
    @Default(WebsiteHeroModel()) WebsiteHeroModel hero,
    @Default(WebsiteAboutModel()) WebsiteAboutModel about,
    @Default([]) List<WebsiteStatModel> stats,
    @Default([]) List<WebsiteCommitteeModel> committees,
    @Default([]) List<WebsiteEducationProgramModel> educationPrograms,
    @Default([]) List<WebsiteStudyProgramModel> studyPrograms,
    @Default([]) List<WebsiteEventModel> upcomingEvents,
    @Default([]) List<WebsitePastEventModel> pastEvents,
    @Default([]) List<WebsiteVideoModel> videos,
    @Default([]) List<WebsitePhotoModel> photos,
    @Default([]) List<WebsiteAlbumModel> albums,
    @Default([]) List<WebsiteNewsModel> newsArticles,
    @Default([]) List<WebsiteTestimonialModel> testimonials,
    @Default([]) List<WebsiteMediaHighlightModel> mediaHighlights,
    @Default([]) List<WebsiteFaqModel> faqItems,
  }) = _WebsiteContentModel;

  factory WebsiteContentModel.fromJson(Map<String, dynamic> json) => _$WebsiteContentModelFromJson(json);
}

@freezed
abstract class WebsiteHeroModel with _$WebsiteHeroModel {
  const factory WebsiteHeroModel({
    @Default('JDCC / ISLAHI CENTER') String kicker,
    @Default('Building') String titlePrefix,
    @Default('faith-centered learning') String titleHighlight,
    @Default('for families and communities') String titleSuffix,
    @Default('Islamic education, local guidance, and meaningful community participation in one connected institution.') String subtitle,
    @Default('JDCC / ISLAHI CENTER is a modern Islamic educational and community institution developing confident learners, connected families, and purposeful service across every area it serves.') String description,
    @Default([]) List<String> highlights,
    @Default('/hero_bg.png') String image,
  }) = _WebsiteHeroModel;

  factory WebsiteHeroModel.fromJson(Map<String, dynamic> json) => _$WebsiteHeroModelFromJson(json);
}

@freezed
abstract class WebsiteAboutModel with _$WebsiteAboutModel {
  const factory WebsiteAboutModel({
    @Default('ABOUT JDCC') String heading,
    @Default('A trusted institution helping faith take root in everyday life.') String title,
    @Default('JDCC / ISLAHI CENTER brings together educational initiatives, local committees, youth development, and civic outreach under one clear mission: nurturing a confident, compassionate Muslim community grounded in knowledge and service.') String description1,
    @Default('This redesign uses editable sample content so the team can quickly replace descriptions, names, and statistics with official copy while keeping the full premium presentation intact.') String description2,
    @Default('/slide1.png') String image,
  }) = _WebsiteAboutModel;

  factory WebsiteAboutModel.fromJson(Map<String, dynamic> json) => _$WebsiteAboutModelFromJson(json);
}

@freezed
abstract class WebsiteStatModel with _$WebsiteStatModel {
  const factory WebsiteStatModel({
    @Default(0) int value,
    @Default('') String label,
    @Default('') String suffix,
  }) = _WebsiteStatModel;

  factory WebsiteStatModel.fromJson(Map<String, dynamic> json) => _$WebsiteStatModelFromJson(json);
}

@freezed
abstract class WebsiteCommitteeModel with _$WebsiteCommitteeModel {
  const factory WebsiteCommitteeModel({
    @Default('') String name,
    @Default('') String group,
    @Default('') String area,
    @Default('') String coordinator,
    @Default(0) int members,
    @Default('') String description,
  }) = _WebsiteCommitteeModel;

  factory WebsiteCommitteeModel.fromJson(Map<String, dynamic> json) => _$WebsiteCommitteeModelFromJson(json);
}

@freezed
abstract class WebsiteEducationProgramModel with _$WebsiteEducationProgramModel {
  const factory WebsiteEducationProgramModel({
    @Default('') String title,
    @Default('') String subtitle,
    @Default('') String objectives,
    @Default([]) List<String> details,
    @Default('') String admission,
    @Default('') String icon,
  }) = _WebsiteEducationProgramModel;

  factory WebsiteEducationProgramModel.fromJson(Map<String, dynamic> json) => _$WebsiteEducationProgramModelFromJson(json);
}

@freezed
abstract class WebsiteStudyProgramModel with _$WebsiteStudyProgramModel {
  const factory WebsiteStudyProgramModel({
    @Default('') String title,
    @Default('') String duration,
    @Default('') String eligibility,
    @Default('') String description,
    @Default('') String icon,
  }) = _WebsiteStudyProgramModel;

  factory WebsiteStudyProgramModel.fromJson(Map<String, dynamic> json) => _$WebsiteStudyProgramModelFromJson(json);
}

@freezed
abstract class WebsiteEventModel with _$WebsiteEventModel {
  const factory WebsiteEventModel({
    @Default('') String date,
    @Default('') String title,
    @Default('') String location,
    @Default('') String time,
    @Default('') String category,
    @Default('') String description,
    @Default('') String registrationLink,
  }) = _WebsiteEventModel;

  factory WebsiteEventModel.fromJson(Map<String, dynamic> json) => _$WebsiteEventModelFromJson(json);
}

@freezed
abstract class WebsitePastEventModel with _$WebsitePastEventModel {
  const factory WebsitePastEventModel({
    @Default('') String title,
    @Default('') String date,
    @Default('') String category,
    @Default('') String image,
  }) = _WebsitePastEventModel;

  factory WebsitePastEventModel.fromJson(Map<String, dynamic> json) => _$WebsitePastEventModelFromJson(json);
}

@freezed
abstract class WebsiteVideoModel with _$WebsiteVideoModel {
  const factory WebsiteVideoModel({
    @Default('') String title,
    @Default('') String date,
    @Default('') String duration,
    @Default('') String href,
    @Default('') String image,
  }) = _WebsiteVideoModel;

  factory WebsiteVideoModel.fromJson(Map<String, dynamic> json) => _$WebsiteVideoModelFromJson(json);
}

@freezed
abstract class WebsitePhotoModel with _$WebsitePhotoModel {
  const factory WebsitePhotoModel({
    @Default('') String title,
    @Default('') String image,
  }) = _WebsitePhotoModel;

  factory WebsitePhotoModel.fromJson(Map<String, dynamic> json) => _$WebsitePhotoModelFromJson(json);
}

@freezed
abstract class WebsiteAlbumModel with _$WebsiteAlbumModel {
  const factory WebsiteAlbumModel({
    @Default('') String title,
    @Default(0) int count,
    @Default('') String date,
    @Default('') String image,
  }) = _WebsiteAlbumModel;

  factory WebsiteAlbumModel.fromJson(Map<String, dynamic> json) => _$WebsiteAlbumModelFromJson(json);
}

@freezed
abstract class WebsiteNewsModel with _$WebsiteNewsModel {
  const factory WebsiteNewsModel({
    @Default('') String category,
    @Default('') String date,
    @Default('') String title,
    @Default('') String excerpt,
    @Default('') String author,
    @Default('') String content,
    @Default('') String image,
  }) = _WebsiteNewsModel;

  factory WebsiteNewsModel.fromJson(Map<String, dynamic> json) => _$WebsiteNewsModelFromJson(json);
}

@freezed
abstract class WebsiteTestimonialModel with _$WebsiteTestimonialModel {
  const factory WebsiteTestimonialModel({
    @Default('') String quote,
    @Default('') String name,
  }) = _WebsiteTestimonialModel;

  factory WebsiteTestimonialModel.fromJson(Map<String, dynamic> json) => _$WebsiteTestimonialModelFromJson(json);
}

@freezed
abstract class WebsiteMediaHighlightModel with _$WebsiteMediaHighlightModel {
  const factory WebsiteMediaHighlightModel({
    @Default('') String title,
    @Default('') String meta,
    @Default('') String image,
  }) = _WebsiteMediaHighlightModel;

  factory WebsiteMediaHighlightModel.fromJson(Map<String, dynamic> json) => _$WebsiteMediaHighlightModelFromJson(json);
}

@freezed
abstract class WebsiteFaqModel with _$WebsiteFaqModel {
  const factory WebsiteFaqModel({
    @Default('') String question,
    @Default('') String answer,
  }) = _WebsiteFaqModel;

  factory WebsiteFaqModel.fromJson(Map<String, dynamic> json) => _$WebsiteFaqModelFromJson(json);
}
