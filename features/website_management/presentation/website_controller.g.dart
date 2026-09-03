// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'website_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WebsiteController)
final websiteControllerProvider = WebsiteControllerProvider._();

final class WebsiteControllerProvider
    extends $AsyncNotifierProvider<WebsiteController, WebsiteContentModel> {
  WebsiteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'websiteControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$websiteControllerHash();

  @$internal
  @override
  WebsiteController create() => WebsiteController();
}

String _$websiteControllerHash() => r'db8e637c1b26189762b94a5fd0a549be08df0b10';

abstract class _$WebsiteController extends $AsyncNotifier<WebsiteContentModel> {
  FutureOr<WebsiteContentModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<WebsiteContentModel>, WebsiteContentModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WebsiteContentModel>, WebsiteContentModel>,
              AsyncValue<WebsiteContentModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
