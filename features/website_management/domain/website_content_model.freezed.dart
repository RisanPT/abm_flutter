// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'website_content_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WebsiteContentModel {

 String get singletonId; WebsiteHeroModel get hero; WebsiteAboutModel get about; List<WebsiteStatModel> get stats; List<WebsiteCommitteeModel> get committees; List<WebsiteEducationProgramModel> get educationPrograms; List<WebsiteStudyProgramModel> get studyPrograms; List<WebsiteEventModel> get upcomingEvents; List<WebsitePastEventModel> get pastEvents; List<WebsiteVideoModel> get videos; List<WebsitePhotoModel> get photos; List<WebsiteAlbumModel> get albums; List<WebsiteNewsModel> get newsArticles; List<WebsiteTestimonialModel> get testimonials; List<WebsiteMediaHighlightModel> get mediaHighlights; List<WebsiteFaqModel> get faqItems;
/// Create a copy of WebsiteContentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteContentModelCopyWith<WebsiteContentModel> get copyWith => _$WebsiteContentModelCopyWithImpl<WebsiteContentModel>(this as WebsiteContentModel, _$identity);

  /// Serializes this WebsiteContentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteContentModel&&(identical(other.singletonId, singletonId) || other.singletonId == singletonId)&&(identical(other.hero, hero) || other.hero == hero)&&(identical(other.about, about) || other.about == about)&&const DeepCollectionEquality().equals(other.stats, stats)&&const DeepCollectionEquality().equals(other.committees, committees)&&const DeepCollectionEquality().equals(other.educationPrograms, educationPrograms)&&const DeepCollectionEquality().equals(other.studyPrograms, studyPrograms)&&const DeepCollectionEquality().equals(other.upcomingEvents, upcomingEvents)&&const DeepCollectionEquality().equals(other.pastEvents, pastEvents)&&const DeepCollectionEquality().equals(other.videos, videos)&&const DeepCollectionEquality().equals(other.photos, photos)&&const DeepCollectionEquality().equals(other.albums, albums)&&const DeepCollectionEquality().equals(other.newsArticles, newsArticles)&&const DeepCollectionEquality().equals(other.testimonials, testimonials)&&const DeepCollectionEquality().equals(other.mediaHighlights, mediaHighlights)&&const DeepCollectionEquality().equals(other.faqItems, faqItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,singletonId,hero,about,const DeepCollectionEquality().hash(stats),const DeepCollectionEquality().hash(committees),const DeepCollectionEquality().hash(educationPrograms),const DeepCollectionEquality().hash(studyPrograms),const DeepCollectionEquality().hash(upcomingEvents),const DeepCollectionEquality().hash(pastEvents),const DeepCollectionEquality().hash(videos),const DeepCollectionEquality().hash(photos),const DeepCollectionEquality().hash(albums),const DeepCollectionEquality().hash(newsArticles),const DeepCollectionEquality().hash(testimonials),const DeepCollectionEquality().hash(mediaHighlights),const DeepCollectionEquality().hash(faqItems));

@override
String toString() {
  return 'WebsiteContentModel(singletonId: $singletonId, hero: $hero, about: $about, stats: $stats, committees: $committees, educationPrograms: $educationPrograms, studyPrograms: $studyPrograms, upcomingEvents: $upcomingEvents, pastEvents: $pastEvents, videos: $videos, photos: $photos, albums: $albums, newsArticles: $newsArticles, testimonials: $testimonials, mediaHighlights: $mediaHighlights, faqItems: $faqItems)';
}


}

/// @nodoc
abstract mixin class $WebsiteContentModelCopyWith<$Res>  {
  factory $WebsiteContentModelCopyWith(WebsiteContentModel value, $Res Function(WebsiteContentModel) _then) = _$WebsiteContentModelCopyWithImpl;
@useResult
$Res call({
 String singletonId, WebsiteHeroModel hero, WebsiteAboutModel about, List<WebsiteStatModel> stats, List<WebsiteCommitteeModel> committees, List<WebsiteEducationProgramModel> educationPrograms, List<WebsiteStudyProgramModel> studyPrograms, List<WebsiteEventModel> upcomingEvents, List<WebsitePastEventModel> pastEvents, List<WebsiteVideoModel> videos, List<WebsitePhotoModel> photos, List<WebsiteAlbumModel> albums, List<WebsiteNewsModel> newsArticles, List<WebsiteTestimonialModel> testimonials, List<WebsiteMediaHighlightModel> mediaHighlights, List<WebsiteFaqModel> faqItems
});


$WebsiteHeroModelCopyWith<$Res> get hero;$WebsiteAboutModelCopyWith<$Res> get about;

}
/// @nodoc
class _$WebsiteContentModelCopyWithImpl<$Res>
    implements $WebsiteContentModelCopyWith<$Res> {
  _$WebsiteContentModelCopyWithImpl(this._self, this._then);

  final WebsiteContentModel _self;
  final $Res Function(WebsiteContentModel) _then;

/// Create a copy of WebsiteContentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? singletonId = null,Object? hero = null,Object? about = null,Object? stats = null,Object? committees = null,Object? educationPrograms = null,Object? studyPrograms = null,Object? upcomingEvents = null,Object? pastEvents = null,Object? videos = null,Object? photos = null,Object? albums = null,Object? newsArticles = null,Object? testimonials = null,Object? mediaHighlights = null,Object? faqItems = null,}) {
  return _then(_self.copyWith(
singletonId: null == singletonId ? _self.singletonId : singletonId // ignore: cast_nullable_to_non_nullable
as String,hero: null == hero ? _self.hero : hero // ignore: cast_nullable_to_non_nullable
as WebsiteHeroModel,about: null == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as WebsiteAboutModel,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as List<WebsiteStatModel>,committees: null == committees ? _self.committees : committees // ignore: cast_nullable_to_non_nullable
as List<WebsiteCommitteeModel>,educationPrograms: null == educationPrograms ? _self.educationPrograms : educationPrograms // ignore: cast_nullable_to_non_nullable
as List<WebsiteEducationProgramModel>,studyPrograms: null == studyPrograms ? _self.studyPrograms : studyPrograms // ignore: cast_nullable_to_non_nullable
as List<WebsiteStudyProgramModel>,upcomingEvents: null == upcomingEvents ? _self.upcomingEvents : upcomingEvents // ignore: cast_nullable_to_non_nullable
as List<WebsiteEventModel>,pastEvents: null == pastEvents ? _self.pastEvents : pastEvents // ignore: cast_nullable_to_non_nullable
as List<WebsitePastEventModel>,videos: null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as List<WebsiteVideoModel>,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<WebsitePhotoModel>,albums: null == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<WebsiteAlbumModel>,newsArticles: null == newsArticles ? _self.newsArticles : newsArticles // ignore: cast_nullable_to_non_nullable
as List<WebsiteNewsModel>,testimonials: null == testimonials ? _self.testimonials : testimonials // ignore: cast_nullable_to_non_nullable
as List<WebsiteTestimonialModel>,mediaHighlights: null == mediaHighlights ? _self.mediaHighlights : mediaHighlights // ignore: cast_nullable_to_non_nullable
as List<WebsiteMediaHighlightModel>,faqItems: null == faqItems ? _self.faqItems : faqItems // ignore: cast_nullable_to_non_nullable
as List<WebsiteFaqModel>,
  ));
}
/// Create a copy of WebsiteContentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WebsiteHeroModelCopyWith<$Res> get hero {
  
  return $WebsiteHeroModelCopyWith<$Res>(_self.hero, (value) {
    return _then(_self.copyWith(hero: value));
  });
}/// Create a copy of WebsiteContentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WebsiteAboutModelCopyWith<$Res> get about {
  
  return $WebsiteAboutModelCopyWith<$Res>(_self.about, (value) {
    return _then(_self.copyWith(about: value));
  });
}
}


/// Adds pattern-matching-related methods to [WebsiteContentModel].
extension WebsiteContentModelPatterns on WebsiteContentModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteContentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteContentModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteContentModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteContentModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteContentModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteContentModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String singletonId,  WebsiteHeroModel hero,  WebsiteAboutModel about,  List<WebsiteStatModel> stats,  List<WebsiteCommitteeModel> committees,  List<WebsiteEducationProgramModel> educationPrograms,  List<WebsiteStudyProgramModel> studyPrograms,  List<WebsiteEventModel> upcomingEvents,  List<WebsitePastEventModel> pastEvents,  List<WebsiteVideoModel> videos,  List<WebsitePhotoModel> photos,  List<WebsiteAlbumModel> albums,  List<WebsiteNewsModel> newsArticles,  List<WebsiteTestimonialModel> testimonials,  List<WebsiteMediaHighlightModel> mediaHighlights,  List<WebsiteFaqModel> faqItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteContentModel() when $default != null:
return $default(_that.singletonId,_that.hero,_that.about,_that.stats,_that.committees,_that.educationPrograms,_that.studyPrograms,_that.upcomingEvents,_that.pastEvents,_that.videos,_that.photos,_that.albums,_that.newsArticles,_that.testimonials,_that.mediaHighlights,_that.faqItems);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String singletonId,  WebsiteHeroModel hero,  WebsiteAboutModel about,  List<WebsiteStatModel> stats,  List<WebsiteCommitteeModel> committees,  List<WebsiteEducationProgramModel> educationPrograms,  List<WebsiteStudyProgramModel> studyPrograms,  List<WebsiteEventModel> upcomingEvents,  List<WebsitePastEventModel> pastEvents,  List<WebsiteVideoModel> videos,  List<WebsitePhotoModel> photos,  List<WebsiteAlbumModel> albums,  List<WebsiteNewsModel> newsArticles,  List<WebsiteTestimonialModel> testimonials,  List<WebsiteMediaHighlightModel> mediaHighlights,  List<WebsiteFaqModel> faqItems)  $default,) {final _that = this;
switch (_that) {
case _WebsiteContentModel():
return $default(_that.singletonId,_that.hero,_that.about,_that.stats,_that.committees,_that.educationPrograms,_that.studyPrograms,_that.upcomingEvents,_that.pastEvents,_that.videos,_that.photos,_that.albums,_that.newsArticles,_that.testimonials,_that.mediaHighlights,_that.faqItems);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String singletonId,  WebsiteHeroModel hero,  WebsiteAboutModel about,  List<WebsiteStatModel> stats,  List<WebsiteCommitteeModel> committees,  List<WebsiteEducationProgramModel> educationPrograms,  List<WebsiteStudyProgramModel> studyPrograms,  List<WebsiteEventModel> upcomingEvents,  List<WebsitePastEventModel> pastEvents,  List<WebsiteVideoModel> videos,  List<WebsitePhotoModel> photos,  List<WebsiteAlbumModel> albums,  List<WebsiteNewsModel> newsArticles,  List<WebsiteTestimonialModel> testimonials,  List<WebsiteMediaHighlightModel> mediaHighlights,  List<WebsiteFaqModel> faqItems)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteContentModel() when $default != null:
return $default(_that.singletonId,_that.hero,_that.about,_that.stats,_that.committees,_that.educationPrograms,_that.studyPrograms,_that.upcomingEvents,_that.pastEvents,_that.videos,_that.photos,_that.albums,_that.newsArticles,_that.testimonials,_that.mediaHighlights,_that.faqItems);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteContentModel implements WebsiteContentModel {
  const _WebsiteContentModel({this.singletonId = 'default', this.hero = const WebsiteHeroModel(), this.about = const WebsiteAboutModel(), final  List<WebsiteStatModel> stats = const [], final  List<WebsiteCommitteeModel> committees = const [], final  List<WebsiteEducationProgramModel> educationPrograms = const [], final  List<WebsiteStudyProgramModel> studyPrograms = const [], final  List<WebsiteEventModel> upcomingEvents = const [], final  List<WebsitePastEventModel> pastEvents = const [], final  List<WebsiteVideoModel> videos = const [], final  List<WebsitePhotoModel> photos = const [], final  List<WebsiteAlbumModel> albums = const [], final  List<WebsiteNewsModel> newsArticles = const [], final  List<WebsiteTestimonialModel> testimonials = const [], final  List<WebsiteMediaHighlightModel> mediaHighlights = const [], final  List<WebsiteFaqModel> faqItems = const []}): _stats = stats,_committees = committees,_educationPrograms = educationPrograms,_studyPrograms = studyPrograms,_upcomingEvents = upcomingEvents,_pastEvents = pastEvents,_videos = videos,_photos = photos,_albums = albums,_newsArticles = newsArticles,_testimonials = testimonials,_mediaHighlights = mediaHighlights,_faqItems = faqItems;
  factory _WebsiteContentModel.fromJson(Map<String, dynamic> json) => _$WebsiteContentModelFromJson(json);

@override@JsonKey() final  String singletonId;
@override@JsonKey() final  WebsiteHeroModel hero;
@override@JsonKey() final  WebsiteAboutModel about;
 final  List<WebsiteStatModel> _stats;
@override@JsonKey() List<WebsiteStatModel> get stats {
  if (_stats is EqualUnmodifiableListView) return _stats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stats);
}

 final  List<WebsiteCommitteeModel> _committees;
@override@JsonKey() List<WebsiteCommitteeModel> get committees {
  if (_committees is EqualUnmodifiableListView) return _committees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_committees);
}

 final  List<WebsiteEducationProgramModel> _educationPrograms;
