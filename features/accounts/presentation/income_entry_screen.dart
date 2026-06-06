import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:abm_madrasa/shared/widgets/institute_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


// ─── Model ─────────────────────────────────────────────────────────────────────

class _IncomeEntry {
  final String id;
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String accountSegment;

  const _IncomeEntry({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.accountSegment,
  });

  factory _IncomeEntry.fromJson(Map<String, dynamic> j) => _IncomeEntry(
        id: (j['_id'] as String?) ?? '',
        category: j['category'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        description: j['description'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        accountSegment: j['accountSegment'] as String? ?? 'Madrasa',
      );
}

// ─── Provider ──────────────────────────────────────────────────────────────────

class _IncomeFilter {
  final String month;
  final String instituteId;
  final String segment;
  const _IncomeFilter(this.month, this.instituteId, this.segment);
}

final _incomeEntriesProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, _IncomeFilter>(
    (ref, filter) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/accounts/daily-income', queryParameters: {
    'month': filter.month,
    if (filter.instituteId.isNotEmpty) 'instituteId': filter.instituteId,
    if (filter.segment != 'All') 'accountSegment': filter.segment,
  });
  return response.data as Map<String, dynamic>;
});

// ─── Screen ────────────────────────────────────────────────────────────────────

class IncomeEntryScreen extends ConsumerStatefulWidget {
  const IncomeEntryScreen({super.key});

  @override
  ConsumerState<IncomeEntryScreen> createState() => _IncomeEntryScreenState();
}

