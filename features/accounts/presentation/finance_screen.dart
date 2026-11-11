import 'dart:async';
import 'dart:io';

import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/utils/money.dart';
import 'package:abm_madrasa/core/whatsapp/whatsapp_service.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:abm_madrasa/features/accounts/presentation/widgets/charge_dialogs.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:abm_madrasa/features/accounts/presentation/finance_controller.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

String _sar(double v) => sar(v);

// Full month-by-month ledger (arrears + current) for the selected student.
final feeLedgerProvider = FutureProvider.family.autoDispose<FeeLedger, String>(
  (ref, studentId) => ref.watch(accountRepositoryProvider).getLedger(studentId),
);

// ─── Main Screen ───────────────────────────────────────────────────────────────

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedStudentId;
  String _classroomFilter = 'All';
  String _statusFilter = 'all'; // 'all' | 'pending' | 'paid'
  bool _processingPayment = false;
  Timer? _searchDebounce;
  List<AccountSummary> _pageItems = const [];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Debounced server-side search (resets to page 1 via a fresh provider key).
  void _onQueryChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  void _onClassroomChanged(String c) => setState(() => _classroomFilter = c);
  void _onStatusChanged(String s) => setState(() => _statusFilter = s);

  List<String> get _chargeMonthOptions {
    final now = DateTime.now();
    final labels = <String>{};
    for (int i = -3; i <= 11; i++) {
      labels.add(DateFormat('MMMM yyyy').format(DateTime(now.year, now.month + i, 1)));
    }
    return labels.toList()
      ..sort((a, b) => DateFormat('MMMM yyyy').parse(a).compareTo(DateFormat('MMMM yyyy').parse(b)));
  }

  Future<void> _openClassCharge(List<String> classOptions) async {
    final grades = classOptions.where((c) => c != 'All').toList();
    if (grades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No classes available')));
      return;
    }
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime(now.year, now.month, 1));
    final res = await showDialog<ClassChargeResult>(
      context: context,
      builder: (_) => ClassChargeDialog(
        classOptions: grades,
        monthOptions: _chargeMonthOptions,
        initialMonths: [currentMonth],
      ),
    );
    if (res != null && mounted) {
      ref.invalidate(accountsDirectoryProvider);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Class charged'),
          content: Text(
            '${res.title} (SAR ${res.amount.toStringAsFixed(0)}) added to '
            '${res.charged} of ${res.studentsInClass} students in ${res.grade}'
            '${res.monthsCount > 1 ? ' for ${res.monthsCount} months' : ''}.',
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dirAsync = ref.watch(accountsDirectoryProvider(_query, _classroomFilter, _statusFilter));
    final classOptions = ref.watch(classroomControllerProvider).maybeWhen(
          data: (classes) => ['All', ...classes.map((c) => c.name)],
          orElse: () => <String>['All'],
        );
    void goToPage(int p) =>
        ref.read(accountsDirectoryProvider(_query, _classroomFilter, _statusFilter).notifier).goToPage(p);

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: (context.isMobile && _selectedStudentId != null)
          ? null
          : FloatingActionButton.extended(
              heroTag: 'chargeClass',
              onPressed: () => _openClassCharge(classOptions),
              icon: const Icon(LucideIcons.layers, size: 18),
              label: const Text('Charge Class'),
            ),
      body: dirAsync.when(
        data: (dir) {
          _pageItems = dir.items;
          final items = dir.items;
          // Default the selection once on desktop/tablet; on mobile keep null so user sees the directory list.
          if (!context.isMobile) {
            _selectedStudentId ??= items.isNotEmpty ? items.first.studentId : null;
          }

          if (context.isMobile) {
            return _MobileLayout(
              summaries: items,
              total: dir.total,
              page: dir.page,
              totalPages: dir.totalPages,
              pageLoading: dir.pageLoading,
              onPage: goToPage,
              selectedStudentId: _selectedStudentId,
              processingPayment: _processingPayment,
              onSelectStudent: (id) => setState(() => _selectedStudentId = id.isEmpty ? null : id),
              onProcessPayment: _handlePayment,
              searchController: _searchController,
              query: _query,
              onQueryChanged: _onQueryChanged,
              classrooms: classOptions,
              classroomFilter: _classroomFilter,
              onClassroomChanged: _onClassroomChanged,
              statusFilter: _statusFilter,
              onStatusChanged: _onStatusChanged,
            );
          }

          return Row(
            children: [
              SizedBox(
                width: 380,
                child: _Sidebar(
                  summaries: items,
                  total: dir.total,
                  page: dir.page,
                  totalPages: dir.totalPages,
                  pageLoading: dir.pageLoading,
                  onPage: goToPage,
                  selectedStudentId: _selectedStudentId,
                  classrooms: classOptions,
                  classroomFilter: _classroomFilter,
                  onClassroomChanged: _onClassroomChanged,
                  statusFilter: _statusFilter,
                  onStatusChanged: _onStatusChanged,
                  searchController: _searchController,
                  onQueryChanged: _onQueryChanged,
                  onSelectStudent: (id) => setState(() => _selectedStudentId = id),
                ),
              ),
              Expanded(
                child: _selectedStudentId == null
                    ? _EmptyState()
                    : _AccountDetailsPanel(
                        studentId: _selectedStudentId!,
                        processingPayment: _processingPayment,
                        onProcessPayment: _handlePayment,
                        onBack: () => setState(() => _selectedStudentId = null),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AbmErrorView(
          message: friendlyErrorMessage(err),
          onRetry: () =>
              ref.invalidate(accountsDirectoryProvider(_query, _classroomFilter, _statusFilter)),
        ),
      ),
    );
  }

  Future<void> _handlePayment(
    String studentId,
    double amount,
    List<String> items, {
    String? monthLabel,
    List<String>? monthLabels,
  }) async {
    setState(() => _processingPayment = true);
    try {
      final receipt = await ref.read(accountRepositoryProvider).processPayment(
            studentId: studentId,
            amount: amount,
            items: items,
            monthLabel: monthLabel,
            monthLabels: monthLabels,
          );
      ref.invalidate(accountsDirectoryProvider);
      ref.invalidate(studentAccountDetailsProvider(studentId));
      ref.invalidate(feeLedgerProvider(studentId));

      if (mounted) {
        // Auto-show invoice dialog immediately after payment
        _showInvoiceDialog(
          context: context,
          studentId: studentId,
          receipt: receipt,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingPayment = false);
    }
  }

  void _showInvoiceDialog({
    required BuildContext context,
    required String studentId,
    required ReceiptHistoryItem receipt,
  }) {
    final student = _pageItems.where((s) => s.studentId == studentId);
    if (student.isEmpty) return;

    final s = student.first;
    final details = StudentAccountDetails(
      summary: s,
      monthLabel: receipt.monthLabel,
      lineItems: receipt.lineItems,
      totalDue: receipt.totalDue,
      totalPaid: receipt.totalPaid,
      balance: 0,
      status: receipt.status,
      receiptNumber: receipt.receiptNumber,
      history: [receipt],
    );
    showDialog(
      context: context,
      builder: (ctx) => _InvoiceDialog(details: details, receipt: receipt),
    );
  }
}

// ─── Mobile Layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.summaries,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.pageLoading,
    required this.onPage,
    required this.selectedStudentId,
    required this.processingPayment,
    required this.onSelectStudent,
    required this.onProcessPayment,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.classrooms,
    required this.classroomFilter,
    required this.onClassroomChanged,
    required this.statusFilter,
    required this.onStatusChanged,
  });

  final List<AccountSummary> summaries;
  final int total;
  final int page;
  final int totalPages;
  final bool pageLoading;
  final ValueChanged<int> onPage;
  final String? selectedStudentId;
  final bool processingPayment;
  final void Function(String id) onSelectStudent;
  final Future<void> Function(String studentId, double amount, List<String> items, {String? monthLabel, List<String>? monthLabels}) onProcessPayment;
  final TextEditingController searchController;
  final String query;
  final void Function(String) onQueryChanged;
  final List<String> classrooms;
  final String classroomFilter;
  final void Function(String) onClassroomChanged;
  final String statusFilter;
  final void Function(String) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    if (selectedStudentId != null && selectedStudentId!.isNotEmpty) {
      return _AccountDetailsPanel(
        studentId: selectedStudentId!,
        processingPayment: processingPayment,
        onProcessPayment: onProcessPayment,
        onBack: () => onSelectStudent(''),
      );
    }

    return _Sidebar(
      summaries: summaries,
      total: total,
      page: page,
      totalPages: totalPages,
      pageLoading: pageLoading,
      onPage: onPage,
      selectedStudentId: selectedStudentId,
      classrooms: classrooms,
      classroomFilter: classroomFilter,
      onClassroomChanged: onClassroomChanged,
      statusFilter: statusFilter,
      onStatusChanged: onStatusChanged,
      searchController: searchController,
      onQueryChanged: onQueryChanged,
      onSelectStudent: onSelectStudent,
      isMobileFullPage: true,
    );
  }
}

// ─── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.summaries,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.pageLoading,
    required this.onPage,
    required this.selectedStudentId,
    required this.classrooms,
    required this.classroomFilter,
    required this.onClassroomChanged,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.searchController,
    required this.onQueryChanged,
    required this.onSelectStudent,
    this.isMobileFullPage = false,
  });

  final List<AccountSummary> summaries;
  final int total;
  final int page;
  final int totalPages;
  final bool pageLoading;
  final ValueChanged<int> onPage;
  final String? selectedStudentId;
  final List<String> classrooms;
  final String classroomFilter;
  final void Function(String) onClassroomChanged;
  final String statusFilter;
  final void Function(String) onStatusChanged;
  final TextEditingController searchController;
  final void Function(String) onQueryChanged;
  final void Function(String id) onSelectStudent;
  final bool isMobileFullPage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        border: isMobileFullPage ? null : Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              isMobileFullPage ? MediaQuery.of(context).padding.top + 10 : 24,
              20,
              16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: isMobileFullPage ? 48 : 0,
                    right: isMobileFullPage ? 96 : 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Fee Collection',
                          style: typography.h3.copyWith(
                            color: Colors.white,
                            fontSize: isMobileFullPage ? 20 : null,
                          ),
                        ),
                      ),
                      // Collect for a whole family (siblings) in one receipt.
                      Material(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: () => context.push(RouteNames.familyFees),
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.users, size: 14, color: Colors.white),
                                const Gap(5),
                                Text('Families',
                                    style: typography.bodySmallSemiBold.copyWith(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: isMobileFullPage ? 48 : 0,
                    top: 4,
                  ),
                  child: Text(
                    '$total students${totalPages > 1 ? ' • page $page of $totalPages' : ''}',
                    style: typography.bodySmall.copyWith(color: Colors.white70),
                  ),
                ),
                const Gap(14),
                TextField(
                  controller: searchController,
                  onChanged: onQueryChanged,
                  style: typography.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search name, ID, parent or phone...',
                    hintStyle: typography.bodySmall.copyWith(color: Colors.white60),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Classroom filter chips
          if (classrooms.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: classrooms.map((cls) {
                    final isSelected = cls == classroomFilter;
                    return GestureDetector(
                      onTap: () => onClassroomChanged(cls),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? colors.primary : colors.border,
                          ),
                        ),
                        child: Text(
                          cls,
                          style: typography.bodySmallSemiBold.copyWith(
                            color: isSelected ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Fee-status filter (All / owes money / fully paid)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Text('Fees',
                    style: typography.bodySmallSemiBold.copyWith(color: colors.textSecondary)),
                const Gap(10),
                ...const [
                  ('All', 'all'),
                  ('Pending', 'pending'),
                  ('Paid', 'paid'),
                ].map((opt) {
                  final isSelected = statusFilter == opt.$2;
                  final accent = opt.$2 == 'pending'
                      ? Colors.red.shade600
                      : opt.$2 == 'paid'
                          ? Colors.green.shade600
                          : colors.primary;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onStatusChanged(opt.$2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: isSelected ? accent : colors.border),
                        ),
                        child: Text(
                          opt.$1,
                          style: typography.bodySmallSemiBold.copyWith(
                            color: isSelected ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Student list
          Expanded(
            child: summaries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.searchX, size: 36, color: colors.textSecondary.withValues(alpha: 0.4)),
                        const Gap(12),
                        Text('No students found', style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, isMobileFullPage && totalPages <= 1 ? 96 : 12),
                    itemCount: summaries.length,
                    itemBuilder: (context, index) {
                      final s = summaries[index];
                      final isSelected = s.studentId == selectedStudentId;
                      return _StudentTile(
                        summary: s,
                        isSelected: isSelected,
                        onTap: () => onSelectStudent(s.studentId),
                      );
                    },
                  ),
          ),
          if (totalPages > 1)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, isMobileFullPage ? 96 : 12),
              child: AbmPaginationBar(
                page: page,
                totalPages: totalPages,
                total: total,
                loading: pageLoading,
                onPage: onPage,
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });
  final AccountSummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final statusColor = summary.status == 'Paid'
        ? Colors.green.shade600
        : summary.status == 'Partially Paid'
            ? Colors.orange.shade700
            : Colors.red.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? colors.primary.withValues(alpha: 0.08) : colors.background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? colors.primary.withValues(alpha: 0.3) : colors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      backgroundImage: summary.photoUrl != null && summary.photoUrl!.isNotEmpty
                          ? NetworkImage(summary.photoUrl!)
                          : null,
                      child: summary.photoUrl == null || summary.photoUrl!.isEmpty
                          ? Text(
                              summary.fullName[0].toUpperCase(),
                              style: typography.bodyMediumSemiBold.copyWith(color: statusColor),
                            )
                          : null,
                    ),
                    if (summary.status != 'Paid')
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.fullName,
                        style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${summary.classroom} • ${summary.admissionNumber}',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _sar(summary.balance),
                      style: typography.bodySmallSemiBold.copyWith(
                        color: summary.status == 'Paid' ? Colors.green.shade600 : statusColor,
                      ),
                    ),
                    const Gap(2),
                    _StatusBadge(status: summary.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.wallet, size: 48, color: colors.primary.withValues(alpha: 0.5)),
          ),
          const Gap(20),
          Text('Select a student', style: context.typography.h4.copyWith(color: colors.textPrimary)),
          const Gap(8),
          Text(
            'Choose a student from the list to manage their fee collection',
            style: context.typography.bodyMedium.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Account Details Panel ─────────────────────────────────────────────────────

class _AccountDetailsPanel extends ConsumerStatefulWidget {
  const _AccountDetailsPanel({
    required this.studentId,
    required this.processingPayment,
    required this.onProcessPayment,
    required this.onBack,
  });

  final String studentId;
  final bool processingPayment;
  final Future<void> Function(String studentId, double amount, List<String> items, {String? monthLabel, List<String>? monthLabels}) onProcessPayment;
  final VoidCallback onBack;

  @override
  ConsumerState<_AccountDetailsPanel> createState() => _AccountDetailsPanelState();
}

class _AccountDetailsPanelState extends ConsumerState<_AccountDetailsPanel> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(studentAccountDetailsProvider(widget.studentId));

    return detailsAsync.when(
      data: (details) {
        if (_amountController.text.isEmpty) {
          _amountController.text = details.balance.toStringAsFixed(0);
        }
        return _buildContent(context, details);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(friendlyErrorMessage(err))),
    );
  }

  Widget _buildContent(BuildContext context, StudentAccountDetails details) {
    final colors = context.colors;
    final typography = context.typography;

    final topPadding = context.isMobile
        ? MediaQuery.of(context).padding.top + 10
        : 32.0;
    final bottomPadding = context.isMobile ? 100.0 : 32.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        context.isMobile ? 16 : 32,
        topPadding,
        context.isMobile ? 16 : 32,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              if (context.isMobile) ...[
                const SizedBox(width: 48),
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  tooltip: 'Back to student list',
                  onPressed: widget.onBack,
                ),
                const Gap(4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fee Collection',
                      style: typography.h2.copyWith(
                        color: colors.primary,
                        fontSize: context.isMobile ? 20 : null,
                      ),
                    ),
                    Text('Current month: ${details.monthLabel}',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
              if (context.isMobile) const SizedBox(width: 96),
            ],
          ),
          const Gap(20),

          // Student header card
          _StudentHeaderCard(details: details),
          const Gap(20),

          if (context.isMobile)
            Column(
              children: [
                _FeeBreakdownCard(
                  details: details,
                  amountController: _amountController,
                  processingPayment: widget.processingPayment,
                  onProcessPayment: widget.onProcessPayment,
                ),
                const Gap(16),
                _PaymentHistoryCard(details: details),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 55,
                  child: _FeeBreakdownCard(
                    details: details,
                    amountController: _amountController,
                    processingPayment: widget.processingPayment,
                    onProcessPayment: widget.onProcessPayment,
                  ),
                ),
                const Gap(20),
                Expanded(
                  flex: 45,
                  child: _PaymentHistoryCard(details: details),
                ),
              ],
            ),
          const Gap(20),
          _LedgerCard(studentId: widget.studentId),
        ],
      ),
    );
  }
}

