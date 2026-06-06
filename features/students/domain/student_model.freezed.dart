// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StudentModel {

@JsonKey(name: '_id') String get id; String get fullName;@JsonKey(name: 'studentId') String get admissionNumber;@JsonKey(name: 'grade') String get classroom; DateTime get dateOfBirth; Gender get gender; String? get bloodGroup; String get guardianName;@JsonKey(name: 'parentContact') String get guardianContact; String get address;@JsonKey(name: 'enrollmentDate') DateTime get admissionDate; double? get attendancePercentage; bool get isActive; String? get photoUrl; String? get parentPassportId; String? get parentIqamaId; bool get needsTransportation; double get transportationFee; bool get hasConcession; String get instituteId; double? get scholarshipAmount;
/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentModelCopyWith<StudentModel> get copyWith => _$StudentModelCopyWithImpl<StudentModel>(this as StudentModel, _$identity);

  /// Serializes this StudentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.admissionNumber, admissionNumber) || other.admissionNumber == admissionNumber)&&(identical(other.classroom, classroom) || other.classroom == classroom)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.bloodGroup, bloodGroup) || other.bloodGroup == bloodGroup)&&(identical(other.guardianName, guardianName) || other.guardianName == guardianName)&&(identical(other.guardianContact, guardianContact) || other.guardianContact == guardianContact)&&(identical(other.address, address) || other.address == address)&&(identical(other.admissionDate, admissionDate) || other.admissionDate == admissionDate)&&(identical(other.attendancePercentage, attendancePercentage) || other.attendancePercentage == attendancePercentage)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.parentPassportId, parentPassportId) || other.parentPassportId == parentPassportId)&&(identical(other.parentIqamaId, parentIqamaId) || other.parentIqamaId == parentIqamaId)&&(identical(other.needsTransportation, needsTransportation) || other.needsTransportation == needsTransportation)&&(identical(other.transportationFee, transportationFee) || other.transportationFee == transportationFee)&&(identical(other.hasConcession, hasConcession) || other.hasConcession == hasConcession)&&(identical(other.instituteId, instituteId) || other.instituteId == instituteId)&&(identical(other.scholarshipAmount, scholarshipAmount) || other.scholarshipAmount == scholarshipAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,fullName,admissionNumber,classroom,dateOfBirth,gender,bloodGroup,guardianName,guardianContact,address,admissionDate,attendancePercentage,isActive,photoUrl,parentPassportId,parentIqamaId,needsTransportation,transportationFee,hasConcession,instituteId,scholarshipAmount]);

@override
String toString() {
  return 'StudentModel(id: $id, fullName: $fullName, admissionNumber: $admissionNumber, classroom: $classroom, dateOfBirth: $dateOfBirth, gender: $gender, bloodGroup: $bloodGroup, guardianName: $guardianName, guardianContact: $guardianContact, address: $address, admissionDate: $admissionDate, attendancePercentage: $attendancePercentage, isActive: $isActive, photoUrl: $photoUrl, parentPassportId: $parentPassportId, parentIqamaId: $parentIqamaId, needsTransportation: $needsTransportation, transportationFee: $transportationFee, hasConcession: $hasConcession, instituteId: $instituteId, scholarshipAmount: $scholarshipAmount)';
}


}

