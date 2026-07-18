// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planning_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarCell {

 DateTime get date; String get displayStatus;// Empty|Planned|Draft|Published|Holiday|Completed|Cancelled
 String get dayStatus; bool get isHoliday; String get holidayReason; int get classCount; int get publishedCount;
/// Create a copy of CalendarCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarCellCopyWith<CalendarCell> get copyWith => _$CalendarCellCopyWithImpl<CalendarCell>(this as CalendarCell, _$identity);

  /// Serializes this CalendarCell to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarCell&&(identical(other.date, date) || other.date == date)&&(identical(other.displayStatus, displayStatus) || other.displayStatus == displayStatus)&&(identical(other.dayStatus, dayStatus) || other.dayStatus == dayStatus)&&(identical(other.isHoliday, isHoliday) || other.isHoliday == isHoliday)&&(identical(other.holidayReason, holidayReason) || other.holidayReason == holidayReason)&&(identical(other.classCount, classCount) || other.classCount == classCount)&&(identical(other.publishedCount, publishedCount) || other.publishedCount == publishedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,displayStatus,dayStatus,isHoliday,holidayReason,classCount,publishedCount);

@override
String toString() {
  return 'CalendarCell(date: $date, displayStatus: $displayStatus, dayStatus: $dayStatus, isHoliday: $isHoliday, holidayReason: $holidayReason, classCount: $classCount, publishedCount: $publishedCount)';
}


}