@override@JsonKey() List<WebsiteEducationProgramModel> get educationPrograms {
  if (_educationPrograms is EqualUnmodifiableListView) return _educationPrograms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_educationPrograms);
}

 final  List<WebsiteStudyProgramModel> _studyPrograms;
@override@JsonKey() List<WebsiteStudyProgramModel> get studyPrograms {
  if (_studyPrograms is EqualUnmodifiableListView) return _studyPrograms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_studyPrograms);
}

 final  List<WebsiteEventModel> _upcomingEvents;
@override@JsonKey() List<WebsiteEventModel> get upcomingEvents {
  if (_upcomingEvents is EqualUnmodifiableListView) return _upcomingEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcomingEvents);
}

 final  List<WebsitePastEventModel> _pastEvents;
@override@JsonKey() List<WebsitePastEventModel> get pastEvents {
  if (_pastEvents is EqualUnmodifiableListView) return _pastEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pastEvents);
}

 final  List<WebsiteVideoModel> _videos;
@override@JsonKey() List<WebsiteVideoModel> get videos {
  if (_videos is EqualUnmodifiableListView) return _videos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videos);
}

 final  List<WebsitePhotoModel> _photos;
@override@JsonKey() List<WebsitePhotoModel> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

 final  List<WebsiteAlbumModel> _albums;
@override@JsonKey() List<WebsiteAlbumModel> get albums {
  if (_albums is EqualUnmodifiableListView) return _albums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albums);
}

 final  List<WebsiteNewsModel> _newsArticles;
@override@JsonKey() List<WebsiteNewsModel> get newsArticles {
  if (_newsArticles is EqualUnmodifiableListView) return _newsArticles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newsArticles);
}

 final  List<WebsiteTestimonialModel> _testimonials;
@override@JsonKey() List<WebsiteTestimonialModel> get testimonials {
  if (_testimonials is EqualUnmodifiableListView) return _testimonials;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_testimonials);
}

 final  List<WebsiteMediaHighlightModel> _mediaHighlights;
@override@JsonKey() List<WebsiteMediaHighlightModel> get mediaHighlights {
  if (_mediaHighlights is EqualUnmodifiableListView) return _mediaHighlights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaHighlights);
}

 final  List<WebsiteFaqModel> _faqItems;
@override@JsonKey() List<WebsiteFaqModel> get faqItems {
  if (_faqItems is EqualUnmodifiableListView) return _faqItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_faqItems);
}


/// Create a copy of WebsiteContentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteContentModelCopyWith<_WebsiteContentModel> get copyWith => __$WebsiteContentModelCopyWithImpl<_WebsiteContentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteContentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteContentModel&&(identical(other.singletonId, singletonId) || other.singletonId == singletonId)&&(identical(other.hero, hero) || other.hero == hero)&&(identical(other.about, about) || other.about == about)&&const DeepCollectionEquality().equals(other._stats, _stats)&&const DeepCollectionEquality().equals(other._committees, _committees)&&const DeepCollectionEquality().equals(other._educationPrograms, _educationPrograms)&&const DeepCollectionEquality().equals(other._studyPrograms, _studyPrograms)&&const DeepCollectionEquality().equals(other._upcomingEvents, _upcomingEvents)&&const DeepCollectionEquality().equals(other._pastEvents, _pastEvents)&&const DeepCollectionEquality().equals(other._videos, _videos)&&const DeepCollectionEquality().equals(other._photos, _photos)&&const DeepCollectionEquality().equals(other._albums, _albums)&&const DeepCollectionEquality().equals(other._newsArticles, _newsArticles)&&const DeepCollectionEquality().equals(other._testimonials, _testimonials)&&const DeepCollectionEquality().equals(other._mediaHighlights, _mediaHighlights)&&const DeepCollectionEquality().equals(other._faqItems, _faqItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,singletonId,hero,about,const DeepCollectionEquality().hash(_stats),const DeepCollectionEquality().hash(_committees),const DeepCollectionEquality().hash(_educationPrograms),const DeepCollectionEquality().hash(_studyPrograms),const DeepCollectionEquality().hash(_upcomingEvents),const DeepCollectionEquality().hash(_pastEvents),const DeepCollectionEquality().hash(_videos),const DeepCollectionEquality().hash(_photos),const DeepCollectionEquality().hash(_albums),const DeepCollectionEquality().hash(_newsArticles),const DeepCollectionEquality().hash(_testimonials),const DeepCollectionEquality().hash(_mediaHighlights),const DeepCollectionEquality().hash(_faqItems));

@override
String toString() {
  return 'WebsiteContentModel(singletonId: $singletonId, hero: $hero, about: $about, stats: $stats, committees: $committees, educationPrograms: $educationPrograms, studyPrograms: $studyPrograms, upcomingEvents: $upcomingEvents, pastEvents: $pastEvents, videos: $videos, photos: $photos, albums: $albums, newsArticles: $newsArticles, testimonials: $testimonials, mediaHighlights: $mediaHighlights, faqItems: $faqItems)';
}


}

/// @nodoc
abstract mixin class _$WebsiteContentModelCopyWith<$Res> implements $WebsiteContentModelCopyWith<$Res> {
  factory _$WebsiteContentModelCopyWith(_WebsiteContentModel value, $Res Function(_WebsiteContentModel) _then) = __$WebsiteContentModelCopyWithImpl;
@override @useResult
$Res call({
 String singletonId, WebsiteHeroModel hero, WebsiteAboutModel about, List<WebsiteStatModel> stats, List<WebsiteCommitteeModel> committees, List<WebsiteEducationProgramModel> educationPrograms, List<WebsiteStudyProgramModel> studyPrograms, List<WebsiteEventModel> upcomingEvents, List<WebsitePastEventModel> pastEvents, List<WebsiteVideoModel> videos, List<WebsitePhotoModel> photos, List<WebsiteAlbumModel> albums, List<WebsiteNewsModel> newsArticles, List<WebsiteTestimonialModel> testimonials, List<WebsiteMediaHighlightModel> mediaHighlights, List<WebsiteFaqModel> faqItems
});


@override $WebsiteHeroModelCopyWith<$Res> get hero;@override $WebsiteAboutModelCopyWith<$Res> get about;

}
/// @nodoc
class __$WebsiteContentModelCopyWithImpl<$Res>
    implements _$WebsiteContentModelCopyWith<$Res> {
  __$WebsiteContentModelCopyWithImpl(this._self, this._then);

  final _WebsiteContentModel _self;
  final $Res Function(_WebsiteContentModel) _then;

/// Create a copy of WebsiteContentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? singletonId = null,Object? hero = null,Object? about = null,Object? stats = null,Object? committees = null,Object? educationPrograms = null,Object? studyPrograms = null,Object? upcomingEvents = null,Object? pastEvents = null,Object? videos = null,Object? photos = null,Object? albums = null,Object? newsArticles = null,Object? testimonials = null,Object? mediaHighlights = null,Object? faqItems = null,}) {
  return _then(_WebsiteContentModel(
singletonId: null == singletonId ? _self.singletonId : singletonId // ignore: cast_nullable_to_non_nullable
as String,hero: null == hero ? _self.hero : hero // ignore: cast_nullable_to_non_nullable
as WebsiteHeroModel,about: null == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as WebsiteAboutModel,stats: null == stats ? _self._stats : stats // ignore: cast_nullable_to_non_nullable
as List<WebsiteStatModel>,committees: null == committees ? _self._committees : committees // ignore: cast_nullable_to_non_nullable
as List<WebsiteCommitteeModel>,educationPrograms: null == educationPrograms ? _self._educationPrograms : educationPrograms // ignore: cast_nullable_to_non_nullable
as List<WebsiteEducationProgramModel>,studyPrograms: null == studyPrograms ? _self._studyPrograms : studyPrograms // ignore: cast_nullable_to_non_nullable
as List<WebsiteStudyProgramModel>,upcomingEvents: null == upcomingEvents ? _self._upcomingEvents : upcomingEvents // ignore: cast_nullable_to_non_nullable
as List<WebsiteEventModel>,pastEvents: null == pastEvents ? _self._pastEvents : pastEvents // ignore: cast_nullable_to_non_nullable
as List<WebsitePastEventModel>,videos: null == videos ? _self._videos : videos // ignore: cast_nullable_to_non_nullable
as List<WebsiteVideoModel>,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<WebsitePhotoModel>,albums: null == albums ? _self._albums : albums // ignore: cast_nullable_to_non_nullable
as List<WebsiteAlbumModel>,newsArticles: null == newsArticles ? _self._newsArticles : newsArticles // ignore: cast_nullable_to_non_nullable
as List<WebsiteNewsModel>,testimonials: null == testimonials ? _self._testimonials : testimonials // ignore: cast_nullable_to_non_nullable
as List<WebsiteTestimonialModel>,mediaHighlights: null == mediaHighlights ? _self._mediaHighlights : mediaHighlights // ignore: cast_nullable_to_non_nullable
as List<WebsiteMediaHighlightModel>,faqItems: null == faqItems ? _self._faqItems : faqItems // ignore: cast_nullable_to_non_nullable
as List<WebsiteFaqModel>,
  ));
}