class _IncomeEntryScreenState extends ConsumerState<IncomeEntryScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _selectedSegment = 'All';
  final _segments = ['All', 'Organization', 'Madrasa', 'CRE'];

  Future<void> _exportIncomePdf(double total, List<_IncomeEntry> entries) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Daily Income Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}'),
          pw.SizedBox(height: 8),
          pw.Text('Segment: $_selectedSegment'),
          pw.SizedBox(height: 8),
          pw.Text('Total Income: SAR ${total.toStringAsFixed(2)}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Category', 'Description', 'Segment', 'Amount'],
            data: entries.map((e) => [
              DateFormat('dd MMM yyyy').format(e.date),
              e.category,
              e.description,
              e.accountSegment,
              'SAR ${e.amount.toStringAsFixed(2)}',
            ]).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final institute = ref.watch(selectedInstituteProvider);
    final user = ref.watch(authControllerProvider).asData?.value;
    final canEdit = user?.role.canEditFinance ?? false;
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final filter = _IncomeFilter(monthStr, institute.id, _selectedSegment);
    final asyncData = ref.watch(_incomeEntriesProvider(filter));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Daily Income Entry', style: typography.h3),
        actions: [
          const InstituteSwitcher(),
          IconButton(
            onPressed: _pickMonth,
            icon: const Icon(LucideIcons.calendar),
            tooltip: 'Select Month',
          ),
          asyncData.whenData((data) {
            final total = (data['total'] as num?)?.toDouble() ?? 0;
            final rawEntries = (data['entries'] as List?) ?? [];
            final entries = rawEntries.map((e) => _IncomeEntry.fromJson(e as Map<String, dynamic>)).toList();
            return IconButton(
              onPressed: () => _exportIncomePdf(total, entries),
              icon: const Icon(LucideIcons.download),
              tooltip: 'Export PDF',
            );
          }).value ?? const SizedBox.shrink(),
          if (canEdit)
            IconButton(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(LucideIcons.plus),
              tooltip: 'Add Income',
            ),
          const Gap(8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segment tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _segments.map((seg) {
                  final isSelected = _selectedSegment == seg;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSegment = seg),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isSelected ? colors.primary : colors.border),
                      ),
                      child: Text(
                        seg,
                        style: typography.bodySmallSemiBold.copyWith(
                          color: isSelected ? Colors.white : colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Gap(20),

            // Month summary
            asyncData.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (data) {
                final total = (data['total'] as num?)?.toDouble() ?? 0;
                final entries = (data['entries'] as List?) ?? [];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Income', style: typography.bodyMedium.copyWith(color: Colors.white70)),
                            const Gap(4),
                            Text('SAR ${total.toStringAsFixed(2)}',
                                style: typography.h2.copyWith(color: Colors.white)),
                            Text(DateFormat('MMMM yyyy').format(_selectedMonth),
                                style: typography.bodySmall.copyWith(color: Colors.white60)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${entries.length}', style: typography.h2.copyWith(color: Colors.white)),
                          Text('Entries', style: typography.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const Gap(20),

            Text(DateFormat('MMMM yyyy').format(_selectedMonth) + ' Income Entries', style: typography.h4),
            const Gap(12),

            // Entries list
            Expanded(
              child: asyncData.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (data) {
                  final rawEntries = (data['entries'] as List?) ?? [];
                  final entries = rawEntries.map((e) => _IncomeEntry.fromJson(e as Map<String, dynamic>)).toList();
                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.trendingUp, size: 48, color: colors.textSecondary.withValues(alpha: 0.3)),
                          const Gap(12),
                          Text('No income entries for this period', style: typography.bodyLarge.copyWith(color: colors.textSecondary)),
                          if (canEdit) ...[
                            const Gap(16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddDialog(context),
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: const Text('Add First Entry'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) => _IncomeCard(entry: entries[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Income'),
            )
          : null,
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
    if (picked != null) setState(() => _selectedMonth = picked);
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddIncomeDialog(
        onSuccess: () => ref.invalidate(_incomeEntriesProvider),
      ),
    );
  }
}

// ─── Income Card ───────────────────────────────────────────────────────────────

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({required this.entry});
  final _IncomeEntry entry;

  Color get _segmentColor {
    switch (entry.accountSegment) {
      case 'Organization': return Colors.purple;
      case 'CRE': return Colors.blue;
      default: return Colors.green;
    }
  }

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
              color: _segmentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.trendingUp, color: _segmentColor, size: 20),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.category, style: typography.bodyLargeSemiBold),
                if (entry.description.isNotEmpty)
                  Text(entry.description, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                Row(
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(entry.date),
                        style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _segmentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(entry.accountSegment,
                          style: TextStyle(color: _segmentColor, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text('+SAR ${entry.amount.toStringAsFixed(0)}',
              style: typography.bodyLargeSemiBold.copyWith(color: Colors.green.shade700)),
        ],
      ),
    );
  }
}

// ─── Add Income Dialog ──────────────────────────────────────────────────────────

class _AddIncomeDialog extends ConsumerStatefulWidget {
  const _AddIncomeDialog({required this.onSuccess});
  final VoidCallback onSuccess;

  @override
  ConsumerState<_AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends ConsumerState<_AddIncomeDialog> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  String _segment = 'Madrasa';
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  final _incomeCategories = ['Donation', 'Grant', 'Zakat', 'Charity', 'Government Aid', 'Other Income'];

  @override
  void initState() {
    super.initState();
    _categoryController.text = _incomeCategories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;
    final category = _categoryController.text.trim();
    if (category.isEmpty) return;

    final institute = ref.read(selectedInstituteProvider);
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/accounts/daily-income', data: {
        'category': category,
        'amount': amount,
        'description': _descController.text.trim(),
        'date': _date.toIso8601String(),
        'accountSegment': _segment,
        'instituteId': institute.id,
      });
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Income Entry'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _categoryController.text.isNotEmpty && _incomeCategories.contains(_categoryController.text)
                  ? _categoryController.text
                  : _incomeCategories.first,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _incomeCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _categoryController.text = v ?? _incomeCategories.first),
            ),
            const Gap(16),
            ABMTextField(
              label: 'Amount (SAR)',
              controller: _amountController,
              keyboardType: TextInputType.number,
              hint: 'Enter amount',
            ),
            const Gap(16),
            ABMTextField(
              label: 'Description (optional)',
              controller: _descController,
              hint: 'Source or notes',
            ),
            const Gap(16),
            DropdownButtonFormField<String>(
              value: _segment,
              decoration: const InputDecoration(labelText: 'Account Segment', border: OutlineInputBorder()),
              items: ['Organization', 'Madrasa', 'CRE']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _segment = v!),
            ),
            const Gap(16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(LucideIcons.calendar, size: 16),
              label: Text('Date: ${DateFormat('dd MMM yyyy').format(_date)}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