/// @nodoc
abstract mixin class $CalendarCellCopyWith<$Res>  {
  factory $CalendarCellCopyWith(CalendarCell value, $Res Function(CalendarCell) _then) = _$CalendarCellCopyWithImpl;
@useResult
$Res call({
 DateTime date, String displayStatus, String dayStatus, bool isHoliday, String holidayReason, int classCount, int publishedCount
});




}
/// @nodoc
class _$CalendarCellCopyWithImpl<$Res>
    implements $CalendarCellCopyWith<$Res> {
  _$CalendarCellCopyWithImpl(this._self, this._then);

  final CalendarCell _self;
  final $Res Function(CalendarCell) _then;

/// Create a copy of CalendarCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? displayStatus = null,Object? dayStatus = null,Object? isHoliday = null,Object? holidayReason = null,Object? classCount = null,Object? publishedCount = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,displayStatus: null == displayStatus ? _self.displayStatus : displayStatus // ignore: cast_nullable_to_non_nullable
as String,dayStatus: null == dayStatus ? _self.dayStatus : dayStatus // ignore: cast_nullable_to_non_nullable
as String,isHoliday: null == isHoliday ? _self.isHoliday : isHoliday // ignore: cast_nullable_to_non_nullable
as bool,holidayReason: null == holidayReason ? _self.holidayReason : holidayReason // ignore: cast_nullable_to_non_nullable
as String,classCount: null == classCount ? _self.classCount : classCount // ignore: cast_nullable_to_non_nullable
as int,publishedCount: null == publishedCount ? _self.publishedCount : publishedCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarCell].
extension CalendarCellPatterns on CalendarCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarCell value)  $default,){
final _that = this;
switch (_that) {
case _CalendarCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarCell value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  String displayStatus,  String dayStatus,  bool isHoliday,  String holidayReason,  int classCount,  int publishedCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarCell() when $default != null:
return $default(_that.date,_that.displayStatus,_that.dayStatus,_that.isHoliday,_that.holidayReason,_that.classCount,_that.publishedCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  String displayStatus,  String dayStatus,  bool isHoliday,  String holidayReason,  int classCount,  int publishedCount)  $default,) {final _that = this;
switch (_that) {
case _CalendarCell():
return $default(_that.date,_that.displayStatus,_that.dayStatus,_that.isHoliday,_that.holidayReason,_that.classCount,_that.publishedCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  String displayStatus,  String dayStatus,  bool isHoliday,  String holidayReason,  int classCount,  int publishedCount)?  $default,) {final _that = this;
switch (_that) {
case _CalendarCell() when $default != null:
return $default(_that.date,_that.displayStatus,_that.dayStatus,_that.isHoliday,_that.holidayReason,_that.classCount,_that.publishedCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarCell implements CalendarCell {
  const _CalendarCell({required this.date, required this.displayStatus, this.dayStatus = 'Planned', this.isHoliday = false, this.holidayReason = '', this.classCount = 0, this.publishedCount = 0});
  factory _CalendarCell.fromJson(Map<String, dynamic> json) => _$CalendarCellFromJson(json);

@override final  DateTime date;
@override final  String displayStatus;
// Empty|Planned|Draft|Published|Holiday|Completed|Cancelled
@override@JsonKey() final  String dayStatus;
@override@JsonKey() final  bool isHoliday;
@override@JsonKey() final  String holidayReason;
@override@JsonKey() final  int classCount;
@override@JsonKey() final  int publishedCount;

/// Create a copy of CalendarCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarCellCopyWith<_CalendarCell> get copyWith => __$CalendarCellCopyWithImpl<_CalendarCell>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarCellToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarCell&&(identical(other.date, date) || other.date == date)&&(identical(other.displayStatus, displayStatus) || other.displayStatus == displayStatus)&&(identical(other.dayStatus, dayStatus) || other.dayStatus == dayStatus)&&(identical(other.isHoliday, isHoliday) || other.isHoliday == isHoliday)&&(identical(other.holidayReason, holidayReason) || other.holidayReason == holidayReason)&&(identical(other.classCount, classCount) || other.classCount == classCount)&&(identical(other.publishedCount, publishedCount) || other.publishedCount == publishedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,displayStatus,dayStatus,isHoliday,holidayReason,classCount,publishedCount);

@override
String toString() {
  return 'CalendarCell(date: $date, displayStatus: $displayStatus, dayStatus: $dayStatus, isHoliday: $isHoliday, holidayReason: $holidayReason, classCount: $classCount, publishedCount: $publishedCount)';
}


}

/// @nodoc
abstract mixin class _$CalendarCellCopyWith<$Res> implements $CalendarCellCopyWith<$Res> {
  factory _$CalendarCellCopyWith(_CalendarCell value, $Res Function(_CalendarCell) _then) = __$CalendarCellCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, String displayStatus, String dayStatus, bool isHoliday, String holidayReason, int classCount, int publishedCount
});




}
/// @nodoc
class __$CalendarCellCopyWithImpl<$Res>
    implements _$CalendarCellCopyWith<$Res> {
  __$CalendarCellCopyWithImpl(this._self, this._then);

  final _CalendarCell _self;
  final $Res Function(_CalendarCell) _then;

/// Create a copy of CalendarCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? displayStatus = null,Object? dayStatus = null,Object? isHoliday = null,Object? holidayReason = null,Object? classCount = null,Object? publishedCount = null,}) {
  return _then(_CalendarCell(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,displayStatus: null == displayStatus ? _self.displayStatus : displayStatus // ignore: cast_nullable_to_non_nullable
as String,dayStatus: null == dayStatus ? _self.dayStatus : dayStatus // ignore: cast_nullable_to_non_nullable
as String,isHoliday: null == isHoliday ? _self.isHoliday : isHoliday // ignore: cast_nullable_to_non_nullable
as bool,holidayReason: null == holidayReason ? _self.holidayReason : holidayReason // ignore: cast_nullable_to_non_nullable
as String,classCount: null == classCount ? _self.classCount : classCount // ignore: cast_nullable_to_non_nullable
as int,publishedCount: null == publishedCount ? _self.publishedCount : publishedCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ShiftCellInfo {

 String get displayStatus; int get classCount; int get publishedCount; bool get isHoliday;
/// Create a copy of ShiftCellInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftCellInfoCopyWith<ShiftCellInfo> get copyWith => _$ShiftCellInfoCopyWithImpl<ShiftCellInfo>(this as ShiftCellInfo, _$identity);

  /// Serializes this ShiftCellInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftCellInfo&&(identical(other.displayStatus, displayStatus) || other.displayStatus == displayStatus)&&(identical(other.classCount, classCount) || other.classCount == classCount)&&(identical(other.publishedCount, publishedCount) || other.publishedCount == publishedCount)&&(identical(other.isHoliday, isHoliday) || other.isHoliday == isHoliday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayStatus,classCount,publishedCount,isHoliday);

@override
String toString() {
  return 'ShiftCellInfo(displayStatus: $displayStatus, classCount: $classCount, publishedCount: $publishedCount, isHoliday: $isHoliday)';
}


}

/// @nodoc
abstract mixin class $ShiftCellInfoCopyWith<$Res>  {
  factory $ShiftCellInfoCopyWith(ShiftCellInfo value, $Res Function(ShiftCellInfo) _then) = _$ShiftCellInfoCopyWithImpl;
@useResult
$Res call({
 String displayStatus, int classCount, int publishedCount, bool isHoliday
});




}
/// @nodoc
class _$ShiftCellInfoCopyWithImpl<$Res>
    implements $ShiftCellInfoCopyWith<$Res> {
  _$ShiftCellInfoCopyWithImpl(this._self, this._then);

  final ShiftCellInfo _self;
  final $Res Function(ShiftCellInfo) _then;

/// Create a copy of ShiftCellInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayStatus = null,Object? classCount = null,Object? publishedCount = null,Object? isHoliday = null,}) {
  return _then(_self.copyWith(
displayStatus: null == displayStatus ? _self.displayStatus : displayStatus // ignore: cast_nullable_to_non_nullable
as String,classCount: null == classCount ? _self.classCount : classCount // ignore: cast_nullable_to_non_nullable
as int,publishedCount: null == publishedCount ? _self.publishedCount : publishedCount // ignore: cast_nullable_to_non_nullable
as int,isHoliday: null == isHoliday ? _self.isHoliday : isHoliday // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftCellInfo].
extension ShiftCellInfoPatterns on ShiftCellInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftCellInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftCellInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftCellInfo value)  $default,){
final _that = this;
switch (_that) {
case _ShiftCellInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftCellInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftCellInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayStatus,  int classCount,  int publishedCount,  bool isHoliday)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftCellInfo() when $default != null:
return $default(_that.displayStatus,_that.classCount,_that.publishedCount,_that.isHoliday);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayStatus,  int classCount,  int publishedCount,  bool isHoliday)  $default,) {final _that = this;
switch (_that) {
case _ShiftCellInfo():
return $default(_that.displayStatus,_that.classCount,_that.publishedCount,_that.isHoliday);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayStatus,  int classCount,  int publishedCount,  bool isHoliday)?  $default,) {final _that = this;
switch (_that) {
case _ShiftCellInfo() when $default != null:
return $default(_that.displayStatus,_that.classCount,_that.publishedCount,_that.isHoliday);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftCellInfo implements ShiftCellInfo {
  const _ShiftCellInfo({this.displayStatus = 'Empty', this.classCount = 0, this.publishedCount = 0, this.isHoliday = false});
  factory _ShiftCellInfo.fromJson(Map<String, dynamic> json) => _$ShiftCellInfoFromJson(json);

@override@JsonKey() final  String displayStatus;
@override@JsonKey() final  int classCount;
@override@JsonKey() final  int publishedCount;
@override@JsonKey() final  bool isHoliday;

/// Create a copy of ShiftCellInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftCellInfoCopyWith<_ShiftCellInfo> get copyWith => __$ShiftCellInfoCopyWithImpl<_ShiftCellInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftCellInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftCellInfo&&(identical(other.displayStatus, displayStatus) || other.displayStatus == displayStatus)&&(identical(other.classCount, classCount) || other.classCount == classCount)&&(identical(other.publishedCount, publishedCount) || other.publishedCount == publishedCount)&&(identical(other.isHoliday, isHoliday) || other.isHoliday == isHoliday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayStatus,classCount,publishedCount,isHoliday);

@override
String toString() {
  return 'ShiftCellInfo(displayStatus: $displayStatus, classCount: $classCount, publishedCount: $publishedCount, isHoliday: $isHoliday)';
}


}

/// @nodoc
abstract mixin class _$ShiftCellInfoCopyWith<$Res> implements $ShiftCellInfoCopyWith<$Res> {
  factory _$ShiftCellInfoCopyWith(_ShiftCellInfo value, $Res Function(_ShiftCellInfo) _then) = __$ShiftCellInfoCopyWithImpl;
@override @useResult
$Res call({
 String displayStatus, int classCount, int publishedCount, bool isHoliday
});




}
/// @nodoc
class __$ShiftCellInfoCopyWithImpl<$Res>
    implements _$ShiftCellInfoCopyWith<$Res> {
  __$ShiftCellInfoCopyWithImpl(this._self, this._then);

  final _ShiftCellInfo _self;
  final $Res Function(_ShiftCellInfo) _then;

/// Create a copy of ShiftCellInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayStatus = null,Object? classCount = null,Object? publishedCount = null,Object? isHoliday = null,}) {
  return _then(_ShiftCellInfo(
displayStatus: null == displayStatus ? _self.displayStatus : displayStatus // ignore: cast_nullable_to_non_nullable
as String,classCount: null == classCount ? _self.classCount : classCount // ignore: cast_nullable_to_non_nullable
as int,publishedCount: null == publishedCount ? _self.publishedCount : publishedCount // ignore: cast_nullable_to_non_nullable
as int,isHoliday: null == isHoliday ? _self.isHoliday : isHoliday // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OverviewCell {

 DateTime get date; Map<String, ShiftCellInfo> get shifts;
/// Create a copy of OverviewCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverviewCellCopyWith<OverviewCell> get copyWith => _$OverviewCellCopyWithImpl<OverviewCell>(this as OverviewCell, _$identity);

  /// Serializes this OverviewCell to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverviewCell&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.shifts, shifts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(shifts));

@override
String toString() {
  return 'OverviewCell(date: $date, shifts: $shifts)';
}


}

/// @nodoc
abstract mixin class $OverviewCellCopyWith<$Res>  {
  factory $OverviewCellCopyWith(OverviewCell value, $Res Function(OverviewCell) _then) = _$OverviewCellCopyWithImpl;
@useResult
$Res call({
 DateTime date, Map<String, ShiftCellInfo> shifts
});




}
/// @nodoc
class _$OverviewCellCopyWithImpl<$Res>
    implements $OverviewCellCopyWith<$Res> {
  _$OverviewCellCopyWithImpl(this._self, this._then);

  final OverviewCell _self;
  final $Res Function(OverviewCell) _then;

/// Create a copy of OverviewCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? shifts = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shifts: null == shifts ? _self.shifts : shifts // ignore: cast_nullable_to_non_nullable
as Map<String, ShiftCellInfo>,
  ));
}

}


/// Adds pattern-matching-related methods to [OverviewCell].
extension OverviewCellPatterns on OverviewCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverviewCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverviewCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverviewCell value)  $default,){
final _that = this;
switch (_that) {
case _OverviewCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverviewCell value)?  $default,){
final _that = this;
switch (_that) {
case _OverviewCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  Map<String, ShiftCellInfo> shifts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverviewCell() when $default != null:
return $default(_that.date,_that.shifts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  Map<String, ShiftCellInfo> shifts)  $default,) {final _that = this;
switch (_that) {
case _OverviewCell():
return $default(_that.date,_that.shifts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  Map<String, ShiftCellInfo> shifts)?  $default,) {final _that = this;
switch (_that) {
case _OverviewCell() when $default != null:
return $default(_that.date,_that.shifts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverviewCell implements OverviewCell {
  const _OverviewCell({required this.date, final  Map<String, ShiftCellInfo> shifts = const {}}): _shifts = shifts;
  factory _OverviewCell.fromJson(Map<String, dynamic> json) => _$OverviewCellFromJson(json);

@override final  DateTime date;
 final  Map<String, ShiftCellInfo> _shifts;
@override@JsonKey() Map<String, ShiftCellInfo> get shifts {
  if (_shifts is EqualUnmodifiableMapView) return _shifts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_shifts);
}


/// Create a copy of OverviewCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverviewCellCopyWith<_OverviewCell> get copyWith => __$OverviewCellCopyWithImpl<_OverviewCell>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverviewCellToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverviewCell&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._shifts, _shifts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_shifts));

@override
String toString() {
  return 'OverviewCell(date: $date, shifts: $shifts)';
}


}

/// @nodoc
abstract mixin class _$OverviewCellCopyWith<$Res> implements $OverviewCellCopyWith<$Res> {
  factory _$OverviewCellCopyWith(_OverviewCell value, $Res Function(_OverviewCell) _then) = __$OverviewCellCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, Map<String, ShiftCellInfo> shifts
});




}
/// @nodoc
class __$OverviewCellCopyWithImpl<$Res>
    implements _$OverviewCellCopyWith<$Res> {
  __$OverviewCellCopyWithImpl(this._self, this._then);

  final _OverviewCell _self;
  final $Res Function(_OverviewCell) _then;

/// Create a copy of OverviewCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? shifts = null,}) {
  return _then(_OverviewCell(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shifts: null == shifts ? _self._shifts : shifts // ignore: cast_nullable_to_non_nullable
as Map<String, ShiftCellInfo>,
  ));
}


}


/// @nodoc
mixin _$MonthlySummary {

 String get academicYear; int get year; int get month; String get shift; int get plannedDays; int get holidays; int get draftTimetables; int get publishedTimetables; int get scheduledClasses; int get teachersAssigned;
/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlySummaryCopyWith<MonthlySummary> get copyWith => _$MonthlySummaryCopyWithImpl<MonthlySummary>(this as MonthlySummary, _$identity);

  /// Serializes this MonthlySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlySummary&&(identical(other.academicYear, academicYear) || other.academicYear == academicYear)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.shift, shift) || other.shift == shift)&&(identical(other.plannedDays, plannedDays) || other.plannedDays == plannedDays)&&(identical(other.holidays, holidays) || other.holidays == holidays)&&(identical(other.draftTimetables, draftTimetables) || other.draftTimetables == draftTimetables)&&(identical(other.publishedTimetables, publishedTimetables) || other.publishedTimetables == publishedTimetables)&&(identical(other.scheduledClasses, scheduledClasses) || other.scheduledClasses == scheduledClasses)&&(identical(other.teachersAssigned, teachersAssigned) || other.teachersAssigned == teachersAssigned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,academicYear,year,month,shift,plannedDays,holidays,draftTimetables,publishedTimetables,scheduledClasses,teachersAssigned);

@override
String toString() {
  return 'MonthlySummary(academicYear: $academicYear, year: $year, month: $month, shift: $shift, plannedDays: $plannedDays, holidays: $holidays, draftTimetables: $draftTimetables, publishedTimetables: $publishedTimetables, scheduledClasses: $scheduledClasses, teachersAssigned: $teachersAssigned)';
}


}

/// @nodoc
abstract mixin class $MonthlySummaryCopyWith<$Res>  {
  factory $MonthlySummaryCopyWith(MonthlySummary value, $Res Function(MonthlySummary) _then) = _$MonthlySummaryCopyWithImpl;
@useResult
$Res call({
 String academicYear, int year, int month, String shift, int plannedDays, int holidays, int draftTimetables, int publishedTimetables, int scheduledClasses, int teachersAssigned
});




}
/// @nodoc
class _$MonthlySummaryCopyWithImpl<$Res>
    implements $MonthlySummaryCopyWith<$Res> {
  _$MonthlySummaryCopyWithImpl(this._self, this._then);

  final MonthlySummary _self;
  final $Res Function(MonthlySummary) _then;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? academicYear = null,Object? year = null,Object? month = null,Object? shift = null,Object? plannedDays = null,Object? holidays = null,Object? draftTimetables = null,Object? publishedTimetables = null,Object? scheduledClasses = null,Object? teachersAssigned = null,}) {
  return _then(_self.copyWith(
academicYear: null == academicYear ? _self.academicYear : academicYear // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,plannedDays: null == plannedDays ? _self.plannedDays : plannedDays // ignore: cast_nullable_to_non_nullable
as int,holidays: null == holidays ? _self.holidays : holidays // ignore: cast_nullable_to_non_nullable
as int,draftTimetables: null == draftTimetables ? _self.draftTimetables : draftTimetables // ignore: cast_nullable_to_non_nullable
as int,publishedTimetables: null == publishedTimetables ? _self.publishedTimetables : publishedTimetables // ignore: cast_nullable_to_non_nullable
as int,scheduledClasses: null == scheduledClasses ? _self.scheduledClasses : scheduledClasses // ignore: cast_nullable_to_non_nullable
as int,teachersAssigned: null == teachersAssigned ? _self.teachersAssigned : teachersAssigned // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlySummary].
extension MonthlySummaryPatterns on MonthlySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlySummary value)  $default,){
final _that = this;
switch (_that) {
case _MonthlySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlySummary value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String academicYear,  int year,  int month,  String shift,  int plannedDays,  int holidays,  int draftTimetables,  int publishedTimetables,  int scheduledClasses,  int teachersAssigned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
return $default(_that.academicYear,_that.year,_that.month,_that.shift,_that.plannedDays,_that.holidays,_that.draftTimetables,_that.publishedTimetables,_that.scheduledClasses,_that.teachersAssigned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String academicYear,  int year,  int month,  String shift,  int plannedDays,  int holidays,  int draftTimetables,  int publishedTimetables,  int scheduledClasses,  int teachersAssigned)  $default,) {final _that = this;
switch (_that) {
case _MonthlySummary():
return $default(_that.academicYear,_that.year,_that.month,_that.shift,_that.plannedDays,_that.holidays,_that.draftTimetables,_that.publishedTimetables,_that.scheduledClasses,_that.teachersAssigned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String academicYear,  int year,  int month,  String shift,  int plannedDays,  int holidays,  int draftTimetables,  int publishedTimetables,  int scheduledClasses,  int teachersAssigned)?  $default,) {final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
return $default(_that.academicYear,_that.year,_that.month,_that.shift,_that.plannedDays,_that.holidays,_that.draftTimetables,_that.publishedTimetables,_that.scheduledClasses,_that.teachersAssigned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlySummary implements MonthlySummary {
  const _MonthlySummary({this.academicYear = '', this.year = 0, this.month = 0, this.shift = 'Shift-1', this.plannedDays = 0, this.holidays = 0, this.draftTimetables = 0, this.publishedTimetables = 0, this.scheduledClasses = 0, this.teachersAssigned = 0});
  factory _MonthlySummary.fromJson(Map<String, dynamic> json) => _$MonthlySummaryFromJson(json);

@override@JsonKey() final  String academicYear;
@override@JsonKey() final  int year;
@override@JsonKey() final  int month;
@override@JsonKey() final  String shift;
@override@JsonKey() final  int plannedDays;
@override@JsonKey() final  int holidays;
@override@JsonKey() final  int draftTimetables;
@override@JsonKey() final  int publishedTimetables;
@override@JsonKey() final  int scheduledClasses;
@override@JsonKey() final  int teachersAssigned;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlySummaryCopyWith<_MonthlySummary> get copyWith => __$MonthlySummaryCopyWithImpl<_MonthlySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlySummary&&(identical(other.academicYear, academicYear) || other.academicYear == academicYear)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.shift, shift) || other.shift == shift)&&(identical(other.plannedDays, plannedDays) || other.plannedDays == plannedDays)&&(identical(other.holidays, holidays) || other.holidays == holidays)&&(identical(other.draftTimetables, draftTimetables) || other.draftTimetables == draftTimetables)&&(identical(other.publishedTimetables, publishedTimetables) || other.publishedTimetables == publishedTimetables)&&(identical(other.scheduledClasses, scheduledClasses) || other.scheduledClasses == scheduledClasses)&&(identical(other.teachersAssigned, teachersAssigned) || other.teachersAssigned == teachersAssigned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,academicYear,year,month,shift,plannedDays,holidays,draftTimetables,publishedTimetables,scheduledClasses,teachersAssigned);

@override
String toString() {
  return 'MonthlySummary(academicYear: $academicYear, year: $year, month: $month, shift: $shift, plannedDays: $plannedDays, holidays: $holidays, draftTimetables: $draftTimetables, publishedTimetables: $publishedTimetables, scheduledClasses: $scheduledClasses, teachersAssigned: $teachersAssigned)';
}


}

/// @nodoc
abstract mixin class _$MonthlySummaryCopyWith<$Res> implements $MonthlySummaryCopyWith<$Res> {
  factory _$MonthlySummaryCopyWith(_MonthlySummary value, $Res Function(_MonthlySummary) _then) = __$MonthlySummaryCopyWithImpl;
@override @useResult
$Res call({
 String academicYear, int year, int month, String shift, int plannedDays, int holidays, int draftTimetables, int publishedTimetables, int scheduledClasses, int teachersAssigned
});




}
/// @nodoc
class __$MonthlySummaryCopyWithImpl<$Res>
    implements _$MonthlySummaryCopyWith<$Res> {
  __$MonthlySummaryCopyWithImpl(this._self, this._then);

  final _MonthlySummary _self;
  final $Res Function(_MonthlySummary) _then;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? academicYear = null,Object? year = null,Object? month = null,Object? shift = null,Object? plannedDays = null,Object? holidays = null,Object? draftTimetables = null,Object? publishedTimetables = null,Object? scheduledClasses = null,Object? teachersAssigned = null,}) {
  return _then(_MonthlySummary(
academicYear: null == academicYear ? _self.academicYear : academicYear // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,plannedDays: null == plannedDays ? _self.plannedDays : plannedDays // ignore: cast_nullable_to_non_nullable
as int,holidays: null == holidays ? _self.holidays : holidays // ignore: cast_nullable_to_non_nullable
as int,draftTimetables: null == draftTimetables ? _self.draftTimetables : draftTimetables // ignore: cast_nullable_to_non_nullable
as int,publishedTimetables: null == publishedTimetables ? _self.publishedTimetables : publishedTimetables // ignore: cast_nullable_to_non_nullable
as int,scheduledClasses: null == scheduledClasses ? _self.scheduledClasses : scheduledClasses // ignore: cast_nullable_to_non_nullable
as int,teachersAssigned: null == teachersAssigned ? _self.teachersAssigned : teachersAssigned // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DayPeriod {

@JsonKey(name: 'id') String? get id; DateTime? get date; String get classroomName; int get period; String get subjectName; String? get teacherId; String? get teacherName; String get startTime; String get endTime; String get room; String get status; String get shift;
/// Create a copy of DayPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayPeriodCopyWith<DayPeriod> get copyWith => _$DayPeriodCopyWithImpl<DayPeriod>(this as DayPeriod, _$identity);

  /// Serializes this DayPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&(identical(other.period, period) || other.period == period)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.room, room) || other.room == room)&&(identical(other.status, status) || other.status == status)&&(identical(other.shift, shift) || other.shift == shift));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,classroomName,period,subjectName,teacherId,teacherName,startTime,endTime,room,status,shift);

@override
String toString() {
  return 'DayPeriod(id: $id, date: $date, classroomName: $classroomName, period: $period, subjectName: $subjectName, teacherId: $teacherId, teacherName: $teacherName, startTime: $startTime, endTime: $endTime, room: $room, status: $status, shift: $shift)';
}


}

/// @nodoc
abstract mixin class $DayPeriodCopyWith<$Res>  {
  factory $DayPeriodCopyWith(DayPeriod value, $Res Function(DayPeriod) _then) = _$DayPeriodCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String? id, DateTime? date, String classroomName, int period, String subjectName, String? teacherId, String? teacherName, String startTime, String endTime, String room, String status, String shift
});




}
/// @nodoc
class _$DayPeriodCopyWithImpl<$Res>
    implements $DayPeriodCopyWith<$Res> {
  _$DayPeriodCopyWithImpl(this._self, this._then);

  final DayPeriod _self;
  final $Res Function(DayPeriod) _then;

/// Create a copy of DayPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? date = freezed,Object? classroomName = null,Object? period = null,Object? subjectName = null,Object? teacherId = freezed,Object? teacherName = freezed,Object? startTime = null,Object? endTime = null,Object? room = null,Object? status = null,Object? shift = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,teacherId: freezed == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String?,teacherName: freezed == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DayPeriod].
extension DayPeriodPatterns on DayPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayPeriod value)  $default,){
final _that = this;
switch (_that) {
case _DayPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _DayPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? id,  DateTime? date,  String classroomName,  int period,  String subjectName,  String? teacherId,  String? teacherName,  String startTime,  String endTime,  String room,  String status,  String shift)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayPeriod() when $default != null:
return $default(_that.id,_that.date,_that.classroomName,_that.period,_that.subjectName,_that.teacherId,_that.teacherName,_that.startTime,_that.endTime,_that.room,_that.status,_that.shift);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? id,  DateTime? date,  String classroomName,  int period,  String subjectName,  String? teacherId,  String? teacherName,  String startTime,  String endTime,  String room,  String status,  String shift)  $default,) {final _that = this;
switch (_that) {
case _DayPeriod():
return $default(_that.id,_that.date,_that.classroomName,_that.period,_that.subjectName,_that.teacherId,_that.teacherName,_that.startTime,_that.endTime,_that.room,_that.status,_that.shift);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String? id,  DateTime? date,  String classroomName,  int period,  String subjectName,  String? teacherId,  String? teacherName,  String startTime,  String endTime,  String room,  String status,  String shift)?  $default,) {final _that = this;
switch (_that) {
case _DayPeriod() when $default != null:
return $default(_that.id,_that.date,_that.classroomName,_that.period,_that.subjectName,_that.teacherId,_that.teacherName,_that.startTime,_that.endTime,_that.room,_that.status,_that.shift);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayPeriod implements DayPeriod {
  const _DayPeriod({@JsonKey(name: 'id') this.id, this.date, this.classroomName = '', required this.period, this.subjectName = '', this.teacherId, this.teacherName, this.startTime = '', this.endTime = '', this.room = '', this.status = 'Draft', this.shift = 'Shift-1'});
  factory _DayPeriod.fromJson(Map<String, dynamic> json) => _$DayPeriodFromJson(json);

@override@JsonKey(name: 'id') final  String? id;
@override final  DateTime? date;
@override@JsonKey() final  String classroomName;
@override final  int period;
@override@JsonKey() final  String subjectName;
@override final  String? teacherId;
@override final  String? teacherName;
@override@JsonKey() final  String startTime;
@override@JsonKey() final  String endTime;
@override@JsonKey() final  String room;
@override@JsonKey() final  String status;
@override@JsonKey() final  String shift;

/// Create a copy of DayPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayPeriodCopyWith<_DayPeriod> get copyWith => __$DayPeriodCopyWithImpl<_DayPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&(identical(other.period, period) || other.period == period)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.room, room) || other.room == room)&&(identical(other.status, status) || other.status == status)&&(identical(other.shift, shift) || other.shift == shift));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,classroomName,period,subjectName,teacherId,teacherName,startTime,endTime,room,status,shift);

@override
String toString() {
  return 'DayPeriod(id: $id, date: $date, classroomName: $classroomName, period: $period, subjectName: $subjectName, teacherId: $teacherId, teacherName: $teacherName, startTime: $startTime, endTime: $endTime, room: $room, status: $status, shift: $shift)';
}


}

/// @nodoc
abstract mixin class _$DayPeriodCopyWith<$Res> implements $DayPeriodCopyWith<$Res> {
  factory _$DayPeriodCopyWith(_DayPeriod value, $Res Function(_DayPeriod) _then) = __$DayPeriodCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String? id, DateTime? date, String classroomName, int period, String subjectName, String? teacherId, String? teacherName, String startTime, String endTime, String room, String status, String shift
});




}
/// @nodoc
class __$DayPeriodCopyWithImpl<$Res>
    implements _$DayPeriodCopyWith<$Res> {
  __$DayPeriodCopyWithImpl(this._self, this._then);

  final _DayPeriod _self;
  final $Res Function(_DayPeriod) _then;

/// Create a copy of DayPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? date = freezed,Object? classroomName = null,Object? period = null,Object? subjectName = null,Object? teacherId = freezed,Object? teacherName = freezed,Object? startTime = null,Object? endTime = null,Object? room = null,Object? status = null,Object? shift = null,}) {
  return _then(_DayPeriod(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,teacherId: freezed == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String?,teacherName: freezed == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TeacherOption {

 String get id; String get fullName; String get title; String? get photoUrl; List<String> get subjects; String get specialty;
/// Create a copy of TeacherOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeacherOptionCopyWith<TeacherOption> get copyWith => _$TeacherOptionCopyWithImpl<TeacherOption>(this as TeacherOption, _$identity);

  /// Serializes this TeacherOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeacherOption&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.title, title) || other.title == title)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&const DeepCollectionEquality().equals(other.subjects, subjects)&&(identical(other.specialty, specialty) || other.specialty == specialty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,title,photoUrl,const DeepCollectionEquality().hash(subjects),specialty);

@override
String toString() {
  return 'TeacherOption(id: $id, fullName: $fullName, title: $title, photoUrl: $photoUrl, subjects: $subjects, specialty: $specialty)';
}


}

/// @nodoc
abstract mixin class $TeacherOptionCopyWith<$Res>  {
  factory $TeacherOptionCopyWith(TeacherOption value, $Res Function(TeacherOption) _then) = _$TeacherOptionCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, String title, String? photoUrl, List<String> subjects, String specialty
});




}
/// @nodoc
class _$TeacherOptionCopyWithImpl<$Res>
    implements $TeacherOptionCopyWith<$Res> {
  _$TeacherOptionCopyWithImpl(this._self, this._then);

  final TeacherOption _self;
  final $Res Function(TeacherOption) _then;

/// Create a copy of TeacherOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? title = null,Object? photoUrl = freezed,Object? subjects = null,Object? specialty = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,subjects: null == subjects ? _self.subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,specialty: null == specialty ? _self.specialty : specialty // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TeacherOption].
extension TeacherOptionPatterns on TeacherOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeacherOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeacherOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeacherOption value)  $default,){
final _that = this;
switch (_that) {
case _TeacherOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeacherOption value)?  $default,){
final _that = this;
switch (_that) {
case _TeacherOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  String title,  String? photoUrl,  List<String> subjects,  String specialty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeacherOption() when $default != null:
return $default(_that.id,_that.fullName,_that.title,_that.photoUrl,_that.subjects,_that.specialty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  String title,  String? photoUrl,  List<String> subjects,  String specialty)  $default,) {final _that = this;
switch (_that) {
case _TeacherOption():
return $default(_that.id,_that.fullName,_that.title,_that.photoUrl,_that.subjects,_that.specialty);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  String title,  String? photoUrl,  List<String> subjects,  String specialty)?  $default,) {final _that = this;
switch (_that) {
case _TeacherOption() when $default != null:
return $default(_that.id,_that.fullName,_that.title,_that.photoUrl,_that.subjects,_that.specialty);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeacherOption extends TeacherOption {
  const _TeacherOption({required this.id, this.fullName = '', this.title = '', this.photoUrl, final  List<String> subjects = const [], this.specialty = ''}): _subjects = subjects,super._();
  factory _TeacherOption.fromJson(Map<String, dynamic> json) => _$TeacherOptionFromJson(json);

@override final  String id;
@override@JsonKey() final  String fullName;
@override@JsonKey() final  String title;
@override final  String? photoUrl;
 final  List<String> _subjects;
@override@JsonKey() List<String> get subjects {
  if (_subjects is EqualUnmodifiableListView) return _subjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subjects);
}

@override@JsonKey() final  String specialty;

/// Create a copy of TeacherOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeacherOptionCopyWith<_TeacherOption> get copyWith => __$TeacherOptionCopyWithImpl<_TeacherOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeacherOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeacherOption&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.title, title) || other.title == title)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&const DeepCollectionEquality().equals(other._subjects, _subjects)&&(identical(other.specialty, specialty) || other.specialty == specialty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,title,photoUrl,const DeepCollectionEquality().hash(_subjects),specialty);

@override
String toString() {
  return 'TeacherOption(id: $id, fullName: $fullName, title: $title, photoUrl: $photoUrl, subjects: $subjects, specialty: $specialty)';
}


}

/// @nodoc
abstract mixin class _$TeacherOptionCopyWith<$Res> implements $TeacherOptionCopyWith<$Res> {
  factory _$TeacherOptionCopyWith(_TeacherOption value, $Res Function(_TeacherOption) _then) = __$TeacherOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, String title, String? photoUrl, List<String> subjects, String specialty
});




}
/// @nodoc
class __$TeacherOptionCopyWithImpl<$Res>
    implements _$TeacherOptionCopyWith<$Res> {
  __$TeacherOptionCopyWithImpl(this._self, this._then);

  final _TeacherOption _self;
  final $Res Function(_TeacherOption) _then;

/// Create a copy of TeacherOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? title = null,Object? photoUrl = freezed,Object? subjects = null,Object? specialty = null,}) {
  return _then(_TeacherOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,subjects: null == subjects ? _self._subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,specialty: null == specialty ? _self.specialty : specialty // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ClassroomOption {

@JsonKey(name: '_id') String? get id; String get name; List<String> get subjects;
/// Create a copy of ClassroomOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassroomOptionCopyWith<ClassroomOption> get copyWith => _$ClassroomOptionCopyWithImpl<ClassroomOption>(this as ClassroomOption, _$identity);

  /// Serializes this ClassroomOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassroomOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.subjects, subjects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(subjects));

@override
String toString() {
  return 'ClassroomOption(id: $id, name: $name, subjects: $subjects)';
}


}

/// @nodoc
abstract mixin class $ClassroomOptionCopyWith<$Res>  {
  factory $ClassroomOptionCopyWith(ClassroomOption value, $Res Function(ClassroomOption) _then) = _$ClassroomOptionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String? id, String name, List<String> subjects
});




}
/// @nodoc
class _$ClassroomOptionCopyWithImpl<$Res>
    implements $ClassroomOptionCopyWith<$Res> {
  _$ClassroomOptionCopyWithImpl(this._self, this._then);

  final ClassroomOption _self;
  final $Res Function(ClassroomOption) _then;

/// Create a copy of ClassroomOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? subjects = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subjects: null == subjects ? _self.subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassroomOption].
extension ClassroomOptionPatterns on ClassroomOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassroomOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassroomOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassroomOption value)  $default,){
final _that = this;
switch (_that) {
case _ClassroomOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassroomOption value)?  $default,){
final _that = this;
switch (_that) {
case _ClassroomOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String? id,  String name,  List<String> subjects)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassroomOption() when $default != null:
return $default(_that.id,_that.name,_that.subjects);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String? id,  String name,  List<String> subjects)  $default,) {final _that = this;
switch (_that) {
case _ClassroomOption():
return $default(_that.id,_that.name,_that.subjects);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String? id,  String name,  List<String> subjects)?  $default,) {final _that = this;
switch (_that) {
case _ClassroomOption() when $default != null:
return $default(_that.id,_that.name,_that.subjects);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClassroomOption implements ClassroomOption {
  const _ClassroomOption({@JsonKey(name: '_id') this.id, this.name = '', final  List<String> subjects = const []}): _subjects = subjects;
  factory _ClassroomOption.fromJson(Map<String, dynamic> json) => _$ClassroomOptionFromJson(json);

@override@JsonKey(name: '_id') final  String? id;
@override@JsonKey() final  String name;
 final  List<String> _subjects;
@override@JsonKey() List<String> get subjects {
  if (_subjects is EqualUnmodifiableListView) return _subjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subjects);
}


/// Create a copy of ClassroomOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassroomOptionCopyWith<_ClassroomOption> get copyWith => __$ClassroomOptionCopyWithImpl<_ClassroomOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClassroomOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassroomOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._subjects, _subjects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_subjects));

@override
String toString() {
  return 'ClassroomOption(id: $id, name: $name, subjects: $subjects)';
}


}

/// @nodoc
abstract mixin class _$ClassroomOptionCopyWith<$Res> implements $ClassroomOptionCopyWith<$Res> {
  factory _$ClassroomOptionCopyWith(_ClassroomOption value, $Res Function(_ClassroomOption) _then) = __$ClassroomOptionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String? id, String name, List<String> subjects
});




}
/// @nodoc
class __$ClassroomOptionCopyWithImpl<$Res>
    implements _$ClassroomOptionCopyWith<$Res> {
  __$ClassroomOptionCopyWithImpl(this._self, this._then);

  final _ClassroomOption _self;
  final $Res Function(_ClassroomOption) _then;

/// Create a copy of ClassroomOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? subjects = null,}) {
  return _then(_ClassroomOption(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subjects: null == subjects ? _self._subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$DayTimetable {

 DateTime get date; String get shift; bool get isPlanned; String get dayStatus; bool get isHoliday; List<DayPeriod> get periods; List<TeacherOption> get teachers; List<ClassroomOption> get classrooms;
/// Create a copy of DayTimetable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayTimetableCopyWith<DayTimetable> get copyWith => _$DayTimetableCopyWithImpl<DayTimetable>(this as DayTimetable, _$identity);

  /// Serializes this DayTimetable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayTimetable&&(identical(other.date, date) || other.date == date)&&(identical(other.shift, shift) || other.shift == shift)&&(identical(other.isPlanned, isPlanned) || other.isPlanned == isPlanned)&&(identical(other.dayStatus, dayStatus) || other.dayStatus == dayStatus)&&(identical(other.isHoliday, isHoliday) || other.isHoliday == isHoliday)&&const DeepCollectionEquality().equals(other.periods, periods)&&const DeepCollectionEquality().equals(other.teachers, teachers)&&const DeepCollectionEquality().equals(other.classrooms, classrooms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,shift,isPlanned,dayStatus,isHoliday,const DeepCollectionEquality().hash(periods),const DeepCollectionEquality().hash(teachers),const DeepCollectionEquality().hash(classrooms));

@override
String toString() {
  return 'DayTimetable(date: $date, shift: $shift, isPlanned: $isPlanned, dayStatus: $dayStatus, isHoliday: $isHoliday, periods: $periods, teachers: $teachers, classrooms: $classrooms)';
}


}

/// @nodoc
abstract mixin class $DayTimetableCopyWith<$Res>  {
  factory $DayTimetableCopyWith(DayTimetable value, $Res Function(DayTimetable) _then) = _$DayTimetableCopyWithImpl;
@useResult
$Res call({
 DateTime date, String shift, bool isPlanned, String dayStatus, bool isHoliday, List<DayPeriod> periods, List<TeacherOption> teachers, List<ClassroomOption> classrooms
});




}
/// @nodoc
class _$DayTimetableCopyWithImpl<$Res>
    implements $DayTimetableCopyWith<$Res> {
  _$DayTimetableCopyWithImpl(this._self, this._then);

  final DayTimetable _self;
  final $Res Function(DayTimetable) _then;

/// Create a copy of DayTimetable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? shift = null,Object? isPlanned = null,Object? dayStatus = null,Object? isHoliday = null,Object? periods = null,Object? teachers = null,Object? classrooms = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,isPlanned: null == isPlanned ? _self.isPlanned : isPlanned // ignore: cast_nullable_to_non_nullable
as bool,dayStatus: null == dayStatus ? _self.dayStatus : dayStatus // ignore: cast_nullable_to_non_nullable
as String,isHoliday: null == isHoliday ? _self.isHoliday : isHoliday // ignore: cast_nullable_to_non_nullable
as bool,periods: null == periods ? _self.periods : periods // ignore: cast_nullable_to_non_nullable
as List<DayPeriod>,teachers: null == teachers ? _self.teachers : teachers // ignore: cast_nullable_to_non_nullable
as List<TeacherOption>,classrooms: null == classrooms ? _self.classrooms : classrooms // ignore: cast_nullable_to_non_nullable
as List<ClassroomOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayTimetable].
extension DayTimetablePatterns on DayTimetable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayTimetable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayTimetable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayTimetable value)  $default,){
final _that = this;
switch (_that) {
case _DayTimetable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayTimetable value)?  $default,){
final _that = this;
switch (_that) {
case _DayTimetable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  String shift,  bool isPlanned,  String dayStatus,  bool isHoliday,  List<DayPeriod> periods,  List<TeacherOption> teachers,  List<ClassroomOption> classrooms)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayTimetable() when $default != null:
return $default(_that.date,_that.shift,_that.isPlanned,_that.dayStatus,_that.isHoliday,_that.periods,_that.teachers,_that.classrooms);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  String shift,  bool isPlanned,  String dayStatus,  bool isHoliday,  List<DayPeriod> periods,  List<TeacherOption> teachers,  List<ClassroomOption> classrooms)  $default,) {final _that = this;
switch (_that) {
case _DayTimetable():
return $default(_that.date,_that.shift,_that.isPlanned,_that.dayStatus,_that.isHoliday,_that.periods,_that.teachers,_that.classrooms);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  String shift,  bool isPlanned,  String dayStatus,  bool isHoliday,  List<DayPeriod> periods,  List<TeacherOption> teachers,  List<ClassroomOption> classrooms)?  $default,) {final _that = this;
switch (_that) {
case _DayTimetable() when $default != null:
return $default(_that.date,_that.shift,_that.isPlanned,_that.dayStatus,_that.isHoliday,_that.periods,_that.teachers,_that.classrooms);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayTimetable implements DayTimetable {
  const _DayTimetable({required this.date, this.shift = 'Shift-1', this.isPlanned = false, this.dayStatus = 'Empty', this.isHoliday = false, final  List<DayPeriod> periods = const [], final  List<TeacherOption> teachers = const [], final  List<ClassroomOption> classrooms = const []}): _periods = periods,_teachers = teachers,_classrooms = classrooms;
  factory _DayTimetable.fromJson(Map<String, dynamic> json) => _$DayTimetableFromJson(json);

@override final  DateTime date;
@override@JsonKey() final  String shift;
@override@JsonKey() final  bool isPlanned;
@override@JsonKey() final  String dayStatus;
@override@JsonKey() final  bool isHoliday;
 final  List<DayPeriod> _periods;
@override@JsonKey() List<DayPeriod> get periods {
  if (_periods is EqualUnmodifiableListView) return _periods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_periods);
}

 final  List<TeacherOption> _teachers;
@override@JsonKey() List<TeacherOption> get teachers {
  if (_teachers is EqualUnmodifiableListView) return _teachers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teachers);
}

 final  List<ClassroomOption> _classrooms;
@override@JsonKey() List<ClassroomOption> get classrooms {
  if (_classrooms is EqualUnmodifiableListView) return _classrooms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classrooms);
}


/// Create a copy of DayTimetable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayTimetableCopyWith<_DayTimetable> get copyWith => __$DayTimetableCopyWithImpl<_DayTimetable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayTimetableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayTimetable&&(identical(other.date, date) || other.date == date)&&(identical(other.shift, shift) || other.shift == shift)&&(identical(other.isPlanned, isPlanned) || other.isPlanned == isPlanned)&&(identical(other.dayStatus, dayStatus) || other.dayStatus == dayStatus)&&(identical(other.isHoliday, isHoliday) || other.isHoliday == isHoliday)&&const DeepCollectionEquality().equals(other._periods, _periods)&&const DeepCollectionEquality().equals(other._teachers, _teachers)&&const DeepCollectionEquality().equals(other._classrooms, _classrooms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,shift,isPlanned,dayStatus,isHoliday,const DeepCollectionEquality().hash(_periods),const DeepCollectionEquality().hash(_teachers),const DeepCollectionEquality().hash(_classrooms));

@override
String toString() {
  return 'DayTimetable(date: $date, shift: $shift, isPlanned: $isPlanned, dayStatus: $dayStatus, isHoliday: $isHoliday, periods: $periods, teachers: $teachers, classrooms: $classrooms)';
}


}

