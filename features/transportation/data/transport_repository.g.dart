// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transportRepository)
final transportRepositoryProvider = TransportRepositoryProvider._();

final class TransportRepositoryProvider
    extends
        $FunctionalProvider<
          TransportRepository,
          TransportRepository,
          TransportRepository
        >
    with $Provider<TransportRepository> {
  TransportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransportRepository create(Ref ref) {
    return transportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransportRepository>(value),
    );
  }
}

String _$transportRepositoryHash() =>
    r'375001c999a1269f1a6149305bffc3451799b0af';
