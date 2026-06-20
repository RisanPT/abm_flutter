// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_structure_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeeStructureController)
final feeStructureControllerProvider = FeeStructureControllerProvider._();

final class FeeStructureControllerProvider
    extends
        $AsyncNotifierProvider<
          FeeStructureController,
          List<FeeStructureModel>
        > {
  FeeStructureControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feeStructureControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feeStructureControllerHash();

  @$internal
  @override
  FeeStructureController create() => FeeStructureController();
}

String _$feeStructureControllerHash() =>
    r'a394d71a776a88107a7db9b078e0b4b4be1bd2ad';

abstract class _$FeeStructureController
    extends $AsyncNotifier<List<FeeStructureModel>> {
  FutureOr<List<FeeStructureModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<FeeStructureModel>>,
              List<FeeStructureModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FeeStructureModel>>,
                List<FeeStructureModel>
              >,
              AsyncValue<List<FeeStructureModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