// ─── Student Header Card ───────────────────────────────────────────────────────

class _StudentHeaderCard extends StatelessWidget {
  const _StudentHeaderCard({required this.details});
  final StudentAccountDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final s = details.summary;
    final isPaid = details.status == 'Paid';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            backgroundImage: s.photoUrl != null && s.photoUrl!.isNotEmpty
                ? NetworkImage(s.photoUrl!)
                : null,
            child: s.photoUrl == null || s.photoUrl!.isEmpty
                ? Text(
                    s.fullName[0].toUpperCase(),
                    style: typography.h3.copyWith(color: colors.primary),
                  )
                : null,
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName, style: typography.h3.copyWith(color: colors.textPrimary)),
                const Gap(2),
                Text(
                  '${s.admissionNumber} • ${s.classroom}',
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
                Text(
                  'Guardian: ${s.guardianName}',
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: details.status),
              const Gap(6),
              if (!isPaid)
                Text(
                  'Balance: ${_sar(details.balance)}',
                  style: typography.bodySmallSemiBold.copyWith(color: Colors.red.shade600),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.checkCircle2, size: 14, color: Colors.green.shade600),
                    const Gap(4),
                    Text('Cleared', style: typography.bodySmall.copyWith(color: Colors.green.shade600)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Fee Breakdown Card ────────────────────────────────────────────────────────

class _FeeBreakdownCard extends ConsumerStatefulWidget {
  const _FeeBreakdownCard({
    required this.details,
    required this.amountController,
    required this.processingPayment,
    required this.onProcessPayment,
  });

  final StudentAccountDetails details;
  final TextEditingController amountController;
  final bool processingPayment;
  final Future<void> Function(String studentId, double amount, List<String> items, {String? monthLabel, List<String>? monthLabels}) onProcessPayment;

  @override
  ConsumerState<_FeeBreakdownCard> createState() => _FeeBreakdownCardState();
}

class _FeeBreakdownCardState extends ConsumerState<_FeeBreakdownCard> {
  // Which fee items the office admin is collecting in this payment.
  late final Set<String> _selected = widget.details.lineItems.map((e) => e.title).toSet();

  // Multi-month selection state
  late List<String> _selectedMonths = [widget.details.monthLabel];
  String _preset = '1'; // '1', '2', '3', '6', 'custom'
  MultiMonthPreview? _monthPreview;
  bool _loadingPreview = false;

  // Optional fees configured for this grade (Admission / Exam / Book / Arts /
  // Sports …), offered as one-tap add-ons at collection time. Excludes the
  // recurring monthly tuition and transport, which the bill handles itself.
  List<AccountLineItem> _optionalFees = [];

  // The month row holds arrears (left) + current + upcoming months (right). It
  // starts scrolled to the far left, which clipped the current month's year and
  // hid the upcoming months — so we auto-centre the current month on first load.
  final ScrollController _monthScrollController = ScrollController();
  final GlobalKey _currentMonthKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.amountController.text = _totalCalculatedDue().toStringAsFixed(0);
      }
      _centerCurrentMonth();
    });
    _loadOptionalFees();
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  // Bring the current month into view (centred) so its full "Month YYYY" label
  // shows and the upcoming months beside it are visible/scrollable.
  void _centerCurrentMonth() {
    final ctx = _currentMonthKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    // Fallback: the current chip isn't built yet (far right after many arrears
    // months). Estimate its offset so the row still lands near it.
    if (!_monthScrollController.hasClients) return;
    final idx = _monthOptions.indexOf(widget.details.monthLabel);
    if (idx <= 0) return;
    const estChipWidth = 150.0; // chip + separator, approximate
    final target = (idx * estChipWidth - 120)
        .clamp(0.0, _monthScrollController.position.maxScrollExtent);
    _monthScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  bool _isBaseMonthly(String t) {
    final l = t.toLowerCase();
    return l.contains('tuition') || l.contains('tution') || l.contains('monthly');
  }

  bool _isTransport(String t) {
    final l = t.toLowerCase();
    return l.contains('transport') || l.contains('bus');
  }

  // Pull the student's grade fee template and keep the non-tuition, non-transport
  // items as optional quick-add chips. Convenience only — silently skips if the
  // structure can't be fetched.
  Future<void> _loadOptionalFees() async {
    try {
      final instId = ref.read(selectedInstituteProvider).id;
      final structures =
          await ref.read(accountRepositoryProvider).getFeeStructures(instituteId: instId);
      final grade = widget.details.summary.classroom;
      final match = structures.where((s) => s.grade == grade).toList();
      if (match.isEmpty || !mounted) return;
      final seen = <String>{};
      final opts = <AccountLineItem>[];
      for (final it in match.first.lineItems) {
        if (_isBaseMonthly(it.title) || _isTransport(it.title)) continue;
        if (seen.add(it.title)) opts.add(it);
      }
      setState(() => _optionalFees = opts);
    } catch (_) {/* chips are optional; ignore */}
  }

  // One-tap add of a configured optional fee to the selected month(s), at its
  // template amount. Mirrors the manual Add-Charge refresh so the new line and
  // balance show immediately and it's pre-ticked for collection.
  Future<void> _quickAddFee(AccountLineItem fee) async {
    if (widget.processingPayment) return;
    try {
      final applied = await ref.read(accountRepositoryProvider).addCharge(
            widget.details.summary.studentId,
            title: fee.title,
            amount: fee.amount,
            monthLabels: List<String>.from(_selectedMonths),
          );
      if (!mounted) return;
      _selected.add(fee.title);
      ref.invalidate(accountsDirectoryProvider);
      ref.invalidate(studentAccountDetailsProvider(widget.details.summary.studentId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${fee.title} (${_sar(fee.amount)}) added to '
            '${applied.length} month${applied.length == 1 ? '' : 's'}'),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }

  List<String> get _monthOptions {
    final now = DateTime.now();
    final labels = <String>{};
    // Include past 3 months
    for (int i = -3; i < 0; i++) {
      labels.add(DateFormat('MMMM yyyy').format(DateTime(now.year, now.month + i, 1)));
    }
    // Include current month
    labels.add(widget.details.monthLabel);
    // Include next 11 months (up to 12 months ahead)
    for (int i = 1; i <= 11; i++) {
      labels.add(DateFormat('MMMM yyyy').format(DateTime(now.year, now.month + i, 1)));
    }
    final sorted = labels.toList()
      ..sort((a, b) => DateFormat('MMMM yyyy').parse(a).compareTo(DateFormat('MMMM yyyy').parse(b)));
    return sorted;
  }

  void _applyPreset(int count) {
    try {
      final baseDate = DateFormat('MMMM yyyy').parse(widget.details.monthLabel);
      final months = <String>[];
      for (int i = 0; i < count; i++) {
        months.add(DateFormat('MMMM yyyy').format(DateTime(baseDate.year, baseDate.month + i, 1)));
      }
      setState(() {
        _preset = '$count';
        _selectedMonths = months;
      });
      _updateCalculations();
    } catch (_) {}
  }

  void _toggleMonth(String month) {
    setState(() {
      if (_selectedMonths.contains(month)) {
        if (_selectedMonths.length > 1) {
          _selectedMonths.remove(month);
        }
      } else {
        _selectedMonths.add(month);
      }
      _selectedMonths.sort((a, b) => DateFormat('MMMM yyyy').parse(a).compareTo(DateFormat('MMMM yyyy').parse(b)));
      _preset = 'custom';
    });
    _updateCalculations();
  }

  double _baseUnitTotal() => widget.details.lineItems
      .where((i) => _selected.contains(i.title))
      .fold(0.0, (s, i) => s + i.amount);

  double _totalCalculatedDue() {
    if (_monthPreview != null && _monthPreview!.monthsCount == _selectedMonths.length) {
      if (_selected.length < widget.details.lineItems.length) {
        return _baseUnitTotal() * _selectedMonths.length;
      }
      return _monthPreview!.totalBalance;
    }
    if (_selectedMonths.length == 1 && _selectedMonths.first == widget.details.monthLabel) {
      if (_selected.length < widget.details.lineItems.length) {
        return _baseUnitTotal();
      }
      return widget.details.balance;
    }
    return _baseUnitTotal() * _selectedMonths.length;
  }

  void _updateCalculations() {
    final due = _totalCalculatedDue();
    widget.amountController.text = due.toStringAsFixed(0);
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    if (_selectedMonths.isEmpty) return;
    setState(() => _loadingPreview = true);
    try {
      final preview = await ref.read(accountRepositoryProvider).previewMonths(
            studentId: widget.details.summary.studentId,
            monthLabels: _selectedMonths,
          );
      if (mounted) {
        setState(() {
          _monthPreview = preview;
          _loadingPreview = false;
          if (_selected.length == widget.details.lineItems.length) {
            widget.amountController.text = preview.totalBalance.toStringAsFixed(0);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  void _toggleItem(String title) {
    setState(() {
      if (_selected.contains(title)) {
        _selected.remove(title);
      } else {
        _selected.add(title);
      }
      widget.amountController.text = _totalCalculatedDue().toStringAsFixed(0);
    });
  }

  Future<void> _openAddCharge() async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddChargeDialog(
        studentId: widget.details.summary.studentId,
        monthOptions: _monthOptions,
        initialMonths: List<String>.from(_selectedMonths),
      ),
    );
    if (res != null && mounted) {
      // Pre-tick the newly-added item and refresh the breakdown so the new
      // line (and balance) show immediately and are included in the collection.
      _selected.add(res['title'] as String);
      ref.invalidate(accountsDirectoryProvider);
      ref.invalidate(studentAccountDetailsProvider(widget.details.summary.studentId));
      final count = res['count'] as int;
      final amt = (res['amount'] as num).toStringAsFixed(0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${res['title']} (SAR $amt) added to '
            '$count month${count == 1 ? '' : 's'}'),
      ));
    }
  }

  bool get _isFullyPaid {
    if (_selectedMonths.length == 1 && _selectedMonths.first == widget.details.monthLabel) {
      return widget.details.status == 'Paid';
    }
    if (_monthPreview != null && _monthPreview!.monthsCount == _selectedMonths.length) {
      return _monthPreview!.totalBalance <= 0;
    }
    return false;
  }

  Widget _presetChip({required String label, required int count, required bool active}) {
    final colors = context.colors;
    return InkWell(
      onTap: () => _applyPreset(count),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? colors.primary : colors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? colors.primary : colors.primary.withValues(alpha: 0.25),
          ),
          boxShadow: active
              ? [BoxShadow(color: colors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : colors.primary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final amountController = widget.amountController;
    final processingPayment = widget.processingPayment;
    final onProcessPayment = widget.onProcessPayment;
    final colors = context.colors;
    final typography = context.typography;
    final isPaid = _isFullyPaid;
    final totalDue = _totalCalculatedDue();

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.fileText, color: colors.primary, size: 20),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fee Collection', style: typography.h4.copyWith(color: colors.textPrimary)),
                      Text(
                        _selectedMonths.length > 1
                            ? '${_selectedMonths.length} Months (${_selectedMonths.first} – ${_selectedMonths.last})'
                            : details.monthLabel,
                        style: typography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (details.receiptNumber != null && _selectedMonths.length == 1 && details.status == 'Paid')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '#${details.receiptNumber}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Duration Presets Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.calendarRange, size: 16, color: colors.primary),
                    const Gap(8),
                    Text(
                      'PAYMENT DURATION',
                      style: typography.bodySmallSemiBold.copyWith(
                        color: colors.primary,
                        letterSpacing: 0.8,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedMonths.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedMonths.length} Months Selected',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const Gap(10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetChip(label: '1 Month', count: 1, active: _preset == '1'),
                    _presetChip(label: '2 Months', count: 2, active: _preset == '2'),
                    _presetChip(label: '3 Months (Quarter)', count: 3, active: _preset == '3'),
                    _presetChip(label: '6 Months (Half Year)', count: 6, active: _preset == '6'),
                  ],
                ),
              ],
            ),
          ),

          // Month Selection Chips with Left/Right Scroll Controls & Mouse Drag Support
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Select / Toggle Months',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const Gap(8),
                    Text(
                      '·  arrears ← | → upcoming',
                      style: typography.caption.copyWith(color: colors.textSecondary.withValues(alpha: 0.7), fontSize: 10),
                    ),
                    const Spacer(),
                    // Quick jump to current month button
                    InkWell(
                      onTap: _centerCurrentMonth,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.calendar, size: 12, color: colors.primary),
                            const Gap(4),
                            Text(
                              'Current Month',
                              style: typography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.w600, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Row(
                  children: [
                    // Scroll Left Button (Arrears)
                    _ScrollArrowButton(
                      icon: LucideIcons.chevronLeft,
                      tooltip: 'Scroll to earlier / arrears months',
                      onPressed: () {
                        if (!_monthScrollController.hasClients) return;
                        final target = (_monthScrollController.offset - 220.0)
                            .clamp(0.0, _monthScrollController.position.maxScrollExtent);
                        _monthScrollController.animateTo(
                          target,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
                    const Gap(6),
                    // Horizontal Months List with Mouse Drag & Wheel Support
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: Listener(
                          onPointerSignal: (pointerSignal) {
                            if (pointerSignal is PointerScrollEvent && _monthScrollController.hasClients) {
                              final delta = pointerSignal.scrollDelta.dx != 0
                                  ? pointerSignal.scrollDelta.dx
                                  : pointerSignal.scrollDelta.dy;
                              if (delta != 0) {
                                final target = (_monthScrollController.offset + delta)
                                    .clamp(0.0, _monthScrollController.position.maxScrollExtent);
                                _monthScrollController.jumpTo(target);
                              }
                            }
                          },
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                                PointerDeviceKind.stylus,
                              },
                            ),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              controller: _monthScrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _monthOptions.length,
                              separatorBuilder: (_, index) => const Gap(8),
                              itemBuilder: (ctx, idx) {
                                final m = _monthOptions[idx];
                                final isSelected = _selectedMonths.contains(m);
                                final isCurrent = m == details.monthLabel;
                                final isPast = DateFormat('MMMM yyyy').parse(m).isBefore(
                                      DateFormat('MMMM yyyy').parse(details.monthLabel),
                                    );

                                return ChoiceChip(
                                  key: isCurrent ? _currentMonthKey : null,
                                  selected: isSelected,
                                  onSelected: (_) => _toggleMonth(m),
                                  selectedColor: colors.primary,
                                  backgroundColor: colors.background,
                                  side: BorderSide(
                                    color: isSelected
                                        ? colors.primary
                                        : (isCurrent ? colors.primary.withValues(alpha: 0.5) : colors.border),
                                  ),
                                  avatar: isSelected
                                      ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                                      : null,
                                  label: Text(
                                    m + (isCurrent ? ' (Current)' : (isPast ? ' (Arrears)' : ' (Upcoming)')),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : colors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(6),
                    // Scroll Right Button (Upcoming)
                    _ScrollArrowButton(
                      icon: LucideIcons.chevronRight,
                      tooltip: 'Scroll to upcoming months',
                      onPressed: () {
                        if (!_monthScrollController.hasClients) return;
                        final target = (_monthScrollController.offset + 220.0)
                            .clamp(0.0, _monthScrollController.position.maxScrollExtent);
                        _monthScrollController.animateTo(
                          target,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Multi-month summary highlight card
          if (_selectedMonths.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendarCheck, size: 18, color: colors.primary),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paying for ${_selectedMonths.length} Months Upfront',
                            style: typography.bodyMediumSemiBold.copyWith(color: colors.primary),
                          ),
                          Text(
                            _selectedMonths.join(' • '),
                            style: typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (_loadingPreview)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),

          // Line items breakdown
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (details.lineItems.isEmpty)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.alertTriangle, size: 16, color: Colors.amber.shade700),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                'No fee template found for this grade. Set up a Fee Structure in Fee Setup, then tap Recalculate.',
                                style: typography.bodySmall.copyWith(color: Colors.amber.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: processingPayment
                              ? null
                              : () async {
                                  try {
                                    await ref.read(accountRepositoryProvider).recalculateFees(details.summary.studentId);
                                    ref.invalidate(accountsDirectoryProvider);
                                    ref.invalidate(studentAccountDetailsProvider(details.summary.studentId));
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(friendlyErrorMessage(e))),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Recalculate Fees from Fee Structure'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  if (!isPaid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _selectedMonths.length > 1
                            ? 'Fee breakdown per category (multiplied for ${_selectedMonths.length} months)'
                            : 'Tick the fee items to collect',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                    ),
                  ...details.lineItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isLast = entry.key == details.lineItems.length - 1;
                    final selected = _selected.contains(item.title);
                    final count = _selectedMonths.length;
                    final multiAmount = item.amount * count;

                    return Column(
                      children: [
                        if (isPaid)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    count > 1 ? '${item.title} ($count months)' : item.title,
                                    style: typography.bodyMedium.copyWith(color: colors.textPrimary),
                                  ),
                                ),
                                Text(
                                  _sar(multiAmount),
                                  style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary),
                                ),
                              ],
                            ),
                          )
                        else
                          InkWell(
                            onTap: () => _toggleItem(item.title),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 34,
                                    child: Checkbox(
                                      value: selected,
                                      onChanged: (_) => _toggleItem(item.title),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      activeColor: colors.primary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title,
                                            style: typography.bodyMedium.copyWith(color: colors.textPrimary)),
                                        if (count > 1)
                                          Text(
                                            '${_sar(item.amount)} × $count months',
                                            style: typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _sar(multiAmount),
                                    style: typography.bodyMediumSemiBold.copyWith(
                                      color: selected ? colors.textPrimary : colors.textSecondary.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!isLast) Divider(height: 1, color: colors.border),
                      ],
                    );
                  }),
                ],

                // Quick-add: the grade's configured optional fees (Admission /
                // Exam / Book / Arts / Sports …) that aren't already on this
                // month's bill, one tap to add at their set amount.
                if (!isPaid && _optionalFees.isNotEmpty)
                  Builder(builder: (context) {
                    final onBill = details.lineItems.map((e) => e.title).toSet();
                    final avail = _optionalFees.where((f) => !onBill.contains(f.title)).toList();
                    if (avail.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add an optional fee',
                            style: typography.bodySmall
                                .copyWith(color: colors.textSecondary, fontSize: 11),
                          ),
                          const Gap(8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: avail
                                .map((f) => ActionChip(
                                      avatar: Icon(LucideIcons.plus, size: 14, color: colors.primary),
                                      label: Text('${f.title} · ${_sar(f.amount)}'),
                                      onPressed: processingPayment ? null : () => _quickAddFee(f),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  }),

                // Manual / ad-hoc charge (a custom amount or a fee not in the
                // template) for the selected month(s), added on top of the above.
                if (!isPaid)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: processingPayment ? null : _openAddCharge,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Other / custom charge'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),

                const Gap(12),
                // Total Balance row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedMonths.length > 1
                              ? 'Total Balance (${_selectedMonths.length} Months)'
                              : 'Balance',
                          style: typography.bodyLargeSemiBold.copyWith(color: colors.textPrimary),
                        ),
                      ),
                      Text(
                        _sar(totalDue),
                        style: typography.h4.copyWith(
                          color: totalDue > 0 ? Colors.red.shade600 : Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isPaid) ...[
                  const Gap(20),
                  // Payment input
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: typography.bodyLarge.copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: _selectedMonths.length > 1
                          ? 'Payment Amount for ${_selectedMonths.length} Months (SAR)'
                          : 'Payment Amount (SAR)',
                      labelStyle: typography.bodyMedium.copyWith(color: colors.textSecondary),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('SAR', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF163D32))),
                      ),
                      prefixIconConstraints: const BoxConstraints(),
                      suffixIcon: TextButton(
                        onPressed: () {
                          amountController.text = totalDue.toStringAsFixed(0);
                        },
                        child: const Text('Full', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      filled: true,
                      fillColor: colors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const Gap(14),
                  // Pay button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: processingPayment
                            ? null
                            : () async {
                                final amount = double.tryParse(amountController.text.trim());
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Enter a valid amount')),
                                  );
                                  return;
                                }
                                if (_selected.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Select at least one fee item to collect')),
                                  );
                                  return;
                                }
                                await onProcessPayment(
                                  details.summary.studentId,
                                  amount,
                                  _selected.toList(),
                                  monthLabels: _selectedMonths.length > 1 ? _selectedMonths : null,
                                  monthLabel: _selectedMonths.length == 1 ? _selectedMonths.first : null,
                                );
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (processingPayment)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            else
                              const Icon(LucideIcons.creditCard, color: Colors.white, size: 20),
                            const Gap(10),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  processingPayment
                                      ? 'Processing Payment...'
                                      : (_selectedMonths.length > 1
                                          ? 'Process ${_selectedMonths.length} Months Payment & Generate Invoice'
                                          : 'Process Payment & Generate Invoice'),
                                  style: typography.bodyMediumSemiBold.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const Gap(16),
                  // Already paid state
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.checkCircle2, color: Colors.green.shade600, size: 20),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            _selectedMonths.length > 1
                                ? 'Fees fully paid for all ${_selectedMonths.length} selected months'
                                : 'Fee fully paid for ${_selectedMonths.first}',
                            style: typography.bodyMedium.copyWith(color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(10),
                  // Even after a month is fully paid, allow adding a late Books /
                  // other charge — it reopens that month owing just the new amount,
                  // collected separately (mirrors the unpaid-state button above).
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: processingPayment ? null : _openAddCharge,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Add Books / Other Charge'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollArrowButton extends StatelessWidget {
  const _ScrollArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: colors.primary),
          ),
        ),
      ),
    );
  }
}

