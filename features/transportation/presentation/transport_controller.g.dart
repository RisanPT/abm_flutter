// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transportVehicles)
final transportVehiclesProvider = TransportVehiclesProvider._();

final class TransportVehiclesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VehicleModel>>,
          List<VehicleModel>,
          FutureOr<List<VehicleModel>>
        >
    with
        $FutureModifier<List<VehicleModel>>,
        $FutureProvider<List<VehicleModel>> {
  TransportVehiclesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportVehiclesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportVehiclesHash();

  @$internal
  @override
  $FutureProviderElement<List<VehicleModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VehicleModel>> create(Ref ref) {
    return transportVehicles(ref);
  }
}

String _$transportVehiclesHash() => r'77f1f6fff97d5961afbe28c1e9f7f8a5ba983c24';

@ProviderFor(transportDrivers)
final transportDriversProvider = TransportDriversProvider._();

final class TransportDriversProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DriverModel>>,
          List<DriverModel>,
          FutureOr<List<DriverModel>>
        >
    with
        $FutureModifier<List<DriverModel>>,
        $FutureProvider<List<DriverModel>> {
  TransportDriversProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportDriversProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportDriversHash();

  @$internal
  @override
  $FutureProviderElement<List<DriverModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DriverModel>> create(Ref ref) {
    return transportDrivers(ref);
  }
}

String _$transportDriversHash() => r'b2c723881b446c214d6da3a33b23a33023d103ad';

@ProviderFor(transportRoutes)
final transportRoutesProvider = TransportRoutesProvider._();

final class TransportRoutesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RouteModel>>,
          List<RouteModel>,
          FutureOr<List<RouteModel>>
        >
    with $FutureModifier<List<RouteModel>>, $FutureProvider<List<RouteModel>> {
  TransportRoutesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportRoutesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportRoutesHash();

  @$internal
  @override
  $FutureProviderElement<List<RouteModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RouteModel>> create(Ref ref) {
    return transportRoutes(ref);
  }
}

String _$transportRoutesHash() => r'b8296a0b87582c53251b195d9f427c6073ca87d0';

@ProviderFor(FleetManagementController)
final fleetManagementControllerProvider = FleetManagementControllerProvider._();

final class FleetManagementControllerProvider
    extends $NotifierProvider<FleetManagementController, void> {
  FleetManagementControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetManagementControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetManagementControllerHash();

  @$internal
  @override
  FleetManagementController create() => FleetManagementController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$fleetManagementControllerHash() =>
    r'391a2b88d73e4db2034f01b21d449c5760c1abf3';

abstract class _$FleetManagementController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
