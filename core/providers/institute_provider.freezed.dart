// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'institute_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Institute {

@JsonKey(name: '_id') String get id; String get name; String get location; String? get address; String? get contactNumber; String? get email; String get iconName; bool get isActive; double get latitude; double get longitude; double get radius;
/// Create a copy of Institute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstituteCopyWith<Institute> get copyWith => _$InstituteCopyWithImpl<Institute>(this as Institute, _$identity);

  /// Serializes this Institute to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Institute&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.address, address) || other.address == address)&&(identical(other.contactNumber, contactNumber) || other.contactNumber == contactNumber)&&(identical(other.email, email) || other.email == email)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.radius, radius) || other.radius == radius));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,location,address,contactNumber,email,iconName,isActive,latitude,longitude,radius);

@override
String toString() {
  return 'Institute(id: $id, name: $name, location: $location, address: $address, contactNumber: $contactNumber, email: $email, iconName: $iconName, isActive: $isActive, latitude: $latitude, longitude: $longitude, radius: $radius)';
}


}

/// @nodoc
abstract mixin class $InstituteCopyWith<$Res>  {
  factory $InstituteCopyWith(Institute value, $Res Function(Institute) _then) = _$InstituteCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String name, String location, String? address, String? contactNumber, String? email, String iconName, bool isActive, double latitude, double longitude, double radius
});




}
/// @nodoc
class _$InstituteCopyWithImpl<$Res>
    implements $InstituteCopyWith<$Res> {
  _$InstituteCopyWithImpl(this._self, this._then);

  final Institute _self;
  final $Res Function(Institute) _then;

/// Create a copy of Institute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? location = null,Object? address = freezed,Object? contactNumber = freezed,Object? email = freezed,Object? iconName = null,Object? isActive = null,Object? latitude = null,Object? longitude = null,Object? radius = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,contactNumber: freezed == contactNumber ? _self.contactNumber : contactNumber // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Institute].
extension InstitutePatterns on Institute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Institute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Institute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Institute value)  $default,){
final _that = this;
switch (_that) {
case _Institute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Institute value)?  $default,){
final _that = this;
switch (_that) {
case _Institute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String name,  String location,  String? address,  String? contactNumber,  String? email,  String iconName,  bool isActive,  double latitude,  double longitude,  double radius)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Institute() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.address,_that.contactNumber,_that.email,_that.iconName,_that.isActive,_that.latitude,_that.longitude,_that.radius);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String name,  String location,  String? address,  String? contactNumber,  String? email,  String iconName,  bool isActive,  double latitude,  double longitude,  double radius)  $default,) {final _that = this;
switch (_that) {
case _Institute():
return $default(_that.id,_that.name,_that.location,_that.address,_that.contactNumber,_that.email,_that.iconName,_that.isActive,_that.latitude,_that.longitude,_that.radius);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String name,  String location,  String? address,  String? contactNumber,  String? email,  String iconName,  bool isActive,  double latitude,  double longitude,  double radius)?  $default,) {final _that = this;
switch (_that) {
case _Institute() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.address,_that.contactNumber,_that.email,_that.iconName,_that.isActive,_that.latitude,_that.longitude,_that.radius);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Institute implements Institute {
  const _Institute({@JsonKey(name: '_id') required this.id, required this.name, required this.location, this.address, this.contactNumber, this.email, this.iconName = 'school', this.isActive = true, this.latitude = 25.2048, this.longitude = 55.2708, this.radius = 500.0});
  factory _Institute.fromJson(Map<String, dynamic> json) => _$InstituteFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override final  String name;
@override final  String location;
@override final  String? address;
@override final  String? contactNumber;
@override final  String? email;
@override@JsonKey() final  String iconName;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  double latitude;
@override@JsonKey() final  double longitude;
@override@JsonKey() final  double radius;

/// Create a copy of Institute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstituteCopyWith<_Institute> get copyWith => __$InstituteCopyWithImpl<_Institute>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstituteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Institute&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.address, address) || other.address == address)&&(identical(other.contactNumber, contactNumber) || other.contactNumber == contactNumber)&&(identical(other.email, email) || other.email == email)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.radius, radius) || other.radius == radius));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,location,address,contactNumber,email,iconName,isActive,latitude,longitude,radius);

@override
String toString() {
  return 'Institute(id: $id, name: $name, location: $location, address: $address, contactNumber: $contactNumber, email: $email, iconName: $iconName, isActive: $isActive, latitude: $latitude, longitude: $longitude, radius: $radius)';
}


}

/// @nodoc
abstract mixin class _$InstituteCopyWith<$Res> implements $InstituteCopyWith<$Res> {
  factory _$InstituteCopyWith(_Institute value, $Res Function(_Institute) _then) = __$InstituteCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String name, String location, String? address, String? contactNumber, String? email, String iconName, bool isActive, double latitude, double longitude, double radius
});




}
/// @nodoc
class __$InstituteCopyWithImpl<$Res>
    implements _$InstituteCopyWith<$Res> {
  __$InstituteCopyWithImpl(this._self, this._then);

  final _Institute _self;
  final $Res Function(_Institute) _then;

/// Create a copy of Institute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? location = null,Object? address = freezed,Object? contactNumber = freezed,Object? email = freezed,Object? iconName = null,Object? isActive = null,Object? latitude = null,Object? longitude = null,Object? radius = null,}) {
  return _then(_Institute(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,contactNumber: freezed == contactNumber ? _self.contactNumber : contactNumber // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
