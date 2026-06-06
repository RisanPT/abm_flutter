import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/finance/data/finance_repository.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


// ─── Providers ────────────────────────────────────────────────────────────────

final _categoriesProvider = FutureProvider<List<FinanceCategory>>((ref) async {
  return ref.watch(madrassaFinanceRepositoryProvider).getCategories();
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

  Future<void> _exportFinanceReportPdf() async {
    try {
      final repository = ref.read(madrassaFinanceRepositoryProvider);
      final expenses = await repository.getExpenses(
        category: _selectedCategory,
        month: DateFormat('yyyy-MM').format(_selectedMonth),
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
            pw.Text('Total Expenditure: INR ₹${total.toStringAsFixed(2)}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Category', 'Description', 'Amount'],
              data: expenses.map((e) => [
                DateFormat('dd MMM yyyy').format(e.date),
                e.category,
                e.description.isEmpty ? 'Madrassa expense entry' : e.description,
                '₹${e.amount.toStringAsFixed(2)}',
              ]).toList(),
            ),
          ],
        ),
      );
      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final user = ref.watch(authControllerProvider).asData?.value;
    final canEdit = user?.role.canEditFinance ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Madrassa Finance', style: typography.h3),
        actions: [
          if (canEdit)
            IconButton(
              onPressed: _showCategoryManager,
              icon: const Icon(LucideIcons.tag),
              tooltip: 'Manage Categories',
            ),
          IconButton(
            onPressed: _pickMonth,
            icon: const Icon(LucideIcons.calendar),
            tooltip: 'Select Month',
          ),
          IconButton(
            onPressed: _exportFinanceReportPdf,
            icon: const Icon(LucideIcons.download),
            tooltip: 'Export PDF',
          ),
          const Gap(8),
        ],
      ),
      body: _buildExpensesBody(context),
    );
  }

  Widget _buildExpensesBody(BuildContext context) {
    final typography = context.typography;
    final user = ref.watch(authControllerProvider).asData?.value;
    final canEdit = user?.role.canEditFinance ?? false;
    final Future<List<MadrassaExpense>> expensesFuture =
        ref.read(madrassaFinanceRepositoryProvider).getExpenses(
              category: _selectedCategory,
              month: DateFormat('yyyy-MM').format(_selectedMonth),
            );
    return FutureBuilder<List<MadrassaExpense>>(
      future: expensesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final expenses = snapshot.data ?? [];
        final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(context, total, expenses.length),
              const Gap(32),
              Row(
                children: [
                  Text('Expenditure List', style: typography.h4),
                  const Spacer(),
                  if (canEdit)
                    ElevatedButton.icon(
                      onPressed: _showAddExpenseDialog,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Add Expense'),
                    ),
                ],
              ),
              const Gap(16),
              Expanded(
                child: expenses.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return _ExpenseCard(expense: expense);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(BuildContext context, double total, int count) {
    final colors = context.colors;
    final typography = context.typography;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Expenditure',
                  style: typography.bodyMedium.copyWith(color: Colors.white70),
                ),
                const Gap(8),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: typography.h2.copyWith(color: Colors.white),
                ),
                const Gap(4),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: typography.bodySmall.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
        const Gap(16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Count',
                  style: typography.bodyMedium.copyWith(color: colors.textSecondary),
                ),
                const Gap(8),
                Text(
                  '$count',
                  style: typography.h2.copyWith(color: colors.primary),
                ),
                const Gap(4),
                Text(
                  'Entries recorded',
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.book, size: 48, color: context.colors.textSecondary.withValues(alpha: 0.3)),
          const Gap(16),
          Text(
            'No expenses recorded for this month',
            style: context.typography.bodyLarge.copyWith(color: context.colors.textSecondary),
          ),
        ],
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
      setState(() => _selectedMonth = picked);
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddExpenseDialog(
        currentMonth: _selectedMonth,
        onSuccess: () => setState(() {}),
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
  const _ExpenseCard({required this.expense});
  final MadrassaExpense expense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              expense.category == 'Monthly Salary' ? LucideIcons.userCheck : LucideIcons.receipt,
              color: colors.primary,
              size: 20,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.category, style: typography.bodyLargeSemiBold),
                Text(
                  expense.description.isEmpty ? 'Madrassa expense entry' : expense.description,
                  style: typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${expense.amount.toStringAsFixed(0)}',
                style: typography.bodyLargeSemiBold.copyWith(color: Colors.red.shade700),
              ),
              Text(
                DateFormat('dd MMM').format(expense.date),
                style: typography.bodySmall.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Add Expense Dialog ────────────────────────────────────────────────────────

class _AddExpenseDialog extends ConsumerStatefulWidget {
  const _AddExpenseDialog({required this.currentMonth, required this.onSuccess});
  final DateTime currentMonth;
  final VoidCallback onSuccess;

  @override
  ConsumerState<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<_AddExpenseDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_categoriesProvider);

    return AlertDialog(
      title: const Text('Add Madrassa Expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading categories: $e'),
            data: (categories) {
              final expenseCategories = categories.where((c) => c.type == 'Expense').toList();
              // Default to first category if none selected
              _selectedCategory ??= expenseCategories.isNotEmpty ? expenseCategories.first.name : null;
              return DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: expenseCategories
                    .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              );
            },
          ),
          const Gap(16),
          ABMTextField(
            label: 'Amount (₹)',
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
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'Saving...' : 'Save Expense'),
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

    setState(() => _isSaving = true);
    try {
      await ref.read(madrassaFinanceRepositoryProvider).addExpense(
            category: _selectedCategory!,
            amount: amount,
            description: _descriptionController.text,
            processedBy: user.id,
            date: widget.currentMonth,
          );
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
        width: 400,
        height: 420,
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
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
                        Text('Default Amount: ₹${cat.amount.toStringAsFixed(0)}', 
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
                label: 'Default Amount (₹)',
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
