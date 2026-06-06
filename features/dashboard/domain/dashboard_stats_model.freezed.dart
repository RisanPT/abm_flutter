// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_stats_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MonthlyFinanceData {

 String get month; double get revenue;
/// Create a copy of MonthlyFinanceData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlyFinanceDataCopyWith<MonthlyFinanceData> get copyWith => _$MonthlyFinanceDataCopyWithImpl<MonthlyFinanceData>(this as MonthlyFinanceData, _$identity);

  /// Serializes this MonthlyFinanceData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlyFinanceData&&(identical(other.month, month) || other.month == month)&&(identical(other.revenue, revenue) || other.revenue == revenue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,revenue);

@override
String toString() {
  return 'MonthlyFinanceData(month: $month, revenue: $revenue)';
}


}

/// @nodoc
abstract mixin class $MonthlyFinanceDataCopyWith<$Res>  {
  factory $MonthlyFinanceDataCopyWith(MonthlyFinanceData value, $Res Function(MonthlyFinanceData) _then) = _$MonthlyFinanceDataCopyWithImpl;
@useResult
$Res call({
 String month, double revenue
});




}
/// @nodoc
class _$MonthlyFinanceDataCopyWithImpl<$Res>
    implements $MonthlyFinanceDataCopyWith<$Res> {
  _$MonthlyFinanceDataCopyWithImpl(this._self, this._then);

  final MonthlyFinanceData _self;
  final $Res Function(MonthlyFinanceData) _then;

/// Create a copy of MonthlyFinanceData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? revenue = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlyFinanceData].
extension MonthlyFinanceDataPatterns on MonthlyFinanceData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlyFinanceData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlyFinanceData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlyFinanceData value)  $default,){
final _that = this;
switch (_that) {
case _MonthlyFinanceData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlyFinanceData value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlyFinanceData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  double revenue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlyFinanceData() when $default != null:
return $default(_that.month,_that.revenue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  double revenue)  $default,) {final _that = this;
switch (_that) {
case _MonthlyFinanceData():
return $default(_that.month,_that.revenue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  double revenue)?  $default,) {final _that = this;
switch (_that) {
case _MonthlyFinanceData() when $default != null:
return $default(_that.month,_that.revenue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlyFinanceData implements MonthlyFinanceData {
  const _MonthlyFinanceData({required this.month, required this.revenue});
  factory _MonthlyFinanceData.fromJson(Map<String, dynamic> json) => _$MonthlyFinanceDataFromJson(json);

@override final  String month;
@override final  double revenue;

/// Create a copy of MonthlyFinanceData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlyFinanceDataCopyWith<_MonthlyFinanceData> get copyWith => __$MonthlyFinanceDataCopyWithImpl<_MonthlyFinanceData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlyFinanceDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlyFinanceData&&(identical(other.month, month) || other.month == month)&&(identical(other.revenue, revenue) || other.revenue == revenue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,revenue);

@override
String toString() {
  return 'MonthlyFinanceData(month: $month, revenue: $revenue)';
}


}

/// @nodoc
abstract mixin class _$MonthlyFinanceDataCopyWith<$Res> implements $MonthlyFinanceDataCopyWith<$Res> {
  factory _$MonthlyFinanceDataCopyWith(_MonthlyFinanceData value, $Res Function(_MonthlyFinanceData) _then) = __$MonthlyFinanceDataCopyWithImpl;
@override @useResult
$Res call({
 String month, double revenue
});




}
/// @nodoc
class __$MonthlyFinanceDataCopyWithImpl<$Res>
    implements _$MonthlyFinanceDataCopyWith<$Res> {
  __$MonthlyFinanceDataCopyWithImpl(this._self, this._then);

  final _MonthlyFinanceData _self;
  final $Res Function(_MonthlyFinanceData) _then;

/// Create a copy of MonthlyFinanceData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? revenue = null,}) {
  return _then(_MonthlyFinanceData(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$RecentActivity {

 String get type; String get title; String get subtitle; DateTime get time;
/// Create a copy of RecentActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentActivityCopyWith<RecentActivity> get copyWith => _$RecentActivityCopyWithImpl<RecentActivity>(this as RecentActivity, _$identity);

  /// Serializes this RecentActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentActivity&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,title,subtitle,time);

@override
String toString() {
  return 'RecentActivity(type: $type, title: $title, subtitle: $subtitle, time: $time)';
}


}

/// @nodoc
abstract mixin class $RecentActivityCopyWith<$Res>  {
  factory $RecentActivityCopyWith(RecentActivity value, $Res Function(RecentActivity) _then) = _$RecentActivityCopyWithImpl;
@useResult
$Res call({
 String type, String title, String subtitle, DateTime time
});




}
/// @nodoc
class _$RecentActivityCopyWithImpl<$Res>
    implements $RecentActivityCopyWith<$Res> {
  _$RecentActivityCopyWithImpl(this._self, this._then);

  final RecentActivity _self;
  final $Res Function(RecentActivity) _then;

/// Create a copy of RecentActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? subtitle = null,Object? time = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentActivity].
extension RecentActivityPatterns on RecentActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentActivity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentActivity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentActivity value)  $default,){
final _that = this;
switch (_that) {
case _RecentActivity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentActivity value)?  $default,){
final _that = this;
switch (_that) {
case _RecentActivity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String title,  String subtitle,  DateTime time)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentActivity() when $default != null:
return $default(_that.type,_that.title,_that.subtitle,_that.time);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String title,  String subtitle,  DateTime time)  $default,) {final _that = this;
switch (_that) {
case _RecentActivity():
return $default(_that.type,_that.title,_that.subtitle,_that.time);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String title,  String subtitle,  DateTime time)?  $default,) {final _that = this;
switch (_that) {
case _RecentActivity() when $default != null:
return $default(_that.type,_that.title,_that.subtitle,_that.time);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecentActivity implements RecentActivity {
  const _RecentActivity({required this.type, required this.title, required this.subtitle, required this.time});
  factory _RecentActivity.fromJson(Map<String, dynamic> json) => _$RecentActivityFromJson(json);

@override final  String type;
@override final  String title;
@override final  String subtitle;
@override final  DateTime time;

/// Create a copy of RecentActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentActivityCopyWith<_RecentActivity> get copyWith => __$RecentActivityCopyWithImpl<_RecentActivity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentActivityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentActivity&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,title,subtitle,time);

@override
String toString() {
  return 'RecentActivity(type: $type, title: $title, subtitle: $subtitle, time: $time)';
}


}

/// @nodoc
abstract mixin class _$RecentActivityCopyWith<$Res> implements $RecentActivityCopyWith<$Res> {
  factory _$RecentActivityCopyWith(_RecentActivity value, $Res Function(_RecentActivity) _then) = __$RecentActivityCopyWithImpl;
@override @useResult
$Res call({
 String type, String title, String subtitle, DateTime time
});




}
/// @nodoc
class __$RecentActivityCopyWithImpl<$Res>
    implements _$RecentActivityCopyWith<$Res> {
  __$RecentActivityCopyWithImpl(this._self, this._then);

  final _RecentActivity _self;
  final $Res Function(_RecentActivity) _then;

/// Create a copy of RecentActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? subtitle = null,Object? time = null,}) {
  return _then(_RecentActivity(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$DashboardStats {

 int get totalStudents; double get attendanceRate; double get feeCollectedThisMonth; String get feeCollectedTrend; int get upcomingEvents; List<MonthlyFinanceData> get monthlyFinanceData; List<RecentActivity> get recentActivities;
/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardStatsCopyWith<DashboardStats> get copyWith => _$DashboardStatsCopyWithImpl<DashboardStats>(this as DashboardStats, _$identity);

  /// Serializes this DashboardStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardStats&&(identical(other.totalStudents, totalStudents) || other.totalStudents == totalStudents)&&(identical(other.attendanceRate, attendanceRate) || other.attendanceRate == attendanceRate)&&(identical(other.feeCollectedThisMonth, feeCollectedThisMonth) || other.feeCollectedThisMonth == feeCollectedThisMonth)&&(identical(other.feeCollectedTrend, feeCollectedTrend) || other.feeCollectedTrend == feeCollectedTrend)&&(identical(other.upcomingEvents, upcomingEvents) || other.upcomingEvents == upcomingEvents)&&const DeepCollectionEquality().equals(other.monthlyFinanceData, monthlyFinanceData)&&const DeepCollectionEquality().equals(other.recentActivities, recentActivities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalStudents,attendanceRate,feeCollectedThisMonth,feeCollectedTrend,upcomingEvents,const DeepCollectionEquality().hash(monthlyFinanceData),const DeepCollectionEquality().hash(recentActivities));

@override
String toString() {
  return 'DashboardStats(totalStudents: $totalStudents, attendanceRate: $attendanceRate, feeCollectedThisMonth: $feeCollectedThisMonth, feeCollectedTrend: $feeCollectedTrend, upcomingEvents: $upcomingEvents, monthlyFinanceData: $monthlyFinanceData, recentActivities: $recentActivities)';
}


}

/// @nodoc
abstract mixin class $DashboardStatsCopyWith<$Res>  {
  factory $DashboardStatsCopyWith(DashboardStats value, $Res Function(DashboardStats) _then) = _$DashboardStatsCopyWithImpl;
@useResult
$Res call({
 int totalStudents, double attendanceRate, double feeCollectedThisMonth, String feeCollectedTrend, int upcomingEvents, List<MonthlyFinanceData> monthlyFinanceData, List<RecentActivity> recentActivities
});




}
/// @nodoc
class _$DashboardStatsCopyWithImpl<$Res>
    implements $DashboardStatsCopyWith<$Res> {
  _$DashboardStatsCopyWithImpl(this._self, this._then);

  final DashboardStats _self;
  final $Res Function(DashboardStats) _then;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalStudents = null,Object? attendanceRate = null,Object? feeCollectedThisMonth = null,Object? feeCollectedTrend = null,Object? upcomingEvents = null,Object? monthlyFinanceData = null,Object? recentActivities = null,}) {
  return _then(_self.copyWith(
totalStudents: null == totalStudents ? _self.totalStudents : totalStudents // ignore: cast_nullable_to_non_nullable
as int,attendanceRate: null == attendanceRate ? _self.attendanceRate : attendanceRate // ignore: cast_nullable_to_non_nullable
as double,feeCollectedThisMonth: null == feeCollectedThisMonth ? _self.feeCollectedThisMonth : feeCollectedThisMonth // ignore: cast_nullable_to_non_nullable
as double,feeCollectedTrend: null == feeCollectedTrend ? _self.feeCollectedTrend : feeCollectedTrend // ignore: cast_nullable_to_non_nullable
as String,upcomingEvents: null == upcomingEvents ? _self.upcomingEvents : upcomingEvents // ignore: cast_nullable_to_non_nullable
as int,monthlyFinanceData: null == monthlyFinanceData ? _self.monthlyFinanceData : monthlyFinanceData // ignore: cast_nullable_to_non_nullable
as List<MonthlyFinanceData>,recentActivities: null == recentActivities ? _self.recentActivities : recentActivities // ignore: cast_nullable_to_non_nullable
as List<RecentActivity>,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardStats].
extension DashboardStatsPatterns on DashboardStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardStats value)  $default,){
final _that = this;
switch (_that) {
case _DashboardStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardStats value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalStudents,  double attendanceRate,  double feeCollectedThisMonth,  String feeCollectedTrend,  int upcomingEvents,  List<MonthlyFinanceData> monthlyFinanceData,  List<RecentActivity> recentActivities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
return $default(_that.totalStudents,_that.attendanceRate,_that.feeCollectedThisMonth,_that.feeCollectedTrend,_that.upcomingEvents,_that.monthlyFinanceData,_that.recentActivities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalStudents,  double attendanceRate,  double feeCollectedThisMonth,  String feeCollectedTrend,  int upcomingEvents,  List<MonthlyFinanceData> monthlyFinanceData,  List<RecentActivity> recentActivities)  $default,) {final _that = this;
switch (_that) {
case _DashboardStats():
return $default(_that.totalStudents,_that.attendanceRate,_that.feeCollectedThisMonth,_that.feeCollectedTrend,_that.upcomingEvents,_that.monthlyFinanceData,_that.recentActivities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalStudents,  double attendanceRate,  double feeCollectedThisMonth,  String feeCollectedTrend,  int upcomingEvents,  List<MonthlyFinanceData> monthlyFinanceData,  List<RecentActivity> recentActivities)?  $default,) {final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
return $default(_that.totalStudents,_that.attendanceRate,_that.feeCollectedThisMonth,_that.feeCollectedTrend,_that.upcomingEvents,_that.monthlyFinanceData,_that.recentActivities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardStats implements DashboardStats {
  const _DashboardStats({this.totalStudents = 0, this.attendanceRate = 0.0, this.feeCollectedThisMonth = 0.0, this.feeCollectedTrend = '', this.upcomingEvents = 0, final  List<MonthlyFinanceData> monthlyFinanceData = const [], final  List<RecentActivity> recentActivities = const []}): _monthlyFinanceData = monthlyFinanceData,_recentActivities = recentActivities;
  factory _DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);

@override@JsonKey() final  int totalStudents;
@override@JsonKey() final  double attendanceRate;
@override@JsonKey() final  double feeCollectedThisMonth;
@override@JsonKey() final  String feeCollectedTrend;
@override@JsonKey() final  int upcomingEvents;
 final  List<MonthlyFinanceData> _monthlyFinanceData;
@override@JsonKey() List<MonthlyFinanceData> get monthlyFinanceData {
  if (_monthlyFinanceData is EqualUnmodifiableListView) return _monthlyFinanceData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlyFinanceData);
}

 final  List<RecentActivity> _recentActivities;
@override@JsonKey() List<RecentActivity> get recentActivities {
  if (_recentActivities is EqualUnmodifiableListView) return _recentActivities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentActivities);
}


/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardStatsCopyWith<_DashboardStats> get copyWith => __$DashboardStatsCopyWithImpl<_DashboardStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardStats&&(identical(other.totalStudents, totalStudents) || other.totalStudents == totalStudents)&&(identical(other.attendanceRate, attendanceRate) || other.attendanceRate == attendanceRate)&&(identical(other.feeCollectedThisMonth, feeCollectedThisMonth) || other.feeCollectedThisMonth == feeCollectedThisMonth)&&(identical(other.feeCollectedTrend, feeCollectedTrend) || other.feeCollectedTrend == feeCollectedTrend)&&(identical(other.upcomingEvents, upcomingEvents) || other.upcomingEvents == upcomingEvents)&&const DeepCollectionEquality().equals(other._monthlyFinanceData, _monthlyFinanceData)&&const DeepCollectionEquality().equals(other._recentActivities, _recentActivities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalStudents,attendanceRate,feeCollectedThisMonth,feeCollectedTrend,upcomingEvents,const DeepCollectionEquality().hash(_monthlyFinanceData),const DeepCollectionEquality().hash(_recentActivities));

@override
String toString() {
  return 'DashboardStats(totalStudents: $totalStudents, attendanceRate: $attendanceRate, feeCollectedThisMonth: $feeCollectedThisMonth, feeCollectedTrend: $feeCollectedTrend, upcomingEvents: $upcomingEvents, monthlyFinanceData: $monthlyFinanceData, recentActivities: $recentActivities)';
}


}

/// @nodoc
abstract mixin class _$DashboardStatsCopyWith<$Res> implements $DashboardStatsCopyWith<$Res> {
  factory _$DashboardStatsCopyWith(_DashboardStats value, $Res Function(_DashboardStats) _then) = __$DashboardStatsCopyWithImpl;
@override @useResult
$Res call({
 int totalStudents, double attendanceRate, double feeCollectedThisMonth, String feeCollectedTrend, int upcomingEvents, List<MonthlyFinanceData> monthlyFinanceData, List<RecentActivity> recentActivities
});




}
/// @nodoc
class __$DashboardStatsCopyWithImpl<$Res>
    implements _$DashboardStatsCopyWith<$Res> {
  __$DashboardStatsCopyWithImpl(this._self, this._then);

  final _DashboardStats _self;
  final $Res Function(_DashboardStats) _then;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalStudents = null,Object? attendanceRate = null,Object? feeCollectedThisMonth = null,Object? feeCollectedTrend = null,Object? upcomingEvents = null,Object? monthlyFinanceData = null,Object? recentActivities = null,}) {
  return _then(_DashboardStats(
totalStudents: null == totalStudents ? _self.totalStudents : totalStudents // ignore: cast_nullable_to_non_nullable
as int,attendanceRate: null == attendanceRate ? _self.attendanceRate : attendanceRate // ignore: cast_nullable_to_non_nullable
as double,feeCollectedThisMonth: null == feeCollectedThisMonth ? _self.feeCollectedThisMonth : feeCollectedThisMonth // ignore: cast_nullable_to_non_nullable
as double,feeCollectedTrend: null == feeCollectedTrend ? _self.feeCollectedTrend : feeCollectedTrend // ignore: cast_nullable_to_non_nullable
as String,upcomingEvents: null == upcomingEvents ? _self.upcomingEvents : upcomingEvents // ignore: cast_nullable_to_non_nullable
as int,monthlyFinanceData: null == monthlyFinanceData ? _self._monthlyFinanceData : monthlyFinanceData // ignore: cast_nullable_to_non_nullable
as List<MonthlyFinanceData>,recentActivities: null == recentActivities ? _self._recentActivities : recentActivities // ignore: cast_nullable_to_non_nullable
as List<RecentActivity>,
  ));
}


}

// dart format on