/// Create a copy of WebsiteContentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WebsiteHeroModelCopyWith<$Res> get hero {
  
  return $WebsiteHeroModelCopyWith<$Res>(_self.hero, (value) {
    return _then(_self.copyWith(hero: value));
  });
}/// Create a copy of WebsiteContentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WebsiteAboutModelCopyWith<$Res> get about {
  
  return $WebsiteAboutModelCopyWith<$Res>(_self.about, (value) {
    return _then(_self.copyWith(about: value));
  });
}
}


/// @nodoc
mixin _$WebsiteHeroModel {

 String get kicker; String get titlePrefix; String get titleHighlight; String get titleSuffix; String get subtitle; String get description; List<String> get highlights; String get image;
/// Create a copy of WebsiteHeroModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteHeroModelCopyWith<WebsiteHeroModel> get copyWith => _$WebsiteHeroModelCopyWithImpl<WebsiteHeroModel>(this as WebsiteHeroModel, _$identity);

  /// Serializes this WebsiteHeroModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteHeroModel&&(identical(other.kicker, kicker) || other.kicker == kicker)&&(identical(other.titlePrefix, titlePrefix) || other.titlePrefix == titlePrefix)&&(identical(other.titleHighlight, titleHighlight) || other.titleHighlight == titleHighlight)&&(identical(other.titleSuffix, titleSuffix) || other.titleSuffix == titleSuffix)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.highlights, highlights)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kicker,titlePrefix,titleHighlight,titleSuffix,subtitle,description,const DeepCollectionEquality().hash(highlights),image);

@override
String toString() {
  return 'WebsiteHeroModel(kicker: $kicker, titlePrefix: $titlePrefix, titleHighlight: $titleHighlight, titleSuffix: $titleSuffix, subtitle: $subtitle, description: $description, highlights: $highlights, image: $image)';
}


}

