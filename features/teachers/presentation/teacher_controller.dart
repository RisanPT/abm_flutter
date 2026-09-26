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

/// The directory's paginated view state: the current page's teachers, the grand
/// total, current page + total pages, and whether a page change is in flight.
class TeacherListState {
  const TeacherListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.pageLoading = false,
  });

  final List<TeacherModel> items;
  final int total;
  final int page;
  final int totalPages;
  final bool pageLoading;
}

/// Server-paginated teacher directory, keyed by the (already-debounced) search
/// query. Changing the query builds a fresh instance (page 1); `goToPage()`
/// replaces the visible page.
@riverpod
class TeacherDirectory extends _$TeacherDirectory {
  static const int _pageSize = 25;

  late String _query;
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  List<TeacherModel> _items = const [];

  @override
  Future<TeacherListState> build(String query) async {
    _query = query;
    ref.watch(selectedInstituteProvider);
    return _loadPage(1);
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

  TeacherListState _state({bool pageLoading = false}) => TeacherListState(
        items: List.unmodifiable(_items),
        total: _total,
        page: _page,
        totalPages: _totalPages,
        pageLoading: pageLoading,
      );

  Future<TeacherListState> _loadPage(int page) async {
    final res = await _fetchPage(page);
    if (res.items.isEmpty && page > 1 && res.total > 0) {
      return _loadPage(page - 1);
    }
    _page = page;
    _items = res.items;
    _total = res.total;
    _totalPages = res.totalPages > 0 ? res.totalPages : 1;
    return _state();
  }

  Future<void> goToPage(int page) async {
    final target = page < 1 ? 1 : (page > _totalPages ? _totalPages : page);
    if (state is AsyncData<TeacherListState>) {
      state = AsyncData(_state(pageLoading: true));
    }
    state = await AsyncValue.guard(() => _loadPage(target));
  }
}
