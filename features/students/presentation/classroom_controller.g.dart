// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClassroomController)
final classroomControllerProvider = ClassroomControllerProvider._();

final class ClassroomControllerProvider
    extends $AsyncNotifierProvider<ClassroomController, List<ClassroomModel>> {
  ClassroomControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classroomControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classroomControllerHash();

  @$internal
  @override
  ClassroomController create() => ClassroomController();
}

String _$classroomControllerHash() =>
    r'8c5da76a4f352551b20b9befdda41402c3666396';

abstract class _$ClassroomController
    extends $AsyncNotifier<List<ClassroomModel>> {
  FutureOr<List<ClassroomModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ClassroomModel>>, List<ClassroomModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ClassroomModel>>,
                List<ClassroomModel>
              >,
              AsyncValue<List<ClassroomModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