/// @nodoc
abstract mixin class _$DayTimetableCopyWith<$Res> implements $DayTimetableCopyWith<$Res> {
  factory _$DayTimetableCopyWith(_DayTimetable value, $Res Function(_DayTimetable) _then) = __$DayTimetableCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, String shift, bool isPlanned, String dayStatus, bool isHoliday, List<DayPeriod> periods, List<TeacherOption> teachers, List<ClassroomOption> classrooms
});




}
/// @nodoc
class __$DayTimetableCopyWithImpl<$Res>
    implements _$DayTimetableCopyWith<$Res> {
  __$DayTimetableCopyWithImpl(this._self, this._then);

  final _DayTimetable _self;
  final $Res Function(_DayTimetable) _then;

/// Create a copy of DayTimetable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? shift = null,Object? isPlanned = null,Object? dayStatus = null,Object? isHoliday = null,Object? periods = null,Object? teachers = null,Object? classrooms = null,}) {
  return _then(_DayTimetable(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,isPlanned: null == isPlanned ? _self.isPlanned : isPlanned // ignore: cast_nullable_to_non_nullable
as bool,dayStatus: null == dayStatus ? _self.dayStatus : dayStatus // ignore: cast_nullable_to_non_nullable
as String,isHoliday: null == isHoliday ? _self.isHoliday : isHoliday // ignore: cast_nullable_to_non_nullable
as bool,periods: null == periods ? _self._periods : periods // ignore: cast_nullable_to_non_nullable
as List<DayPeriod>,teachers: null == teachers ? _self._teachers : teachers // ignore: cast_nullable_to_non_nullable
as List<TeacherOption>,classrooms: null == classrooms ? _self._classrooms : classrooms // ignore: cast_nullable_to_non_nullable
as List<ClassroomOption>,
  ));
}


}


