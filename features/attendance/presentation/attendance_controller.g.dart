// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AttendanceController)
final attendanceControllerProvider = AttendanceControllerFamily._();

final class AttendanceControllerProvider
    extends
        $AsyncNotifierProvider<AttendanceController, List<AttendanceModel>> {
  AttendanceControllerProvider._({
    required AttendanceControllerFamily super.from,
    required ({
      DateTime date,
      String? classroom,
      String type,
      String shift,
      String academicYear,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'attendanceControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attendanceControllerHash();

  @override
  String toString() {
    return r'attendanceControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AttendanceController create() => AttendanceController();

  @override
  bool operator ==(Object other) {
    return other is AttendanceControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attendanceControllerHash() =>
    r'5a6ffcf362037ba98071caf4a73d6c72759c2e16';

final class AttendanceControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AttendanceController,
          AsyncValue<List<AttendanceModel>>,
          List<AttendanceModel>,
          FutureOr<List<AttendanceModel>>,
          ({
            DateTime date,
            String? classroom,
            String type,
            String shift,
            String academicYear,
          })
        > {
  AttendanceControllerFamily._()
    : super(
        retry: null,
        name: r'attendanceControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AttendanceControllerProvider call({
    required DateTime date,
    String? classroom,
    String type = 'Student',
    required String shift,
    required String academicYear,
  }) => AttendanceControllerProvider._(
    argument: (
      date: date,
      classroom: classroom,
      type: type,
      shift: shift,
      academicYear: academicYear,
    ),
    from: this,
  );

  @override
  String toString() => r'attendanceControllerProvider';
}

abstract class _$AttendanceController
    extends $AsyncNotifier<List<AttendanceModel>> {
  late final _$args =
      ref.$arg
          as ({
            DateTime date,
            String? classroom,
            String type,
            String shift,
            String academicYear,
          });
  DateTime get date => _$args.date;
  String? get classroom => _$args.classroom;
  String get type => _$args.type;
  String get shift => _$args.shift;
  String get academicYear => _$args.academicYear;

  FutureOr<List<AttendanceModel>> build({
    required DateTime date,
    String? classroom,
    String type = 'Student',
    required String shift,
    required String academicYear,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<AttendanceModel>>, List<AttendanceModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AttendanceModel>>,
                List<AttendanceModel>
              >,
              AsyncValue<List<AttendanceModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        date: _$args.date,
        classroom: _$args.classroom,
        type: _$args.type,
        shift: _$args.shift,
        academicYear: _$args.academicYear,
      ),
    );
  }
}
