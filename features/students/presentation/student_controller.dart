import 'dart:async';

import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'student_controller.g.dart';

/// The directory's view state: the students loaded so far (across pages), the
/// grand total on the server, whether more pages remain, and whether a
/// load-more request is currently in flight.
class StudentListState {
  const StudentListState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<StudentModel> items;
  final int total;
  final bool hasMore;
  final bool loadingMore;

  StudentListState copyWith({
    List<StudentModel>? items,
    int? total,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      StudentListState(
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

@riverpod
class StudentController extends _$StudentController {
  static const int _pageSize = 30;

  @override
  FutureOr<StudentListState> build() async {
    ref.watch(selectedInstituteProvider);
    ref.onDispose(() => _debounce?.cancel());
    return _loadFirstPage();
  }

  // Persisted filters so status + class + shift + search combine correctly.
  String? _query;
  String? _classroom;
  String? _shift;
  String _status = 'active'; // 'active' (default) | 'inactive' | 'all'

  // Paging bookkeeping.
  int _page = 1;
  List<StudentModel> _items = const [];
  int _total = 0;
  bool _hasMore = false;

  Timer? _debounce;   // debounces search-as-you-type
  int _searchSeq = 0; // guards against out-of-order search responses

  String get status => _status;

  Future<PagedResult<StudentModel>> _fetchPage(int page) {
    final instituteId = ref.read(selectedInstituteProvider).id;
    return ref.read(studentRepositoryProvider).getStudentsPage(
          instituteId: instituteId,
          query: _query,
          classroom: _classroom,
          shift: _shift,
          status: _status,
          page: page,
          limit: _pageSize,
        );
  }

  Future<StudentListState> _loadFirstPage() async {
    final res = await _fetchPage(1);
    _page = 1;
    _items = res.items;
    _total = res.total;
    _hasMore = res.hasMore;
    return StudentListState(
      items: List.unmodifiable(_items),
      total: _total,
      hasMore: _hasMore,
      loadingMore: false,
    );
  }

  StudentListState _snapshot({bool loadingMore = false}) => StudentListState(
        items: List.unmodifiable(_items),
        total: _total,
        hasMore: _hasMore,
        loadingMore: loadingMore,
      );

  Future<void> _apply() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadFirstPage);
  }

  /// Fetch and append the next page (infinite scroll). No-op while a load is in
  /// flight or when the last page has been reached.
  Future<void> loadMore() async {
    if (_hasMore == false) return;
    final current = state;
    if (current is! AsyncData<StudentListState>) return;
    if (current.value.loadingMore) return;

    // Reflect the load-more spinner without disturbing the visible list.
    state = AsyncData(_snapshot(loadingMore: true));
    try {
      final res = await _fetchPage(_page + 1);
      _page += 1;
      _items = [..._items, ...res.items];
      _total = res.total;
      _hasMore = res.hasMore;
    } catch (_) {
      // Keep what we have; just stop the spinner so the user can retry by
      // scrolling again.
    }
    state = AsyncData(_snapshot(loadingMore: false));
  }

  /// Debounced search-as-you-type: waits for a pause in typing, keeps the current
  /// list visible while fetching (no full-screen spinner), and drops out-of-order
  /// responses so the last query always wins.
  Future<void> search(String query) async {
    _query = query.trim().isEmpty ? null : query.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _applySearch);
  }

  Future<void> _applySearch() async {
    final seq = ++_searchSeq;
    final result = await AsyncValue.guard(_loadFirstPage);
    if (seq != _searchSeq) return; // a newer search superseded this one
    state = result;
  }

  Future<void> filter(String? classroom, String? shift) async {
    _classroom = (classroom == null || classroom == 'All') ? null : classroom;
    _shift = (shift == null || shift == 'All') ? null : shift;
    await _apply();
  }

  Future<void> filterByClassroom(String? classroom) async {
    _classroom = (classroom == null || classroom == 'All') ? null : classroom;
    await _apply();
  }

  Future<void> setStatus(String status) async {
    _status = status;
    await _apply();
  }

  /// Deactivate / reactivate, then refresh the current view.
  Future<void> setActive(String id, bool active) async {
    await ref.read(studentRepositoryProvider).setStudentActive(id, active);
    ref.invalidate(studentDetailsProvider(id));
    ref.invalidate(allStudentsProvider);
    await _apply();
  }

  Future<void> refresh() async {
    await _apply();
  }

  // Mutations keep the current list visible; guard sets the refreshed data/error.
  Future<void> addStudent(StudentModel student) async {
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).addStudent(student);
      ref.invalidate(allStudentsProvider);
      return _loadFirstPage();
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).updateStudent(student);
      ref.invalidate(studentDetailsProvider(student.id));
      ref.invalidate(allStudentsProvider);
      return _loadFirstPage();
    });
  }

  Future<void> deleteStudent(String id) async {
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).deleteStudent(id);
      ref.invalidate(allStudentsProvider);
      return _loadFirstPage();
    });
  }
}

/// Full (un-paginated) student list for consumers that genuinely need everyone —
/// e.g. classroom occupancy counts and directory PDF export. Scoped to the
/// selected institute and to active students, mirroring the directory default.
final allStudentsProvider =
    FutureProvider.autoDispose<List<StudentModel>>((ref) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref.read(studentRepositoryProvider).getStudents(instituteId: instituteId);
});

final studentDetailsProvider = FutureProvider.autoDispose.family<StudentModel, String>((
  ref,
  id,
) {
  return ref.read(studentRepositoryProvider).getStudentById(id);
});
