import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/features/books/data/book_repository.dart';
import 'package:abm_madrasa/features/books/domain/book_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookListState {
  const BookListState({
    this.books = const [],
    this.stats = const BookStats(),
    this.isLoading = false,
    this.isActionLoading = false,
    this.searchQuery = '',
    this.selectedGrade = 'All',
    this.selectedSubject = 'All',
    this.selectedStatus = 'All',
    this.errorMessage,
  });

  final List<BookModel> books;
  final BookStats stats;
  final bool isLoading;
  final bool isActionLoading;
  final String searchQuery;
  final String selectedGrade;
  final String selectedSubject;
  final String selectedStatus;
  final String? errorMessage;

  BookListState copyWith({
    List<BookModel>? books,
    BookStats? stats,
    bool? isLoading,
    bool? isActionLoading,
    String? searchQuery,
    String? selectedGrade,
    String? selectedSubject,
    String? selectedStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookListState(
      books: books ?? this.books,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedGrade: selectedGrade ?? this.selectedGrade,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Client-side filtered list based on current active search and filters
  List<BookModel> get filteredBooks {
    return books.where((b) {
      if (selectedGrade != 'All' && b.grade.toLowerCase() != selectedGrade.toLowerCase()) {
        return false;
      }
      if (selectedSubject != 'All' && b.subject.toLowerCase() != selectedSubject.toLowerCase()) {
        return false;
      }
      if (selectedStatus != 'All' && b.status.toLowerCase() != selectedStatus.toLowerCase()) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matches = b.title.toLowerCase().contains(q) ||
            b.bookCode.toLowerCase().contains(q) ||
            b.subject.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q) ||
            b.publisher.toLowerCase().contains(q) ||
            b.isbn.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  /// Distinct subjects found across all books
  List<String> get availableSubjects {
    final set = <String>{};
    for (final b in books) {
      if (b.subject.trim().isNotEmpty) {
        set.add(b.subject.trim());
      }
    }
    return ['All', ...set.toList()..sort()];
  }

  /// Distinct grades found across all books
  List<String> get availableGrades {
    final set = <String>{};
    for (final b in books) {
      if (b.grade.trim().isNotEmpty) {
        set.add(b.grade.trim());
      }
    }
    return ['All', ...set.toList()..sort()];
  }
}

class BookController extends Notifier<BookListState> {
  @override
  BookListState build() {
    ref.watch(selectedInstituteProvider);
    Future.microtask(() => loadBooks());
    return const BookListState();
  }

  BookRepository get _repo => ref.read(bookRepositoryProvider);
  String get _instituteId => ref.read(selectedInstituteProvider).id;

  Future<void> loadBooks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.getBooks(instituteId: _instituteId);
      state = state.copyWith(
        books: res.books,
        stats: res.stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load books: $e',
      );
    }
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setSelectedGrade(String grade) {
    state = state.copyWith(selectedGrade: grade);
  }

  void setSelectedSubject(String subject) {
    state = state.copyWith(selectedSubject: subject);
  }

  void setSelectedStatus(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  Future<bool> addBook(Map<String, dynamic> data) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final payload = Map<String, dynamic>.from(data);
      if (!payload.containsKey('instituteId') || payload['instituteId'] == null) {
        payload['instituteId'] = _instituteId;
      }
      await _repo.createBook(payload);
      await loadBooks();
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to add book: $e',
      );
      return false;
    }
  }

  Future<bool> updateBook(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      await _repo.updateBook(id, data);
      await loadBooks();
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to update book: $e',
      );
      return false;
    }
  }

  Future<bool> deleteBook(String id) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      await _repo.deleteBook(id);
      await loadBooks();
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to delete book: $e',
      );
      return false;
    }
  }

  Future<int> bulkImport(List<Map<String, dynamic>> books) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final count = await _repo.bulkImport(books, instituteId: _instituteId);
      await loadBooks();
      return count;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Import failed: $e',
      );
      return 0;
    }
  }
}

final bookControllerProvider = NotifierProvider<BookController, BookListState>(BookController.new);
