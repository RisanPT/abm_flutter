// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Server-paginated fee-collection directory, keyed by the (debounced) search
/// and classroom filter. Changing either builds a fresh instance (page 1);
/// `goToPage()` swaps the visible page while keeping the list on screen.

@ProviderFor(AccountsDirectory)
final accountsDirectoryProvider = AccountsDirectoryFamily._();

/// Server-paginated fee-collection directory, keyed by the (debounced) search
/// and classroom filter. Changing either builds a fresh instance (page 1);
/// `goToPage()` swaps the visible page while keeping the list on screen.
final class AccountsDirectoryProvider
    extends $AsyncNotifierProvider<AccountsDirectory, AccountsListState> {
  /// Server-paginated fee-collection directory, keyed by the (debounced) search
  /// and classroom filter. Changing either builds a fresh instance (page 1);
  /// `goToPage()` swaps the visible page while keeping the list on screen.
  AccountsDirectoryProvider._({
    required AccountsDirectoryFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'accountsDirectoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accountsDirectoryHash();

  @override
  String toString() {
    return r'accountsDirectoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AccountsDirectory create() => AccountsDirectory();

  @override
  bool operator ==(Object other) {
    return other is AccountsDirectoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountsDirectoryHash() => r'9b987bb1595ee03158a2094396df99f18aaf4eeb';

/// Server-paginated fee-collection directory, keyed by the (debounced) search
/// and classroom filter. Changing either builds a fresh instance (page 1);
/// `goToPage()` swaps the visible page while keeping the list on screen.

final class AccountsDirectoryFamily extends $Family
    with
        $ClassFamilyOverride<
          AccountsDirectory,
          AsyncValue<AccountsListState>,
          AccountsListState,
          FutureOr<AccountsListState>,
          (String, String)
        > {
  AccountsDirectoryFamily._()
    : super(
        retry: null,
        name: r'accountsDirectoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Server-paginated fee-collection directory, keyed by the (debounced) search
  /// and classroom filter. Changing either builds a fresh instance (page 1);
  /// `goToPage()` swaps the visible page while keeping the list on screen.

  AccountsDirectoryProvider call(String search, String classroom) =>
      AccountsDirectoryProvider._(argument: (search, classroom), from: this);

  @override
  String toString() => r'accountsDirectoryProvider';
}

/// Server-paginated fee-collection directory, keyed by the (debounced) search
/// and classroom filter. Changing either builds a fresh instance (page 1);
/// `goToPage()` swaps the visible page while keeping the list on screen.

abstract class _$AccountsDirectory extends $AsyncNotifier<AccountsListState> {
  late final _$args = ref.$arg as (String, String);
  String get search => _$args.$1;
  String get classroom => _$args.$2;

  FutureOr<AccountsListState> build(String search, String classroom);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AccountsListState>, AccountsListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AccountsListState>, AccountsListState>,
              AsyncValue<AccountsListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
