import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:abm_madrasa/features/accounts/presentation/finance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

String _sar(double v) => 'SAR ${v.toStringAsFixed(0)}';

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
  bool _processingPayment = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getClassrooms(List<AccountSummary> summaries) {
    final classrooms = summaries.map((s) => s.classroom).toSet().toList()..sort();
    return ['All', ...classrooms];
  }

  List<AccountSummary> _applyFilters(List<AccountSummary> summaries) {
    return summaries.where((s) {
      final query = _query.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          s.fullName.toLowerCase().contains(query) ||
          s.admissionNumber.toLowerCase().contains(query);
      final matchesClass = _classroomFilter == 'All' || s.classroom == _classroomFilter;
      return matchesQuery && matchesClass;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final summariesAsync = ref.watch(accountSummariesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: summariesAsync.when(
        data: (summaries) {
          final filtered = _applyFilters(summaries);
          if (_selectedStudentId != null &&
              !filtered.any((s) => s.studentId == _selectedStudentId)) {
            _selectedStudentId = filtered.isNotEmpty ? filtered.first.studentId : null;
          }
          _selectedStudentId ??= filtered.isNotEmpty ? filtered.first.studentId : null;

          if (context.isMobile) {
            return _MobileLayout(
              summaries: filtered,
              selectedStudentId: _selectedStudentId,
              processingPayment: _processingPayment,
              onSelectStudent: (id) => setState(() => _selectedStudentId = id),
              onProcessPayment: _handlePayment,
              searchController: _searchController,
              query: _query,
              onQueryChanged: (v) => setState(() => _query = v),
              classrooms: _getClassrooms(summaries),
              classroomFilter: _classroomFilter,
              onClassroomChanged: (c) => setState(() => _classroomFilter = c),
            );
          }

          return Row(
            children: [
              SizedBox(
                width: 380,
                child: _Sidebar(
                  summaries: filtered,
                  selectedStudentId: _selectedStudentId,
                  classrooms: _getClassrooms(summaries),
                  classroomFilter: _classroomFilter,
                  onClassroomChanged: (c) => setState(() => _classroomFilter = c),
                  searchController: _searchController,
                  onQueryChanged: (v) => setState(() => _query = v),
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
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _handlePayment(String studentId, double amount, List<String> items) async {
    setState(() => _processingPayment = true);
    try {
      final receipt = await ref.read(accountRepositoryProvider).processPayment(
            studentId: studentId,
            amount: amount,
            items: items,
          );
      ref.invalidate(accountSummariesProvider);
      ref.invalidate(studentAccountDetailsProvider(studentId));

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
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
    final summaries = ref.read(accountSummariesProvider).asData?.value ?? [];
    final student = summaries.where((s) => s.studentId == studentId);
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
  });

  final List<AccountSummary> summaries;
  final String? selectedStudentId;
  final bool processingPayment;
  final void Function(String id) onSelectStudent;
  final Future<void> Function(String studentId, double amount, List<String> items) onProcessPayment;
  final TextEditingController searchController;
  final String query;
  final void Function(String) onQueryChanged;
  final List<String> classrooms;
  final String classroomFilter;
  final void Function(String) onClassroomChanged;

  @override
  Widget build(BuildContext context) {
    if (selectedStudentId != null) {
      return _AccountDetailsPanel(
        studentId: selectedStudentId!,
        processingPayment: processingPayment,
        onProcessPayment: onProcessPayment,
        onBack: () => onSelectStudent(''),
      );
    }

    return _Sidebar(
      summaries: summaries,
      selectedStudentId: selectedStudentId,
      classrooms: classrooms,
      classroomFilter: classroomFilter,
      onClassroomChanged: onClassroomChanged,
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
    required this.selectedStudentId,
    required this.classrooms,
    required this.classroomFilter,
    required this.onClassroomChanged,
    required this.searchController,
    required this.onQueryChanged,
    required this.onSelectStudent,
    this.isMobileFullPage = false,
  });

  final List<AccountSummary> summaries;
  final String? selectedStudentId;
  final List<String> classrooms;
  final String classroomFilter;
  final void Function(String) onClassroomChanged;
  final TextEditingController searchController;
  final void Function(String) onQueryChanged;
  final void Function(String id) onSelectStudent;
  final bool isMobileFullPage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final pendingCount = summaries.where((s) => s.status == 'Pending').length;
    final partialCount = summaries.where((s) => s.status == 'Partially Paid').length;

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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                Text('Fee Collection', style: typography.h3.copyWith(color: Colors.white)),
                const Gap(4),
                Text(
                  '${summaries.length} students • $pendingCount pending • $partialCount partial',
                  style: typography.bodySmall.copyWith(color: Colors.white70),
                ),
                const Gap(14),
                TextField(
                  controller: searchController,
                  onChanged: onQueryChanged,
                  style: typography.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID...',
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
                    padding: const EdgeInsets.all(12),
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
  final Future<void> Function(String studentId, double amount, List<String> items) onProcessPayment;
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
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildContent(BuildContext context, StudentAccountDetails details) {
    final colors = context.colors;
    final typography = context.typography;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              if (context.isMobile)
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: widget.onBack,
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fee Collection', style: typography.h2.copyWith(color: colors.primary)),
                    Text('Current month: ${details.monthLabel}',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
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
  final Future<void> Function(String studentId, double amount, List<String> items) onProcessPayment;

  @override
  ConsumerState<_FeeBreakdownCard> createState() => _FeeBreakdownCardState();
}

class _FeeBreakdownCardState extends ConsumerState<_FeeBreakdownCard> {
  // Which fee items the office admin is collecting in this payment.
  late final Set<String> _selected = widget.details.lineItems.map((e) => e.title).toSet();

  double _selectedTotal() => widget.details.lineItems
      .where((i) => _selected.contains(i.title))
      .fold(0.0, (s, i) => s + i.amount);

  void _toggleItem(String title) {
    setState(() {
      if (_selected.contains(title)) {
        _selected.remove(title);
      } else {
        _selected.add(title);
      }
      widget.amountController.text = _selectedTotal().toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final amountController = widget.amountController;
    final processingPayment = widget.processingPayment;
    final onProcessPayment = widget.onProcessPayment;
    final colors = context.colors;
    final typography = context.typography;
    final isPaid = details.status == 'Paid';

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
                      Text('Fee Breakdown', style: typography.h4.copyWith(color: colors.textPrimary)),
                      Text(details.monthLabel,
                          style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
                if (details.receiptNumber != null)
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

          // Line items
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
                                    ref.invalidate(accountSummariesProvider);
                                    ref.invalidate(studentAccountDetailsProvider(details.summary.studentId));
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
                      child: Text('Tick the fee items to collect',
                          style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                    ),
                  ...details.lineItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isLast = entry.key == details.lineItems.length - 1;
                    final selected = _selected.contains(item.title);
                    return Column(
                      children: [
                        if (isPaid)
                          _FeeLineItem(item: item)
                        else
                          InkWell(
                            onTap: () => _toggleItem(item.title),
                            borderRadius: BorderRadius.circular(8),
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
                                Expanded(child: _FeeLineItem(item: item)),
                              ],
                            ),
                          ),
                        if (!isLast) Divider(height: 1, color: colors.border),
                      ],
                    );
                  }),
                ],

                const Gap(12),
                // Total row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Total Due',
                            style: typography.bodyLargeSemiBold.copyWith(color: colors.textPrimary)),
                      ),
                      Text(_sar(details.totalDue),
                          style: typography.h4.copyWith(color: colors.primary)),
                    ],
                  ),
                ),

                if (details.totalPaid > 0) ...[
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Paid',
                            style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
                      ),
                      Text(
                        '− ${_sar(details.totalPaid)}',
                        style: typography.bodyMediumSemiBold.copyWith(color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Balance',
                            style: typography.bodyLargeSemiBold.copyWith(color: colors.textPrimary)),
                      ),
                      Text(
                        _sar(details.balance),
                        style: typography.h4.copyWith(
                          color: details.balance > 0 ? Colors.red.shade600 : Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],

                if (!isPaid) ...[
                  const Gap(20),
                  // Payment input
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: typography.bodyLarge.copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Payment Amount (SAR)',
                      labelStyle: typography.bodyMedium.copyWith(color: colors.textSecondary),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('SAR', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF163D32))),
                      ),
                      prefixIconConstraints: const BoxConstraints(),
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
                                    details.summary.studentId, amount, _selected.toList());
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
                            Text(
                              processingPayment ? 'Processing Payment...' : 'Process Payment & Generate Invoice',
                              style: typography.bodyMediumSemiBold.copyWith(color: Colors.white),
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
                            'Fee fully paid for ${details.monthLabel}',
                            style: typography.bodyMedium.copyWith(color: Colors.green.shade700),
                          ),
                        ),
                      ],
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

class _FeeLineItem extends StatelessWidget {
  const _FeeLineItem({required this.item});
  final AccountLineItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(item.title,
                style: typography.bodyMedium.copyWith(color: colors.textPrimary)),
          ),
          Text(
            _sar(item.amount),
            style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary),
          ),
        ],
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
                Text(item.monthLabel,
                    style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
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
    return Dialog(
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
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _printInvoice(details, receipt),
                      icon: const Icon(LucideIcons.printer, size: 16),
                      label: const Text('Print Invoice'),
                      style: ElevatedButton.styleFrom(
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
    );
  }

  Future<void> _printInvoice(StudentAccountDetails details, ReceiptHistoryItem item) async {
    final pdf = pw.Document();
    final s = details.summary;
    final lineItems = item.lineItems.isNotEmpty ? item.lineItems : details.lineItems;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ANAS BIN MALIK MADRASA',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('FEE PAYMENT INVOICE', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Receipt info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice #: ${item.receiptNumber ?? "N/A"}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text(
                    'Date: ${item.paidOn != null ? DateFormat('dd MMM yyyy').format(item.paidOn!) : "N/A"}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Student info
              pw.Text('Student Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 6),
              _pdfRow('Name', s.fullName),
              _pdfRow('Admission No.', s.admissionNumber),
              _pdfRow('Classroom', s.classroom),
              _pdfRow('Guardian', s.guardianName),
              _pdfRow('Fee Month', item.monthLabel),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Line items
              pw.Text('Fee Breakdown', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),
              ...lineItems.map((li) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(li.title, style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('SAR ${li.amount.toStringAsFixed(0)}',
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 6),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Due', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('SAR ${item.totalDue.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text('SAR ${item.totalPaid.toStringAsFixed(0)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Status
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text('✓  PAID',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, color: PdfColors.green800, fontSize: 13)),
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Center(
                child: pw.Text(
                  'Thank you! May Allah bless you.',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600, fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text('$label:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
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
                _InvoiceRow(label: 'Fee Month', value: receipt.monthLabel),
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
                _InvoiceRow(label: 'Total Due', value: _sar(receipt.totalDue)),
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
    ref.invalidate(accountSummariesProvider);
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
    if (amount == null || amount <= 0) return;
    try {
      await ref.read(accountRepositoryProvider).processPayment(
          studentId: studentId, amount: amount, monthLabel: m.monthLabel);
      _refresh(ref);
      if (context.mounted) _snack(context, 'Collected ${_sar(amount)} for ${m.monthLabel}');
    } catch (e) {
      if (context.mounted) _snack(context, e.toString().replaceFirst('Exception: ', ''), ok: false);
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
    if (amount == null || amount <= 0) return;
    try {
      await ref.read(accountRepositoryProvider)
          .processPayment(studentId: studentId, amount: amount, allocate: 'oldest');
      _refresh(ref);
      if (context.mounted) _snack(context, 'Applied ${_sar(amount)} oldest-first');
    } catch (e) {
      if (context.mounted) _snack(context, e.toString().replaceFirst('Exception: ', ''), ok: false);
    }
  }

  Future<void> _toggleWaive(BuildContext context, WidgetRef ref, LedgerMonth m) async {
    try {
      await ref.read(accountRepositoryProvider).waiveMonth(studentId, m.monthLabel, !m.waived);
      _refresh(ref);
      if (context.mounted) _snack(context, m.waived ? '${m.monthLabel} restored' : '${m.monthLabel} waived');
    } catch (e) {
      if (context.mounted) _snack(context, e.toString().replaceFirst('Exception: ', ''), ok: false);
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
        error: (e, _) => Text('Ledger error: $e', style: typography.bodySmall),
        data: (ledger) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(LucideIcons.history, color: colors.primary, size: 20),
                const Gap(10),
                Text('Fee Ledger', style: typography.h4),
                const Spacer(),
                if (ledger.arrears > 0)
                  ElevatedButton.icon(
                    onPressed: () => _settleArrears(context, ref, ledger.arrears),
                    icon: const Icon(LucideIcons.wallet, size: 15),
                    label: const Text('Settle Arrears'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
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