/// @nodoc
abstract mixin class $StudentModelCopyWith<$Res>  {
  factory $StudentModelCopyWith(StudentModel value, $Res Function(StudentModel) _then) = _$StudentModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String fullName,@JsonKey(name: 'studentId') String admissionNumber,@JsonKey(name: 'grade') String classroom, DateTime dateOfBirth, Gender gender, String? bloodGroup, String guardianName,@JsonKey(name: 'parentContact') String guardianContact, String address,@JsonKey(name: 'enrollmentDate') DateTime admissionDate, double? attendancePercentage, bool isActive, String? photoUrl, String? parentPassportId, String? parentIqamaId, bool needsTransportation, double transportationFee, bool hasConcession, String instituteId, double? scholarshipAmount
});




}
/// @nodoc
class _$StudentModelCopyWithImpl<$Res>
    implements $StudentModelCopyWith<$Res> {
  _$StudentModelCopyWithImpl(this._self, this._then);

  final StudentModel _self;
  final $Res Function(StudentModel) _then;

/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? admissionNumber = null,Object? classroom = null,Object? dateOfBirth = null,Object? gender = null,Object? bloodGroup = freezed,Object? guardianName = null,Object? guardianContact = null,Object? address = null,Object? admissionDate = null,Object? attendancePercentage = freezed,Object? isActive = null,Object? photoUrl = freezed,Object? parentPassportId = freezed,Object? parentIqamaId = freezed,Object? needsTransportation = null,Object? transportationFee = null,Object? hasConcession = null,Object? instituteId = null,Object? scholarshipAmount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,admissionNumber: null == admissionNumber ? _self.admissionNumber : admissionNumber // ignore: cast_nullable_to_non_nullable
as String,classroom: null == classroom ? _self.classroom : classroom // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,bloodGroup: freezed == bloodGroup ? _self.bloodGroup : bloodGroup // ignore: cast_nullable_to_non_nullable
as String?,guardianName: null == guardianName ? _self.guardianName : guardianName // ignore: cast_nullable_to_non_nullable
as String,guardianContact: null == guardianContact ? _self.guardianContact : guardianContact // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,admissionDate: null == admissionDate ? _self.admissionDate : admissionDate // ignore: cast_nullable_to_non_nullable
as DateTime,attendancePercentage: freezed == attendancePercentage ? _self.attendancePercentage : attendancePercentage // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,parentPassportId: freezed == parentPassportId ? _self.parentPassportId : parentPassportId // ignore: cast_nullable_to_non_nullable
as String?,parentIqamaId: freezed == parentIqamaId ? _self.parentIqamaId : parentIqamaId // ignore: cast_nullable_to_non_nullable
as String?,needsTransportation: null == needsTransportation ? _self.needsTransportation : needsTransportation // ignore: cast_nullable_to_non_nullable
as bool,transportationFee: null == transportationFee ? _self.transportationFee : transportationFee // ignore: cast_nullable_to_non_nullable
as double,hasConcession: null == hasConcession ? _self.hasConcession : hasConcession // ignore: cast_nullable_to_non_nullable
as bool,instituteId: null == instituteId ? _self.instituteId : instituteId // ignore: cast_nullable_to_non_nullable
as String,scholarshipAmount: freezed == scholarshipAmount ? _self.scholarshipAmount : scholarshipAmount // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentModel].
extension StudentModelPatterns on StudentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentModel value)  $default,){
final _that = this;
switch (_that) {
case _StudentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentModel value)?  $default,){
final _that = this;
switch (_that) {
case _StudentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String fullName, @JsonKey(name: 'studentId')  String admissionNumber, @JsonKey(name: 'grade')  String classroom,  DateTime dateOfBirth,  Gender gender,  String? bloodGroup,  String guardianName, @JsonKey(name: 'parentContact')  String guardianContact,  String address, @JsonKey(name: 'enrollmentDate')  DateTime admissionDate,  double? attendancePercentage,  bool isActive,  String? photoUrl,  String? parentPassportId,  String? parentIqamaId,  bool needsTransportation,  double transportationFee,  bool hasConcession,  String instituteId,  double? scholarshipAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentModel() when $default != null:
return $default(_that.id,_that.fullName,_that.admissionNumber,_that.classroom,_that.dateOfBirth,_that.gender,_that.bloodGroup,_that.guardianName,_that.guardianContact,_that.address,_that.admissionDate,_that.attendancePercentage,_that.isActive,_that.photoUrl,_that.parentPassportId,_that.parentIqamaId,_that.needsTransportation,_that.transportationFee,_that.hasConcession,_that.instituteId,_that.scholarshipAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String fullName, @JsonKey(name: 'studentId')  String admissionNumber, @JsonKey(name: 'grade')  String classroom,  DateTime dateOfBirth,  Gender gender,  String? bloodGroup,  String guardianName, @JsonKey(name: 'parentContact')  String guardianContact,  String address, @JsonKey(name: 'enrollmentDate')  DateTime admissionDate,  double? attendancePercentage,  bool isActive,  String? photoUrl,  String? parentPassportId,  String? parentIqamaId,  bool needsTransportation,  double transportationFee,  bool hasConcession,  String instituteId,  double? scholarshipAmount)  $default,) {final _that = this;
switch (_that) {
case _StudentModel():
return $default(_that.id,_that.fullName,_that.admissionNumber,_that.classroom,_that.dateOfBirth,_that.gender,_that.bloodGroup,_that.guardianName,_that.guardianContact,_that.address,_that.admissionDate,_that.attendancePercentage,_that.isActive,_that.photoUrl,_that.parentPassportId,_that.parentIqamaId,_that.needsTransportation,_that.transportationFee,_that.hasConcession,_that.instituteId,_that.scholarshipAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String fullName, @JsonKey(name: 'studentId')  String admissionNumber, @JsonKey(name: 'grade')  String classroom,  DateTime dateOfBirth,  Gender gender,  String? bloodGroup,  String guardianName, @JsonKey(name: 'parentContact')  String guardianContact,  String address, @JsonKey(name: 'enrollmentDate')  DateTime admissionDate,  double? attendancePercentage,  bool isActive,  String? photoUrl,  String? parentPassportId,  String? parentIqamaId,  bool needsTransportation,  double transportationFee,  bool hasConcession,  String instituteId,  double? scholarshipAmount)?  $default,) {final _that = this;
switch (_that) {
case _StudentModel() when $default != null:
return $default(_that.id,_that.fullName,_that.admissionNumber,_that.classroom,_that.dateOfBirth,_that.gender,_that.bloodGroup,_that.guardianName,_that.guardianContact,_that.address,_that.admissionDate,_that.attendancePercentage,_that.isActive,_that.photoUrl,_that.parentPassportId,_that.parentIqamaId,_that.needsTransportation,_that.transportationFee,_that.hasConcession,_that.instituteId,_that.scholarshipAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentModel implements StudentModel {
  const _StudentModel({@JsonKey(name: '_id') required this.id, required this.fullName, @JsonKey(name: 'studentId') required this.admissionNumber, @JsonKey(name: 'grade') required this.classroom, required this.dateOfBirth, required this.gender, this.bloodGroup, this.guardianName = 'Unknown', @JsonKey(name: 'parentContact') required this.guardianContact, required this.address, @JsonKey(name: 'enrollmentDate') required this.admissionDate, this.attendancePercentage, this.isActive = true, this.photoUrl, this.parentPassportId, this.parentIqamaId, this.needsTransportation = false, this.transportationFee = 0, this.hasConcession = false, this.instituteId = 'abm-offline-1', this.scholarshipAmount});
  factory _StudentModel.fromJson(Map<String, dynamic> json) => _$StudentModelFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override final  String fullName;
@override@JsonKey(name: 'studentId') final  String admissionNumber;
@override@JsonKey(name: 'grade') final  String classroom;
@override final  DateTime dateOfBirth;
@override final  Gender gender;
@override final  String? bloodGroup;
@override@JsonKey() final  String guardianName;
@override@JsonKey(name: 'parentContact') final  String guardianContact;
@override final  String address;
@override@JsonKey(name: 'enrollmentDate') final  DateTime admissionDate;
@override final  double? attendancePercentage;
@override@JsonKey() final  bool isActive;
@override final  String? photoUrl;
@override final  String? parentPassportId;
@override final  String? parentIqamaId;
@override@JsonKey() final  bool needsTransportation;
@override@JsonKey() final  double transportationFee;
@override@JsonKey() final  bool hasConcession;
@override@JsonKey() final  String instituteId;
@override final  double? scholarshipAmount;

/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentModelCopyWith<_StudentModel> get copyWith => __$StudentModelCopyWithImpl<_StudentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.admissionNumber, admissionNumber) || other.admissionNumber == admissionNumber)&&(identical(other.classroom, classroom) || other.classroom == classroom)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.bloodGroup, bloodGroup) || other.bloodGroup == bloodGroup)&&(identical(other.guardianName, guardianName) || other.guardianName == guardianName)&&(identical(other.guardianContact, guardianContact) || other.guardianContact == guardianContact)&&(identical(other.address, address) || other.address == address)&&(identical(other.admissionDate, admissionDate) || other.admissionDate == admissionDate)&&(identical(other.attendancePercentage, attendancePercentage) || other.attendancePercentage == attendancePercentage)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.parentPassportId, parentPassportId) || other.parentPassportId == parentPassportId)&&(identical(other.parentIqamaId, parentIqamaId) || other.parentIqamaId == parentIqamaId)&&(identical(other.needsTransportation, needsTransportation) || other.needsTransportation == needsTransportation)&&(identical(other.transportationFee, transportationFee) || other.transportationFee == transportationFee)&&(identical(other.hasConcession, hasConcession) || other.hasConcession == hasConcession)&&(identical(other.instituteId, instituteId) || other.instituteId == instituteId)&&(identical(other.scholarshipAmount, scholarshipAmount) || other.scholarshipAmount == scholarshipAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,fullName,admissionNumber,classroom,dateOfBirth,gender,bloodGroup,guardianName,guardianContact,address,admissionDate,attendancePercentage,isActive,photoUrl,parentPassportId,parentIqamaId,needsTransportation,transportationFee,hasConcession,instituteId,scholarshipAmount]);

