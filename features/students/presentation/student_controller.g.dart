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
    extends $AsyncNotifierProvider<StudentController, StudentListState> {
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

String _$studentControllerHash() => r'd7d3a6a0ef960c29fe9044cdd54d9929aa4e4499';

abstract class _$StudentController extends $AsyncNotifier<StudentListState> {
  FutureOr<StudentListState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<StudentListState>, StudentListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StudentListState>, StudentListState>,
              AsyncValue<StudentListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
