// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttendanceModel {

@JsonKey(name: '_id') String? get id; String? get studentId; String? get studentName;// Populated from studentId object if available
 String? get admissionNumber;// The student's roll number or admission ID
 String? get teacherId; String? get teacherName;// Populated from teacherId object if available
 String? get employeeId;// Friendly teacher employee number (e.g. "0013")
 DateTime get date; AttendanceStatus get status; String get markedBy; String? get remarks; DateTime? get createdAt;
/// Create a copy of AttendanceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceModelCopyWith<AttendanceModel> get copyWith => _$AttendanceModelCopyWithImpl<AttendanceModel>(this as AttendanceModel, _$identity);

  /// Serializes this AttendanceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.studentName, studentName) || other.studentName == studentName)&&(identical(other.admissionNumber, admissionNumber) || other.admissionNumber == admissionNumber)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.markedBy, markedBy) || other.markedBy == markedBy)&&(identical(other.remarks, remarks) || other.remarks == remarks)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,studentName,admissionNumber,teacherId,teacherName,employeeId,date,status,markedBy,remarks,createdAt);

@override
String toString() {
  return 'AttendanceModel(id: $id, studentId: $studentId, studentName: $studentName, admissionNumber: $admissionNumber, teacherId: $teacherId, teacherName: $teacherName, employeeId: $employeeId, date: $date, status: $status, markedBy: $markedBy, remarks: $remarks, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AttendanceModelCopyWith<$Res>  {
  factory $AttendanceModelCopyWith(AttendanceModel value, $Res Function(AttendanceModel) _then) = _$AttendanceModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String? id, String? studentId, String? studentName, String? admissionNumber, String? teacherId, String? teacherName, String? employeeId, DateTime date, AttendanceStatus status, String markedBy, String? remarks, DateTime? createdAt
});




}
/// @nodoc
class _$AttendanceModelCopyWithImpl<$Res>
    implements $AttendanceModelCopyWith<$Res> {
  _$AttendanceModelCopyWithImpl(this._self, this._then);

  final AttendanceModel _self;
  final $Res Function(AttendanceModel) _then;

/// Create a copy of AttendanceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? studentId = freezed,Object? studentName = freezed,Object? admissionNumber = freezed,Object? teacherId = freezed,Object? teacherName = freezed,Object? employeeId = freezed,Object? date = null,Object? status = null,Object? markedBy = null,Object? remarks = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,studentId: freezed == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String?,studentName: freezed == studentName ? _self.studentName : studentName // ignore: cast_nullable_to_non_nullable
as String?,admissionNumber: freezed == admissionNumber ? _self.admissionNumber : admissionNumber // ignore: cast_nullable_to_non_nullable
as String?,teacherId: freezed == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String?,teacherName: freezed == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String?,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AttendanceStatus,markedBy: null == markedBy ? _self.markedBy : markedBy // ignore: cast_nullable_to_non_nullable
as String,remarks: freezed == remarks ? _self.remarks : remarks // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceModel].
extension AttendanceModelPatterns on AttendanceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceModel value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceModel value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String? id,  String? studentId,  String? studentName,  String? admissionNumber,  String? teacherId,  String? teacherName,  String? employeeId,  DateTime date,  AttendanceStatus status,  String markedBy,  String? remarks,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceModel() when $default != null:
return $default(_that.id,_that.studentId,_that.studentName,_that.admissionNumber,_that.teacherId,_that.teacherName,_that.employeeId,_that.date,_that.status,_that.markedBy,_that.remarks,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String? id,  String? studentId,  String? studentName,  String? admissionNumber,  String? teacherId,  String? teacherName,  String? employeeId,  DateTime date,  AttendanceStatus status,  String markedBy,  String? remarks,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AttendanceModel():
return $default(_that.id,_that.studentId,_that.studentName,_that.admissionNumber,_that.teacherId,_that.teacherName,_that.employeeId,_that.date,_that.status,_that.markedBy,_that.remarks,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String? id,  String? studentId,  String? studentName,  String? admissionNumber,  String? teacherId,  String? teacherName,  String? employeeId,  DateTime date,  AttendanceStatus status,  String markedBy,  String? remarks,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceModel() when $default != null:
return $default(_that.id,_that.studentId,_that.studentName,_that.admissionNumber,_that.teacherId,_that.teacherName,_that.employeeId,_that.date,_that.status,_that.markedBy,_that.remarks,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceModel implements AttendanceModel {
  const _AttendanceModel({@JsonKey(name: '_id') this.id, this.studentId, this.studentName, this.admissionNumber, this.teacherId, this.teacherName, this.employeeId, required this.date, this.status = AttendanceStatus.absent, this.markedBy = 'Admin', this.remarks, this.createdAt});
  factory _AttendanceModel.fromJson(Map<String, dynamic> json) => _$AttendanceModelFromJson(json);

@override@JsonKey(name: '_id') final  String? id;
@override final  String? studentId;
@override final  String? studentName;
// Populated from studentId object if available
@override final  String? admissionNumber;
// The student's roll number or admission ID
@override final  String? teacherId;
@override final  String? teacherName;
// Populated from teacherId object if available
@override final  String? employeeId;
// Friendly teacher employee number (e.g. "0013")
@override final  DateTime date;
@override@JsonKey() final  AttendanceStatus status;
@override@JsonKey() final  String markedBy;
@override final  String? remarks;
@override final  DateTime? createdAt;

/// Create a copy of AttendanceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceModelCopyWith<_AttendanceModel> get copyWith => __$AttendanceModelCopyWithImpl<_AttendanceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.studentName, studentName) || other.studentName == studentName)&&(identical(other.admissionNumber, admissionNumber) || other.admissionNumber == admissionNumber)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.markedBy, markedBy) || other.markedBy == markedBy)&&(identical(other.remarks, remarks) || other.remarks == remarks)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,studentName,admissionNumber,teacherId,teacherName,employeeId,date,status,markedBy,remarks,createdAt);

@override
String toString() {
  return 'AttendanceModel(id: $id, studentId: $studentId, studentName: $studentName, admissionNumber: $admissionNumber, teacherId: $teacherId, teacherName: $teacherName, employeeId: $employeeId, date: $date, status: $status, markedBy: $markedBy, remarks: $remarks, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AttendanceModelCopyWith<$Res> implements $AttendanceModelCopyWith<$Res> {
  factory _$AttendanceModelCopyWith(_AttendanceModel value, $Res Function(_AttendanceModel) _then) = __$AttendanceModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String? id, String? studentId, String? studentName, String? admissionNumber, String? teacherId, String? teacherName, String? employeeId, DateTime date, AttendanceStatus status, String markedBy, String? remarks, DateTime? createdAt
});




}
/// @nodoc
class __$AttendanceModelCopyWithImpl<$Res>
    implements _$AttendanceModelCopyWith<$Res> {
  __$AttendanceModelCopyWithImpl(this._self, this._then);

  final _AttendanceModel _self;
  final $Res Function(_AttendanceModel) _then;

/// Create a copy of AttendanceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? studentId = freezed,Object? studentName = freezed,Object? admissionNumber = freezed,Object? teacherId = freezed,Object? teacherName = freezed,Object? employeeId = freezed,Object? date = null,Object? status = null,Object? markedBy = null,Object? remarks = freezed,Object? createdAt = freezed,}) {
  return _then(_AttendanceModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,studentId: freezed == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String?,studentName: freezed == studentName ? _self.studentName : studentName // ignore: cast_nullable_to_non_nullable
as String?,admissionNumber: freezed == admissionNumber ? _self.admissionNumber : admissionNumber // ignore: cast_nullable_to_non_nullable
as String?,teacherId: freezed == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String?,teacherName: freezed == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String?,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AttendanceStatus,markedBy: null == markedBy ? _self.markedBy : markedBy // ignore: cast_nullable_to_non_nullable
as String,remarks: freezed == remarks ? _self.remarks : remarks // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
