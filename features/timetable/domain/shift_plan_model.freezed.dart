// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShiftPlanModel {

@JsonKey(name: '_id') String? get id; String get instituteId; String get shift; int get year; int get month; List<DateTime> get classDates;
/// Create a copy of ShiftPlanModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftPlanModelCopyWith<ShiftPlanModel> get copyWith => _$ShiftPlanModelCopyWithImpl<ShiftPlanModel>(this as ShiftPlanModel, _$identity);

  /// Serializes this ShiftPlanModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftPlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.instituteId, instituteId) || other.instituteId == instituteId)&&(identical(other.shift, shift) || other.shift == shift)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other.classDates, classDates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,instituteId,shift,year,month,const DeepCollectionEquality().hash(classDates));

@override
String toString() {
  return 'ShiftPlanModel(id: $id, instituteId: $instituteId, shift: $shift, year: $year, month: $month, classDates: $classDates)';
}


}

/// @nodoc
abstract mixin class $ShiftPlanModelCopyWith<$Res>  {
  factory $ShiftPlanModelCopyWith(ShiftPlanModel value, $Res Function(ShiftPlanModel) _then) = _$ShiftPlanModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String? id, String instituteId, String shift, int year, int month, List<DateTime> classDates
});




}
/// @nodoc
class _$ShiftPlanModelCopyWithImpl<$Res>
    implements $ShiftPlanModelCopyWith<$Res> {
  _$ShiftPlanModelCopyWithImpl(this._self, this._then);

  final ShiftPlanModel _self;
  final $Res Function(ShiftPlanModel) _then;

/// Create a copy of ShiftPlanModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? instituteId = null,Object? shift = null,Object? year = null,Object? month = null,Object? classDates = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,instituteId: null == instituteId ? _self.instituteId : instituteId // ignore: cast_nullable_to_non_nullable
as String,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,classDates: null == classDates ? _self.classDates : classDates // ignore: cast_nullable_to_non_nullable
as List<DateTime>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftPlanModel].
extension ShiftPlanModelPatterns on ShiftPlanModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftPlanModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftPlanModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftPlanModel value)  $default,){
final _that = this;
switch (_that) {
case _ShiftPlanModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftPlanModel value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftPlanModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String? id,  String instituteId,  String shift,  int year,  int month,  List<DateTime> classDates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftPlanModel() when $default != null:
return $default(_that.id,_that.instituteId,_that.shift,_that.year,_that.month,_that.classDates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String? id,  String instituteId,  String shift,  int year,  int month,  List<DateTime> classDates)  $default,) {final _that = this;
switch (_that) {
case _ShiftPlanModel():
return $default(_that.id,_that.instituteId,_that.shift,_that.year,_that.month,_that.classDates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String? id,  String instituteId,  String shift,  int year,  int month,  List<DateTime> classDates)?  $default,) {final _that = this;
switch (_that) {
case _ShiftPlanModel() when $default != null:
return $default(_that.id,_that.instituteId,_that.shift,_that.year,_that.month,_that.classDates);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftPlanModel implements ShiftPlanModel {
  const _ShiftPlanModel({@JsonKey(name: '_id') this.id, required this.instituteId, required this.shift, required this.year, required this.month, final  List<DateTime> classDates = const []}): _classDates = classDates;
  factory _ShiftPlanModel.fromJson(Map<String, dynamic> json) => _$ShiftPlanModelFromJson(json);

@override@JsonKey(name: '_id') final  String? id;
@override final  String instituteId;
@override final  String shift;
@override final  int year;
@override final  int month;
 final  List<DateTime> _classDates;
@override@JsonKey() List<DateTime> get classDates {
  if (_classDates is EqualUnmodifiableListView) return _classDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classDates);
}


/// Create a copy of ShiftPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftPlanModelCopyWith<_ShiftPlanModel> get copyWith => __$ShiftPlanModelCopyWithImpl<_ShiftPlanModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftPlanModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftPlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.instituteId, instituteId) || other.instituteId == instituteId)&&(identical(other.shift, shift) || other.shift == shift)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other._classDates, _classDates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,instituteId,shift,year,month,const DeepCollectionEquality().hash(_classDates));

@override
String toString() {
  return 'ShiftPlanModel(id: $id, instituteId: $instituteId, shift: $shift, year: $year, month: $month, classDates: $classDates)';
}


}

/// @nodoc
abstract mixin class _$ShiftPlanModelCopyWith<$Res> implements $ShiftPlanModelCopyWith<$Res> {
  factory _$ShiftPlanModelCopyWith(_ShiftPlanModel value, $Res Function(_ShiftPlanModel) _then) = __$ShiftPlanModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String? id, String instituteId, String shift, int year, int month, List<DateTime> classDates
});




}
/// @nodoc
class __$ShiftPlanModelCopyWithImpl<$Res>
    implements _$ShiftPlanModelCopyWith<$Res> {
  __$ShiftPlanModelCopyWithImpl(this._self, this._then);

  final _ShiftPlanModel _self;
  final $Res Function(_ShiftPlanModel) _then;

/// Create a copy of ShiftPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? instituteId = null,Object? shift = null,Object? year = null,Object? month = null,Object? classDates = null,}) {
  return _then(_ShiftPlanModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,instituteId: null == instituteId ? _self.instituteId : instituteId // ignore: cast_nullable_to_non_nullable
as String,shift: null == shift ? _self.shift : shift // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,classDates: null == classDates ? _self._classDates : classDates // ignore: cast_nullable_to_non_nullable
as List<DateTime>,
  ));
}


}

// dart format on
