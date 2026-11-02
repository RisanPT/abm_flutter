import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/money.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:abm_madrasa/features/finance/data/finance_repository.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

IconData _getCategoryIcon(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('salary') || lower.contains('payroll')) {
    return LucideIcons.userCheck;
  }
  if (lower.contains('utilit') || lower.contains('electric') || lower.contains('water') || lower.contains('power')) {
    return LucideIcons.zap;
  }
  if (lower.contains('rent') || lower.contains('building') || lower.contains('property')) {
    return LucideIcons.home;
  }
  if (lower.contains('office') || lower.contains('paper') || lower.contains('suppl') || lower.contains('stationery')) {
    return LucideIcons.fileText;
  }
  if (lower.contains('maint') || lower.contains('repair')) {
    return LucideIcons.wrench;
  }
  if (lower.contains('book') || lower.contains('material')) {
    return LucideIcons.bookOpen;
  }
  if (lower.contains('transport') || lower.contains('bus') || lower.contains('fuel')) {
    return LucideIcons.bus;
  }
  return LucideIcons.receipt;
}

Color _getCategoryColor(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('salary') || lower.contains('payroll')) {
    return const Color(0xFF1B3D2F);
  }
  if (lower.contains('utilit') || lower.contains('electric') || lower.contains('power')) {
    return const Color(0xFFD97706);
  }
  if (lower.contains('rent')) {
    return const Color(0xFF2563EB);
  }
  if (lower.contains('office') || lower.contains('paper')) {
    return const Color(0xFF7C3AED);
  }
  if (lower.contains('maint')) {
    return const Color(0xFF0D9488);
  }
  return const Color(0xFF4B5563);
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _categoriesProvider = FutureProvider<List<FinanceCategory>>((ref) async {
  return ref.watch(madrassaFinanceRepositoryProvider).getCategories();
});

// P&L report keyed by month ('yyyy-MM'), scoped to the selected institute.
final _pnlProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, month) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref.watch(madrassaFinanceRepositoryProvider).getPnlReport(month: month, instituteId: instituteId);
});

class _ExpensesQuery {
  const _ExpensesQuery(this.month, this.category, this.page);
  final String month;
  final String? category;
  final int page;
  @override
  bool operator ==(Object other) =>
      other is _ExpensesQuery &&
      month == other.month &&
      category == other.category &&
      page == other.page;
  @override
  int get hashCode => Object.hash(month, category, page);
}

final _expensesProvider =
    FutureProvider.autoDispose.family<PagedResult<MadrassaExpense>, _ExpensesQuery>((ref, q) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref.watch(madrassaFinanceRepositoryProvider).getExpensesPage(
        category: q.category,
        month: q.month,
        instituteId: instituteId,
        page: q.page,
        limit: 25,
      );
});

