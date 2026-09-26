import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/teachers/data/teacher_repository.dart';
import 'package:abm_madrasa/features/teachers/domain/teacher_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'teacher_controller.g.dart';

/// Full (un-paginated) teacher list — used by the summary stats bar (total,
/// active, payroll, subjects) and by anything that needs every teacher at once.
final teacherListProvider =
    FutureProvider.autoDispose.family<List<TeacherModel>, String>((ref, query) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref
      .read(teacherRepositoryProvider)
      .getTeachers(query: query.trim().isEmpty ? null : query.trim(), instituteId: instituteId);
});

/// The directory's paginated view state (loaded-so-far items + totals for
/// infinite scroll).
class TeacherListState {
  const TeacherListState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<TeacherModel> items;
  final int total;
  final bool hasMore;
  final bool loadingMore;

  TeacherListState copyWith({
    List<TeacherModel>? items,
    int? total,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      TeacherListState(
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

/// Server-paginated teacher directory, keyed by the (already-debounced) search
/// query. Changing the query builds a fresh instance (page 1); `loadMore()`
/// appends the next page onto the same instance.
@riverpod
class TeacherDirectory extends _$TeacherDirectory {
  static const int _pageSize = 30;

  late String _query;
  int _page = 1;
  List<TeacherModel> _items = const [];
  int _total = 0;
  bool _hasMore = false;

  @override
  Future<TeacherListState> build(String query) async {
    _query = query;
    ref.watch(selectedInstituteProvider);
    return _loadFirstPage();
  }

  Future<PagedResult<TeacherModel>> _fetchPage(int page) {
    final instituteId = ref.read(selectedInstituteProvider).id;
    return ref.read(teacherRepositoryProvider).getTeachersPage(
          query: _query.trim().isEmpty ? null : _query.trim(),
          instituteId: instituteId,
          page: page,
          limit: _pageSize,
        );
  }

  Future<TeacherListState> _loadFirstPage() async {
    final res = await _fetchPage(1);
    _page = 1;
    _items = res.items;
    _total = res.total;
    _hasMore = res.hasMore;
    return TeacherListState(
      items: List.unmodifiable(_items),
      total: _total,
      hasMore: _hasMore,
    );
  }

  TeacherListState _snapshot({bool loadingMore = false}) => TeacherListState(
        items: List.unmodifiable(_items),
        total: _total,
        hasMore: _hasMore,
        loadingMore: loadingMore,
      );

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state;
    if (current is! AsyncData<TeacherListState>) return;
    if (current.value.loadingMore) return;

    state = AsyncData(_snapshot(loadingMore: true));
    try {
      final res = await _fetchPage(_page + 1);
      _page += 1;
      _items = [..._items, ...res.items];
      _total = res.total;
      _hasMore = res.hasMore;
    } catch (_) {
      // keep current items; stop the spinner
    }
    state = AsyncData(_snapshot(loadingMore: false));
  }
}
