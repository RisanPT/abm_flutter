// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(classroomRepository)
final classroomRepositoryProvider = ClassroomRepositoryProvider._();

final class ClassroomRepositoryProvider
    extends
        $FunctionalProvider<
          ClassroomRepository,
          ClassroomRepository,
          ClassroomRepository
        >
    with $Provider<ClassroomRepository> {
  ClassroomRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classroomRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classroomRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClassroomRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClassroomRepository create(Ref ref) {
    return classroomRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassroomRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassroomRepository>(value),
    );
  }
}

String _$classroomRepositoryHash() =>
    r'512a8ac60b93d56258e1b4e655d58930e13a10a2';
