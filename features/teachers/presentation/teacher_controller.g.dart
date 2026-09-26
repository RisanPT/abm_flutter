// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Server-paginated teacher directory, keyed by the (already-debounced) search
/// query. Changing the query builds a fresh instance (page 1); `goToPage()`
/// replaces the visible page.

@ProviderFor(TeacherDirectory)
final teacherDirectoryProvider = TeacherDirectoryFamily._();

/// Server-paginated teacher directory, keyed by the (already-debounced) search
/// query. Changing the query builds a fresh instance (page 1); `goToPage()`
/// replaces the visible page.
final class TeacherDirectoryProvider
    extends $AsyncNotifierProvider<TeacherDirectory, TeacherListState> {
  /// Server-paginated teacher directory, keyed by the (already-debounced) search
  /// query. Changing the query builds a fresh instance (page 1); `goToPage()`
  /// replaces the visible page.
  TeacherDirectoryProvider._({
    required TeacherDirectoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teacherDirectoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teacherDirectoryHash();

  @override
  String toString() {
    return r'teacherDirectoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TeacherDirectory create() => TeacherDirectory();

  @override
  bool operator ==(Object other) {
    return other is TeacherDirectoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teacherDirectoryHash() => r'8e8706dbfd0f6f999db507f5397e675c09b4bc7f';

/// Server-paginated teacher directory, keyed by the (already-debounced) search
/// query. Changing the query builds a fresh instance (page 1); `goToPage()`
/// replaces the visible page.

final class TeacherDirectoryFamily extends $Family
    with
        $ClassFamilyOverride<
          TeacherDirectory,
          AsyncValue<TeacherListState>,
          TeacherListState,
          FutureOr<TeacherListState>,
          String
        > {
  TeacherDirectoryFamily._()
    : super(
        retry: null,
        name: r'teacherDirectoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Server-paginated teacher directory, keyed by the (already-debounced) search
  /// query. Changing the query builds a fresh instance (page 1); `goToPage()`
  /// replaces the visible page.

  TeacherDirectoryProvider call(String query) =>
      TeacherDirectoryProvider._(argument: query, from: this);

  @override
  String toString() => r'teacherDirectoryProvider';
}

/// Server-paginated teacher directory, keyed by the (already-debounced) search
/// query. Changing the query builds a fresh instance (page 1); `goToPage()`
/// replaces the visible page.

abstract class _$TeacherDirectory extends $AsyncNotifier<TeacherListState> {
  late final _$args = ref.$arg as String;
  String get query => _$args;

  FutureOr<TeacherListState> build(String query);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TeacherListState>, TeacherListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TeacherListState>, TeacherListState>,
              AsyncValue<TeacherListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