/// @nodoc
mixin _$TeacherClass {

@JsonKey(name: 'id') String get id; DateTime get date; String get shift; String get classroomName; int get period; String get subjectName; String get startTime; String get endTime; String get room; String get status; bool get attendanceEnabled; bool get alreadyMarked;
/// Create a copy of TeacherClass
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeacherClassCopyWith<TeacherClass> get copyWith => _$TeacherClassCopyWithImpl<TeacherClass>(this as TeacherClass, _$identity);

  /// Serializes this TeacherClass to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeacherClass&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.shift, shift) || other.shift == shift)&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&(identical(other.period, period) || other.period == period)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.room, room) || other.room == room)&&(identical(other.status, status) || other.status == status)&&(identical(other.attendanceEnabled, attendanceEnabled) || other.attendanceEnabled == attendanceEnabled)&&(identical(other.alreadyMarked, alreadyMarked) || other.alreadyMarked == alreadyMarked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,shift,classroomName,period,subjectName,startTime,endTime,room,status,attendanceEnabled,alreadyMarked);

@override
String toString() {
  return 'TeacherClass(id: $id, date: $date, shift: $shift, classroomName: $classroomName, period: $period, subjectName: $subjectName, startTime: $startTime, endTime: $endTime, room: $room, status: $status, attendanceEnabled: $attendanceEnabled, alreadyMarked: $alreadyMarked)';
}


}

