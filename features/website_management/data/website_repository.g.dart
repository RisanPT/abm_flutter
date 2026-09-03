// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'website_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(websiteRepository)
final websiteRepositoryProvider = WebsiteRepositoryProvider._();

final class WebsiteRepositoryProvider
    extends
        $FunctionalProvider<
          WebsiteRepository,
          WebsiteRepository,
          WebsiteRepository
        >
    with $Provider<WebsiteRepository> {
  WebsiteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'websiteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$websiteRepositoryHash();

  @$internal
  @override
  $ProviderElement<WebsiteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WebsiteRepository create(Ref ref) {
    return websiteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebsiteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebsiteRepository>(value),
    );
  }
}

String _$websiteRepositoryHash() => r'1e115b7799f16db7bafb47d5aa4d5e388e9d2c9a';