@override
String toString() {
  return 'StudentModel(id: $id, fullName: $fullName, admissionNumber: $admissionNumber, classroom: $classroom, dateOfBirth: $dateOfBirth, gender: $gender, bloodGroup: $bloodGroup, guardianName: $guardianName, guardianContact: $guardianContact, address: $address, admissionDate: $admissionDate, attendancePercentage: $attendancePercentage, isActive: $isActive, photoUrl: $photoUrl, parentPassportId: $parentPassportId, parentIqamaId: $parentIqamaId, needsTransportation: $needsTransportation, transportationFee: $transportationFee, hasConcession: $hasConcession, instituteId: $instituteId, scholarshipAmount: $scholarshipAmount)';
}


}

/// @nodoc
abstract mixin class _$StudentModelCopyWith<$Res> implements $StudentModelCopyWith<$Res> {
  factory _$StudentModelCopyWith(_StudentModel value, $Res Function(_StudentModel) _then) = __$StudentModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String fullName,@JsonKey(name: 'studentId') String admissionNumber,@JsonKey(name: 'grade') String classroom, DateTime dateOfBirth, Gender gender, String? bloodGroup, String guardianName,@JsonKey(name: 'parentContact') String guardianContact, String address,@JsonKey(name: 'enrollmentDate') DateTime admissionDate, double? attendancePercentage, bool isActive, String? photoUrl, String? parentPassportId, String? parentIqamaId, bool needsTransportation, double transportationFee, bool hasConcession, String instituteId, double? scholarshipAmount
});




}
/// @nodoc
class __$StudentModelCopyWithImpl<$Res>
    implements _$StudentModelCopyWith<$Res> {
  __$StudentModelCopyWithImpl(this._self, this._then);

  final _StudentModel _self;
  final $Res Function(_StudentModel) _then;

/// Create a copy of StudentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? admissionNumber = null,Object? classroom = null,Object? dateOfBirth = null,Object? gender = null,Object? bloodGroup = freezed,Object? guardianName = null,Object? guardianContact = null,Object? address = null,Object? admissionDate = null,Object? attendancePercentage = freezed,Object? isActive = null,Object? photoUrl = freezed,Object? parentPassportId = freezed,Object? parentIqamaId = freezed,Object? needsTransportation = null,Object? transportationFee = null,Object? hasConcession = null,Object? instituteId = null,Object? scholarshipAmount = freezed,}) {
  return _then(_StudentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,admissionNumber: null == admissionNumber ? _self.admissionNumber : admissionNumber // ignore: cast_nullable_to_non_nullable
as String,classroom: null == classroom ? _self.classroom : classroom // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,bloodGroup: freezed == bloodGroup ? _self.bloodGroup : bloodGroup // ignore: cast_nullable_to_non_nullable
as String?,guardianName: null == guardianName ? _self.guardianName : guardianName // ignore: cast_nullable_to_non_nullable
as String,guardianContact: null == guardianContact ? _self.guardianContact : guardianContact // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,admissionDate: null == admissionDate ? _self.admissionDate : admissionDate // ignore: cast_nullable_to_non_nullable
as DateTime,attendancePercentage: freezed == attendancePercentage ? _self.attendancePercentage : attendancePercentage // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,parentPassportId: freezed == parentPassportId ? _self.parentPassportId : parentPassportId // ignore: cast_nullable_to_non_nullable
as String?,parentIqamaId: freezed == parentIqamaId ? _self.parentIqamaId : parentIqamaId // ignore: cast_nullable_to_non_nullable
as String?,needsTransportation: null == needsTransportation ? _self.needsTransportation : needsTransportation // ignore: cast_nullable_to_non_nullable
as bool,transportationFee: null == transportationFee ? _self.transportationFee : transportationFee // ignore: cast_nullable_to_non_nullable
as double,hasConcession: null == hasConcession ? _self.hasConcession : hasConcession // ignore: cast_nullable_to_non_nullable
as bool,instituteId: null == instituteId ? _self.instituteId : instituteId // ignore: cast_nullable_to_non_nullable
as String,scholarshipAmount: freezed == scholarshipAmount ? _self.scholarshipAmount : scholarshipAmount // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
