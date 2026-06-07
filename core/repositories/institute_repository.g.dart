// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'institute_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(instituteRepository)
final instituteRepositoryProvider = InstituteRepositoryProvider._();

final class InstituteRepositoryProvider
    extends
        $FunctionalProvider<
          InstituteRepository,
          InstituteRepository,
          InstituteRepository
        >
    with $Provider<InstituteRepository> {
  InstituteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'instituteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$instituteRepositoryHash();

  @$internal
  @override
  $ProviderElement<InstituteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InstituteRepository create(Ref ref) {
    return instituteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstituteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstituteRepository>(value),
    );
  }
}

String _$instituteRepositoryHash() =>
    r'aefbb607ea7e1f464d2047f7218df5cc5bddea2c';