// ─── Finance Screen ────────────────────────────────────────────────────────────

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  DateTime _selectedMonth = DateTime.now();
  String? _selectedCategory;
  int _tab = 0; // 0 = Expenditure, 1 = Income
  int _page = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final text = _searchCtrl.text.trim();
      if (text != _searchQuery) {
        setState(() => _searchQuery = text);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
      _page = 1;
    });
  }

  void _goToCurrentMonth() {
    setState(() {
      _selectedMonth = DateTime.now();
      _page = 1;
    });
  }

  Future<void> _exportFinanceReportPdf() async {
    try {
      final repository = ref.read(madrassaFinanceRepositoryProvider);
      final expenses = await repository.getExpenses(
        category: _selectedCategory,
        month: DateFormat('yyyy-MM').format(_selectedMonth),
        instituteId: ref.read(selectedInstituteProvider).id,
      );
      
      final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text('Madrassa Expenditure Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}'),
            pw.SizedBox(height: 8),
            pw.Text('Total Expenditure: SAR ${total.toStringAsFixed(2)}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Category', 'Description', 'Amount'],
              data: expenses.map((e) => [
                DateFormat('dd MMM yyyy').format(e.date),
                e.category,
                e.description.isEmpty ? 'Madrassa expense entry' : e.description,
                'SAR ${e.amount.toStringAsFixed(2)}',
              ]).toList(),
            ),
          ],
        ),
      );
      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF. ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _confirmDeleteExpense(MadrassaExpense expense) async {
    final isSalary = expense.category == 'Monthly Salary' || expense.category == 'Salary';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red.shade600, size: 22),
            const Gap(10),
            Text(isSalary ? 'Delete Salary Entry' : 'Delete Expense'),
          ],
        ),
        content: Text(
          isSalary
              ? 'Delete the salary disbursement of ${sar(expense.amount)} for ${expense.teacherName ?? 'this teacher'}?\n\nThis will remove the transaction from accounts and reopen the teacher in Payroll to allow re-processing.'
              : 'Delete this expense record of ${sar(expense.amount)} (${expense.category})?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(madrassaFinanceRepositoryProvider).deleteExpense(expense.id);
      ref.invalidate(_expensesProvider);
      ref.invalidate(_pnlProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense entry deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete expense: ${friendlyErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authControllerProvider).asData?.value;
    final allowedModules = user != null ? ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role) : <String>{};
    final canEdit = user?.role.canEditFinance(allowedModules) ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          AbmGradientHeader(
            title: 'Madrassa Finance',
            leading: const SizedBox(width: 40),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick shortcut to Payroll
                FilledButton.tonalIcon(
                  onPressed: () => context.go(RouteNames.payroll),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(LucideIcons.wallet, size: 16, color: Color(0xFFD6B64C)),
                  label: const Text('Payroll', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const Gap(8),
                if (canEdit) ...[
                  AbmHeaderIconButton(icon: LucideIcons.tag, onTap: _showCategoryManager, tooltip: 'Manage Categories'),
                  const Gap(6),
                ],
                AbmHeaderIconButton(icon: LucideIcons.calendar, onTap: _pickMonth, tooltip: 'Select Month'),
                const Gap(6),
                AbmHeaderIconButton(icon: LucideIcons.download, onTap: _exportFinanceReportPdf, tooltip: 'Export PDF'),
              ],
            ),
          ),
          // Interactive Month & Tab Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                // Month Switcher
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, size: 18),
                        onPressed: () => _changeMonth(-1),
                        tooltip: 'Previous Month',
                        visualDensity: VisualDensity.compact,
                      ),
                      InkWell(
                        onTap: _pickMonth,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.calendar, size: 16, color: colors.primary),
                              const Gap(8),
                              Text(
                                DateFormat('MMMM yyyy').format(_selectedMonth),
                                style: context.typography.bodyMediumSemiBold.copyWith(color: colors.primary),
                              ),
                              const Gap(4),
                              Icon(LucideIcons.chevronDown, size: 14, color: colors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 18),
                        onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
                        tooltip: 'Next Month',
                        visualDensity: VisualDensity.compact,
                      ),
                      if (!_isCurrentMonth) ...[
                        const Gap(4),
                        TextButton.icon(
                          onPressed: _goToCurrentMonth,
                          icon: const Icon(LucideIcons.rotateCcw, size: 12),
                          label: const Text('Current', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(16),
                // Tab Switcher
                Expanded(
                  child: _FinanceTabs(
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0 ? _buildExpensesBody(context) : _buildIncomeBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeBody(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final async = ref.watch(_pnlProvider(DateFormat('yyyy-MM').format(_selectedMonth)));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
      data: (data) {
        final totalIncome = (data['totalIncomes'] as num?)?.toDouble() ?? 0;
        final totalExpense = (data['totalExpenses'] as num?)?.toDouble() ?? 0;
        final net = (data['netBalance'] as num?)?.toDouble() ?? (totalIncome - totalExpense);
        final incomes = (data['incomes'] as List?) ?? [];
        final collected = incomes.where((e) => ((e['amount'] as num?) ?? 0) > 0).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _IncomeStatCard(
                      label: 'Total Fee Income',
                      value: totalIncome,
                      tint: colors.primary,
                      icon: LucideIcons.trendingUp,
                      subtitle: DateFormat('MMMM yyyy').format(_selectedMonth),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: _IncomeStatCard(
                      label: 'Net Balance',
                      value: net,
                      tint: net >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      icon: LucideIcons.scale,
                      subtitle: 'Fee Income − Total Expenditure',
                    ),
                  ),
                ],
              ),
              const Gap(24),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fee Collections', style: typography.h4),
                      Text('${collected.length} collections recorded this month',
                          style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
              const Gap(16),
              Expanded(
                child: collected.isEmpty
                    ? _buildEmptyState(context, 'No fee collections recorded for this month')
                    : ListView.separated(
                        itemCount: collected.length,
                        separatorBuilder: (_, _) => const Gap(10),
                        itemBuilder: (context, index) => _IncomeCard(row: Map<String, dynamic>.from(collected[index])),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesBody(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final user = ref.watch(authControllerProvider).asData?.value;
    final allowedModules = user != null ? ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role) : <String>{};
    final canEdit = user?.role.canEditFinance(allowedModules) ?? false;
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);

    final async = ref.watch(_expensesProvider(_ExpensesQuery(monthStr, _selectedCategory, _page)));
    final pnlAsync = ref.watch(_pnlProvider(monthStr));
    final categoriesAsync = ref.watch(_categoriesProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
      data: (pagedResult) {
        // Financial metrics from P&L report
        final pnlData = pnlAsync.asData?.value ?? {};
        final totalExpense = (pnlData['totalExpenses'] as num?)?.toDouble() ??
            pagedResult.items.fold<double>(0, (sum, e) => sum + e.amount);
        final totalIncome = (pnlData['totalIncomes'] as num?)?.toDouble() ?? 0;
        final netBalance = (pnlData['netBalance'] as num?)?.toDouble() ?? (totalIncome - totalExpense);
        
        final expenseSummary = (pnlData['expenseSummary'] as Map<String, dynamic>?) ?? {};
        final salaryTotal = (expenseSummary['Monthly Salary'] as num?)?.toDouble() ?? 0;
        final operationalTotal = (totalExpense - salaryTotal).clamp(0.0, double.infinity);
        
        final allExpensesList = (pnlData['expenses'] as List?) ?? [];
        final salaryDisbursementsCount = allExpensesList
            .where((e) => e['category'] == 'Monthly Salary' || e['category'] == 'Salary')
            .length;

        // Apply client-side search filter
        final displayItems = pagedResult.items.where((e) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final teacher = (e.teacherName ?? '').toLowerCase();
          final desc = e.description.toLowerCase();
          final cat = e.category.toLowerCase();
          final emp = (e.employeeId ?? '').toLowerCase();
          return teacher.contains(q) || desc.contains(q) || cat.contains(q) || emp.contains(q);
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3-Stat Executive Dashboard Overview
              _buildExecutiveMetrics(
                context: context,
                totalExpense: totalExpense,
                salaryExpense: salaryTotal,
                operationalExpense: operationalTotal,
                salaryCount: salaryDisbursementsCount,
                totalIncome: totalIncome,
                netBalance: netBalance,
              ),
              const Gap(20),

              // Staff Salary & Payroll Integration Banner
              _buildPayrollLinkBanner(context, salaryDisbursementsCount, salaryTotal),
              const Gap(20),

              // Category Pills & Search Bar Row
              Row(
                children: [
                  // Search Box
                  SizedBox(
                    width: 260,
                    height: 40,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search expenses, teachers...',
                        hintStyle: typography.bodySmall.copyWith(color: colors.textSecondary),
                        prefixIcon: const Icon(LucideIcons.search, size: 16),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () => _searchCtrl.clear(),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: colors.white,
                      ),
                      style: typography.bodyMedium,
                    ),
                  ),
                  const Gap(12),
                  // Category Filter Chips
                  Expanded(
                    child: categoriesAsync.maybeWhen(
                      data: (categories) => _buildCategoryFilterChips(
                        context,
                        categories.where((c) => c.type == 'Expense').toList(),
                        salaryDisbursementsCount,
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ),
                  const Gap(12),
                  if (canEdit)
                    ElevatedButton.icon(
                      onPressed: _showAddExpenseDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const Gap(16),

              // List of Expenses
              Expanded(
                child: displayItems.isEmpty
                    ? _buildEmptyState(
                        context,
                        _selectedCategory == 'Monthly Salary'
                            ? 'No teacher salaries recorded for this month yet.\nClick "Manage Payroll" to process monthly teacher salaries.'
                            : 'No expenses matching the criteria for this month.',
                        actionButton: _selectedCategory == 'Monthly Salary'
                            ? ElevatedButton.icon(
                                onPressed: () => context.go(RouteNames.payroll),
                                icon: const Icon(LucideIcons.wallet, size: 16),
                                label: const Text('Go to Payroll'),
                              )
                            : null,
                      )
                    : ListView.builder(
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final expense = displayItems[index];
                          final isSalary = expense.category == 'Monthly Salary' || expense.category == 'Salary';
                          return _ExpenseCard(
                            expense: expense,
                            canDelete: canEdit,
                            onDelete: () => _confirmDeleteExpense(expense),
                            onEdit: (canEdit && !isSalary) ? () => _showEditExpenseDialog(expense) : null,
                            onOpenPayroll: () => context.go(RouteNames.payroll),
                          );
                        },
                      ),
              ),
              if (pagedResult.totalPages > 1) ...[
                const Gap(12),
                AbmPaginationBar(
                  page: pagedResult.page,
                  totalPages: pagedResult.totalPages,
                  total: pagedResult.total,
                  onPage: (p) => setState(() => _page = p),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExecutiveMetrics({
    required BuildContext context,
    required double totalExpense,
    required double salaryExpense,
    required double operationalExpense,
    required int salaryCount,
    required double totalIncome,
    required double netBalance,
  }) {
    final colors = context.colors;
    final typography = context.typography;

    // Card 1: Total Expenditure
    final expenditureCard = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1B3D2F), const Color(0xFF265240)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3D2F).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.trendingDown, color: Colors.white, size: 16),
              ),
              const Gap(10),
              Text('TOTAL EXPENDITURE',
                  style: typography.bodySmall.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6B64C).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  DateFormat('MMM yyyy').format(_selectedMonth),
                  style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Gap(12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(sar(totalExpense),
                style: typography.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const Gap(8),
          Row(
            children: [
              Text(
                'Operational: ${sar(operationalExpense)}',
                style: typography.bodySmall.copyWith(color: Colors.white70),
              ),
              const Text('  •  ', style: TextStyle(color: Colors.white38)),
              Text(
                'Salaries: ${sar(salaryExpense)}',
                style: typography.bodySmall.copyWith(color: const Color(0xFFD6B64C), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );

    // Card 2: Staff Salaries & Payroll (Clickable link to Payroll)
    final payrollCard = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(RouteNames.payroll),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD6B64C).withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD6B64C).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6B64C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.userCheck, color: Color(0xFF92400E), size: 16),
                  ),
                  const Gap(10),
                  Text('STAFF PAYROLL',
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      )),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Payroll',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          )),
                      const Gap(2),
                      Icon(LucideIcons.arrowUpRight, size: 14, color: colors.primary),
                    ],
                  ),
                ],
              ),
              const Gap(12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(sar(salaryExpense),
                    style: typography.h2.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
              ),
              const Gap(8),
              Text(
                salaryCount > 0
                    ? '$salaryCount Staff Disbursements Recorded'
                    : 'No salary entries recorded yet',
                style: typography.bodySmall.copyWith(
                  color: salaryCount > 0 ? const Color(0xFF047857) : colors.textSecondary,
                  fontWeight: salaryCount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Card 3: Net Cash Position
    final netCard = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (netBalance >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.scale,
                  color: netBalance >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  size: 16,
                ),
              ),
              const Gap(10),
              Text('NET BALANCE',
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (netBalance >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  netBalance >= 0 ? 'Surplus' : 'Deficit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: netBalance >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${netBalance >= 0 ? '+' : ''}${sar(netBalance)}',
              style: typography.h2.copyWith(
                color: netBalance >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(8),
          Text(
            'Inflow: ${sar(totalIncome)}  •  Outflow: ${sar(totalExpense)}',
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );

    if (context.isMobile) {
      return Column(
        children: [
          expenditureCard,
          const Gap(12),
          payrollCard,
          const Gap(12),
          netCard,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: expenditureCard),
        const Gap(16),
        Expanded(child: payrollCard),
        const Gap(16),
        Expanded(child: netCard),
      ],
    );
  }

  Widget _buildPayrollLinkBanner(BuildContext context, int salaryCount, double salaryTotal) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6B64C).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3D2F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.users, color: Color(0xFFD6B64C), size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Teacher & Staff Payroll System',
                      style: typography.bodyLargeSemiBold.copyWith(color: colors.textPrimary),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B3D2F).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Integrated with Finance',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  salaryCount > 0
                      ? '$salaryCount teacher salaries (${sar(salaryTotal)}) processed from timetable attendance for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.'
                      : 'Calculate attendance-adjusted monthly teacher compensation and automatically book disbursements into Finance.',
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const Gap(16),
          FilledButton.icon(
            onPressed: () => context.go(RouteNames.payroll),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B3D2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(LucideIcons.arrowUpRight, size: 16, color: Color(0xFFD6B64C)),
            label: const Text('Manage Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChips(
    BuildContext context,
    List<FinanceCategory> categories,
    int salaryCount,
  ) {
    final colors = context.colors;

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      IconData? icon,
      Color? iconColor,
      int? count,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : (iconColor ?? colors.textSecondary),
                ),
                const Gap(6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? Colors.white : colors.textPrimary,
                ),
              ),
              if (count != null && count > 0) ...[
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withValues(alpha: 0.25) : colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : colors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            label: 'All Expenses',
            selected: _selectedCategory == null,
            icon: LucideIcons.layers,
            onTap: () => setState(() {
              _selectedCategory = null;
              _page = 1;
            }),
          ),
          const Gap(8),
          chip(
            label: 'Staff Salaries',
            selected: _selectedCategory == 'Monthly Salary',
            icon: LucideIcons.userCheck,
            iconColor: const Color(0xFFD6B64C),
            count: salaryCount > 0 ? salaryCount : null,
            onTap: () => setState(() {
              _selectedCategory = _selectedCategory == 'Monthly Salary' ? null : 'Monthly Salary';
              _page = 1;
            }),
          ),
          for (final cat in categories) ...[
            if (cat.name != 'Monthly Salary') ...[
              const Gap(8),
              chip(
                label: cat.name,
                selected: _selectedCategory == cat.name,
                icon: _getCategoryIcon(cat.name),
                iconColor: _getCategoryColor(cat.name),
                onTap: () => setState(() {
                  _selectedCategory = _selectedCategory == cat.name ? null : cat.name;
                  _page = 1;
                }),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, {Widget? actionButton}) {
    final colors = context.colors;
    final typography = context.typography;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.inbox, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
            ),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: typography.bodyMedium.copyWith(color: colors.textSecondary, height: 1.4),
            ),
            if (actionButton != null) ...[
              const Gap(16),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
        _page = 1;
      });
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddExpenseDialog(
        currentMonth: _selectedMonth,
        onSuccess: () {
          ref.invalidate(_expensesProvider);
          ref.invalidate(_pnlProvider);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _showEditExpenseDialog(MadrassaExpense expense) {
    showDialog(
      context: context,
      builder: (context) => _AddExpenseDialog(
        currentMonth: _selectedMonth,
        expense: expense,
        onSuccess: () {
          ref.invalidate(_expensesProvider);
          ref.invalidate(_pnlProvider);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _showCategoryManager() {
    showDialog(
      context: context,
      builder: (context) => _CategoryManagerDialog(
        onChanged: () => ref.invalidate(_categoriesProvider),
      ),
    );
  }
}

// ─── Expense Card ─────────────────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.canDelete,
    required this.onDelete,
    required this.onOpenPayroll,
    this.onEdit,
  });

  final MadrassaExpense expense;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onOpenPayroll;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isSalary = expense.category == 'Monthly Salary' || expense.category == 'Salary';

    if (isSalary) {
      // Premium Staff Salary Disbursement Card
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6B64C).withValues(alpha: 0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B3D2F).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Teacher / Salary Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B3D2F), Color(0xFF265240)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.userCheck, color: Color(0xFFD6B64C), size: 20),
            ),
            const Gap(16),
            // Teacher Details & Attendance Note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3D2F).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF1B3D2F).withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'TEACHER SALARY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B3D2F),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (expense.employeeId != null && expense.employeeId!.isNotEmpty) ...[
                        const Gap(6),
                        Text(
                          '#${expense.employeeId}',
                          style: typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Gap(8),
                      Text(
                        expense.teacherName ?? 'Teacher',
                        style: typography.bodyLargeSemiBold.copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    expense.description.isNotEmpty ? expense.description : 'Monthly attendance salary disbursement',
                    style: typography.bodySmall.copyWith(color: colors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 12, color: colors.textSecondary),
                      const Gap(4),
                      Text(
                        DateFormat('dd MMM yyyy').format(expense.date),
                        style: typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(16),
            // Amount & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  sar(expense.amount),
                  style: typography.h4.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onOpenPayroll,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Payroll',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                            const Gap(2),
                            Icon(LucideIcons.arrowUpRight, size: 12, color: colors.primary),
                          ],
                        ),
                      ),
                    ),
                    if (canDelete) ...[
                      const Gap(6),
                      IconButton(
                        icon: Icon(LucideIcons.trash2, size: 15, color: Colors.red.shade600),
                        onPressed: onDelete,
                        tooltip: 'Delete salary disbursement',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Standard Operational Expense Card
    final catColor = _getCategoryColor(expense.category);
    final catIcon = _getCategoryIcon(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(catIcon, color: catColor, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        expense.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (expense.accountSegment != null && expense.accountSegment!.isNotEmpty) ...[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          expense.accountSegment!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(4),
                Text(
                  expense.description.isEmpty ? 'Madrassa expense entry' : expense.description,
                  style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Text(
                  DateFormat('dd MMM yyyy').format(expense.date),
                  style: typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sar(expense.amount),
                style: typography.h4.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (canDelete) ...[
                const Gap(6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(LucideIcons.pencil, size: 15, color: colors.primary),
                        onPressed: onEdit,
                        tooltip: 'Edit expense',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    const Gap(4),
                    IconButton(
                      icon: Icon(LucideIcons.trash2, size: 15, color: Colors.red.shade600),
                      onPressed: onDelete,
                      tooltip: 'Delete expense',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Add Expense Dialog ────────────────────────────────────────────────────────

class _AddExpenseDialog extends ConsumerStatefulWidget {
  const _AddExpenseDialog({required this.currentMonth, required this.onSuccess, this.expense});
  final DateTime currentMonth;
  final VoidCallback onSuccess;
  final MadrassaExpense? expense;

  @override
  ConsumerState<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<_AddExpenseDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _accountSegment;
  late DateTime _selectedDate;
  bool _isSaving = false;

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _selectedDate = e?.date ?? widget.currentMonth;
    if (e != null) {
      _amountController.text = e.amount % 1 == 0 ? e.amount.toStringAsFixed(0) : e.amount.toString();
      _descriptionController.text = e.description;
      _selectedCategory = e.category;
      _accountSegment = e.accountSegment;
    } else {
      final currentInst = ref.read(selectedInstituteProvider);
      if (currentInst.name.toUpperCase().contains('CRE') || currentInst.id == '6a37837e5ac32f68075f0108') {
        _accountSegment = 'CRE';
      } else {
        _accountSegment = 'Madrasa';
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_categoriesProvider);

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Expense' : 'Add Madrassa Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _accountSegment ?? 'Madrasa',
              decoration: const InputDecoration(labelText: 'Account Segment / Institute', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Madrasa', child: Text('Madrasa')),
                DropdownMenuItem(value: 'CRE', child: Text('CRE (Center for Religious Education)')),
                DropdownMenuItem(value: 'Organization', child: Text('Organization')),
              ],
              onChanged: (v) => setState(() => _accountSegment = v),
            ),
            const Gap(16),
            categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading categories. ${friendlyErrorMessage(e)}'),
              data: (categories) {
                final names = categories.where((c) => c.type == 'Expense').map((c) => c.name).toList();
                // Keep the edited expense's category selectable even if it's no longer a listed category.
                if (_selectedCategory != null && !names.contains(_selectedCategory)) names.insert(0, _selectedCategory!);
                _selectedCategory ??= names.isNotEmpty ? names.first : null;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: names.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                );
              },
            ),
            if (_selectedCategory == 'Monthly Salary') ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3D2F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD6B64C).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.lightbulb, size: 18, color: Color(0xFFD6B64C)),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        'Teacher salaries can be calculated and recorded automatically in the Payroll module.',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    const Gap(8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go(RouteNames.payroll);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Go to Payroll', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            const Gap(16),
            ABMTextField(
              label: 'Amount (SAR)',
              controller: _amountController,
              keyboardType: TextInputType.number,
              hint: 'Enter amount',
            ),
            const Gap(16),
            ABMTextField(
              label: 'Description',
              controller: _descriptionController,
              hint: 'E.g. Monthly rent, Utility bills...',
            ),
            const Gap(16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.calendar, size: 18),
                ),
                child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving
              ? (_isEdit ? 'Updating...' : 'Saving...')
              : (_isEdit ? 'Update Expense' : 'Save Expense')),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;
    if (_selectedCategory == null) return;

    final user = ref.read(authControllerProvider).asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated')),
      );
      return;
    }

    final activeInstitute = ref.read(selectedInstituteProvider);

    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await ref.read(madrassaFinanceRepositoryProvider).updateExpense(
              id: widget.expense!.id,
              category: _selectedCategory!,
              amount: amount,
              description: _descriptionController.text,
              date: _selectedDate,
              instituteId: widget.expense!.instituteId ?? activeInstitute.id,
              accountSegment: _accountSegment,
            );
      } else {
        await ref.read(madrassaFinanceRepositoryProvider).addExpense(
              category: _selectedCategory!,
              amount: amount,
              description: _descriptionController.text,
              processedBy: user.id,
              date: _selectedDate,
              instituteId: activeInstitute.id,
              accountSegment: _accountSegment,
            );
      }
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─── Category Manager Dialog ───────────────────────────────────────────────────

class _CategoryManagerDialog extends ConsumerStatefulWidget {
  const _CategoryManagerDialog({required this.onChanged});
  final VoidCallback onChanged;

  @override
  ConsumerState<_CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends ConsumerState<_CategoryManagerDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final categoriesAsync = ref.watch(_categoriesProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.tag, size: 20, color: colors.primary),
          const Gap(8),
          Text('Manage Categories', style: typography.h4),
          const Spacer(),
          IconButton(
            onPressed: _showAddCategoryDialog,
            icon: Icon(LucideIcons.plus, color: colors.primary),
            tooltip: 'Add Category',
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.9 < 400 ? MediaQuery.sizeOf(context).width * 0.9 : 400,
        height: 420,
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
          data: (categories) {
            if (categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.tag, size: 40, color: colors.textSecondary.withValues(alpha: 0.4)),
                    const Gap(12),
                    Text('No categories yet', style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, _) => Divider(color: colors.border, height: 1),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cat.isSystem ? LucideIcons.lock : LucideIcons.tag,
                      size: 16,
                      color: colors.primary,
                    ),
                  ),
                   title: Row(
                    children: [
                      Text(cat.name, style: typography.bodyMedium),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (cat.type == 'Income' ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cat.type,
                          style: TextStyle(
                            fontSize: 10,
                            color: cat.type == 'Income' ? Colors.green.shade800 : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cat.description.isNotEmpty)
                        Text(cat.description, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                      if (cat.type == 'Income')
                        Text('Default Amount: SAR ${cat.amount.toStringAsFixed(0)}', 
                             style: typography.bodySmall.copyWith(color: colors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: cat.isSystem
                      ? Tooltip(
                          message: 'System category',
                          child: Icon(LucideIcons.shieldCheck, size: 16, color: colors.textSecondary),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(LucideIcons.pencil, size: 16, color: colors.primary),
                              onPressed: () => _showEditCategoryDialog(cat),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(LucideIcons.trash2, size: 16, color: Colors.red.shade600),
                              onPressed: _loading ? null : () => _deleteCategory(cat),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryFormDialog(
        title: 'Add Category',
        onSave: (name, description, type, amount) async {
          await ref.read(madrassaFinanceRepositoryProvider).createCategory(
                name: name,
                description: description,
                type: type,
                amount: amount,
              );
          ref.invalidate(_categoriesProvider);
          widget.onChanged();
        },
      ),
    );
  }

  void _showEditCategoryDialog(FinanceCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryFormDialog(
        title: 'Edit Category',
        initialName: category.name,
        initialDescription: category.description,
        initialType: category.type,
        initialAmount: category.amount,
        onSave: (name, description, type, amount) async {
          await ref.read(madrassaFinanceRepositoryProvider).updateCategory(
                id: category.id,
                name: name,
                description: description,
                type: type,
                amount: amount,
              );
          ref.invalidate(_categoriesProvider);
          widget.onChanged();
        },
      ),
    );
  }

  Future<void> _deleteCategory(FinanceCategory category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${category.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(madrassaFinanceRepositoryProvider).deleteCategory(category.id);
      ref.invalidate(_categoriesProvider);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Category Form Dialog ──────────────────────────────────────────────────────

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({
    required this.title,
    required this.onSave,
    this.initialName,
    this.initialDescription,
    this.initialType,
    this.initialAmount,
  });
  final String title;
  final String? initialName;
  final String? initialDescription;
  final String? initialType;
  final double? initialAmount;
  final Future<void> Function(String name, String description, String type, double amount) onSave;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _amountController;
  late String _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descController = TextEditingController(text: widget.initialDescription ?? '');
    _amountController = TextEditingController(text: widget.initialAmount?.toStringAsFixed(0) ?? '0');
    _type = widget.initialType ?? 'Expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ABMTextField(
              label: 'Category Name',
              controller: _nameController,
              hint: 'e.g. Electricity Bills',
            ),
            const Gap(16),
            ABMTextField(
              label: 'Description (optional)',
              controller: _descController,
              hint: 'Brief description',
            ),
            const Gap(16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Account Type', border: OutlineInputBorder()),
              items: ['Expense', 'Income']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            if (_type == 'Income') ...[
              const Gap(16),
              ABMTextField(
                label: 'Default Amount (SAR)',
                controller: _amountController,
                keyboardType: TextInputType.number,
                hint: 'e.g. 1000',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name cannot be empty')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      await widget.onSave(name, _descController.text.trim(), _type, amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Income tab widgets ─────────────────────────────────────────────────────

class _FinanceTabs extends StatelessWidget {
  const _FinanceTabs({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget tab(int i, String label, IconData icon) {
      final active = index == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: active ? Colors.white : colors.textSecondary),
                const Gap(7),
                Text(label,
                    style: context.typography.bodyMediumSemiBold
                        .copyWith(color: active ? Colors.white : colors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(children: [
        tab(0, 'Expenditure', LucideIcons.trendingDown),
        tab(1, 'Income', LucideIcons.trendingUp),
      ]),
    );
  }
}

class _IncomeStatCard extends StatelessWidget {
  const _IncomeStatCard({
    required this.label,
    required this.value,
    required this.tint,
    required this.icon,
    required this.subtitle,
  });
  final String label, subtitle;
  final double value;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [tint, tint.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white70, size: 18),
            const Gap(8),
            Text(label, style: typography.bodyMedium.copyWith(color: Colors.white70)),
          ]),
          const Gap(8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(sar(value), style: typography.h2.copyWith(color: Colors.white)),
          ),
          const Gap(4),
          Text(subtitle, style: typography.bodySmall.copyWith(color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final name = (row['studentName'] ?? 'Fee payment').toString();
    final adm = (row['admissionNumber'] ?? '').toString();
    final grade = (row['grade'] ?? '').toString();
    final month = (row['monthLabel'] ?? '').toString();
    final amount = ((row['amount'] as num?) ?? 0).toDouble();
    final receipt = (row['receiptNumber'] ?? '').toString();
    final paidOn = row['paidOn'] != null ? DateTime.tryParse(row['paidOn'].toString()) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(LucideIcons.banknote, color: colors.primary, size: 20),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: typography.bodyMediumSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                const Gap(2),
                Text(
                  [
                    if (adm.isNotEmpty) 'ID $adm',
                    if (grade.isNotEmpty) grade,
                    if (month.isNotEmpty) month,
                    if (receipt.isNotEmpty) receipt,
                  ].join('  •  '),
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+ ${sar(amount)}',
                  style: typography.bodyMediumSemiBold.copyWith(color: context.colors.green)),
              if (paidOn != null)
                Text(DateFormat('dd MMM').format(paidOn),
                    style: typography.bodySmall.copyWith(color: colors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