// ─── Payment History Card ──────────────────────────────────────────────────────

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.details});
  final StudentAccountDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.history, color: Colors.indigo, size: 20),
                ),
                const Gap(12),
                Text('Payment History', style: typography.h4.copyWith(color: colors.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: details.history.isEmpty
                ? Column(
                    children: [
                      Icon(LucideIcons.folderOpen, size: 36, color: colors.textSecondary.withValues(alpha: 0.4)),
                      const Gap(8),
                      Text('No payment history yet',
                          style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
                    ],
                  )
                : Column(
                    children: details.history.map((item) {
                      return _HistoryRow(item: item, details: details);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.details});
  final ReceiptHistoryItem item;
  final StudentAccountDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isPaid = item.status == 'Paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPaid
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid ? LucideIcons.checkCircle : LucideIcons.clock,
              color: isPaid ? Colors.green.shade600 : Colors.orange.shade700,
              size: 16,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.monthsCount != null && item.monthsCount! > 1
                      ? '${item.monthsCount} Months: ${item.monthLabel}'
                      : item.monthLabel,
                  style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary),
                ),
                if (item.paidOn != null)
                  Text(
                    DateFormat('dd MMM yyyy').format(item.paidOn!),
                    style: typography.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                if (item.receiptNumber != null)
                  Text(
                    '#${item.receiptNumber}',
                    style: typography.bodySmall.copyWith(
                      color: colors.primary.withValues(alpha: 0.8),
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_sar(item.totalPaid),
                  style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
              const Gap(4),
              _StatusBadge(status: item.status),
            ],
          ),
          if (isPaid) ...[
            const Gap(8),
            IconButton(
              icon: Icon(LucideIcons.receipt, size: 18, color: colors.primary),
              onPressed: () => _showReceiptDialog(context, details, item),
              tooltip: 'View Invoice',
              style: IconButton.styleFrom(
                backgroundColor: colors.primary.withValues(alpha: 0.08),
                padding: const EdgeInsets.all(6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, StudentAccountDetails details, ReceiptHistoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => _InvoiceDialog(details: details, receipt: item),
    );
  }
}

// ─── Invoice / Receipt Dialog ──────────────────────────────────────────────────

class _InvoiceDialog extends StatelessWidget {
  const _InvoiceDialog({required this.details, required this.receipt});
  final StudentAccountDetails details;
  final ReceiptHistoryItem receipt;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SelectionArea(
      child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: screenHeight * 0.88),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Invoice content — scrollable
            Flexible(
              child: SingleChildScrollView(
                child: _InvoiceContent(details: details, receipt: receipt),
              ),
            ),
            // Actions — always pinned at the bottom
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _printInvoice(details, receipt),
                      icon: const Icon(LucideIcons.printer, size: 16),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendWhatsApp(context, details, receipt),
                      icon: const Icon(LucideIcons.messageCircle, size: 16),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _printInvoice(StudentAccountDetails details, ReceiptHistoryItem item) async {
    await Printing.layoutPdf(onLayout: (_) => _buildPdf(details, item).save());
  }

  String _whatsAppMessage(StudentAccountDetails details, ReceiptHistoryItem item) {
    final s = details.summary;
    final remaining = (item.totalDue - item.totalPaid);
    final b = StringBuffer()
      ..writeln('*Fee Receipt — Anas Bin Malik Madrasa*')
      ..writeln('Receipt: #${item.receiptNumber ?? '-'}')
      ..writeln('Student: ${s.fullName}${s.classroom.isNotEmpty ? ' (${s.classroom})' : ''}')
      ..writeln('Guardian: ${s.guardianName}')
      ..writeln('Month: ${item.monthLabel}')
      ..writeln('Paid: ${_sar(item.totalPaid)}');
    if (remaining > 0) b.writeln('Balance: ${_sar(remaining)}');
    b
      ..writeln('Date: ${DateFormat('dd MMM yyyy').format(item.paidOn ?? DateTime.now())}')
      ..writeln('')
      ..writeln('Thank you! May Allah bless you.');
    return b.toString();
  }

  Future<void> _sendWhatsApp(BuildContext context, StudentAccountDetails details, ReceiptHistoryItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = details.summary.parentContact;
    // Capture the share-sheet anchor (iPad) synchronously, before any await.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);
    final message = _whatsAppMessage(details, item);
    final bytes = await _buildPdf(details, item).save();
    final fname = 'receipt-${item.receiptNumber ?? details.summary.admissionNumber}.pdf';

    if (!kIsWeb) {
      // Mobile: one share-sheet action carrying BOTH the PDF (attached) and the
      // receipt text (as caption). Staff pick the guardian's WhatsApp chat →
      // the PDF and message go together. wa.me links can't attach files, so the
      // share sheet is the only way to send a real attachment without a paid API.
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fname');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf', name: fname)],
          text: message,
          sharePositionOrigin: origin,
        );
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
      return;
    }

    // Web: WhatsApp Web can't be handed a file, so download the PDF (staff
    // attach it) and open the guardian's chat prefilled with the receipt text.
    try {
      await Printing.sharePdf(bytes: bytes, filename: fname);
    } catch (_) {}
    final ok = await WhatsAppService.send(phone, message);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(phone.trim().isEmpty
            ? 'No guardian number on file for this student.'
            : 'Could not open WhatsApp for $phone.'),
      ));
    }
  }

  pw.Document _buildPdf(StudentAccountDetails details, ReceiptHistoryItem item) {
    final pdf = pw.Document();
    final s = details.summary;
    final lineItems = item.lineItems.isNotEmpty ? item.lineItems : details.lineItems;

    final green = PdfColor.fromInt(0xFF1B3D2F);
    final gold = PdfColor.fromInt(0xFFB8860B);
    final softBg = PdfColor.fromInt(0xFFF4F6F3);
    final remaining = item.totalDue - item.totalPaid;
    final monthStr =
        '${item.monthsCount != null && item.monthsCount! > 1 ? "(${item.monthsCount} months) " : ""}${item.monthLabel}';
    final dateStr = DateFormat('dd MMM yyyy').format(item.paidOn ?? DateTime.now());

    pw.Widget cell(String label, String value, {bool right = false}) => pw.Column(
          crossAxisAlignment: right ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(),
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600, letterSpacing: 0.5)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Letterhead band
              pw.Container(
                color: green,
                padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ANAS BIN MALIK MADRASA',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 3),
                        pw.Text('FEE PAYMENT RECEIPT',
                            style: pw.TextStyle(color: gold, fontSize: 9, letterSpacing: 1.5)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF2E7D32),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text('PAID',
                          style: pw.TextStyle(
                              color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ],
                ),
              ),
              pw.Container(height: 3, color: gold),

              pw.Padding(
                padding: const pw.EdgeInsets.all(28),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Receipt meta
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        cell('Receipt No.', item.receiptNumber ?? '-'),
                        cell('Date', dateStr, right: true),
                      ],
                    ),
                    pw.SizedBox(height: 18),

                    // Billed-to card
                    pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(color: softBg, borderRadius: pw.BorderRadius.circular(8)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILLED TO',
                              style: pw.TextStyle(fontSize: 7, color: green, letterSpacing: 0.8, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(s.fullName,
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: green)),
                          pw.SizedBox(height: 12),
                          pw.Row(children: [
                            pw.Expanded(child: cell('Admission No.', s.admissionNumber)),
                            pw.Expanded(child: cell('Class', s.classroom)),
                          ]),
                          pw.SizedBox(height: 10),
                          pw.Row(children: [
                            pw.Expanded(child: cell('Guardian', s.guardianName)),
                            pw.Expanded(child: cell('Fee Month', monthStr)),
                          ]),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 18),

                    // Fee table
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: pw.BoxDecoration(color: green, borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('DESCRIPTION',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                          pw.Text('AMOUNT',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    ...lineItems.asMap().entries.map((e) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: e.key.isEven ? PdfColors.white : softBg,
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(child: pw.Text(e.value.title, style: const pw.TextStyle(fontSize: 10))),
                              pw.Text('SAR ${e.value.amount.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        )),
                    pw.SizedBox(height: 14),

                    // Total
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: pw.BoxDecoration(color: green, borderRadius: pw.BorderRadius.circular(8)),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('TOTAL PAID',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                          pw.Text('SAR ${item.totalPaid.toStringAsFixed(0)}',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 17, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (remaining > 0) ...[
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Balance remaining', style: pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                          pw.Text('SAR ${remaining.toStringAsFixed(0)}',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                        ],
                      ),
                    ],
                    pw.SizedBox(height: 28),

                    pw.Center(
                      child: pw.Text('Thank you! May Allah bless you.',
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: green, fontSize: 10)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Center(
                      child: pw.Text('This is a computer-generated receipt and needs no signature.',
                          style: pw.TextStyle(color: PdfColors.grey500, fontSize: 7)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

}

// ─── Invoice Content (Flutter UI) ─────────────────────────────────────────────

class _InvoiceContent extends StatelessWidget {
  const _InvoiceContent({required this.details, required this.receipt});
  final StudentAccountDetails details;
  final ReceiptHistoryItem receipt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final s = details.summary;
    final lineItems = receipt.lineItems.isNotEmpty ? receipt.lineItems : details.lineItems;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.primary.withValues(alpha: 0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 32),
                ),
                const Gap(14),
                Text(
                  'Invoice Generated',
                  style: typography.h3.copyWith(color: colors.primary),
                ),
                const Gap(4),
                Text(
                  'Receipt: #${receipt.receiptNumber ?? "N/A"}',
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
                if (receipt.paidOn != null) ...[
                  const Gap(2),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(receipt.paidOn!),
                    style: typography.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const Gap(24),

          // Madrasa header divider
          Row(
            children: [
              Expanded(child: Divider(color: colors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ANAS BIN MALIK MADRASA',
                  style: typography.bodySmallSemiBold.copyWith(color: colors.textSecondary, letterSpacing: 0.5),
                ),
              ),
              Expanded(child: Divider(color: colors.border)),
            ],
          ),
          const Gap(20),

          // Student info
          _InvoiceSection(
            title: 'Student Details',
            icon: LucideIcons.user,
            child: Column(
              children: [
                _InvoiceRow(label: 'Name', value: s.fullName, isBold: true),
                _InvoiceRow(label: 'Admission No.', value: s.admissionNumber),
                _InvoiceRow(label: 'Classroom', value: s.classroom),
                _InvoiceRow(label: 'Guardian', value: s.guardianName),
                _InvoiceRow(label: 'Fee Month(s)', value: receipt.monthLabel),
                if (receipt.monthsCount != null && receipt.monthsCount! > 1)
                  _InvoiceRow(
                    label: 'Payment Duration',
                    value: '${receipt.monthsCount} Months Paid Together',
                    isBold: true,
                    valueColor: colors.primary,
                  ),
              ],
            ),
          ),
          const Gap(16),

          // Fee breakdown
          _InvoiceSection(
            title: 'Fee Breakdown',
            icon: LucideIcons.listChecks,
            child: Column(
              children: [
                ...lineItems.map((item) => _InvoiceRow(label: item.title, value: _sar(item.amount))),
                Divider(height: 20, color: colors.border),
                _InvoiceRow(
                  label: 'Amount Paid',
                  value: _sar(receipt.totalPaid),
                  isBold: true,
                  valueColor: colors.primary,
                ),
              ],
            ),
          ),
          const Gap(20),

          // Paid badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.checkCircle2, color: Colors.green.shade600, size: 18),
                const Gap(8),
                Text(
                  'Payment Confirmed',
                  style: typography.bodyMediumSemiBold.copyWith(color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          const Gap(20),
        ],
      ),
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 14, color: colors.textSecondary),
                const Gap(6),
                Text(title,
                    style: typography.bodySmallSemiBold.copyWith(
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    )),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
          ),
          Text(
            value,
            style: isBold
                ? typography.bodyMediumSemiBold.copyWith(color: valueColor ?? colors.textPrimary)
                : typography.bodySmall.copyWith(color: valueColor ?? colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status.toLowerCase() == 'paid';
    final isPartial = status.toLowerCase() == 'partially paid';
    final color = isPaid
        ? Colors.green
        : isPartial
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─── Fee Ledger Card (arrears + month-by-month + waive) ──────────────────────

class _LedgerCard extends ConsumerWidget {
  const _LedgerCard({required this.studentId});
  final String studentId;

  void _refresh(WidgetRef ref) {
    ref.invalidate(feeLedgerProvider(studentId));
    ref.invalidate(accountsDirectoryProvider);
    ref.invalidate(studentAccountDetailsProvider(studentId));
  }

  Future<void> _snack(BuildContext context, String msg, {bool ok = true}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? const Color(0xFF16A34A) : null),
    );
  }

  Future<void> _payMonth(BuildContext context, WidgetRef ref, LedgerMonth m) async {
    final ctrl = TextEditingController(text: m.balance.toStringAsFixed(0));
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Collect — ${m.monthLabel}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (SAR)', prefixText: 'SAR '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            child: const Text('Collect'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (amount == null || amount <= 0) return;
    try {
      await ref.read(accountRepositoryProvider).processPayment(
          studentId: studentId, amount: amount, monthLabel: m.monthLabel);
      _refresh(ref);
      if (context.mounted) _snack(context, 'Collected ${_sar(amount)} for ${m.monthLabel}');
    } catch (e) {
      if (context.mounted) _snack(context, friendlyErrorMessage(e), ok: false);
    }
  }

  Future<void> _settleArrears(BuildContext context, WidgetRef ref, num arrears) async {
    final ctrl = TextEditingController(text: arrears.toStringAsFixed(0));
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle Arrears (oldest first)'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Total arrears: ${_sar(arrears.toDouble())}'),
          const Gap(10),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount to collect (SAR)', prefixText: 'SAR '),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            child: const Text('Collect'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (amount == null || amount <= 0) return;
    try {
      await ref.read(accountRepositoryProvider)
          .processPayment(studentId: studentId, amount: amount, allocate: 'oldest');
      _refresh(ref);
      if (context.mounted) _snack(context, 'Applied ${_sar(amount)} oldest-first');
    } catch (e) {
      if (context.mounted) _snack(context, friendlyErrorMessage(e), ok: false);
    }
  }

  Future<void> _payMultipleMonthsDialog(BuildContext context, WidgetRef ref, FeeLedger ledger) async {
    final unpaidMonths = ledger.months.where((m) => !m.waived && m.balance > 0).toList();
    if (unpaidMonths.isEmpty) {
      _snack(context, 'No unpaid months in ledger', ok: false);
      return;
    }

    final selected = Set<String>.from(unpaidMonths.map((m) => m.monthLabel));
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final selList = unpaidMonths.where((m) => selected.contains(m.monthLabel)).toList();
            final totalBal = selList.fold(0.0, (s, m) => s + m.balance);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(LucideIcons.calendarRange, size: 20),
                  Gap(10),
                  Text('Collect Multiple Months'),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select which unpaid months to collect:'),
                    const Gap(12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: SingleChildScrollView(
                        child: Column(
                          children: unpaidMonths.map((m) {
                            final isChecked = selected.contains(m.monthLabel);
                            return CheckboxListTile(
                              dense: true,
                              value: isChecked,
                              title: Text(m.monthLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Due: ${_sar(m.balance.toDouble())}'),
                              onChanged: (val) {
                                setDlgState(() {
                                  if (val == true) {
                                    selected.add(m.monthLabel);
                                  } else {
                                    selected.remove(m.monthLabel);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${selected.length} Months Selected', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(_sar(totalBal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(ctx, {'months': selected.toList(), 'amount': totalBal}),
                  child: Text('Collect ${_sar(totalBal)}'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final months = (result['months'] as List).cast<String>();
    final amount = (result['amount'] as num).toDouble();
    if (months.isEmpty || amount <= 0) return;

    try {
      await ref.read(accountRepositoryProvider).processPayment(
            studentId: studentId,
            amount: amount,
            monthLabels: months,
          );
      _refresh(ref);
      if (context.mounted) {
        _snack(context, 'Successfully collected ${_sar(amount)} for ${months.length} months');
      }
    } catch (e) {
      if (context.mounted) _snack(context, friendlyErrorMessage(e), ok: false);
    }
  }

  Future<void> _toggleWaive(BuildContext context, WidgetRef ref, LedgerMonth m) async {
    try {
      await ref.read(accountRepositoryProvider).waiveMonth(studentId, m.monthLabel, !m.waived);
      _refresh(ref);
      if (context.mounted) _snack(context, m.waived ? '${m.monthLabel} restored' : '${m.monthLabel} waived');
    } catch (e) {
      if (context.mounted) _snack(context, friendlyErrorMessage(e), ok: false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final async = ref.watch(feeLedgerProvider(studentId));

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text(friendlyErrorMessage(e), style: typography.bodySmall),
        data: (ledger) {
          final unpaidMonthsCount = ledger.months.where((m) => !m.waived && m.balance > 0).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(LucideIcons.history, color: colors.primary, size: 20),
                const Gap(10),
                Text('Fee Ledger', style: typography.h4),
                const Spacer(),
                if (ledger.arrears > 0) ...[
                  ElevatedButton.icon(
                    onPressed: () => _settleArrears(context, ref, ledger.arrears),
                    icon: const Icon(LucideIcons.wallet, size: 15),
                    label: const Text('Settle Arrears'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                  ),
                  const Gap(8),
                ],
                if (unpaidMonthsCount > 1)
                  ElevatedButton.icon(
                    onPressed: () => _payMultipleMonthsDialog(context, ref, ledger),
                    icon: const Icon(LucideIcons.calendarRange, size: 15),
                    label: const Text('Multi-Month'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ]),
              const Gap(14),
              // Arrears vs current summary
              Row(children: [
                _sumTile(context, 'Arrears', ledger.arrears.toDouble(),
                    ledger.arrears > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                const Gap(10),
                _sumTile(context, 'This Month', ledger.currentDue.toDouble(), colors.primary),
                const Gap(10),
                _sumTile(context, 'Advance', ledger.advanceBalance.toDouble(), const Color(0xFF2563EB)),
              ]),
              const Gap(16),
              ...ledger.months.reversed.map((m) => _monthRow(context, ref, m)),
            ],
          );
        },
      ),
    );
  }

  Widget _sumTile(BuildContext context, String label, double value, Color tint) {
    final typography = context.typography;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: tint.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: typography.bodySmall.copyWith(color: context.colors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Gap(2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_sar(value), style: typography.bodyLargeSemiBold.copyWith(color: tint)),
          ),
        ]),
      ),
    );
  }

  Widget _monthRow(BuildContext context, WidgetRef ref, LedgerMonth m) {
    final colors = context.colors;
    final typography = context.typography;
    final color = m.waived
        ? const Color(0xFF6B7280)
        : (m.status == 'Paid'
            ? const Color(0xFF16A34A)
            : (m.balance > 0 ? const Color(0xFFD97706) : colors.textSecondary));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(m.monthLabel, style: typography.bodyMediumSemiBold),
                if (m.isCurrent) ...[
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text('Current', style: typography.bodySmall.copyWith(color: colors.primary, fontSize: 10)),
                  ),
                ],
              ]),
              Text(m.waived ? 'Waived — no fee due' : 'SAR ${m.totalPaid.toStringAsFixed(0)} / ${m.totalDue.toStringAsFixed(0)}',
                  style: typography.bodySmall.copyWith(color: colors.textSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(m.waived ? 'Waived' : m.status,
                style: typography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
          if (!m.waived && m.balance > 0) ...[
            const Gap(6),
            IconButton(
              tooltip: 'Collect this month',
              visualDensity: VisualDensity.compact,
              onPressed: () => _payMonth(context, ref, m),
              icon: Icon(LucideIcons.creditCard, size: 18, color: colors.primary),
            ),
          ],
          if (m.totalPaid == 0)
            IconButton(
              tooltip: m.waived ? 'Restore fee' : 'Waive this month',
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleWaive(context, ref, m),
              icon: Icon(m.waived ? LucideIcons.rotateCcw : LucideIcons.ban,
                  size: 17, color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}
