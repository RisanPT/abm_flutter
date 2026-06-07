// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'institute_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Institute _$InstituteFromJson(Map<String, dynamic> json) => _Institute(
  id: json['_id'] as String,
  name: json['name'] as String,
  location: json['location'] as String,
  address: json['address'] as String?,
  contactNumber: json['contactNumber'] as String?,
  email: json['email'] as String?,
  iconName: json['iconName'] as String? ?? 'school',
  isActive: json['isActive'] as bool? ?? true,
  latitude: (json['latitude'] as num?)?.toDouble() ?? 25.2048,
  longitude: (json['longitude'] as num?)?.toDouble() ?? 55.2708,
  radius: (json['radius'] as num?)?.toDouble() ?? 500.0,
);

Map<String, dynamic> _$InstituteToJson(_Institute instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'address': instance.address,
      'contactNumber': instance.contactNumber,
      'email': instance.email,
      'iconName': instance.iconName,
      'isActive': instance.isActive,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius': instance.radius,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InstituteList)
final instituteListProvider = InstituteListProvider._();

final class InstituteListProvider
    extends $AsyncNotifierProvider<InstituteList, List<Institute>> {
  InstituteListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'instituteListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$instituteListHash();

  @$internal
  @override
  InstituteList create() => InstituteList();
}

String _$instituteListHash() => r'afff5f7254ac31b4553f4761956a5c9091349486';

abstract class _$InstituteList extends $AsyncNotifier<List<Institute>> {
  FutureOr<List<Institute>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Institute>>, List<Institute>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Institute>>, List<Institute>>,
              AsyncValue<List<Institute>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedInstitute)
final selectedInstituteProvider = SelectedInstituteProvider._();

final class SelectedInstituteProvider
    extends $NotifierProvider<SelectedInstitute, Institute> {
  SelectedInstituteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedInstituteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedInstituteHash();

  @$internal
  @override
  SelectedInstitute create() => SelectedInstitute();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Institute value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Institute>(value),
    );
  }
}

String _$selectedInstituteHash() => r'e860f6c6b9a371e72f29c2d4e99efd5925102a35';

abstract class _$SelectedInstitute extends $Notifier<Institute> {
  Institute build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Institute, Institute>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Institute, Institute>,
              Institute,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
