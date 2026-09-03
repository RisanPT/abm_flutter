// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'website_content_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WebsiteContentModel _$WebsiteContentModelFromJson(
  Map<String, dynamic> json,
) => _WebsiteContentModel(
  singletonId: json['singletonId'] as String? ?? 'default',
  hero: json['hero'] == null
      ? const WebsiteHeroModel()
      : WebsiteHeroModel.fromJson(json['hero'] as Map<String, dynamic>),
  about: json['about'] == null
      ? const WebsiteAboutModel()
      : WebsiteAboutModel.fromJson(json['about'] as Map<String, dynamic>),
  stats:
      (json['stats'] as List<dynamic>?)
          ?.map((e) => WebsiteStatModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  committees:
      (json['committees'] as List<dynamic>?)
          ?.map(
            (e) => WebsiteCommitteeModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  educationPrograms:
      (json['educationPrograms'] as List<dynamic>?)
          ?.map(
            (e) => WebsiteEducationProgramModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const [],
  studyPrograms:
      (json['studyPrograms'] as List<dynamic>?)
          ?.map(
            (e) => WebsiteStudyProgramModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  upcomingEvents:
      (json['upcomingEvents'] as List<dynamic>?)
          ?.map((e) => WebsiteEventModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  pastEvents:
      (json['pastEvents'] as List<dynamic>?)
          ?.map(
            (e) => WebsitePastEventModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  videos:
      (json['videos'] as List<dynamic>?)
          ?.map((e) => WebsiteVideoModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  photos:
      (json['photos'] as List<dynamic>?)
          ?.map((e) => WebsitePhotoModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  albums:
      (json['albums'] as List<dynamic>?)
          ?.map((e) => WebsiteAlbumModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  newsArticles:
      (json['newsArticles'] as List<dynamic>?)
          ?.map((e) => WebsiteNewsModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  testimonials:
      (json['testimonials'] as List<dynamic>?)
          ?.map(
            (e) => WebsiteTestimonialModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  mediaHighlights:
      (json['mediaHighlights'] as List<dynamic>?)
          ?.map(
            (e) =>
                WebsiteMediaHighlightModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  faqItems:
      (json['faqItems'] as List<dynamic>?)
          ?.map((e) => WebsiteFaqModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$WebsiteContentModelToJson(
  _WebsiteContentModel instance,
) => <String, dynamic>{
  'singletonId': instance.singletonId,
  'hero': instance.hero,
  'about': instance.about,
  'stats': instance.stats,
  'committees': instance.committees,
  'educationPrograms': instance.educationPrograms,
  'studyPrograms': instance.studyPrograms,
  'upcomingEvents': instance.upcomingEvents,
  'pastEvents': instance.pastEvents,
  'videos': instance.videos,
  'photos': instance.photos,
  'albums': instance.albums,
  'newsArticles': instance.newsArticles,
  'testimonials': instance.testimonials,
  'mediaHighlights': instance.mediaHighlights,
  'faqItems': instance.faqItems,
};

_WebsiteHeroModel _$WebsiteHeroModelFromJson(
  Map<String, dynamic> json,
) => _WebsiteHeroModel(
  kicker: json['kicker'] as String? ?? 'JDCC / ISLAHI CENTER',
  titlePrefix: json['titlePrefix'] as String? ?? 'Building',
  titleHighlight:
      json['titleHighlight'] as String? ?? 'faith-centered learning',
  titleSuffix: json['titleSuffix'] as String? ?? 'for families and communities',
  subtitle:
      json['subtitle'] as String? ??
      'Islamic education, local guidance, and meaningful community participation in one connected institution.',
  description:
      json['description'] as String? ??
      'JDCC / ISLAHI CENTER is a modern Islamic educational and community institution developing confident learners, connected families, and purposeful service across every area it serves.',
  highlights:
      (json['highlights'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  image: json['image'] as String? ?? '/hero_bg.png',
);

Map<String, dynamic> _$WebsiteHeroModelToJson(_WebsiteHeroModel instance) =>
    <String, dynamic>{
      'kicker': instance.kicker,
      'titlePrefix': instance.titlePrefix,
      'titleHighlight': instance.titleHighlight,
      'titleSuffix': instance.titleSuffix,
      'subtitle': instance.subtitle,
      'description': instance.description,
      'highlights': instance.highlights,
      'image': instance.image,
    };

_WebsiteAboutModel _$WebsiteAboutModelFromJson(
  Map<String, dynamic> json,
) => _WebsiteAboutModel(
  heading: json['heading'] as String? ?? 'ABOUT JDCC',
  title:
      json['title'] as String? ??
      'A trusted institution helping faith take root in everyday life.',
  description1:
      json['description1'] as String? ??
      'JDCC / ISLAHI CENTER brings together educational initiatives, local committees, youth development, and civic outreach under one clear mission: nurturing a confident, compassionate Muslim community grounded in knowledge and service.',
  description2:
      json['description2'] as String? ??
      'This redesign uses editable sample content so the team can quickly replace descriptions, names, and statistics with official copy while keeping the full premium presentation intact.',
  image: json['image'] as String? ?? '/slide1.png',
);

Map<String, dynamic> _$WebsiteAboutModelToJson(_WebsiteAboutModel instance) =>
    <String, dynamic>{
      'heading': instance.heading,
      'title': instance.title,
      'description1': instance.description1,
      'description2': instance.description2,
      'image': instance.image,
    };

_WebsiteStatModel _$WebsiteStatModelFromJson(Map<String, dynamic> json) =>
    _WebsiteStatModel(
      value: (json['value'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? '',
      suffix: json['suffix'] as String? ?? '',
    );

Map<String, dynamic> _$WebsiteStatModelToJson(_WebsiteStatModel instance) =>
    <String, dynamic>{
      'value': instance.value,
      'label': instance.label,
      'suffix': instance.suffix,
    };

_WebsiteCommitteeModel _$WebsiteCommitteeModelFromJson(
  Map<String, dynamic> json,
) => _WebsiteCommitteeModel(
  name: json['name'] as String? ?? '',
  group: json['group'] as String? ?? '',
  area: json['area'] as String? ?? '',
  coordinator: json['coordinator'] as String? ?? '',
  members: (json['members'] as num?)?.toInt() ?? 0,
  description: json['description'] as String? ?? '',
);

Map<String, dynamic> _$WebsiteCommitteeModelToJson(
  _WebsiteCommitteeModel instance,
) => <String, dynamic>{
  'name': instance.name,
  'group': instance.group,
  'area': instance.area,
  'coordinator': instance.coordinator,
  'members': instance.members,
  'description': instance.description,
};

_WebsiteEducationProgramModel _$WebsiteEducationProgramModelFromJson(
  Map<String, dynamic> json,
) => _WebsiteEducationProgramModel(
  title: json['title'] as String? ?? '',
  subtitle: json['subtitle'] as String? ?? '',
  objectives: json['objectives'] as String? ?? '',
  details:
      (json['details'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  admission: json['admission'] as String? ?? '',
  icon: json['icon'] as String? ?? '',
);

Map<String, dynamic> _$WebsiteEducationProgramModelToJson(
  _WebsiteEducationProgramModel instance,
) => <String, dynamic>{
  'title': instance.title,
  'subtitle': instance.subtitle,
  'objectives': instance.objectives,
  'details': instance.details,
  'admission': instance.admission,
  'icon': instance.icon,
};

_WebsiteStudyProgramModel _$WebsiteStudyProgramModelFromJson(
  Map<String, dynamic> json,
) => _WebsiteStudyProgramModel(
  title: json['title'] as String? ?? '',
  duration: json['duration'] as String? ?? '',
  eligibility: json['eligibility'] as String? ?? '',
  description: json['description'] as String? ?? '',
  icon: json['icon'] as String? ?? '',
);

Map<String, dynamic> _$WebsiteStudyProgramModelToJson(
  _WebsiteStudyProgramModel instance,
) => <String, dynamic>{
  'title': instance.title,
  'duration': instance.duration,
  'eligibility': instance.eligibility,
  'description': instance.description,
  'icon': instance.icon,
};

_WebsiteEventModel _$WebsiteEventModelFromJson(Map<String, dynamic> json) =>
    _WebsiteEventModel(
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      time: json['time'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      registrationLink: json['registrationLink'] as String? ?? '',
    );

Map<String, dynamic> _$WebsiteEventModelToJson(_WebsiteEventModel instance) =>
    <String, dynamic>{
      'date': instance.date,
      'title': instance.title,
      'location': instance.location,
      'time': instance.time,
      'category': instance.category,
      'description': instance.description,
      'registrationLink': instance.registrationLink,
    };

_WebsitePastEventModel _$WebsitePastEventModelFromJson(
  Map<String, dynamic> json,
) => _WebsitePastEventModel(
  title: json['title'] as String? ?? '',
  date: json['date'] as String? ?? '',
  category: json['category'] as String? ?? '',
  image: json['image'] as String? ?? '',
);

Map<String, dynamic> _$WebsitePastEventModelToJson(
  _WebsitePastEventModel instance,
) => <String, dynamic>{
  'title': instance.title,
  'date': instance.date,
  'category': instance.category,
  'image': instance.image,
};

_WebsiteVideoModel _$WebsiteVideoModelFromJson(Map<String, dynamic> json) =>
    _WebsiteVideoModel(
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      href: json['href'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );

Map<String, dynamic> _$WebsiteVideoModelToJson(_WebsiteVideoModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'date': instance.date,
      'duration': instance.duration,
      'href': instance.href,
      'image': instance.image,
    };

_WebsitePhotoModel _$WebsitePhotoModelFromJson(Map<String, dynamic> json) =>
    _WebsitePhotoModel(
      title: json['title'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );

Map<String, dynamic> _$WebsitePhotoModelToJson(_WebsitePhotoModel instance) =>
    <String, dynamic>{'title': instance.title, 'image': instance.image};

_WebsiteAlbumModel _$WebsiteAlbumModelFromJson(Map<String, dynamic> json) =>
    _WebsiteAlbumModel(
      title: json['title'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      date: json['date'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );

Map<String, dynamic> _$WebsiteAlbumModelToJson(_WebsiteAlbumModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'count': instance.count,
      'date': instance.date,
      'image': instance.image,
    };

_WebsiteNewsModel _$WebsiteNewsModelFromJson(Map<String, dynamic> json) =>
    _WebsiteNewsModel(
      category: json['category'] as String? ?? '',
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      author: json['author'] as String? ?? '',
      content: json['content'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );

Map<String, dynamic> _$WebsiteNewsModelToJson(_WebsiteNewsModel instance) =>
    <String, dynamic>{
      'category': instance.category,
      'date': instance.date,
      'title': instance.title,
      'excerpt': instance.excerpt,
      'author': instance.author,
      'content': instance.content,
      'image': instance.image,
    };

_WebsiteTestimonialModel _$WebsiteTestimonialModelFromJson(
  Map<String, dynamic> json,
) => _WebsiteTestimonialModel(
  quote: json['quote'] as String? ?? '',
  name: json['name'] as String? ?? '',
);

Map<String, dynamic> _$WebsiteTestimonialModelToJson(
  _WebsiteTestimonialModel instance,
) => <String, dynamic>{'quote': instance.quote, 'name': instance.name};

_WebsiteMediaHighlightModel _$WebsiteMediaHighlightModelFromJson(
  Map<String, dynamic> json,
) => _WebsiteMediaHighlightModel(
  title: json['title'] as String? ?? '',
  meta: json['meta'] as String? ?? '',
  image: json['image'] as String? ?? '',
);

Map<String, dynamic> _$WebsiteMediaHighlightModelToJson(
  _WebsiteMediaHighlightModel instance,
) => <String, dynamic>{
  'title': instance.title,
  'meta': instance.meta,
  'image': instance.image,
};

_WebsiteFaqModel _$WebsiteFaqModelFromJson(Map<String, dynamic> json) =>
    _WebsiteFaqModel(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );

Map<String, dynamic> _$WebsiteFaqModelToJson(_WebsiteFaqModel instance) =>
    <String, dynamic>{'question': instance.question, 'answer': instance.answer};
