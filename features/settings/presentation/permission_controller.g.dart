// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(permissionRepository)
final permissionRepositoryProvider = PermissionRepositoryProvider._();

final class PermissionRepositoryProvider
    extends
        $FunctionalProvider<
          PermissionRepository,
          PermissionRepository,
          PermissionRepository
        >
    with $Provider<PermissionRepository> {
  PermissionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permissionRepositoryHash();

  @$internal
  @override
  $ProviderElement<PermissionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PermissionRepository create(Ref ref) {
    return permissionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PermissionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PermissionRepository>(value),
    );
  }
}

String _$permissionRepositoryHash() =>
    r'b24bfb1f044f03f8566bc826e2a361cb5b791439';

@ProviderFor(PermissionController)
final permissionControllerProvider = PermissionControllerProvider._();

final class PermissionControllerProvider
    extends
        $AsyncNotifierProvider<PermissionController, List<PermissionModel>> {
  PermissionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permissionControllerHash();

  @$internal
  @override
  PermissionController create() => PermissionController();
}

String _$permissionControllerHash() =>
    r'2e84f4d4a0722a57c32efdd071d15309f95448af';

abstract class _$PermissionController
    extends $AsyncNotifier<List<PermissionModel>> {
  FutureOr<List<PermissionModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<PermissionModel>>, List<PermissionModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PermissionModel>>,
                List<PermissionModel>
              >,
              AsyncValue<List<PermissionModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
