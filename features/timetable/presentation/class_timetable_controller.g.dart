// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_timetable_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClassTimetableController)
final classTimetableControllerProvider = ClassTimetableControllerFamily._();

final class ClassTimetableControllerProvider
    extends $AsyncNotifierProvider<ClassTimetableController, ClassTimetable> {
  ClassTimetableControllerProvider._({
    required ClassTimetableControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'classTimetableControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classTimetableControllerHash();

  @override
  String toString() {
    return r'classTimetableControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ClassTimetableController create() => ClassTimetableController();

  @override
  bool operator ==(Object other) {
    return other is ClassTimetableControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classTimetableControllerHash() =>
    r'cd0cd9ae1724cd65b215fdeaad11d663eaf6b07f';

final class ClassTimetableControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ClassTimetableController,
          AsyncValue<ClassTimetable>,
          ClassTimetable,
          FutureOr<ClassTimetable>,
          String
        > {
  ClassTimetableControllerFamily._()
    : super(
        retry: null,
        name: r'classTimetableControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClassTimetableControllerProvider call(String className) =>
      ClassTimetableControllerProvider._(argument: className, from: this);

  @override
  String toString() => r'classTimetableControllerProvider';
}

abstract class _$ClassTimetableController
    extends $AsyncNotifier<ClassTimetable> {
  late final _$args = ref.$arg as String;
  String get className => _$args;

  FutureOr<ClassTimetable> build(String className);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ClassTimetable>, ClassTimetable>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ClassTimetable>, ClassTimetable>,
              AsyncValue<ClassTimetable>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
