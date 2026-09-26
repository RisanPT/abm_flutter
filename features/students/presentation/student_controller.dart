import 'dart:async';

import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'student_controller.g.dart';

/// The directory's view state: the current page's students, the grand total on
/// the server, the current page + total pages, and whether a page change is in
/// flight (so the pagination bar can show a spinner).
class StudentListState {
  const StudentListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.pageLoading = false,
  });

  final List<StudentModel> items;
  final int total;
  final int page;
  final int totalPages;
  final bool pageLoading;
}

@riverpod
class StudentController extends _$StudentController {
  static const int _pageSize = 25;

  @override
  FutureOr<StudentListState> build() async {
    ref.watch(selectedInstituteProvider);
    ref.onDispose(() => _debounce?.cancel());
    return _loadPage(1);
  }

  // Persisted filters so status + class + shift + search combine correctly.
  String? _query;
  String? _classroom;
  String? _shift;
  String _status = 'active'; // 'active' (default) | 'inactive' | 'all'

  // Paging bookkeeping.
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  List<StudentModel> _items = const [];

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

  StudentListState _state({bool pageLoading = false}) => StudentListState(
        items: List.unmodifiable(_items),
        total: _total,
        page: _page,
        totalPages: _totalPages,
        pageLoading: pageLoading,
      );

  /// Load a specific page (1-based), replacing the visible list. If a page comes
  /// back empty (e.g. after deleting the last item on it), step back a page.
  Future<StudentListState> _loadPage(int page) async {
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

  Future<void> _apply() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadPage(1));
  }

  /// Jump to a page from the pagination control.
  Future<void> goToPage(int page) async {
    final target = page < 1 ? 1 : (page > _totalPages ? _totalPages : page);
    if (state is AsyncData<StudentListState>) {
      state = AsyncData(_state(pageLoading: true));
    }
    state = await AsyncValue.guard(() => _loadPage(target));
  }

  /// Debounced search-as-you-type: waits for a pause in typing, resets to page 1,
  /// keeps the current list visible while fetching (no full-screen spinner), and
  /// drops out-of-order responses so the last query always wins.
  Future<void> search(String query) async {
    _query = query.trim().isEmpty ? null : query.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _applySearch);
  }

  Future<void> _applySearch() async {
    final seq = ++_searchSeq;
    final result = await AsyncValue.guard(() => _loadPage(1));
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
      return _loadPage(_page);
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).updateStudent(student);
      ref.invalidate(studentDetailsProvider(student.id));
      ref.invalidate(allStudentsProvider);
      return _loadPage(_page);
    });
  }

  Future<void> deleteStudent(String id) async {
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).deleteStudent(id);
      ref.invalidate(allStudentsProvider);
      return _loadPage(_page);
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
