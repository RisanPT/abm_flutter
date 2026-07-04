// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_planner_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ShiftPlannerController)
final shiftPlannerControllerProvider = ShiftPlannerControllerFamily._();

final class ShiftPlannerControllerProvider
    extends $AsyncNotifierProvider<ShiftPlannerController, List<DateTime>> {
  ShiftPlannerControllerProvider._({
    required ShiftPlannerControllerFamily super.from,
    required (String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'shiftPlannerControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shiftPlannerControllerHash();

  @override
  String toString() {
    return r'shiftPlannerControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ShiftPlannerController create() => ShiftPlannerController();

  @override
  bool operator ==(Object other) {
    return other is ShiftPlannerControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shiftPlannerControllerHash() =>
    r'29db3612459e7a4265690ef70afcd7ad6135b35b';

final class ShiftPlannerControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ShiftPlannerController,
          AsyncValue<List<DateTime>>,
          List<DateTime>,
          FutureOr<List<DateTime>>,
          (String, int, int)
        > {
  ShiftPlannerControllerFamily._()
    : super(
        retry: null,
        name: r'shiftPlannerControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShiftPlannerControllerProvider call(String shift, int year, int month) =>
      ShiftPlannerControllerProvider._(
        argument: (shift, year, month),
        from: this,
      );

  @override
  String toString() => r'shiftPlannerControllerProvider';
}

abstract class _$ShiftPlannerController extends $AsyncNotifier<List<DateTime>> {
  late final _$args = ref.$arg as (String, int, int);
  String get shift => _$args.$1;
  int get year => _$args.$2;
  int get month => _$args.$3;

  FutureOr<List<DateTime>> build(String shift, int year, int month);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<DateTime>>, List<DateTime>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<DateTime>>, List<DateTime>>,
              AsyncValue<List<DateTime>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