/// @nodoc
abstract mixin class $TeacherClassCopyWith<$Res>  {
  factory $TeacherClassCopyWith(TeacherClass value, $Res Function(TeacherClass) _then) = _$TeacherClassCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id, DateTime date, String shift, String classroomName, int period, String subjectName, String startTime, String endTime, String room, String status, bool attendanceEnabled, bool alreadyMarked
});




}
/// @nodoc
class _$TeacherClassCopyWithImpl<$Res>
    implements $TeacherClassCopyWith<$Res> {
  _$TeacherClassCopyWithImpl(this._self, this._then);

  final TeacherClass _self;
  final $Res Function(TeacherClass) _then;

/// Create a copy of TeacherClass
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? shift = null,Object? classroomName = null,Object? period = null,Object? subjectName = null,Object? startTime = null,Object? endTime = null,Object? room = null,Object? status = null,Object? attendanceEnabled = null,Object? alreadyMarked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,attendanceEnabled: null == attendanceEnabled ? _self.attendanceEnabled : attendanceEnabled // ignore: cast_nullable_to_non_nullable
as bool,alreadyMarked: null == alreadyMarked ? _self.alreadyMarked : alreadyMarked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TeacherClass].
extension TeacherClassPatterns on TeacherClass {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeacherClass value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeacherClass() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeacherClass value)  $default,){
final _that = this;
switch (_that) {
case _TeacherClass():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeacherClass value)?  $default,){
final _that = this;
switch (_that) {
case _TeacherClass() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id,  DateTime date,  String shift,  String classroomName,  int period,  String subjectName,  String startTime,  String endTime,  String room,  String status,  bool attendanceEnabled,  bool alreadyMarked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeacherClass() when $default != null:
return $default(_that.id,_that.date,_that.shift,_that.classroomName,_that.period,_that.subjectName,_that.startTime,_that.endTime,_that.room,_that.status,_that.attendanceEnabled,_that.alreadyMarked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id,  DateTime date,  String shift,  String classroomName,  int period,  String subjectName,  String startTime,  String endTime,  String room,  String status,  bool attendanceEnabled,  bool alreadyMarked)  $default,) {final _that = this;
switch (_that) {
case _TeacherClass():
return $default(_that.id,_that.date,_that.shift,_that.classroomName,_that.period,_that.subjectName,_that.startTime,_that.endTime,_that.room,_that.status,_that.attendanceEnabled,_that.alreadyMarked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id,  DateTime date,  String shift,  String classroomName,  int period,  String subjectName,  String startTime,  String endTime,  String room,  String status,  bool attendanceEnabled,  bool alreadyMarked)?  $default,) {final _that = this;
switch (_that) {
case _TeacherClass() when $default != null:
return $default(_that.id,_that.date,_that.shift,_that.classroomName,_that.period,_that.subjectName,_that.startTime,_that.endTime,_that.room,_that.status,_that.attendanceEnabled,_that.alreadyMarked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeacherClass implements TeacherClass {
  const _TeacherClass({@JsonKey(name: 'id') required this.id, required this.date, this.shift = 'Shift-1', this.classroomName = '', required this.period, this.subjectName = '', this.startTime = '', this.endTime = '', this.room = '', this.status = 'Published', this.attendanceEnabled = false, this.alreadyMarked = false});
  factory _TeacherClass.fromJson(Map<String, dynamic> json) => _$TeacherClassFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override final  DateTime date;
@override@JsonKey() final  String shift;
@override@JsonKey() final  String classroomName;
@override final  int period;
@override@JsonKey() final  String subjectName;
@override@JsonKey() final  String startTime;
@override@JsonKey() final  String endTime;
@override@JsonKey() final  String room;
@override@JsonKey() final  String status;
@override@JsonKey() final  bool attendanceEnabled;
@override@JsonKey() final  bool alreadyMarked;

/// Create a copy of TeacherClass
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeacherClassCopyWith<_TeacherClass> get copyWith => __$TeacherClassCopyWithImpl<_TeacherClass>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeacherClassToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeacherClass&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.shift, shift) || other.shift == shift)&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&(identical(other.period, period) || other.period == period)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.room, room) || other.room == room)&&(identical(other.status, status) || other.status == status)&&(identical(other.attendanceEnabled, attendanceEnabled) || other.attendanceEnabled == attendanceEnabled)&&(identical(other.alreadyMarked, alreadyMarked) || other.alreadyMarked == alreadyMarked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,shift,classroomName,period,subjectName,startTime,endTime,room,status,attendanceEnabled,alreadyMarked);

@override
String toString() {
  return 'TeacherClass(id: $id, date: $date, shift: $shift, classroomName: $classroomName, period: $period, subjectName: $subjectName, startTime: $startTime, endTime: $endTime, room: $room, status: $status, attendanceEnabled: $attendanceEnabled, alreadyMarked: $alreadyMarked)';
}


}

/// @nodoc
abstract mixin class _$TeacherClassCopyWith<$Res> implements $TeacherClassCopyWith<$Res> {
  factory _$TeacherClassCopyWith(_TeacherClass value, $Res Function(_TeacherClass) _then) = __$TeacherClassCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id, DateTime date, String shift, String classroomName, int period, String subjectName, String startTime, String endTime, String room, String status, bool attendanceEnabled, bool alreadyMarked
});




}
/// @nodoc
class __$TeacherClassCopyWithImpl<$Res>
    implements _$TeacherClassCopyWith<$Res> {
  __$TeacherClassCopyWithImpl(this._self, this._then);

  final _TeacherClass _self;
  final $Res Function(_TeacherClass) _then;

/// Create a copy of TeacherClass
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? shift = null,Object? classroomName = null,Object? period = null,Object? subjectName = null,Object? startTime = null,Object? endTime = null,Object? room = null,Object? status = null,Object? attendanceEnabled = null,Object? alreadyMarked = null,}) {
  return _then(_TeacherClass(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,attendanceEnabled: null == attendanceEnabled ? _self.attendanceEnabled : attendanceEnabled // ignore: cast_nullable_to_non_nullable
as bool,alreadyMarked: null == alreadyMarked ? _self.alreadyMarked : alreadyMarked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$StudentPeriod {

@JsonKey(name: 'id') String get id; DateTime get date; String get classroomName; int get period; String get subjectName; String? get teacherName; String get startTime; String get endTime; String get room; String get status;
/// Create a copy of StudentPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentPeriodCopyWith<StudentPeriod> get copyWith => _$StudentPeriodCopyWithImpl<StudentPeriod>(this as StudentPeriod, _$identity);

  /// Serializes this StudentPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&(identical(other.period, period) || other.period == period)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.room, room) || other.room == room)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,classroomName,period,subjectName,teacherName,startTime,endTime,room,status);

@override
String toString() {
  return 'StudentPeriod(id: $id, date: $date, classroomName: $classroomName, period: $period, subjectName: $subjectName, teacherName: $teacherName, startTime: $startTime, endTime: $endTime, room: $room, status: $status)';
}


}

/// @nodoc
abstract mixin class $StudentPeriodCopyWith<$Res>  {
  factory $StudentPeriodCopyWith(StudentPeriod value, $Res Function(StudentPeriod) _then) = _$StudentPeriodCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id, DateTime date, String classroomName, int period, String subjectName, String? teacherName, String startTime, String endTime, String room, String status
});




}
/// @nodoc
class _$StudentPeriodCopyWithImpl<$Res>
    implements $StudentPeriodCopyWith<$Res> {
  _$StudentPeriodCopyWithImpl(this._self, this._then);

  final StudentPeriod _self;
  final $Res Function(StudentPeriod) _then;

/// Create a copy of StudentPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? classroomName = null,Object? period = null,Object? subjectName = null,Object? teacherName = freezed,Object? startTime = null,Object? endTime = null,Object? room = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,teacherName: freezed == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentPeriod].
extension StudentPeriodPatterns on StudentPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentPeriod value)  $default,){
final _that = this;
switch (_that) {
case _StudentPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _StudentPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id,  DateTime date,  String classroomName,  int period,  String subjectName,  String? teacherName,  String startTime,  String endTime,  String room,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentPeriod() when $default != null:
return $default(_that.id,_that.date,_that.classroomName,_that.period,_that.subjectName,_that.teacherName,_that.startTime,_that.endTime,_that.room,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id,  DateTime date,  String classroomName,  int period,  String subjectName,  String? teacherName,  String startTime,  String endTime,  String room,  String status)  $default,) {final _that = this;
switch (_that) {
case _StudentPeriod():
return $default(_that.id,_that.date,_that.classroomName,_that.period,_that.subjectName,_that.teacherName,_that.startTime,_that.endTime,_that.room,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id,  DateTime date,  String classroomName,  int period,  String subjectName,  String? teacherName,  String startTime,  String endTime,  String room,  String status)?  $default,) {final _that = this;
switch (_that) {
case _StudentPeriod() when $default != null:
return $default(_that.id,_that.date,_that.classroomName,_that.period,_that.subjectName,_that.teacherName,_that.startTime,_that.endTime,_that.room,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentPeriod implements StudentPeriod {
  const _StudentPeriod({@JsonKey(name: 'id') required this.id, required this.date, this.classroomName = '', required this.period, this.subjectName = '', this.teacherName, this.startTime = '', this.endTime = '', this.room = '', this.status = 'Published'});
  factory _StudentPeriod.fromJson(Map<String, dynamic> json) => _$StudentPeriodFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override final  DateTime date;
@override@JsonKey() final  String classroomName;
@override final  int period;
@override@JsonKey() final  String subjectName;
@override final  String? teacherName;
@override@JsonKey() final  String startTime;
@override@JsonKey() final  String endTime;
@override@JsonKey() final  String room;
@override@JsonKey() final  String status;

/// Create a copy of StudentPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentPeriodCopyWith<_StudentPeriod> get copyWith => __$StudentPeriodCopyWithImpl<_StudentPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.classroomName, classroomName) || other.classroomName == classroomName)&&(identical(other.period, period) || other.period == period)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.room, room) || other.room == room)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,classroomName,period,subjectName,teacherName,startTime,endTime,room,status);

@override
String toString() {
  return 'StudentPeriod(id: $id, date: $date, classroomName: $classroomName, period: $period, subjectName: $subjectName, teacherName: $teacherName, startTime: $startTime, endTime: $endTime, room: $room, status: $status)';
}


}

/// @nodoc
abstract mixin class _$StudentPeriodCopyWith<$Res> implements $StudentPeriodCopyWith<$Res> {
  factory _$StudentPeriodCopyWith(_StudentPeriod value, $Res Function(_StudentPeriod) _then) = __$StudentPeriodCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id, DateTime date, String classroomName, int period, String subjectName, String? teacherName, String startTime, String endTime, String room, String status
});




}
/// @nodoc
class __$StudentPeriodCopyWithImpl<$Res>
    implements _$StudentPeriodCopyWith<$Res> {
  __$StudentPeriodCopyWithImpl(this._self, this._then);

  final _StudentPeriod _self;
  final $Res Function(_StudentPeriod) _then;

/// Create a copy of StudentPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? classroomName = null,Object? period = null,Object? subjectName = null,Object? teacherName = freezed,Object? startTime = null,Object? endTime = null,Object? room = null,Object? status = null,}) {
  return _then(_StudentPeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,classroomName: null == classroomName ? _self.classroomName : classroomName // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as int,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,teacherName: freezed == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
