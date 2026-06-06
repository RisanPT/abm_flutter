// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StudentController)
final studentControllerProvider = StudentControllerProvider._();

final class StudentControllerProvider
    extends $AsyncNotifierProvider<StudentController, List<StudentModel>> {
  StudentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentControllerHash();

  @$internal
  @override
  StudentController create() => StudentController();
}

String _$studentControllerHash() => r'4c246baea8a4b244aaf762272551dd5f0a1d9eb2';

abstract class _$StudentController extends $AsyncNotifier<List<StudentModel>> {
  FutureOr<List<StudentModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<StudentModel>>, List<StudentModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<StudentModel>>, List<StudentModel>>,
              AsyncValue<List<StudentModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
