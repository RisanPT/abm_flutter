// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planner_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calendar cells for a given academic year / shift / month.

@ProviderFor(PlannerCalendar)
final plannerCalendarProvider = PlannerCalendarFamily._();

/// Calendar cells for a given academic year / shift / month.
final class PlannerCalendarProvider
    extends $AsyncNotifierProvider<PlannerCalendar, List<CalendarCell>> {
  /// Calendar cells for a given academic year / shift / month.
  PlannerCalendarProvider._({
    required PlannerCalendarFamily super.from,
    required (String, String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'plannerCalendarProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plannerCalendarHash();

  @override
  String toString() {
    return r'plannerCalendarProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PlannerCalendar create() => PlannerCalendar();

  @override
  bool operator ==(Object other) {
    return other is PlannerCalendarProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannerCalendarHash() => r'1701dcaa1489a8cbe383e5ef4349f9a125082ceb';

/// Calendar cells for a given academic year / shift / month.

final class PlannerCalendarFamily extends $Family
    with
        $ClassFamilyOverride<
          PlannerCalendar,
          AsyncValue<List<CalendarCell>>,
          List<CalendarCell>,
          FutureOr<List<CalendarCell>>,
          (String, String, int, int)
        > {
  PlannerCalendarFamily._()
    : super(
        retry: null,
        name: r'plannerCalendarProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Calendar cells for a given academic year / shift / month.

  PlannerCalendarProvider call(
    String academicYear,
    String shift,
    int year,
    int month,
  ) => PlannerCalendarProvider._(
    argument: (academicYear, shift, year, month),
    from: this,
  );

  @override
  String toString() => r'plannerCalendarProvider';
}

/// Calendar cells for a given academic year / shift / month.

abstract class _$PlannerCalendar extends $AsyncNotifier<List<CalendarCell>> {
  late final _$args = ref.$arg as (String, String, int, int);
  String get academicYear => _$args.$1;
  String get shift => _$args.$2;
  int get year => _$args.$3;
  int get month => _$args.$4;

  FutureOr<List<CalendarCell>> build(
    String academicYear,
    String shift,
    int year,
    int month,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CalendarCell>>, List<CalendarCell>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CalendarCell>>, List<CalendarCell>>,
              AsyncValue<List<CalendarCell>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, _$args.$3, _$args.$4),
    );
  }
}

/// Per-day status for BOTH shifts in the month.

@ProviderFor(plannerOverview)
final plannerOverviewProvider = PlannerOverviewFamily._();

/// Per-day status for BOTH shifts in the month.

final class PlannerOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OverviewCell>>,
          List<OverviewCell>,
          FutureOr<List<OverviewCell>>
        >
    with
        $FutureModifier<List<OverviewCell>>,
        $FutureProvider<List<OverviewCell>> {
  /// Per-day status for BOTH shifts in the month.
  PlannerOverviewProvider._({
    required PlannerOverviewFamily super.from,
    required (String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'plannerOverviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plannerOverviewHash();

  @override
  String toString() {
    return r'plannerOverviewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<OverviewCell>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OverviewCell>> create(Ref ref) {
    final argument = this.argument as (String, int, int);
    return plannerOverview(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is PlannerOverviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannerOverviewHash() => r'43488d6ca231833703c1f5890bf1e3b8f870c0c3';

/// Per-day status for BOTH shifts in the month.

final class PlannerOverviewFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<OverviewCell>>,
          (String, int, int)
        > {
  PlannerOverviewFamily._()
    : super(
        retry: null,
        name: r'plannerOverviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-day status for BOTH shifts in the month.

  PlannerOverviewProvider call(String academicYear, int year, int month) =>
      PlannerOverviewProvider._(
        argument: (academicYear, year, month),
        from: this,
      );

  @override
  String toString() => r'plannerOverviewProvider';
}

/// Monthly summary numbers for the header cards.

@ProviderFor(plannerSummary)
final plannerSummaryProvider = PlannerSummaryFamily._();

/// Monthly summary numbers for the header cards.

final class PlannerSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<MonthlySummary>,
          MonthlySummary,
          FutureOr<MonthlySummary>
        >
    with $FutureModifier<MonthlySummary>, $FutureProvider<MonthlySummary> {
  /// Monthly summary numbers for the header cards.
  PlannerSummaryProvider._({
    required PlannerSummaryFamily super.from,
    required (String, String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'plannerSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plannerSummaryHash();

  @override
  String toString() {
    return r'plannerSummaryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MonthlySummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MonthlySummary> create(Ref ref) {
    final argument = this.argument as (String, String, int, int);
    return plannerSummary(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      argument.$4,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlannerSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannerSummaryHash() => r'9b715e3845b195414a30999f2712091fd2d62752';

/// Monthly summary numbers for the header cards.

final class PlannerSummaryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MonthlySummary>,
          (String, String, int, int)
        > {
  PlannerSummaryFamily._()
    : super(
        retry: null,
        name: r'plannerSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Monthly summary numbers for the header cards.

  PlannerSummaryProvider call(
    String academicYear,
    String shift,
    int year,
    int month,
  ) => PlannerSummaryProvider._(
    argument: (academicYear, shift, year, month),
    from: this,
  );

  @override
  String toString() => r'plannerSummaryProvider';
}

/// A teacher's classes for a scope (today | upcoming | completed).

@ProviderFor(teacherSchedule)
final teacherScheduleProvider = TeacherScheduleFamily._();

/// A teacher's classes for a scope (today | upcoming | completed).

final class TeacherScheduleProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeacherClass>>,
          List<TeacherClass>,
          FutureOr<List<TeacherClass>>
        >
    with
        $FutureModifier<List<TeacherClass>>,
        $FutureProvider<List<TeacherClass>> {
  /// A teacher's classes for a scope (today | upcoming | completed).
  TeacherScheduleProvider._({
    required TeacherScheduleFamily super.from,
    required (String, {String? teacherId, String? shift}) super.argument,
  }) : super(
         retry: null,
         name: r'teacherScheduleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teacherScheduleHash();

  @override
  String toString() {
    return r'teacherScheduleProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TeacherClass>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeacherClass>> create(Ref ref) {
    final argument =
        this.argument as (String, {String? teacherId, String? shift});
    return teacherSchedule(
      ref,
      argument.$1,
      teacherId: argument.teacherId,
      shift: argument.shift,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherScheduleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teacherScheduleHash() => r'cafc0df8ef61350cb8365f7dbe9b9052bc1d6d83';

/// A teacher's classes for a scope (today | upcoming | completed).

final class TeacherScheduleFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TeacherClass>>,
          (String, {String? teacherId, String? shift})
        > {
  TeacherScheduleFamily._()
    : super(
        retry: null,
        name: r'teacherScheduleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A teacher's classes for a scope (today | upcoming | completed).

  TeacherScheduleProvider call(
    String scope, {
    String? teacherId,
    String? shift,
  }) => TeacherScheduleProvider._(
    argument: (scope, teacherId: teacherId, shift: shift),
    from: this,
  );

  @override
  String toString() => r'teacherScheduleProvider';
}

/// A student's (or classroom's) timetable for a date.

@ProviderFor(studentSchedule)
final studentScheduleProvider = StudentScheduleFamily._();

/// A student's (or classroom's) timetable for a date.

final class StudentScheduleProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StudentPeriod>>,
          List<StudentPeriod>,
          FutureOr<List<StudentPeriod>>
        >
    with
        $FutureModifier<List<StudentPeriod>>,
        $FutureProvider<List<StudentPeriod>> {
  /// A student's (or classroom's) timetable for a date.
  StudentScheduleProvider._({
    required StudentScheduleFamily super.from,
    required ({
      String? studentId,
      String? classroom,
      DateTime? date,
      String? shift,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'studentScheduleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentScheduleHash();

  @override
  String toString() {
    return r'studentScheduleProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<StudentPeriod>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StudentPeriod>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String? studentId,
              String? classroom,
              DateTime? date,
              String? shift,
            });
    return studentSchedule(
      ref,
      studentId: argument.studentId,
      classroom: argument.classroom,
      date: argument.date,
      shift: argument.shift,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudentScheduleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentScheduleHash() => r'dd97033ef9e2642ad79fe106b88785c8c871b0f9';

/// A student's (or classroom's) timetable for a date.

final class StudentScheduleFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<StudentPeriod>>,
          ({
            String? studentId,
            String? classroom,
            DateTime? date,
            String? shift,
          })
        > {
  StudentScheduleFamily._()
    : super(
        retry: null,
        name: r'studentScheduleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A student's (or classroom's) timetable for a date.

  StudentScheduleProvider call({
    String? studentId,
    String? classroom,
    DateTime? date,
    String? shift,
  }) => StudentScheduleProvider._(
    argument: (
      studentId: studentId,
      classroom: classroom,
      date: date,
      shift: shift,
    ),
    from: this,
  );

  @override
  String toString() => r'studentScheduleProvider';
}
