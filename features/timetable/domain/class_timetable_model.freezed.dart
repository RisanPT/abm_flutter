// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'class_timetable_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClassTimetableEntry {

 String get day; int get period; String get subjectName; String get teacherId; String get startTime; String get endTime;
/// Create a copy of ClassTimetableEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassTimetableEntryCopyWith<ClassTimetableEntry> get copyWith => _$ClassTimetableEntryCopyWithImpl<ClassTimetableEntry>(this as ClassTimetableEntry, _$identity);

  /// Serializes this ClassTimetableEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassTimetableEntry&&(identical(other.day, day) || other.day == day)&&(identical(other.period, period) || other.period == period)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,period,subjectName,teacherId,startTime,endTime);

@override
String toString() {
  return 'ClassTimetableEntry(day: $day, period: $period, subjectName: $subjectName, teacherId: $teacherId, startTime: $startTime, endTime: $endTime)';
}


}

/// @nodoc
abstract mixin class $ClassTimetableEntryCopyWith<$Res>  {
  factory $ClassTimetableEntryCopyWith(ClassTimetableEntry value, $Res Function(ClassTimetableEntry) _then) = _$ClassTimetableEntryCopyWithImpl;
@useResult
$Res call({
 String day, int period, String subjectName, String teacherId, String startTime, String endTime
});




}
/// @nodoc
class _$ClassTimetableEntryCopyWithImpl<$Res>
    implements $ClassTimetableEntryCopyWith<$Res> {
  _$ClassTimetableEntryCopyWithImpl(this._self, this._then);

  final ClassTimetableEntry _self;
  final $Res Function(ClassTimetableEntry) _then;

/// Create a copy of ClassTimetableEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? period = null,Object? subjectName = null,Object? teacherId = null,Object? startTime = null,Object? endTime = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassTimetableEntry].
extension ClassTimetableEntryPatterns on ClassTimetableEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassTimetableEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassTimetableEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassTimetableEntry value)  $default,){
final _that = this;
switch (_that) {
case _ClassTimetableEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassTimetableEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ClassTimetableEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String day,  int period,  String subjectName,  String teacherId,  String startTime,  String endTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassTimetableEntry() when $default != null:
return $default(_that.day,_that.period,_that.subjectName,_that.teacherId,_that.startTime,_that.endTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String day,  int period,  String subjectName,  String teacherId,  String startTime,  String endTime)  $default,) {final _that = this;
switch (_that) {
case _ClassTimetableEntry():
return $default(_that.day,_that.period,_that.subjectName,_that.teacherId,_that.startTime,_that.endTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String day,  int period,  String subjectName,  String teacherId,  String startTime,  String endTime)?  $default,) {final _that = this;
switch (_that) {
case _ClassTimetableEntry() when $default != null:
return $default(_that.day,_that.period,_that.subjectName,_that.teacherId,_that.startTime,_that.endTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClassTimetableEntry implements ClassTimetableEntry {
  const _ClassTimetableEntry({required this.day, required this.period, required this.subjectName, required this.teacherId, this.startTime = '', this.endTime = ''});
  factory _ClassTimetableEntry.fromJson(Map<String, dynamic> json) => _$ClassTimetableEntryFromJson(json);

@override final  String day;
@override final  int period;
@override final  String subjectName;
@override final  String teacherId;
@override@JsonKey() final  String startTime;
@override@JsonKey() final  String endTime;

/// Create a copy of ClassTimetableEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassTimetableEntryCopyWith<_ClassTimetableEntry> get copyWith => __$ClassTimetableEntryCopyWithImpl<_ClassTimetableEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClassTimetableEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassTimetableEntry&&(identical(other.day, day) || other.day == day)&&(identical(other.period, period) || other.period == period)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,period,subjectName,teacherId,startTime,endTime);

@override
String toString() {
  return 'ClassTimetableEntry(day: $day, period: $period, subjectName: $subjectName, teacherId: $teacherId, startTime: $startTime, endTime: $endTime)';
}


}

/// @nodoc
abstract mixin class _$ClassTimetableEntryCopyWith<$Res> implements $ClassTimetableEntryCopyWith<$Res> {
  factory _$ClassTimetableEntryCopyWith(_ClassTimetableEntry value, $Res Function(_ClassTimetableEntry) _then) = __$ClassTimetableEntryCopyWithImpl;
@override @useResult
$Res call({
 String day, int period, String subjectName, String teacherId, String startTime, String endTime
});




}
/// @nodoc
class __$ClassTimetableEntryCopyWithImpl<$Res>
    implements _$ClassTimetableEntryCopyWith<$Res> {
  __$ClassTimetableEntryCopyWithImpl(this._self, this._then);

  final _ClassTimetableEntry _self;
  final $Res Function(_ClassTimetableEntry) _then;

/// Create a copy of ClassTimetableEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? period = null,Object? subjectName = null,Object? teacherId = null,Object? startTime = null,Object? endTime = null,}) {
  return _then(_ClassTimetableEntry(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ClassTimetable {

 String get classroomName; List<ClassTimetableEntry> get schedule;
/// Create a copy of ClassTimetable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassTimetableCopyWith<ClassTimetable> get copyWith => _$ClassTimetableCopyWithImpl<ClassTimetable>(this as ClassTimetable, _$identity);

  /// Serializes this ClassTimetable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassTimetable&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&const DeepCollectionEquality().equals(other.schedule, schedule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,classroomName,const DeepCollectionEquality().hash(schedule));

@override
String toString() {
  return 'ClassTimetable(classroomName: $classroomName, schedule: $schedule)';
}


}

/// @nodoc
abstract mixin class $ClassTimetableCopyWith<$Res>  {
  factory $ClassTimetableCopyWith(ClassTimetable value, $Res Function(ClassTimetable) _then) = _$ClassTimetableCopyWithImpl;
@useResult
$Res call({
 String classroomName, List<ClassTimetableEntry> schedule
});




}
/// @nodoc
class _$ClassTimetableCopyWithImpl<$Res>
    implements $ClassTimetableCopyWith<$Res> {
  _$ClassTimetableCopyWithImpl(this._self, this._then);

  final ClassTimetable _self;
  final $Res Function(ClassTimetable) _then;

/// Create a copy of ClassTimetable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? classroomName = null,Object? schedule = null,}) {
  return _then(_self.copyWith(
classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as List<ClassTimetableEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassTimetable].
extension ClassTimetablePatterns on ClassTimetable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassTimetable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassTimetable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassTimetable value)  $default,){
final _that = this;
switch (_that) {
case _ClassTimetable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassTimetable value)?  $default,){
final _that = this;
switch (_that) {
case _ClassTimetable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String classroomName,  List<ClassTimetableEntry> schedule)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassTimetable() when $default != null:
return $default(_that.classroomName,_that.schedule);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String classroomName,  List<ClassTimetableEntry> schedule)  $default,) {final _that = this;
switch (_that) {
case _ClassTimetable():
return $default(_that.classroomName,_that.schedule);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String classroomName,  List<ClassTimetableEntry> schedule)?  $default,) {final _that = this;
switch (_that) {
case _ClassTimetable() when $default != null:
return $default(_that.classroomName,_that.schedule);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClassTimetable implements ClassTimetable {
  const _ClassTimetable({required this.classroomName, required final  List<ClassTimetableEntry> schedule}): _schedule = schedule;
  factory _ClassTimetable.fromJson(Map<String, dynamic> json) => _$ClassTimetableFromJson(json);

@override final  String classroomName;
 final  List<ClassTimetableEntry> _schedule;
@override List<ClassTimetableEntry> get schedule {
  if (_schedule is EqualUnmodifiableListView) return _schedule;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_schedule);
}


/// Create a copy of ClassTimetable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassTimetableCopyWith<_ClassTimetable> get copyWith => __$ClassTimetableCopyWithImpl<_ClassTimetable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClassTimetableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassTimetable&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&const DeepCollectionEquality().equals(other._schedule, _schedule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,classroomName,const DeepCollectionEquality().hash(_schedule));

@override
String toString() {
  return 'ClassTimetable(classroomName: $classroomName, schedule: $schedule)';
}


}

/// @nodoc
abstract mixin class _$ClassTimetableCopyWith<$Res> implements $ClassTimetableCopyWith<$Res> {
  factory _$ClassTimetableCopyWith(_ClassTimetable value, $Res Function(_ClassTimetable) _then) = __$ClassTimetableCopyWithImpl;
@override @useResult
$Res call({
 String classroomName, List<ClassTimetableEntry> schedule
});




}
/// @nodoc
class __$ClassTimetableCopyWithImpl<$Res>
    implements _$ClassTimetableCopyWith<$Res> {
  __$ClassTimetableCopyWithImpl(this._self, this._then);

  final _ClassTimetable _self;
  final $Res Function(_ClassTimetable) _then;

/// Create a copy of ClassTimetable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? classroomName = null,Object? schedule = null,}) {
  return _then(_ClassTimetable(
classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,schedule: null == schedule ? _self._schedule : schedule // ignore: cast_nullable_to_non_nullable
as List<ClassTimetableEntry>,
  ));
}


}

// dart format on
