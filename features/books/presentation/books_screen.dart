import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/class_sort.dart';
import 'package:abm_madrasa/core/utils/money.dart';
import 'package:abm_madrasa/features/books/domain/book_model.dart';
import 'package:abm_madrasa/features/books/presentation/book_controller.dart';
import 'package:abm_madrasa/features/books/presentation/widgets/book_csv_exporter.dart';
import 'package:abm_madrasa/features/books/presentation/widgets/book_form_dialog.dart';
import 'package:abm_madrasa/features/books/presentation/widgets/book_import_dialog.dart';
import 'package:abm_madrasa/features/books/presentation/widgets/book_pdf_exporter.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({
    super.key,
    this.initialGrade,
  });

  final String? initialGrade;

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialGrade != null && widget.initialGrade!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bookControllerProvider.notifier).setSelectedGrade(widget.initialGrade!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddBookDialog({String? defaultClass}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookFormDialog(defaultClassName: defaultClass),
    );
  }

  void _openEditBookDialog(BookModel book) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookFormDialog(initialBook: book),
    );
  }

  void _openImportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BookImportDialog(),
    );
  }

  Future<void> _confirmDeleteBook(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to remove "${book.title}" from books inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(bookControllerProvider.notifier).deleteBook(book.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${book.title}"'),
              backgroundColor: const Color(0xFF0F4A3A),
            ),
          );
        } else {
          final err = ref.read(bookControllerProvider).errorMessage ?? 'Failed to delete';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isMobile = context.isMobile;
    final bookState = ref.watch(bookControllerProvider);
    final institute = ref.watch(selectedInstituteProvider);

    final classroomsAsync = ref.watch(classroomControllerProvider);
    final List<ClassroomModel> classrooms = classroomsAsync.value ?? [];
    final classNames = sortClassNames(classrooms.map((c) => c.name));

    // Combine classrooms with classes from bookState
    final Set<String> allGradeChoices = {'All', ...classNames, ...bookState.availableGrades};
    final sortedGrades = ['All', ...sortClassNames(allGradeChoices.where((g) => g != 'All'))];

    final filteredBooks = bookState.filteredBooks;

    // Check if a specific class is currently selected to show Class Bundle details
    final isClassSelected = bookState.selectedGrade != 'All';
    final classBooks = isClassSelected
        ? bookState.books.where((b) => b.grade.toLowerCase() == bookState.selectedGrade.toLowerCase()).toList()
        : <BookModel>[];
    final classBundlePrice = classBooks.fold<double>(0.0, (s, b) => s + b.price);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // Elegant Madrasa Header
          ABMPageHeader(
            title: 'Books & Class Curriculum',
            subtitle: 'Manage curriculum textbooks, pricing and class-wise bundles',
            compact: true,
            globalActions: true,
            showBackButton: false,
            actions: [
              // Export Menu Button
              PopupMenuButton<String>(
                tooltip: 'Export & Download',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: colors.cardBackground,
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.download, size: 15, color: Colors.white),
                      if (!isMobile) ...[
                        const Gap(6),
                        Text(
                          'Export',
                          style: typography.bodySmallSemiBold.copyWith(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
                onSelected: (val) {
                  if (val == 'pdf_preview') {
                    BookPdfExporter.printOrPreview(
                      books: filteredBooks,
                      instituteName: institute.name,
                    );
                  } else if (val == 'pdf_download') {
                    BookPdfExporter.downloadDirect(
                      books: filteredBooks,
                      instituteName: institute.name,
                      context: context,
                    );
                  } else if (val == 'csv_download') {
                    BookCsvExporter.exportBooks(filteredBooks, context);
                  } else if (val == 'sample_template') {
                    BookCsvExporter.downloadSampleTemplate(context);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'pdf_preview',
                    child: Row(
                      children: [
                        const Icon(LucideIcons.printer, size: 18, color: Color(0xFF0F4A3A)),
                        const Gap(10),
                        Text(
                          isClassSelected ? 'Print ${bookState.selectedGrade} Book List' : 'Preview / Print PDF',
                          style: typography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pdf_download',
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileText, size: 18, color: Color(0xFF0F4A3A)),
                        const Gap(10),
                        Text('Download PDF Report', style: typography.bodyMedium),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'csv_download',
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileSpreadsheet, size: 18, color: Color(0xFF0F4A3A)),
                        const Gap(10),
                        Text('Download CSV File', style: typography.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'sample_template',
                    child: Row(
                      children: [
                        const Icon(LucideIcons.downloadCloud, size: 18, color: Colors.blue),
                        const Gap(10),
                        Text('Download Sample Template', style: typography.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(8),

              // Import CSV / Excel Button
              InkWell(
                onTap: _openImportDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.fileInput, size: 15, color: Colors.white),
                      if (!isMobile) ...[
                        const Gap(6),
                        Text(
                          'Import',
                          style: typography.bodySmallSemiBold.copyWith(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Gap(8),

              // Add Book Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37), // Madrasa Gold Accent
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openAddBookDialog(defaultClass: isClassSelected ? bookState.selectedGrade : null),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text(
                  isMobile ? 'Add' : 'Add Book',
                  style: typography.bodySmallSemiBold.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Main Scrollable Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(bookControllerProvider.notifier).loadBooks(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metric Summary Cards
                    _buildMetricCards(bookState, colors, typography, isMobile),
                    const Gap(16),

                    // Class Bundle Callout if a class is filtered
                    if (isClassSelected)
                      _buildClassBundleCard(
                        className: bookState.selectedGrade,
                        booksCount: classBooks.length,
                        bundlePrice: classBundlePrice,
                        colors: colors,
                        typography: typography,
                        onAddBook: () => _openAddBookDialog(defaultClass: bookState.selectedGrade),
                      ),

                    if (isClassSelected) const Gap(16),

                    // Filter & Search Toolbar
                    _buildToolbar(bookState, sortedGrades, colors, typography, isMobile),
                    const Gap(16),

                    // Active Filters Chips Bar
                    if (bookState.selectedGrade != 'All' ||
                        bookState.selectedSubject != 'All' ||
                        bookState.selectedStatus != 'All' ||
                        bookState.searchQuery.isNotEmpty)
                      _buildActiveFilters(bookState, colors, typography),

                    const Gap(12),

                    // Content View
                    if (bookState.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF0F4A3A)),
                        ),
                      )
                    else if (filteredBooks.isEmpty)
                      _buildEmptyState(bookState, colors, typography)
                    else if (_isTableView)
                      _buildTableView(filteredBooks, colors, typography)
                    else
                      _buildGridView(filteredBooks, colors, typography, isMobile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassBundleCard({
    required String className,
    required int booksCount,
    required double bundlePrice,
    required ColorExtension colors,
    required TypographyExtension typography,
    required VoidCallback onAddBook,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4A3A), Color(0xFF165B47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4A3A).withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 24),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Class $className Curriculum',
                      style: typography.bodyLargeSemiBold.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$booksCount Books',
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Gap(3),
                Text(
                  'Complete book set bundle price for student enrolment: ${sar(bundlePrice, decimals: 2)}',
                  style: typography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          const Gap(12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F4A3A),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onAddBook,
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('Add to this Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(
    BookListState state,
    ColorExtension colors,
    TypographyExtension typography,
    bool isMobile,
  ) {
    final stats = state.stats;

    final cards = [
      _MetricTile(
        title: 'Total Titles',
        value: '${stats.totalTitles}',
        subtitle: 'Curriculum Books',
        icon: LucideIcons.bookOpen,
        color: const Color(0xFF0F4A3A),
      ),
      _MetricTile(
        title: 'Inventory Stock',
        value: number(stats.totalQuantity),
        subtitle: 'Available Copies',
        icon: LucideIcons.boxes,
        color: const Color(0xFF1E88E5),
      ),
      _MetricTile(
        title: 'Total Value',
        value: sar(stats.totalInventoryValue, decimals: 0),
        subtitle: 'Valuation at Price',
        icon: LucideIcons.tag,
        color: const Color(0xFFD4AF37),
      ),
      _MetricTile(
        title: 'Low / Out of Stock',
        value: '${stats.lowStockCount} / ${stats.outOfStockCount}',
        subtitle: 'Attention Needed',
        icon: LucideIcons.alertTriangle,
        color: stats.outOfStockCount > 0 ? Colors.red.shade600 : Colors.amber.shade700,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const Gap(10),
              Expanded(child: cards[1]),
            ],
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const Gap(10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
    );
  }

  Widget _buildToolbar(
    BookListState state,
    List<String> sortedGrades,
    ColorExtension colors,
    TypographyExtension typography,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Search Box
          SizedBox(
            width: isMobile ? double.infinity : 280,
            height: 42,
            child: TextField(
              controller: _searchController,
              onChanged: (q) => ref.read(bookControllerProvider.notifier).setSearchQuery(q),
              decoration: InputDecoration(
                hintText: 'Search title, code, author...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(bookControllerProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // Dropdowns and View Toggle
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Dynamic Grade / Class Filter
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sortedGrades.contains(state.selectedGrade) ? state.selectedGrade : 'All',
                    icon: const Icon(LucideIcons.chevronDown, size: 16),
                    onChanged: (v) {
                      if (v != null) ref.read(bookControllerProvider.notifier).setSelectedGrade(v);
                    },
                    items: sortedGrades
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    g == 'All' ? LucideIcons.layoutGrid : LucideIcons.graduationCap,
                                    size: 14,
                                    color: const Color(0xFF0F4A3A),
                                  ),
                                  const Gap(6),
                                  Text(g == 'All' ? 'All Classes' : 'Class $g', style: typography.bodyMedium),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

              // Subject Filter
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedSubject,
                    icon: const Icon(LucideIcons.chevronDown, size: 16),
                    onChanged: (v) {
                      if (v != null) ref.read(bookControllerProvider.notifier).setSelectedSubject(v);
                    },
                    items: state.availableSubjects
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s == 'All' ? 'All Subjects' : s, style: typography.bodyMedium),
                            ))
                        .toList(),
                  ),
                ),
              ),

              // Status Filter
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedStatus,
                    icon: const Icon(LucideIcons.chevronDown, size: 16),
                    onChanged: (v) {
                      if (v != null) ref.read(bookControllerProvider.notifier).setSelectedStatus(v);
                    },
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Stock')),
                      DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                      DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock')),
                      DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                    ],
                  ),
                ),
              ),

              // Grid / Table View Switcher
              Container(
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        LucideIcons.layoutGrid,
                        size: 18,
                        color: !_isTableView ? const Color(0xFF0F4A3A) : colors.textSecondary,
                      ),
                      tooltip: 'Grid View',
                      onPressed: () => setState(() => _isTableView = false),
                    ),
                    VerticalDivider(width: 1, color: colors.border),
                    IconButton(
                      icon: Icon(
                        LucideIcons.table,
                        size: 18,
                        color: _isTableView ? const Color(0xFF0F4A3A) : colors.textSecondary,
                      ),
                      tooltip: 'Table View',
                      onPressed: () => setState(() => _isTableView = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(BookListState state, ColorExtension colors, TypographyExtension typography) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Filters:', style: typography.bodySmallSemiBold.copyWith(color: colors.textSecondary)),
        if (state.selectedGrade != 'All')
          Chip(
            avatar: const Icon(LucideIcons.graduationCap, size: 14),
            label: Text('Class: ${state.selectedGrade}'),
            onDeleted: () => ref.read(bookControllerProvider.notifier).setSelectedGrade('All'),
            visualDensity: VisualDensity.compact,
          ),
        if (state.selectedSubject != 'All')
          Chip(
            label: Text('Subject: ${state.selectedSubject}'),
            onDeleted: () => ref.read(bookControllerProvider.notifier).setSelectedSubject('All'),
            visualDensity: VisualDensity.compact,
          ),
        if (state.selectedStatus != 'All')
          Chip(
            label: Text('Status: ${state.selectedStatus}'),
            onDeleted: () => ref.read(bookControllerProvider.notifier).setSelectedStatus('All'),
            visualDensity: VisualDensity.compact,
          ),
        if (state.searchQuery.isNotEmpty)
          Chip(
            label: Text('Search: "${state.searchQuery}"'),
            onDeleted: () {
              _searchController.clear();
              ref.read(bookControllerProvider.notifier).setSearchQuery('');
            },
            visualDensity: VisualDensity.compact,
          ),
        TextButton(
          onPressed: () {
            _searchController.clear();
            final notifier = ref.read(bookControllerProvider.notifier);
            notifier.setSearchQuery('');
            notifier.setSelectedGrade('All');
            notifier.setSelectedSubject('All');
            notifier.setSelectedStatus('All');
          },
          child: const Text('Reset All', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BookListState state, ColorExtension colors, TypographyExtension typography) {
    final hasFilter = state.selectedGrade != 'All' ||
        state.selectedSubject != 'All' ||
        state.selectedStatus != 'All' ||
        state.searchQuery.isNotEmpty;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(36),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F4A3A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bookX, size: 48, color: Color(0xFF0F4A3A)),
            ),
            const Gap(16),
            Text(
              hasFilter ? 'No matching books found' : 'No books in inventory yet',
              style: typography.h4,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              hasFilter
                  ? 'Try clearing the search query or adjusting your class filter.'
                  : 'Start by linking books with classes, pricing, or import in bulk using CSV / Excel.',
              style: typography.bodyMedium.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const Gap(20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!hasFilter) ...[
                  OutlinedButton.icon(
                    onPressed: _openImportDialog,
                    icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
                    label: const Text('Import CSV/Excel'),
                  ),
                  const Gap(12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F4A3A)),
                    onPressed: () => _openAddBookDialog(),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Book to Class'),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: () {
                      _searchController.clear();
                      final n = ref.read(bookControllerProvider.notifier);
                      n.setSearchQuery('');
                      n.setSelectedGrade('All');
                      n.setSelectedSubject('All');
                      n.setSelectedStatus('All');
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(
    List<BookModel> books,
    ColorExtension colors,
    TypographyExtension typography,
    bool isMobile,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1150) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: books.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 220,
          ),
          itemBuilder: (context, index) {
            final book = books[index];
            return _BookCard(
              book: book,
              onEdit: () => _openEditBookDialog(book),
              onDelete: () => _confirmDeleteBook(book),
            );
          },
        );
      },
    );
  }

  Widget _buildTableView(
    List<BookModel> books,
    ColorExtension colors,
    TypographyExtension typography,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF0F4A3A).withValues(alpha: 0.08)),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Code')),
              DataColumn(label: Text('Book Title')),
              DataColumn(label: Text('Linked Class')),
              DataColumn(label: Text('Subject')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Stock')),
              DataColumn(label: Text('Total Value')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: books.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final b = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text('$idx')),
                  DataCell(Text(b.bookCode.isNotEmpty ? b.bookCode : '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(b.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (b.author.isNotEmpty)
                          Text('by ${b.author}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F4A3A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.graduationCap, size: 12, color: Color(0xFF0F4A3A)),
                          const Gap(4),
                          Text(b.grade, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F4A3A))),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(b.subject)),
                  DataCell(
                    Text(
                      sar(b.price, decimals: 2),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4A3A)),
                    ),
                  ),
                  DataCell(Text('${b.stockQuantity}')),
                  DataCell(
                    Text(
                      sar(b.totalValue, decimals: 2),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(_buildStatusBadge(b)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.edit2, size: 16),
                          tooltip: 'Edit',
                          onPressed: () => _openEditBookDialog(b),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDeleteBook(b),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookModel b) {
    Color bg = Colors.green.shade50;
    Color fg = Colors.green.shade800;

    if (b.isOutOfStock) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else if (b.isLowStock) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        b.status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Metric Tile ───────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  value,
                  style: typography.h4.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: typography.bodySmall.copyWith(fontSize: 10, color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Book Card ─────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  final BookModel book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    Color badgeBg = Colors.green.shade50;
    Color badgeFg = Colors.green.shade800;

    if (book.isOutOfStock) {
      badgeBg = Colors.red.shade50;
      badgeFg = Colors.red.shade800;
    } else if (book.isLowStock) {
      badgeBg = Colors.amber.shade50;
      badgeFg = Colors.amber.shade900;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code Pill, Linked Class Tag, and Menu
            Row(
              children: [
                if (book.bookCode.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      book.bookCode,
                      style: typography.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (book.bookCode.isNotEmpty) const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4A3A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.graduationCap, size: 12, color: Color(0xFF0F4A3A)),
                      const Gap(4),
                      Text(
                        book.grade,
                        style: const TextStyle(
                          color: Color(0xFF0F4A3A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    book.status,
                    style: TextStyle(color: badgeFg, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const Gap(4),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  icon: const Icon(LucideIcons.moreVertical, size: 16),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.edit2, size: 16),
                          const Gap(8),
                          Text('Edit', style: typography.bodyMedium),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                          const Gap(8),
                          Text('Delete', style: typography.bodyMedium.copyWith(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(10),

            // Book Title
            Text(
              book.title,
              style: typography.bodyLargeSemiBold.copyWith(height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),

            // Author / Publisher & Subject
            Text(
              '${book.subject}${book.author.isNotEmpty ? " • by ${book.author}" : ""}',
              style: typography.bodySmall.copyWith(color: colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Divider(height: 1, color: colors.border),
            const Gap(10),

            // Bottom: Price and Stock Quantity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: typography.bodySmall.copyWith(fontSize: 10, color: colors.textSecondary),
                    ),
                    Text(
                      sar(book.price, decimals: 2),
                      style: typography.bodyLargeSemiBold.copyWith(
                        color: const Color(0xFF0F4A3A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock',
                      style: typography.bodySmall.copyWith(fontSize: 10, color: colors.textSecondary),
                    ),
                    Text(
                      '${book.stockQuantity} pcs',
                      style: typography.bodyMediumSemiBold,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