/// @nodoc
abstract mixin class $WebsiteHeroModelCopyWith<$Res>  {
  factory $WebsiteHeroModelCopyWith(WebsiteHeroModel value, $Res Function(WebsiteHeroModel) _then) = _$WebsiteHeroModelCopyWithImpl;
@useResult
$Res call({
 String kicker, String titlePrefix, String titleHighlight, String titleSuffix, String subtitle, String description, List<String> highlights, String image
});




}
/// @nodoc
class _$WebsiteHeroModelCopyWithImpl<$Res>
    implements $WebsiteHeroModelCopyWith<$Res> {
  _$WebsiteHeroModelCopyWithImpl(this._self, this._then);

  final WebsiteHeroModel _self;
  final $Res Function(WebsiteHeroModel) _then;

/// Create a copy of WebsiteHeroModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kicker = null,Object? titlePrefix = null,Object? titleHighlight = null,Object? titleSuffix = null,Object? subtitle = null,Object? description = null,Object? highlights = null,Object? image = null,}) {
  return _then(_self.copyWith(
kicker: null == kicker ? _self.kicker : kicker // ignore: cast_nullable_to_non_nullable
as String,titlePrefix: null == titlePrefix ? _self.titlePrefix : titlePrefix // ignore: cast_nullable_to_non_nullable
as String,titleHighlight: null == titleHighlight ? _self.titleHighlight : titleHighlight // ignore: cast_nullable_to_non_nullable
as String,titleSuffix: null == titleSuffix ? _self.titleSuffix : titleSuffix // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,highlights: null == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteHeroModel].
extension WebsiteHeroModelPatterns on WebsiteHeroModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteHeroModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteHeroModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteHeroModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteHeroModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteHeroModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteHeroModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kicker,  String titlePrefix,  String titleHighlight,  String titleSuffix,  String subtitle,  String description,  List<String> highlights,  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteHeroModel() when $default != null:
return $default(_that.kicker,_that.titlePrefix,_that.titleHighlight,_that.titleSuffix,_that.subtitle,_that.description,_that.highlights,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kicker,  String titlePrefix,  String titleHighlight,  String titleSuffix,  String subtitle,  String description,  List<String> highlights,  String image)  $default,) {final _that = this;
switch (_that) {
case _WebsiteHeroModel():
return $default(_that.kicker,_that.titlePrefix,_that.titleHighlight,_that.titleSuffix,_that.subtitle,_that.description,_that.highlights,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kicker,  String titlePrefix,  String titleHighlight,  String titleSuffix,  String subtitle,  String description,  List<String> highlights,  String image)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteHeroModel() when $default != null:
return $default(_that.kicker,_that.titlePrefix,_that.titleHighlight,_that.titleSuffix,_that.subtitle,_that.description,_that.highlights,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteHeroModel implements WebsiteHeroModel {
  const _WebsiteHeroModel({this.kicker = 'JDCC / ISLAHI CENTER', this.titlePrefix = 'Building', this.titleHighlight = 'faith-centered learning', this.titleSuffix = 'for families and communities', this.subtitle = 'Islamic education, local guidance, and meaningful community participation in one connected institution.', this.description = 'JDCC / ISLAHI CENTER is a modern Islamic educational and community institution developing confident learners, connected families, and purposeful service across every area it serves.', final  List<String> highlights = const [], this.image = '/hero_bg.png'}): _highlights = highlights;
  factory _WebsiteHeroModel.fromJson(Map<String, dynamic> json) => _$WebsiteHeroModelFromJson(json);

@override@JsonKey() final  String kicker;
@override@JsonKey() final  String titlePrefix;
@override@JsonKey() final  String titleHighlight;
@override@JsonKey() final  String titleSuffix;
@override@JsonKey() final  String subtitle;
@override@JsonKey() final  String description;
 final  List<String> _highlights;
@override@JsonKey() List<String> get highlights {
  if (_highlights is EqualUnmodifiableListView) return _highlights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_highlights);
}

@override@JsonKey() final  String image;

/// Create a copy of WebsiteHeroModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteHeroModelCopyWith<_WebsiteHeroModel> get copyWith => __$WebsiteHeroModelCopyWithImpl<_WebsiteHeroModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteHeroModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteHeroModel&&(identical(other.kicker, kicker) || other.kicker == kicker)&&(identical(other.titlePrefix, titlePrefix) || other.titlePrefix == titlePrefix)&&(identical(other.titleHighlight, titleHighlight) || other.titleHighlight == titleHighlight)&&(identical(other.titleSuffix, titleSuffix) || other.titleSuffix == titleSuffix)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._highlights, _highlights)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kicker,titlePrefix,titleHighlight,titleSuffix,subtitle,description,const DeepCollectionEquality().hash(_highlights),image);

@override
String toString() {
  return 'WebsiteHeroModel(kicker: $kicker, titlePrefix: $titlePrefix, titleHighlight: $titleHighlight, titleSuffix: $titleSuffix, subtitle: $subtitle, description: $description, highlights: $highlights, image: $image)';
}


}

/// @nodoc
abstract mixin class _$WebsiteHeroModelCopyWith<$Res> implements $WebsiteHeroModelCopyWith<$Res> {
  factory _$WebsiteHeroModelCopyWith(_WebsiteHeroModel value, $Res Function(_WebsiteHeroModel) _then) = __$WebsiteHeroModelCopyWithImpl;
@override @useResult
$Res call({
 String kicker, String titlePrefix, String titleHighlight, String titleSuffix, String subtitle, String description, List<String> highlights, String image
});




}
/// @nodoc
class __$WebsiteHeroModelCopyWithImpl<$Res>
    implements _$WebsiteHeroModelCopyWith<$Res> {
  __$WebsiteHeroModelCopyWithImpl(this._self, this._then);

  final _WebsiteHeroModel _self;
  final $Res Function(_WebsiteHeroModel) _then;

/// Create a copy of WebsiteHeroModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kicker = null,Object? titlePrefix = null,Object? titleHighlight = null,Object? titleSuffix = null,Object? subtitle = null,Object? description = null,Object? highlights = null,Object? image = null,}) {
  return _then(_WebsiteHeroModel(
kicker: null == kicker ? _self.kicker : kicker // ignore: cast_nullable_to_non_nullable
as String,titlePrefix: null == titlePrefix ? _self.titlePrefix : titlePrefix // ignore: cast_nullable_to_non_nullable
as String,titleHighlight: null == titleHighlight ? _self.titleHighlight : titleHighlight // ignore: cast_nullable_to_non_nullable
as String,titleSuffix: null == titleSuffix ? _self.titleSuffix : titleSuffix // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,highlights: null == highlights ? _self._highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteAboutModel {

 String get heading; String get title; String get description1; String get description2; String get image;
/// Create a copy of WebsiteAboutModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteAboutModelCopyWith<WebsiteAboutModel> get copyWith => _$WebsiteAboutModelCopyWithImpl<WebsiteAboutModel>(this as WebsiteAboutModel, _$identity);

  /// Serializes this WebsiteAboutModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteAboutModel&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.title, title) || other.title == title)&&(identical(other.description1, description1) || other.description1 == description1)&&(identical(other.description2, description2) || other.description2 == description2)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,heading,title,description1,description2,image);

@override
String toString() {
  return 'WebsiteAboutModel(heading: $heading, title: $title, description1: $description1, description2: $description2, image: $image)';
}


}

/// @nodoc
abstract mixin class $WebsiteAboutModelCopyWith<$Res>  {
  factory $WebsiteAboutModelCopyWith(WebsiteAboutModel value, $Res Function(WebsiteAboutModel) _then) = _$WebsiteAboutModelCopyWithImpl;
@useResult
$Res call({
 String heading, String title, String description1, String description2, String image
});




}
/// @nodoc
class _$WebsiteAboutModelCopyWithImpl<$Res>
    implements $WebsiteAboutModelCopyWith<$Res> {
  _$WebsiteAboutModelCopyWithImpl(this._self, this._then);

  final WebsiteAboutModel _self;
  final $Res Function(WebsiteAboutModel) _then;

/// Create a copy of WebsiteAboutModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? heading = null,Object? title = null,Object? description1 = null,Object? description2 = null,Object? image = null,}) {
  return _then(_self.copyWith(
heading: null == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description1: null == description1 ? _self.description1 : description1 // ignore: cast_nullable_to_non_nullable
as String,description2: null == description2 ? _self.description2 : description2 // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteAboutModel].
extension WebsiteAboutModelPatterns on WebsiteAboutModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteAboutModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteAboutModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteAboutModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteAboutModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteAboutModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteAboutModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String heading,  String title,  String description1,  String description2,  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteAboutModel() when $default != null:
return $default(_that.heading,_that.title,_that.description1,_that.description2,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String heading,  String title,  String description1,  String description2,  String image)  $default,) {final _that = this;
switch (_that) {
case _WebsiteAboutModel():
return $default(_that.heading,_that.title,_that.description1,_that.description2,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String heading,  String title,  String description1,  String description2,  String image)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteAboutModel() when $default != null:
return $default(_that.heading,_that.title,_that.description1,_that.description2,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteAboutModel implements WebsiteAboutModel {
  const _WebsiteAboutModel({this.heading = 'ABOUT JDCC', this.title = 'A trusted institution helping faith take root in everyday life.', this.description1 = 'JDCC / ISLAHI CENTER brings together educational initiatives, local committees, youth development, and civic outreach under one clear mission: nurturing a confident, compassionate Muslim community grounded in knowledge and service.', this.description2 = 'This redesign uses editable sample content so the team can quickly replace descriptions, names, and statistics with official copy while keeping the full premium presentation intact.', this.image = '/slide1.png'});
  factory _WebsiteAboutModel.fromJson(Map<String, dynamic> json) => _$WebsiteAboutModelFromJson(json);

@override@JsonKey() final  String heading;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description1;
@override@JsonKey() final  String description2;
@override@JsonKey() final  String image;

/// Create a copy of WebsiteAboutModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteAboutModelCopyWith<_WebsiteAboutModel> get copyWith => __$WebsiteAboutModelCopyWithImpl<_WebsiteAboutModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteAboutModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteAboutModel&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.title, title) || other.title == title)&&(identical(other.description1, description1) || other.description1 == description1)&&(identical(other.description2, description2) || other.description2 == description2)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,heading,title,description1,description2,image);

@override
String toString() {
  return 'WebsiteAboutModel(heading: $heading, title: $title, description1: $description1, description2: $description2, image: $image)';
}


}

/// @nodoc
abstract mixin class _$WebsiteAboutModelCopyWith<$Res> implements $WebsiteAboutModelCopyWith<$Res> {
  factory _$WebsiteAboutModelCopyWith(_WebsiteAboutModel value, $Res Function(_WebsiteAboutModel) _then) = __$WebsiteAboutModelCopyWithImpl;
@override @useResult
$Res call({
 String heading, String title, String description1, String description2, String image
});




}
/// @nodoc
class __$WebsiteAboutModelCopyWithImpl<$Res>
    implements _$WebsiteAboutModelCopyWith<$Res> {
  __$WebsiteAboutModelCopyWithImpl(this._self, this._then);

  final _WebsiteAboutModel _self;
  final $Res Function(_WebsiteAboutModel) _then;

/// Create a copy of WebsiteAboutModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? heading = null,Object? title = null,Object? description1 = null,Object? description2 = null,Object? image = null,}) {
  return _then(_WebsiteAboutModel(
heading: null == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description1: null == description1 ? _self.description1 : description1 // ignore: cast_nullable_to_non_nullable
as String,description2: null == description2 ? _self.description2 : description2 // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteStatModel {

 int get value; String get label; String get suffix;
/// Create a copy of WebsiteStatModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteStatModelCopyWith<WebsiteStatModel> get copyWith => _$WebsiteStatModelCopyWithImpl<WebsiteStatModel>(this as WebsiteStatModel, _$identity);

  /// Serializes this WebsiteStatModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteStatModel&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label)&&(identical(other.suffix, suffix) || other.suffix == suffix));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,label,suffix);

@override
String toString() {
  return 'WebsiteStatModel(value: $value, label: $label, suffix: $suffix)';
}


}

/// @nodoc
abstract mixin class $WebsiteStatModelCopyWith<$Res>  {
  factory $WebsiteStatModelCopyWith(WebsiteStatModel value, $Res Function(WebsiteStatModel) _then) = _$WebsiteStatModelCopyWithImpl;
@useResult
$Res call({
 int value, String label, String suffix
});




}
/// @nodoc
class _$WebsiteStatModelCopyWithImpl<$Res>
    implements $WebsiteStatModelCopyWith<$Res> {
  _$WebsiteStatModelCopyWithImpl(this._self, this._then);

  final WebsiteStatModel _self;
  final $Res Function(WebsiteStatModel) _then;

/// Create a copy of WebsiteStatModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? label = null,Object? suffix = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,suffix: null == suffix ? _self.suffix : suffix // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteStatModel].
extension WebsiteStatModelPatterns on WebsiteStatModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteStatModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteStatModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteStatModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteStatModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteStatModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteStatModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int value,  String label,  String suffix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteStatModel() when $default != null:
return $default(_that.value,_that.label,_that.suffix);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value,  String label,  String suffix)  $default,) {final _that = this;
switch (_that) {
case _WebsiteStatModel():
return $default(_that.value,_that.label,_that.suffix);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int value,  String label,  String suffix)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteStatModel() when $default != null:
return $default(_that.value,_that.label,_that.suffix);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteStatModel implements WebsiteStatModel {
  const _WebsiteStatModel({this.value = 0, this.label = '', this.suffix = ''});
  factory _WebsiteStatModel.fromJson(Map<String, dynamic> json) => _$WebsiteStatModelFromJson(json);

@override@JsonKey() final  int value;
@override@JsonKey() final  String label;
@override@JsonKey() final  String suffix;

/// Create a copy of WebsiteStatModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteStatModelCopyWith<_WebsiteStatModel> get copyWith => __$WebsiteStatModelCopyWithImpl<_WebsiteStatModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteStatModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteStatModel&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label)&&(identical(other.suffix, suffix) || other.suffix == suffix));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,label,suffix);

@override
String toString() {
  return 'WebsiteStatModel(value: $value, label: $label, suffix: $suffix)';
}


}

/// @nodoc
abstract mixin class _$WebsiteStatModelCopyWith<$Res> implements $WebsiteStatModelCopyWith<$Res> {
  factory _$WebsiteStatModelCopyWith(_WebsiteStatModel value, $Res Function(_WebsiteStatModel) _then) = __$WebsiteStatModelCopyWithImpl;
@override @useResult
$Res call({
 int value, String label, String suffix
});




}
/// @nodoc
class __$WebsiteStatModelCopyWithImpl<$Res>
    implements _$WebsiteStatModelCopyWith<$Res> {
  __$WebsiteStatModelCopyWithImpl(this._self, this._then);

  final _WebsiteStatModel _self;
  final $Res Function(_WebsiteStatModel) _then;

/// Create a copy of WebsiteStatModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? label = null,Object? suffix = null,}) {
  return _then(_WebsiteStatModel(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,suffix: null == suffix ? _self.suffix : suffix // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteCommitteeModel {

 String get name; String get group; String get area; String get coordinator; int get members; String get description;
/// Create a copy of WebsiteCommitteeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteCommitteeModelCopyWith<WebsiteCommitteeModel> get copyWith => _$WebsiteCommitteeModelCopyWithImpl<WebsiteCommitteeModel>(this as WebsiteCommitteeModel, _$identity);

  /// Serializes this WebsiteCommitteeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteCommitteeModel&&(identical(other.name, name) || other.name == name)&&(identical(other.group, group) || other.group == group)&&(identical(other.area, area) || other.area == area)&&(identical(other.coordinator, coordinator) || other.coordinator == coordinator)&&(identical(other.members, members) || other.members == members)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,group,area,coordinator,members,description);

@override
String toString() {
  return 'WebsiteCommitteeModel(name: $name, group: $group, area: $area, coordinator: $coordinator, members: $members, description: $description)';
}


}

/// @nodoc
abstract mixin class $WebsiteCommitteeModelCopyWith<$Res>  {
  factory $WebsiteCommitteeModelCopyWith(WebsiteCommitteeModel value, $Res Function(WebsiteCommitteeModel) _then) = _$WebsiteCommitteeModelCopyWithImpl;
@useResult
$Res call({
 String name, String group, String area, String coordinator, int members, String description
});




}
/// @nodoc
class _$WebsiteCommitteeModelCopyWithImpl<$Res>
    implements $WebsiteCommitteeModelCopyWith<$Res> {
  _$WebsiteCommitteeModelCopyWithImpl(this._self, this._then);

  final WebsiteCommitteeModel _self;
  final $Res Function(WebsiteCommitteeModel) _then;

/// Create a copy of WebsiteCommitteeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? group = null,Object? area = null,Object? coordinator = null,Object? members = null,Object? description = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,coordinator: null == coordinator ? _self.coordinator : coordinator // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteCommitteeModel].
extension WebsiteCommitteeModelPatterns on WebsiteCommitteeModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteCommitteeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteCommitteeModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteCommitteeModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteCommitteeModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteCommitteeModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteCommitteeModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String group,  String area,  String coordinator,  int members,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteCommitteeModel() when $default != null:
return $default(_that.name,_that.group,_that.area,_that.coordinator,_that.members,_that.description);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String group,  String area,  String coordinator,  int members,  String description)  $default,) {final _that = this;
switch (_that) {
case _WebsiteCommitteeModel():
return $default(_that.name,_that.group,_that.area,_that.coordinator,_that.members,_that.description);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String group,  String area,  String coordinator,  int members,  String description)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteCommitteeModel() when $default != null:
return $default(_that.name,_that.group,_that.area,_that.coordinator,_that.members,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteCommitteeModel implements WebsiteCommitteeModel {
  const _WebsiteCommitteeModel({this.name = '', this.group = '', this.area = '', this.coordinator = '', this.members = 0, this.description = ''});
  factory _WebsiteCommitteeModel.fromJson(Map<String, dynamic> json) => _$WebsiteCommitteeModelFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String group;
@override@JsonKey() final  String area;
@override@JsonKey() final  String coordinator;
@override@JsonKey() final  int members;
@override@JsonKey() final  String description;

/// Create a copy of WebsiteCommitteeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteCommitteeModelCopyWith<_WebsiteCommitteeModel> get copyWith => __$WebsiteCommitteeModelCopyWithImpl<_WebsiteCommitteeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteCommitteeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteCommitteeModel&&(identical(other.name, name) || other.name == name)&&(identical(other.group, group) || other.group == group)&&(identical(other.area, area) || other.area == area)&&(identical(other.coordinator, coordinator) || other.coordinator == coordinator)&&(identical(other.members, members) || other.members == members)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,group,area,coordinator,members,description);

@override
String toString() {
  return 'WebsiteCommitteeModel(name: $name, group: $group, area: $area, coordinator: $coordinator, members: $members, description: $description)';
}


}

/// @nodoc
abstract mixin class _$WebsiteCommitteeModelCopyWith<$Res> implements $WebsiteCommitteeModelCopyWith<$Res> {
  factory _$WebsiteCommitteeModelCopyWith(_WebsiteCommitteeModel value, $Res Function(_WebsiteCommitteeModel) _then) = __$WebsiteCommitteeModelCopyWithImpl;
@override @useResult
$Res call({
 String name, String group, String area, String coordinator, int members, String description
});




}
/// @nodoc
class __$WebsiteCommitteeModelCopyWithImpl<$Res>
    implements _$WebsiteCommitteeModelCopyWith<$Res> {
  __$WebsiteCommitteeModelCopyWithImpl(this._self, this._then);

  final _WebsiteCommitteeModel _self;
  final $Res Function(_WebsiteCommitteeModel) _then;

/// Create a copy of WebsiteCommitteeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? group = null,Object? area = null,Object? coordinator = null,Object? members = null,Object? description = null,}) {
  return _then(_WebsiteCommitteeModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,coordinator: null == coordinator ? _self.coordinator : coordinator // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteEducationProgramModel {

 String get title; String get subtitle; String get objectives; List<String> get details; String get admission; String get icon;
/// Create a copy of WebsiteEducationProgramModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteEducationProgramModelCopyWith<WebsiteEducationProgramModel> get copyWith => _$WebsiteEducationProgramModelCopyWithImpl<WebsiteEducationProgramModel>(this as WebsiteEducationProgramModel, _$identity);

  /// Serializes this WebsiteEducationProgramModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteEducationProgramModel&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.objectives, objectives) || other.objectives == objectives)&&const DeepCollectionEquality().equals(other.details, details)&&(identical(other.admission, admission) || other.admission == admission)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,subtitle,objectives,const DeepCollectionEquality().hash(details),admission,icon);

@override
String toString() {
  return 'WebsiteEducationProgramModel(title: $title, subtitle: $subtitle, objectives: $objectives, details: $details, admission: $admission, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $WebsiteEducationProgramModelCopyWith<$Res>  {
  factory $WebsiteEducationProgramModelCopyWith(WebsiteEducationProgramModel value, $Res Function(WebsiteEducationProgramModel) _then) = _$WebsiteEducationProgramModelCopyWithImpl;
@useResult
$Res call({
 String title, String subtitle, String objectives, List<String> details, String admission, String icon
});




}
/// @nodoc
class _$WebsiteEducationProgramModelCopyWithImpl<$Res>
    implements $WebsiteEducationProgramModelCopyWith<$Res> {
  _$WebsiteEducationProgramModelCopyWithImpl(this._self, this._then);

  final WebsiteEducationProgramModel _self;
  final $Res Function(WebsiteEducationProgramModel) _then;

/// Create a copy of WebsiteEducationProgramModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? subtitle = null,Object? objectives = null,Object? details = null,Object? admission = null,Object? icon = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,objectives: null == objectives ? _self.objectives : objectives // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as List<String>,admission: null == admission ? _self.admission : admission // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteEducationProgramModel].
extension WebsiteEducationProgramModelPatterns on WebsiteEducationProgramModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteEducationProgramModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteEducationProgramModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteEducationProgramModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteEducationProgramModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteEducationProgramModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteEducationProgramModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String subtitle,  String objectives,  List<String> details,  String admission,  String icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteEducationProgramModel() when $default != null:
return $default(_that.title,_that.subtitle,_that.objectives,_that.details,_that.admission,_that.icon);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String subtitle,  String objectives,  List<String> details,  String admission,  String icon)  $default,) {final _that = this;
switch (_that) {
case _WebsiteEducationProgramModel():
return $default(_that.title,_that.subtitle,_that.objectives,_that.details,_that.admission,_that.icon);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String subtitle,  String objectives,  List<String> details,  String admission,  String icon)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteEducationProgramModel() when $default != null:
return $default(_that.title,_that.subtitle,_that.objectives,_that.details,_that.admission,_that.icon);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteEducationProgramModel implements WebsiteEducationProgramModel {
  const _WebsiteEducationProgramModel({this.title = '', this.subtitle = '', this.objectives = '', final  List<String> details = const [], this.admission = '', this.icon = ''}): _details = details;
  factory _WebsiteEducationProgramModel.fromJson(Map<String, dynamic> json) => _$WebsiteEducationProgramModelFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  String subtitle;
@override@JsonKey() final  String objectives;
 final  List<String> _details;
@override@JsonKey() List<String> get details {
  if (_details is EqualUnmodifiableListView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_details);
}

@override@JsonKey() final  String admission;
@override@JsonKey() final  String icon;

/// Create a copy of WebsiteEducationProgramModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteEducationProgramModelCopyWith<_WebsiteEducationProgramModel> get copyWith => __$WebsiteEducationProgramModelCopyWithImpl<_WebsiteEducationProgramModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteEducationProgramModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteEducationProgramModel&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.objectives, objectives) || other.objectives == objectives)&&const DeepCollectionEquality().equals(other._details, _details)&&(identical(other.admission, admission) || other.admission == admission)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,subtitle,objectives,const DeepCollectionEquality().hash(_details),admission,icon);

@override
String toString() {
  return 'WebsiteEducationProgramModel(title: $title, subtitle: $subtitle, objectives: $objectives, details: $details, admission: $admission, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$WebsiteEducationProgramModelCopyWith<$Res> implements $WebsiteEducationProgramModelCopyWith<$Res> {
  factory _$WebsiteEducationProgramModelCopyWith(_WebsiteEducationProgramModel value, $Res Function(_WebsiteEducationProgramModel) _then) = __$WebsiteEducationProgramModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String subtitle, String objectives, List<String> details, String admission, String icon
});




}
/// @nodoc
class __$WebsiteEducationProgramModelCopyWithImpl<$Res>
    implements _$WebsiteEducationProgramModelCopyWith<$Res> {
  __$WebsiteEducationProgramModelCopyWithImpl(this._self, this._then);

  final _WebsiteEducationProgramModel _self;
  final $Res Function(_WebsiteEducationProgramModel) _then;

/// Create a copy of WebsiteEducationProgramModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? subtitle = null,Object? objectives = null,Object? details = null,Object? admission = null,Object? icon = null,}) {
  return _then(_WebsiteEducationProgramModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,objectives: null == objectives ? _self.objectives : objectives // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as List<String>,admission: null == admission ? _self.admission : admission // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteStudyProgramModel {

 String get title; String get duration; String get eligibility; String get description; String get icon;
/// Create a copy of WebsiteStudyProgramModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteStudyProgramModelCopyWith<WebsiteStudyProgramModel> get copyWith => _$WebsiteStudyProgramModelCopyWithImpl<WebsiteStudyProgramModel>(this as WebsiteStudyProgramModel, _$identity);

  /// Serializes this WebsiteStudyProgramModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteStudyProgramModel&&(identical(other.title, title) || other.title == title)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.eligibility, eligibility) || other.eligibility == eligibility)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,duration,eligibility,description,icon);

@override
String toString() {
  return 'WebsiteStudyProgramModel(title: $title, duration: $duration, eligibility: $eligibility, description: $description, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $WebsiteStudyProgramModelCopyWith<$Res>  {
  factory $WebsiteStudyProgramModelCopyWith(WebsiteStudyProgramModel value, $Res Function(WebsiteStudyProgramModel) _then) = _$WebsiteStudyProgramModelCopyWithImpl;
@useResult
$Res call({
 String title, String duration, String eligibility, String description, String icon
});




}
/// @nodoc
class _$WebsiteStudyProgramModelCopyWithImpl<$Res>
    implements $WebsiteStudyProgramModelCopyWith<$Res> {
  _$WebsiteStudyProgramModelCopyWithImpl(this._self, this._then);

  final WebsiteStudyProgramModel _self;
  final $Res Function(WebsiteStudyProgramModel) _then;

/// Create a copy of WebsiteStudyProgramModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? duration = null,Object? eligibility = null,Object? description = null,Object? icon = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,eligibility: null == eligibility ? _self.eligibility : eligibility // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteStudyProgramModel].
extension WebsiteStudyProgramModelPatterns on WebsiteStudyProgramModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteStudyProgramModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteStudyProgramModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteStudyProgramModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteStudyProgramModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteStudyProgramModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteStudyProgramModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String duration,  String eligibility,  String description,  String icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteStudyProgramModel() when $default != null:
return $default(_that.title,_that.duration,_that.eligibility,_that.description,_that.icon);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String duration,  String eligibility,  String description,  String icon)  $default,) {final _that = this;
switch (_that) {
case _WebsiteStudyProgramModel():
return $default(_that.title,_that.duration,_that.eligibility,_that.description,_that.icon);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String duration,  String eligibility,  String description,  String icon)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteStudyProgramModel() when $default != null:
return $default(_that.title,_that.duration,_that.eligibility,_that.description,_that.icon);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteStudyProgramModel implements WebsiteStudyProgramModel {
  const _WebsiteStudyProgramModel({this.title = '', this.duration = '', this.eligibility = '', this.description = '', this.icon = ''});
  factory _WebsiteStudyProgramModel.fromJson(Map<String, dynamic> json) => _$WebsiteStudyProgramModelFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  String duration;
@override@JsonKey() final  String eligibility;
@override@JsonKey() final  String description;
@override@JsonKey() final  String icon;

/// Create a copy of WebsiteStudyProgramModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteStudyProgramModelCopyWith<_WebsiteStudyProgramModel> get copyWith => __$WebsiteStudyProgramModelCopyWithImpl<_WebsiteStudyProgramModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteStudyProgramModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteStudyProgramModel&&(identical(other.title, title) || other.title == title)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.eligibility, eligibility) || other.eligibility == eligibility)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,duration,eligibility,description,icon);

@override
String toString() {
  return 'WebsiteStudyProgramModel(title: $title, duration: $duration, eligibility: $eligibility, description: $description, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$WebsiteStudyProgramModelCopyWith<$Res> implements $WebsiteStudyProgramModelCopyWith<$Res> {
  factory _$WebsiteStudyProgramModelCopyWith(_WebsiteStudyProgramModel value, $Res Function(_WebsiteStudyProgramModel) _then) = __$WebsiteStudyProgramModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String duration, String eligibility, String description, String icon
});




}
/// @nodoc
class __$WebsiteStudyProgramModelCopyWithImpl<$Res>
    implements _$WebsiteStudyProgramModelCopyWith<$Res> {
  __$WebsiteStudyProgramModelCopyWithImpl(this._self, this._then);

  final _WebsiteStudyProgramModel _self;
  final $Res Function(_WebsiteStudyProgramModel) _then;

/// Create a copy of WebsiteStudyProgramModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? duration = null,Object? eligibility = null,Object? description = null,Object? icon = null,}) {
  return _then(_WebsiteStudyProgramModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,eligibility: null == eligibility ? _self.eligibility : eligibility // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteEventModel {

 String get date; String get title; String get location; String get time; String get category; String get description; String get registrationLink;
/// Create a copy of WebsiteEventModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteEventModelCopyWith<WebsiteEventModel> get copyWith => _$WebsiteEventModelCopyWithImpl<WebsiteEventModel>(this as WebsiteEventModel, _$identity);

  /// Serializes this WebsiteEventModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteEventModel&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.time, time) || other.time == time)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.registrationLink, registrationLink) || other.registrationLink == registrationLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,title,location,time,category,description,registrationLink);

@override
String toString() {
  return 'WebsiteEventModel(date: $date, title: $title, location: $location, time: $time, category: $category, description: $description, registrationLink: $registrationLink)';
}


}

/// @nodoc
abstract mixin class $WebsiteEventModelCopyWith<$Res>  {
  factory $WebsiteEventModelCopyWith(WebsiteEventModel value, $Res Function(WebsiteEventModel) _then) = _$WebsiteEventModelCopyWithImpl;
@useResult
$Res call({
 String date, String title, String location, String time, String category, String description, String registrationLink
});




}
/// @nodoc
class _$WebsiteEventModelCopyWithImpl<$Res>
    implements $WebsiteEventModelCopyWith<$Res> {
  _$WebsiteEventModelCopyWithImpl(this._self, this._then);

  final WebsiteEventModel _self;
  final $Res Function(WebsiteEventModel) _then;

/// Create a copy of WebsiteEventModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? title = null,Object? location = null,Object? time = null,Object? category = null,Object? description = null,Object? registrationLink = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,registrationLink: null == registrationLink ? _self.registrationLink : registrationLink // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteEventModel].
extension WebsiteEventModelPatterns on WebsiteEventModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteEventModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteEventModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteEventModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteEventModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteEventModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteEventModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  String title,  String location,  String time,  String category,  String description,  String registrationLink)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteEventModel() when $default != null:
return $default(_that.date,_that.title,_that.location,_that.time,_that.category,_that.description,_that.registrationLink);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  String title,  String location,  String time,  String category,  String description,  String registrationLink)  $default,) {final _that = this;
switch (_that) {
case _WebsiteEventModel():
return $default(_that.date,_that.title,_that.location,_that.time,_that.category,_that.description,_that.registrationLink);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  String title,  String location,  String time,  String category,  String description,  String registrationLink)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteEventModel() when $default != null:
return $default(_that.date,_that.title,_that.location,_that.time,_that.category,_that.description,_that.registrationLink);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteEventModel implements WebsiteEventModel {
  const _WebsiteEventModel({this.date = '', this.title = '', this.location = '', this.time = '', this.category = '', this.description = '', this.registrationLink = ''});
  factory _WebsiteEventModel.fromJson(Map<String, dynamic> json) => _$WebsiteEventModelFromJson(json);

@override@JsonKey() final  String date;
@override@JsonKey() final  String title;
@override@JsonKey() final  String location;
@override@JsonKey() final  String time;
@override@JsonKey() final  String category;
@override@JsonKey() final  String description;
@override@JsonKey() final  String registrationLink;

/// Create a copy of WebsiteEventModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteEventModelCopyWith<_WebsiteEventModel> get copyWith => __$WebsiteEventModelCopyWithImpl<_WebsiteEventModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteEventModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteEventModel&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.time, time) || other.time == time)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.registrationLink, registrationLink) || other.registrationLink == registrationLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,title,location,time,category,description,registrationLink);

@override
String toString() {
  return 'WebsiteEventModel(date: $date, title: $title, location: $location, time: $time, category: $category, description: $description, registrationLink: $registrationLink)';
}


}

/// @nodoc
abstract mixin class _$WebsiteEventModelCopyWith<$Res> implements $WebsiteEventModelCopyWith<$Res> {
  factory _$WebsiteEventModelCopyWith(_WebsiteEventModel value, $Res Function(_WebsiteEventModel) _then) = __$WebsiteEventModelCopyWithImpl;
@override @useResult
$Res call({
 String date, String title, String location, String time, String category, String description, String registrationLink
});




}
/// @nodoc
class __$WebsiteEventModelCopyWithImpl<$Res>
    implements _$WebsiteEventModelCopyWith<$Res> {
  __$WebsiteEventModelCopyWithImpl(this._self, this._then);

  final _WebsiteEventModel _self;
  final $Res Function(_WebsiteEventModel) _then;

/// Create a copy of WebsiteEventModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? title = null,Object? location = null,Object? time = null,Object? category = null,Object? description = null,Object? registrationLink = null,}) {
  return _then(_WebsiteEventModel(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,registrationLink: null == registrationLink ? _self.registrationLink : registrationLink // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsitePastEventModel {

 String get title; String get date; String get category; String get image;
/// Create a copy of WebsitePastEventModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsitePastEventModelCopyWith<WebsitePastEventModel> get copyWith => _$WebsitePastEventModelCopyWithImpl<WebsitePastEventModel>(this as WebsitePastEventModel, _$identity);

  /// Serializes this WebsitePastEventModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsitePastEventModel&&(identical(other.title, title) || other.title == title)&&(identical(other.date, date) || other.date == date)&&(identical(other.category, category) || other.category == category)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,date,category,image);

@override
String toString() {
  return 'WebsitePastEventModel(title: $title, date: $date, category: $category, image: $image)';
}


}

/// @nodoc
abstract mixin class $WebsitePastEventModelCopyWith<$Res>  {
  factory $WebsitePastEventModelCopyWith(WebsitePastEventModel value, $Res Function(WebsitePastEventModel) _then) = _$WebsitePastEventModelCopyWithImpl;
@useResult
$Res call({
 String title, String date, String category, String image
});




}
/// @nodoc
class _$WebsitePastEventModelCopyWithImpl<$Res>
    implements $WebsitePastEventModelCopyWith<$Res> {
  _$WebsitePastEventModelCopyWithImpl(this._self, this._then);

  final WebsitePastEventModel _self;
  final $Res Function(WebsitePastEventModel) _then;

/// Create a copy of WebsitePastEventModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? date = null,Object? category = null,Object? image = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsitePastEventModel].
extension WebsitePastEventModelPatterns on WebsitePastEventModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsitePastEventModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsitePastEventModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsitePastEventModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsitePastEventModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsitePastEventModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsitePastEventModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String date,  String category,  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsitePastEventModel() when $default != null:
return $default(_that.title,_that.date,_that.category,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String date,  String category,  String image)  $default,) {final _that = this;
switch (_that) {
case _WebsitePastEventModel():
return $default(_that.title,_that.date,_that.category,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String date,  String category,  String image)?  $default,) {final _that = this;
switch (_that) {
case _WebsitePastEventModel() when $default != null:
return $default(_that.title,_that.date,_that.category,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsitePastEventModel implements WebsitePastEventModel {
  const _WebsitePastEventModel({this.title = '', this.date = '', this.category = '', this.image = ''});
  factory _WebsitePastEventModel.fromJson(Map<String, dynamic> json) => _$WebsitePastEventModelFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  String date;
@override@JsonKey() final  String category;
@override@JsonKey() final  String image;

/// Create a copy of WebsitePastEventModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsitePastEventModelCopyWith<_WebsitePastEventModel> get copyWith => __$WebsitePastEventModelCopyWithImpl<_WebsitePastEventModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsitePastEventModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsitePastEventModel&&(identical(other.title, title) || other.title == title)&&(identical(other.date, date) || other.date == date)&&(identical(other.category, category) || other.category == category)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,date,category,image);

@override
String toString() {
  return 'WebsitePastEventModel(title: $title, date: $date, category: $category, image: $image)';
}


}

/// @nodoc
abstract mixin class _$WebsitePastEventModelCopyWith<$Res> implements $WebsitePastEventModelCopyWith<$Res> {
  factory _$WebsitePastEventModelCopyWith(_WebsitePastEventModel value, $Res Function(_WebsitePastEventModel) _then) = __$WebsitePastEventModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String date, String category, String image
});




}
/// @nodoc
class __$WebsitePastEventModelCopyWithImpl<$Res>
    implements _$WebsitePastEventModelCopyWith<$Res> {
  __$WebsitePastEventModelCopyWithImpl(this._self, this._then);

  final _WebsitePastEventModel _self;
  final $Res Function(_WebsitePastEventModel) _then;

/// Create a copy of WebsitePastEventModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? date = null,Object? category = null,Object? image = null,}) {
  return _then(_WebsitePastEventModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteVideoModel {

 String get title; String get date; String get duration; String get href; String get image;
/// Create a copy of WebsiteVideoModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteVideoModelCopyWith<WebsiteVideoModel> get copyWith => _$WebsiteVideoModelCopyWithImpl<WebsiteVideoModel>(this as WebsiteVideoModel, _$identity);

  /// Serializes this WebsiteVideoModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteVideoModel&&(identical(other.title, title) || other.title == title)&&(identical(other.date, date) || other.date == date)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.href, href) || other.href == href)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,date,duration,href,image);

@override
String toString() {
  return 'WebsiteVideoModel(title: $title, date: $date, duration: $duration, href: $href, image: $image)';
}


}

/// @nodoc
abstract mixin class $WebsiteVideoModelCopyWith<$Res>  {
  factory $WebsiteVideoModelCopyWith(WebsiteVideoModel value, $Res Function(WebsiteVideoModel) _then) = _$WebsiteVideoModelCopyWithImpl;
@useResult
$Res call({
 String title, String date, String duration, String href, String image
});




}
/// @nodoc
class _$WebsiteVideoModelCopyWithImpl<$Res>
    implements $WebsiteVideoModelCopyWith<$Res> {
  _$WebsiteVideoModelCopyWithImpl(this._self, this._then);

  final WebsiteVideoModel _self;
  final $Res Function(WebsiteVideoModel) _then;

/// Create a copy of WebsiteVideoModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? date = null,Object? duration = null,Object? href = null,Object? image = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,href: null == href ? _self.href : href // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteVideoModel].
extension WebsiteVideoModelPatterns on WebsiteVideoModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteVideoModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteVideoModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteVideoModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteVideoModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteVideoModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteVideoModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String date,  String duration,  String href,  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteVideoModel() when $default != null:
return $default(_that.title,_that.date,_that.duration,_that.href,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String date,  String duration,  String href,  String image)  $default,) {final _that = this;
switch (_that) {
case _WebsiteVideoModel():
return $default(_that.title,_that.date,_that.duration,_that.href,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String date,  String duration,  String href,  String image)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteVideoModel() when $default != null:
return $default(_that.title,_that.date,_that.duration,_that.href,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteVideoModel implements WebsiteVideoModel {
  const _WebsiteVideoModel({this.title = '', this.date = '', this.duration = '', this.href = '', this.image = ''});
  factory _WebsiteVideoModel.fromJson(Map<String, dynamic> json) => _$WebsiteVideoModelFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  String date;
@override@JsonKey() final  String duration;
@override@JsonKey() final  String href;
@override@JsonKey() final  String image;

/// Create a copy of WebsiteVideoModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteVideoModelCopyWith<_WebsiteVideoModel> get copyWith => __$WebsiteVideoModelCopyWithImpl<_WebsiteVideoModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteVideoModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteVideoModel&&(identical(other.title, title) || other.title == title)&&(identical(other.date, date) || other.date == date)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.href, href) || other.href == href)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,date,duration,href,image);

@override
String toString() {
  return 'WebsiteVideoModel(title: $title, date: $date, duration: $duration, href: $href, image: $image)';
}


}

/// @nodoc
abstract mixin class _$WebsiteVideoModelCopyWith<$Res> implements $WebsiteVideoModelCopyWith<$Res> {
  factory _$WebsiteVideoModelCopyWith(_WebsiteVideoModel value, $Res Function(_WebsiteVideoModel) _then) = __$WebsiteVideoModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String date, String duration, String href, String image
});




}
/// @nodoc
class __$WebsiteVideoModelCopyWithImpl<$Res>
    implements _$WebsiteVideoModelCopyWith<$Res> {
  __$WebsiteVideoModelCopyWithImpl(this._self, this._then);

  final _WebsiteVideoModel _self;
  final $Res Function(_WebsiteVideoModel) _then;

/// Create a copy of WebsiteVideoModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? date = null,Object? duration = null,Object? href = null,Object? image = null,}) {
  return _then(_WebsiteVideoModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,href: null == href ? _self.href : href // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsitePhotoModel {

 String get title; String get image;
/// Create a copy of WebsitePhotoModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsitePhotoModelCopyWith<WebsitePhotoModel> get copyWith => _$WebsitePhotoModelCopyWithImpl<WebsitePhotoModel>(this as WebsitePhotoModel, _$identity);

  /// Serializes this WebsitePhotoModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsitePhotoModel&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,image);

@override
String toString() {
  return 'WebsitePhotoModel(title: $title, image: $image)';
}


}

/// @nodoc
abstract mixin class $WebsitePhotoModelCopyWith<$Res>  {
  factory $WebsitePhotoModelCopyWith(WebsitePhotoModel value, $Res Function(WebsitePhotoModel) _then) = _$WebsitePhotoModelCopyWithImpl;
@useResult
$Res call({
 String title, String image
});




}
/// @nodoc
class _$WebsitePhotoModelCopyWithImpl<$Res>
    implements $WebsitePhotoModelCopyWith<$Res> {
  _$WebsitePhotoModelCopyWithImpl(this._self, this._then);

  final WebsitePhotoModel _self;
  final $Res Function(WebsitePhotoModel) _then;

/// Create a copy of WebsitePhotoModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? image = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsitePhotoModel].
extension WebsitePhotoModelPatterns on WebsitePhotoModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsitePhotoModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsitePhotoModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsitePhotoModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsitePhotoModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsitePhotoModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsitePhotoModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsitePhotoModel() when $default != null:
return $default(_that.title,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String image)  $default,) {final _that = this;
switch (_that) {
case _WebsitePhotoModel():
return $default(_that.title,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String image)?  $default,) {final _that = this;
switch (_that) {
case _WebsitePhotoModel() when $default != null:
return $default(_that.title,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsitePhotoModel implements WebsitePhotoModel {
  const _WebsitePhotoModel({this.title = '', this.image = ''});
  factory _WebsitePhotoModel.fromJson(Map<String, dynamic> json) => _$WebsitePhotoModelFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  String image;

/// Create a copy of WebsitePhotoModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsitePhotoModelCopyWith<_WebsitePhotoModel> get copyWith => __$WebsitePhotoModelCopyWithImpl<_WebsitePhotoModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsitePhotoModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsitePhotoModel&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,image);

@override
String toString() {
  return 'WebsitePhotoModel(title: $title, image: $image)';
}


}

/// @nodoc
abstract mixin class _$WebsitePhotoModelCopyWith<$Res> implements $WebsitePhotoModelCopyWith<$Res> {
  factory _$WebsitePhotoModelCopyWith(_WebsitePhotoModel value, $Res Function(_WebsitePhotoModel) _then) = __$WebsitePhotoModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String image
});




}
/// @nodoc
class __$WebsitePhotoModelCopyWithImpl<$Res>
    implements _$WebsitePhotoModelCopyWith<$Res> {
  __$WebsitePhotoModelCopyWithImpl(this._self, this._then);

  final _WebsitePhotoModel _self;
  final $Res Function(_WebsitePhotoModel) _then;

/// Create a copy of WebsitePhotoModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? image = null,}) {
  return _then(_WebsitePhotoModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteAlbumModel {

 String get title; int get count; String get date; String get image;
/// Create a copy of WebsiteAlbumModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteAlbumModelCopyWith<WebsiteAlbumModel> get copyWith => _$WebsiteAlbumModelCopyWithImpl<WebsiteAlbumModel>(this as WebsiteAlbumModel, _$identity);

  /// Serializes this WebsiteAlbumModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteAlbumModel&&(identical(other.title, title) || other.title == title)&&(identical(other.count, count) || other.count == count)&&(identical(other.date, date) || other.date == date)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,count,date,image);

@override
String toString() {
  return 'WebsiteAlbumModel(title: $title, count: $count, date: $date, image: $image)';
}


}

/// @nodoc
abstract mixin class $WebsiteAlbumModelCopyWith<$Res>  {
  factory $WebsiteAlbumModelCopyWith(WebsiteAlbumModel value, $Res Function(WebsiteAlbumModel) _then) = _$WebsiteAlbumModelCopyWithImpl;
@useResult
$Res call({
 String title, int count, String date, String image
});




}
/// @nodoc
class _$WebsiteAlbumModelCopyWithImpl<$Res>
    implements $WebsiteAlbumModelCopyWith<$Res> {
  _$WebsiteAlbumModelCopyWithImpl(this._self, this._then);

  final WebsiteAlbumModel _self;
  final $Res Function(WebsiteAlbumModel) _then;

/// Create a copy of WebsiteAlbumModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? count = null,Object? date = null,Object? image = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteAlbumModel].
extension WebsiteAlbumModelPatterns on WebsiteAlbumModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteAlbumModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteAlbumModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteAlbumModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteAlbumModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteAlbumModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteAlbumModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  int count,  String date,  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteAlbumModel() when $default != null:
return $default(_that.title,_that.count,_that.date,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  int count,  String date,  String image)  $default,) {final _that = this;
switch (_that) {
case _WebsiteAlbumModel():
return $default(_that.title,_that.count,_that.date,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  int count,  String date,  String image)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteAlbumModel() when $default != null:
return $default(_that.title,_that.count,_that.date,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteAlbumModel implements WebsiteAlbumModel {
  const _WebsiteAlbumModel({this.title = '', this.count = 0, this.date = '', this.image = ''});
  factory _WebsiteAlbumModel.fromJson(Map<String, dynamic> json) => _$WebsiteAlbumModelFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  int count;
@override@JsonKey() final  String date;
@override@JsonKey() final  String image;

/// Create a copy of WebsiteAlbumModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteAlbumModelCopyWith<_WebsiteAlbumModel> get copyWith => __$WebsiteAlbumModelCopyWithImpl<_WebsiteAlbumModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteAlbumModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteAlbumModel&&(identical(other.title, title) || other.title == title)&&(identical(other.count, count) || other.count == count)&&(identical(other.date, date) || other.date == date)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,count,date,image);

@override
String toString() {
  return 'WebsiteAlbumModel(title: $title, count: $count, date: $date, image: $image)';
}


}

/// @nodoc
abstract mixin class _$WebsiteAlbumModelCopyWith<$Res> implements $WebsiteAlbumModelCopyWith<$Res> {
  factory _$WebsiteAlbumModelCopyWith(_WebsiteAlbumModel value, $Res Function(_WebsiteAlbumModel) _then) = __$WebsiteAlbumModelCopyWithImpl;
@override @useResult
$Res call({
 String title, int count, String date, String image
});




}
/// @nodoc
class __$WebsiteAlbumModelCopyWithImpl<$Res>
    implements _$WebsiteAlbumModelCopyWith<$Res> {
  __$WebsiteAlbumModelCopyWithImpl(this._self, this._then);

  final _WebsiteAlbumModel _self;
  final $Res Function(_WebsiteAlbumModel) _then;

/// Create a copy of WebsiteAlbumModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? count = null,Object? date = null,Object? image = null,}) {
  return _then(_WebsiteAlbumModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteNewsModel {

 String get category; String get date; String get title; String get excerpt; String get author; String get content; String get image;
/// Create a copy of WebsiteNewsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteNewsModelCopyWith<WebsiteNewsModel> get copyWith => _$WebsiteNewsModelCopyWithImpl<WebsiteNewsModel>(this as WebsiteNewsModel, _$identity);

  /// Serializes this WebsiteNewsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteNewsModel&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.author, author) || other.author == author)&&(identical(other.content, content) || other.content == content)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,date,title,excerpt,author,content,image);

@override
String toString() {
  return 'WebsiteNewsModel(category: $category, date: $date, title: $title, excerpt: $excerpt, author: $author, content: $content, image: $image)';
}


}

/// @nodoc
abstract mixin class $WebsiteNewsModelCopyWith<$Res>  {
  factory $WebsiteNewsModelCopyWith(WebsiteNewsModel value, $Res Function(WebsiteNewsModel) _then) = _$WebsiteNewsModelCopyWithImpl;
@useResult
$Res call({
 String category, String date, String title, String excerpt, String author, String content, String image
});




}
/// @nodoc
class _$WebsiteNewsModelCopyWithImpl<$Res>
    implements $WebsiteNewsModelCopyWith<$Res> {
  _$WebsiteNewsModelCopyWithImpl(this._self, this._then);

  final WebsiteNewsModel _self;
  final $Res Function(WebsiteNewsModel) _then;

/// Create a copy of WebsiteNewsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? date = null,Object? title = null,Object? excerpt = null,Object? author = null,Object? content = null,Object? image = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteNewsModel].
extension WebsiteNewsModelPatterns on WebsiteNewsModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteNewsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteNewsModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteNewsModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteNewsModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteNewsModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteNewsModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  String date,  String title,  String excerpt,  String author,  String content,  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteNewsModel() when $default != null:
return $default(_that.category,_that.date,_that.title,_that.excerpt,_that.author,_that.content,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  String date,  String title,  String excerpt,  String author,  String content,  String image)  $default,) {final _that = this;
switch (_that) {
case _WebsiteNewsModel():
return $default(_that.category,_that.date,_that.title,_that.excerpt,_that.author,_that.content,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  String date,  String title,  String excerpt,  String author,  String content,  String image)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteNewsModel() when $default != null:
return $default(_that.category,_that.date,_that.title,_that.excerpt,_that.author,_that.content,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteNewsModel implements WebsiteNewsModel {
  const _WebsiteNewsModel({this.category = '', this.date = '', this.title = '', this.excerpt = '', this.author = '', this.content = '', this.image = ''});
  factory _WebsiteNewsModel.fromJson(Map<String, dynamic> json) => _$WebsiteNewsModelFromJson(json);

@override@JsonKey() final  String category;
@override@JsonKey() final  String date;
@override@JsonKey() final  String title;
@override@JsonKey() final  String excerpt;
@override@JsonKey() final  String author;
@override@JsonKey() final  String content;
@override@JsonKey() final  String image;

/// Create a copy of WebsiteNewsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteNewsModelCopyWith<_WebsiteNewsModel> get copyWith => __$WebsiteNewsModelCopyWithImpl<_WebsiteNewsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteNewsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteNewsModel&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.title, title) || other.title == title)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.author, author) || other.author == author)&&(identical(other.content, content) || other.content == content)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,date,title,excerpt,author,content,image);

@override
String toString() {
  return 'WebsiteNewsModel(category: $category, date: $date, title: $title, excerpt: $excerpt, author: $author, content: $content, image: $image)';
}


}

/// @nodoc
abstract mixin class _$WebsiteNewsModelCopyWith<$Res> implements $WebsiteNewsModelCopyWith<$Res> {
  factory _$WebsiteNewsModelCopyWith(_WebsiteNewsModel value, $Res Function(_WebsiteNewsModel) _then) = __$WebsiteNewsModelCopyWithImpl;
@override @useResult
$Res call({
 String category, String date, String title, String excerpt, String author, String content, String image
});




}
/// @nodoc
class __$WebsiteNewsModelCopyWithImpl<$Res>
    implements _$WebsiteNewsModelCopyWith<$Res> {
  __$WebsiteNewsModelCopyWithImpl(this._self, this._then);

  final _WebsiteNewsModel _self;
  final $Res Function(_WebsiteNewsModel) _then;

/// Create a copy of WebsiteNewsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? date = null,Object? title = null,Object? excerpt = null,Object? author = null,Object? content = null,Object? image = null,}) {
  return _then(_WebsiteNewsModel(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteTestimonialModel {

 String get quote; String get name;
/// Create a copy of WebsiteTestimonialModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteTestimonialModelCopyWith<WebsiteTestimonialModel> get copyWith => _$WebsiteTestimonialModelCopyWithImpl<WebsiteTestimonialModel>(this as WebsiteTestimonialModel, _$identity);

  /// Serializes this WebsiteTestimonialModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteTestimonialModel&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quote,name);

@override
String toString() {
  return 'WebsiteTestimonialModel(quote: $quote, name: $name)';
}


}

/// @nodoc
abstract mixin class $WebsiteTestimonialModelCopyWith<$Res>  {
  factory $WebsiteTestimonialModelCopyWith(WebsiteTestimonialModel value, $Res Function(WebsiteTestimonialModel) _then) = _$WebsiteTestimonialModelCopyWithImpl;
@useResult
$Res call({
 String quote, String name
});




}
/// @nodoc
class _$WebsiteTestimonialModelCopyWithImpl<$Res>
    implements $WebsiteTestimonialModelCopyWith<$Res> {
  _$WebsiteTestimonialModelCopyWithImpl(this._self, this._then);

  final WebsiteTestimonialModel _self;
  final $Res Function(WebsiteTestimonialModel) _then;

/// Create a copy of WebsiteTestimonialModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quote = null,Object? name = null,}) {
  return _then(_self.copyWith(
quote: null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteTestimonialModel].
extension WebsiteTestimonialModelPatterns on WebsiteTestimonialModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteTestimonialModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteTestimonialModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteTestimonialModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteTestimonialModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteTestimonialModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteTestimonialModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String quote,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteTestimonialModel() when $default != null:
return $default(_that.quote,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String quote,  String name)  $default,) {final _that = this;
switch (_that) {
case _WebsiteTestimonialModel():
return $default(_that.quote,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String quote,  String name)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteTestimonialModel() when $default != null:
return $default(_that.quote,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteTestimonialModel implements WebsiteTestimonialModel {
  const _WebsiteTestimonialModel({this.quote = '', this.name = ''});
  factory _WebsiteTestimonialModel.fromJson(Map<String, dynamic> json) => _$WebsiteTestimonialModelFromJson(json);

@override@JsonKey() final  String quote;
@override@JsonKey() final  String name;

/// Create a copy of WebsiteTestimonialModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteTestimonialModelCopyWith<_WebsiteTestimonialModel> get copyWith => __$WebsiteTestimonialModelCopyWithImpl<_WebsiteTestimonialModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteTestimonialModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteTestimonialModel&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quote,name);

@override
String toString() {
  return 'WebsiteTestimonialModel(quote: $quote, name: $name)';
}


}

/// @nodoc
abstract mixin class _$WebsiteTestimonialModelCopyWith<$Res> implements $WebsiteTestimonialModelCopyWith<$Res> {
  factory _$WebsiteTestimonialModelCopyWith(_WebsiteTestimonialModel value, $Res Function(_WebsiteTestimonialModel) _then) = __$WebsiteTestimonialModelCopyWithImpl;
@override @useResult
$Res call({
 String quote, String name
});




}
/// @nodoc
class __$WebsiteTestimonialModelCopyWithImpl<$Res>
    implements _$WebsiteTestimonialModelCopyWith<$Res> {
  __$WebsiteTestimonialModelCopyWithImpl(this._self, this._then);

  final _WebsiteTestimonialModel _self;
  final $Res Function(_WebsiteTestimonialModel) _then;

/// Create a copy of WebsiteTestimonialModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quote = null,Object? name = null,}) {
  return _then(_WebsiteTestimonialModel(
quote: null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteMediaHighlightModel {

 String get title; String get meta; String get image;
/// Create a copy of WebsiteMediaHighlightModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteMediaHighlightModelCopyWith<WebsiteMediaHighlightModel> get copyWith => _$WebsiteMediaHighlightModelCopyWithImpl<WebsiteMediaHighlightModel>(this as WebsiteMediaHighlightModel, _$identity);

  /// Serializes this WebsiteMediaHighlightModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteMediaHighlightModel&&(identical(other.title, title) || other.title == title)&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,meta,image);

@override
String toString() {
  return 'WebsiteMediaHighlightModel(title: $title, meta: $meta, image: $image)';
}


}

/// @nodoc
abstract mixin class $WebsiteMediaHighlightModelCopyWith<$Res>  {
  factory $WebsiteMediaHighlightModelCopyWith(WebsiteMediaHighlightModel value, $Res Function(WebsiteMediaHighlightModel) _then) = _$WebsiteMediaHighlightModelCopyWithImpl;
@useResult
$Res call({
 String title, String meta, String image
});




}
/// @nodoc
class _$WebsiteMediaHighlightModelCopyWithImpl<$Res>
    implements $WebsiteMediaHighlightModelCopyWith<$Res> {
  _$WebsiteMediaHighlightModelCopyWithImpl(this._self, this._then);

  final WebsiteMediaHighlightModel _self;
  final $Res Function(WebsiteMediaHighlightModel) _then;

/// Create a copy of WebsiteMediaHighlightModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? meta = null,Object? image = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteMediaHighlightModel].
extension WebsiteMediaHighlightModelPatterns on WebsiteMediaHighlightModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteMediaHighlightModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteMediaHighlightModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteMediaHighlightModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteMediaHighlightModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteMediaHighlightModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteMediaHighlightModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String meta,  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteMediaHighlightModel() when $default != null:
return $default(_that.title,_that.meta,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String meta,  String image)  $default,) {final _that = this;
switch (_that) {
case _WebsiteMediaHighlightModel():
return $default(_that.title,_that.meta,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String meta,  String image)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteMediaHighlightModel() when $default != null:
return $default(_that.title,_that.meta,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteMediaHighlightModel implements WebsiteMediaHighlightModel {
  const _WebsiteMediaHighlightModel({this.title = '', this.meta = '', this.image = ''});
  factory _WebsiteMediaHighlightModel.fromJson(Map<String, dynamic> json) => _$WebsiteMediaHighlightModelFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  String meta;
@override@JsonKey() final  String image;

/// Create a copy of WebsiteMediaHighlightModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteMediaHighlightModelCopyWith<_WebsiteMediaHighlightModel> get copyWith => __$WebsiteMediaHighlightModelCopyWithImpl<_WebsiteMediaHighlightModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteMediaHighlightModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteMediaHighlightModel&&(identical(other.title, title) || other.title == title)&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,meta,image);

@override
String toString() {
  return 'WebsiteMediaHighlightModel(title: $title, meta: $meta, image: $image)';
}


}

/// @nodoc
abstract mixin class _$WebsiteMediaHighlightModelCopyWith<$Res> implements $WebsiteMediaHighlightModelCopyWith<$Res> {
  factory _$WebsiteMediaHighlightModelCopyWith(_WebsiteMediaHighlightModel value, $Res Function(_WebsiteMediaHighlightModel) _then) = __$WebsiteMediaHighlightModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String meta, String image
});




}
/// @nodoc
class __$WebsiteMediaHighlightModelCopyWithImpl<$Res>
    implements _$WebsiteMediaHighlightModelCopyWith<$Res> {
  __$WebsiteMediaHighlightModelCopyWithImpl(this._self, this._then);

  final _WebsiteMediaHighlightModel _self;
  final $Res Function(_WebsiteMediaHighlightModel) _then;

/// Create a copy of WebsiteMediaHighlightModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? meta = null,Object? image = null,}) {
  return _then(_WebsiteMediaHighlightModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebsiteFaqModel {

 String get question; String get answer;
/// Create a copy of WebsiteFaqModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebsiteFaqModelCopyWith<WebsiteFaqModel> get copyWith => _$WebsiteFaqModelCopyWithImpl<WebsiteFaqModel>(this as WebsiteFaqModel, _$identity);

  /// Serializes this WebsiteFaqModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebsiteFaqModel&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,answer);

@override
String toString() {
  return 'WebsiteFaqModel(question: $question, answer: $answer)';
}


}

/// @nodoc
abstract mixin class $WebsiteFaqModelCopyWith<$Res>  {
  factory $WebsiteFaqModelCopyWith(WebsiteFaqModel value, $Res Function(WebsiteFaqModel) _then) = _$WebsiteFaqModelCopyWithImpl;
@useResult
$Res call({
 String question, String answer
});




}
/// @nodoc
class _$WebsiteFaqModelCopyWithImpl<$Res>
    implements $WebsiteFaqModelCopyWith<$Res> {
  _$WebsiteFaqModelCopyWithImpl(this._self, this._then);

  final WebsiteFaqModel _self;
  final $Res Function(WebsiteFaqModel) _then;

/// Create a copy of WebsiteFaqModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? question = null,Object? answer = null,}) {
  return _then(_self.copyWith(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebsiteFaqModel].
extension WebsiteFaqModelPatterns on WebsiteFaqModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebsiteFaqModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebsiteFaqModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebsiteFaqModel value)  $default,){
final _that = this;
switch (_that) {
case _WebsiteFaqModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebsiteFaqModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebsiteFaqModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String question,  String answer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebsiteFaqModel() when $default != null:
return $default(_that.question,_that.answer);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String question,  String answer)  $default,) {final _that = this;
switch (_that) {
case _WebsiteFaqModel():
return $default(_that.question,_that.answer);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String question,  String answer)?  $default,) {final _that = this;
switch (_that) {
case _WebsiteFaqModel() when $default != null:
return $default(_that.question,_that.answer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebsiteFaqModel implements WebsiteFaqModel {
  const _WebsiteFaqModel({this.question = '', this.answer = ''});
  factory _WebsiteFaqModel.fromJson(Map<String, dynamic> json) => _$WebsiteFaqModelFromJson(json);

@override@JsonKey() final  String question;
@override@JsonKey() final  String answer;

/// Create a copy of WebsiteFaqModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebsiteFaqModelCopyWith<_WebsiteFaqModel> get copyWith => __$WebsiteFaqModelCopyWithImpl<_WebsiteFaqModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebsiteFaqModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebsiteFaqModel&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,answer);

@override
String toString() {
  return 'WebsiteFaqModel(question: $question, answer: $answer)';
}


}

/// @nodoc
abstract mixin class _$WebsiteFaqModelCopyWith<$Res> implements $WebsiteFaqModelCopyWith<$Res> {
  factory _$WebsiteFaqModelCopyWith(_WebsiteFaqModel value, $Res Function(_WebsiteFaqModel) _then) = __$WebsiteFaqModelCopyWithImpl;
@override @useResult
$Res call({
 String question, String answer
});




}
/// @nodoc
class __$WebsiteFaqModelCopyWithImpl<$Res>
    implements _$WebsiteFaqModelCopyWith<$Res> {
  __$WebsiteFaqModelCopyWithImpl(this._self, this._then);

  final _WebsiteFaqModel _self;
  final $Res Function(_WebsiteFaqModel) _then;

/// Create a copy of WebsiteFaqModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? question = null,Object? answer = null,}) {
  return _then(_WebsiteFaqModel(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
