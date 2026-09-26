import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'finance_controller.g.dart';

final accountSummariesProvider = FutureProvider<List<AccountSummary>>((ref) {
  final institute = ref.watch(selectedInstituteProvider);
  return ref.read(accountRepositoryProvider).getStudentSummaries(instituteId: institute.id);
});

final studentAccountDetailsProvider =
    FutureProvider.autoDispose.family<StudentAccountDetails, String>((ref, studentId) {
  return ref.read(accountRepositoryProvider).getStudentAccountDetails(studentId);
});

/// Paginated accounts directory state: the current page's fee summaries + totals.
class AccountsListState {
  const AccountsListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.pageLoading = false,
  });

  final List<AccountSummary> items;
  final int total;
  final int page;
  final int totalPages;
  final bool pageLoading;
}

/// Server-paginated fee-collection directory, keyed by the (debounced) search
/// and classroom filter. Changing either builds a fresh instance (page 1);
/// `goToPage()` swaps the visible page while keeping the list on screen.
@riverpod
class AccountsDirectory extends _$AccountsDirectory {
  static const int _pageSize = 25;

  late String _search;
  late String _classroom;
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  List<AccountSummary> _items = const [];

  @override
  Future<AccountsListState> build(String search, String classroom) async {
    _search = search;
    _classroom = classroom;
    ref.watch(selectedInstituteProvider);
    return _loadPage(1);
  }

  Future<PagedResult<AccountSummary>> _fetch(int page) {
    final instituteId = ref.read(selectedInstituteProvider).id;
    return ref.read(accountRepositoryProvider).getStudentSummariesPage(
          instituteId: instituteId,
          search: _search,
          classroom: _classroom,
          page: page,
          limit: _pageSize,
        );
  }

  AccountsListState _state({bool pageLoading = false}) => AccountsListState(
        items: List.unmodifiable(_items),
        total: _total,
        page: _page,
        totalPages: _totalPages,
        pageLoading: pageLoading,
      );

  Future<AccountsListState> _loadPage(int page) async {
    final res = await _fetch(page);
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
    if (state is AsyncData<AccountsListState>) {
      state = AsyncData(_state(pageLoading: true));
    }
    state = await AsyncValue.guard(() => _loadPage(target));
  }

  /// Reload the current page (after a payment) without losing the position.
  Future<void> reload() async {
    state = await AsyncValue.guard(() => _loadPage(_page));
  }
}
