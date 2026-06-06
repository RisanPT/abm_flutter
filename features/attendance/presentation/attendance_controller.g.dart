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
    required ({DateTime date, String? classroom}) super.argument,
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
    r'90cc297121240e1cda9041c30e4c940c7375c206';

final class AttendanceControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AttendanceController,
          AsyncValue<List<AttendanceModel>>,
          List<AttendanceModel>,
          FutureOr<List<AttendanceModel>>,
          ({DateTime date, String? classroom})
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
  }) => AttendanceControllerProvider._(
    argument: (date: date, classroom: classroom),
    from: this,
  );

  @override
  String toString() => r'attendanceControllerProvider';
}

abstract class _$AttendanceController
    extends $AsyncNotifier<List<AttendanceModel>> {
  late final _$args = ref.$arg as ({DateTime date, String? classroom});
  DateTime get date => _$args.date;
  String? get classroom => _$args.classroom;

  FutureOr<List<AttendanceModel>> build({
    required DateTime date,
    String? classroom,
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
      () => build(date: _$args.date, classroom: _$args.classroom),
    );
  }
}

@ProviderFor(attendanceSummary)
final attendanceSummaryProvider = AttendanceSummaryProvider._();

final class AttendanceSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Map<String, int>>>,
          Map<String, Map<String, int>>,
          FutureOr<Map<String, Map<String, int>>>
        >
    with
        $FutureModifier<Map<String, Map<String, int>>>,
        $FutureProvider<Map<String, Map<String, int>>> {
  AttendanceSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceSummaryHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, Map<String, int>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, Map<String, int>>> create(Ref ref) {
    return attendanceSummary(ref);
  }
}

String _$attendanceSummaryHash() => r'290d62a80e955416a52196c0b4acecee1ed25363';
