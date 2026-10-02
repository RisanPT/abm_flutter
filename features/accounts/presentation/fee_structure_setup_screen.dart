import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:abm_madrasa/features/accounts/presentation/fee_structure_controller.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FeeStructureSetupScreen extends ConsumerStatefulWidget {
  const FeeStructureSetupScreen({super.key});

  @override
  ConsumerState<FeeStructureSetupScreen> createState() => _FeeStructureSetupScreenState();
}

class _FeeStructureSetupScreenState extends ConsumerState<FeeStructureSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncStructures = ref.watch(feeStructureControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ABMPageHeader(
              title: 'Fee Structure Setup',
              subtitle: 'Define default fee templates per grade/classroom',
              actions: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _FeeTrackingDialog(instituteId: ref.read(selectedInstituteProvider).id),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.slidersHorizontal, color: Colors.white, size: 16),
                          Gap(6),
                          Text(
                            'Fee Rules & Discounts',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                    onPressed: () => ref.read(feeStructureControllerProvider.notifier).refresh(),
                    tooltip: 'Refresh',
                  ),
                ),
              ],
            ),
          ),
          asyncStructures.when(
            data: (structures) {
              if (structures.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.fileQuestion, size: 40, color: colors.primary.withValues(alpha: 0.5)),
                        ),
                        const Gap(16),
                        Text('No fee structures set up yet', style: context.typography.h4),
                        const Gap(8),
                        Text(
                          'Create a template for each grade to auto-assign fees to students.',
                          style: context.typography.bodyMedium.copyWith(color: colors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final structure = structures[index];
                      return _FeeStructureCard(
                        structure: structure,
                        onDelete: () => _deleteStructure(structure),
                        onEdit: () => _showEditStructureDialog(context, structure),
                      );
                    },
                    childCount: structures.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text(friendlyErrorMessage(err)))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStructureDialog(context),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Template', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _deleteStructure(FeeStructureModel structure) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Delete the fee template for "${structure.grade}"? This won\'t affect existing student fee records.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(feeStructureControllerProvider.notifier).deleteStructure(structure.id);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  void _showAddStructureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _AddStructureDialog(),
    );
  }

  void _showEditStructureDialog(BuildContext context, FeeStructureModel structure) {
    showDialog(
      context: context,
      builder: (ctx) => _AddStructureDialog(existing: structure),
    );
  }
}

// ─── Fee Structure Card ────────────────────────────────────────────────────────

const _kMonthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Empty months → recurring ('Every month'); otherwise the list, e.g. 'Apr, Oct'.
String _monthsLabelFor(List<int> months) {
  if (months.isEmpty) return 'Every month';
  final sorted = [...months]..sort();
  return sorted.map((m) => _kMonthAbbr[m - 1]).join(', ');
}

class _FeeStructureCard extends StatelessWidget {
  const _FeeStructureCard({
    required this.structure,
    required this.onDelete,
    required this.onEdit,
  });
  final FeeStructureModel structure;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.layoutList, color: colors.primary, size: 18),
          ),
          title: Text(structure.grade, style: typography.h4),
          subtitle: Text(
            'SAR ${structure.totalAmount.toStringAsFixed(0)} total • ${structure.lineItems.length} fee types${structure.hasTransport ? " • Includes transport" : ""}',
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  ...structure.lineItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isLast = entry.key == structure.lineItems.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Gap(10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title, style: typography.bodyMedium),
                                    if (!item.title.toLowerCase().contains('admission'))
                                      Text(
                                        _monthsLabelFor(item.months),
                                        style: typography.bodySmall.copyWith(
                                          color: item.isRecurring
                                              ? colors.textSecondary
                                              : colors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                'SAR ${item.amount.toStringAsFixed(0)}',
                                style: typography.bodyMediumSemiBold.copyWith(color: colors.primary),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast) Divider(height: 1, color: colors.border, indent: 32),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const Gap(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(LucideIcons.pencil, size: 14),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Gap(8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 14),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _AddStructureDialog extends ConsumerStatefulWidget {
  const _AddStructureDialog({this.existing});
  final FeeStructureModel? existing;

  @override
  ConsumerState<_AddStructureDialog> createState() => _AddStructureDialogState();
}

class _AddStructureDialogState extends ConsumerState<_AddStructureDialog> {
  // Grade selection: null = not chosen yet, '_custom_' = user typed custom
  static const _customKey = '_custom_';
  String? _selectedGrade;
  late final TextEditingController _customGradeCtrl;

  late final TextEditingController _admissionFeeCtrl;
  late final TextEditingController _monthlyFeeCtrl;
  late final TextEditingController _sportsFeeCtrl;
  late final TextEditingController _artsFeeCtrl;
  late final TextEditingController _exam1FeeCtrl;
  late final TextEditingController _exam2FeeCtrl;
  late final TextEditingController _tourFeeCtrl;
  bool _isSubmitting = false;

  // Month-based billing per fee (1 = Jan … 12 = Dec). Empty = recurring/every
  // month (and waived in vacation months). Admission is one-time, so it has no
  // month picker. Keyed by a stable slug matching each fee field below.
  final Map<String, List<int>> _months = {
    'monthly': [],
    'sports': [],
    'arts': [],
    'exam1': [],
    'exam2': [],
    'tour': [],
  };

  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  bool get _isEdit => widget.existing != null;

  /// The resolved grade string to save
  String get _effectiveGrade {
    if (_selectedGrade == _customKey) return _customGradeCtrl.text.trim();
    return _selectedGrade ?? '';
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    // On edit, pre-select the existing grade
    _selectedGrade = e?.grade;
    _customGradeCtrl = TextEditingController(text: e?.grade ?? '');

    // Pre-fill from existing line items
    double admission = 0, monthly = 0, sports = 0, arts = 0, exam1 = 0, exam2 = 0, tour = 0;
    if (e != null) {
      for (final item in e.lineItems) {
        final name = item.title.toLowerCase();
        if (name.contains('admission')) {
          admission = item.amount;
        } else if (name.contains('monthly') || name.contains('tuition')) {
          monthly = item.amount;
          _months['monthly'] = List.of(item.months);
        } else if (name.contains('sports')) {
          sports = item.amount;
          _months['sports'] = List.of(item.months);
        } else if (name.contains('arts')) {
          arts = item.amount;
          _months['arts'] = List.of(item.months);
        } else if (name.contains('exam-1') || name == 'exam-1 fee' || name == 'exam 1 fee') {
          exam1 = item.amount;
          _months['exam1'] = List.of(item.months);
        } else if (name.contains('exam-2') || name == 'exam-2 fee' || name == 'exam 2 fee') {
          exam2 = item.amount;
          _months['exam2'] = List.of(item.months);
        } else if (name.contains('tour')) {
          tour = item.amount;
          _months['tour'] = List.of(item.months);
        }
      }
    }

    _admissionFeeCtrl = TextEditingController(text: admission > 0 ? admission.toStringAsFixed(0) : '');
    _monthlyFeeCtrl = TextEditingController(text: monthly > 0 ? monthly.toStringAsFixed(0) : '');
    _sportsFeeCtrl = TextEditingController(text: sports > 0 ? sports.toStringAsFixed(0) : '');
    _artsFeeCtrl = TextEditingController(text: arts > 0 ? arts.toStringAsFixed(0) : '');
    _exam1FeeCtrl = TextEditingController(text: exam1 > 0 ? exam1.toStringAsFixed(0) : '');
    _exam2FeeCtrl = TextEditingController(text: exam2 > 0 ? exam2.toStringAsFixed(0) : '');
    _tourFeeCtrl = TextEditingController(text: tour > 0 ? tour.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _customGradeCtrl.dispose();
    _admissionFeeCtrl.dispose();
    _monthlyFeeCtrl.dispose();
    _sportsFeeCtrl.dispose();
    _artsFeeCtrl.dispose();
    _exam1FeeCtrl.dispose();
    _exam2FeeCtrl.dispose();
    _tourFeeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Fee Structure' : 'Add Fee Structure'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Grade selector ──────────────────────────────────────
            if (_isEdit)
              // On edit, grade is locked — just show it as a read-only field
              TextField(
                controller: TextEditingController(text: widget.existing!.grade),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Grade / Classroom',
                  suffixIcon: Icon(Icons.lock_outline, size: 16),
                ),
              )
            else
              // On add, load all classrooms and show as a dropdown
              Consumer(
                builder: (context, ref, _) {
                  final classroomsAsync = ref.watch(classroomControllerProvider);
                  final classroomNames = classroomsAsync.asData?.value
                          .map((c) => c.name)
                          .toList() ??
                      [];

                  // Build dropdown items: all classrooms + custom option
                  final items = <DropdownMenuItem<String>>[
                    ...classroomNames.map(
                      (name) => DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      ),
                    ),
                    DropdownMenuItem(
                      value: _customKey,
                      child: Row(
                        children: [
                          Icon(LucideIcons.edit, size: 14),
                          Gap(8),
                          Text('Custom grade...'),
                        ],
                      ),
                    ),
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: (_selectedGrade != null &&
                                (_selectedGrade == _customKey ||
                                    classroomNames.contains(_selectedGrade)))
                            ? _selectedGrade
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Grade / Classroom',
                          hintText: classroomsAsync.isLoading
                              ? 'Loading classrooms...'
                              : 'Select a classroom',
                        ),
                        items: items,
                        onChanged: (val) => setState(() => _selectedGrade = val),
                      ),
                      // Show custom text field when user picks "Custom grade..."
                      if (_selectedGrade == _customKey) ...[
                        const Gap(10),
                        TextField(
                          controller: _customGradeCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Enter grade name',
                            hintText: 'e.g., Grade 2A, Hifz 1',
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            const Gap(16),
            const Text('Fee Breakdown (SAR)', style: TextStyle(fontWeight: FontWeight.bold)),
            const Gap(4),
            Text(
              'Set “Billed in” months for term/one-off fees. Leave it on Every month for recurring fees — those are automatically skipped during vacation months.',
              style: context.typography.bodySmall.copyWith(color: context.colors.textSecondary),
            ),
            const Gap(12),
            // Admission is one-time (charged once per student, ever) — no month picker.
            _feeField(controller: _admissionFeeCtrl, label: 'Admission Fee (SAR)'),
            const Gap(12),
            _feeField(controller: _monthlyFeeCtrl, label: 'Monthly Tuition Fee (SAR)', monthKey: 'monthly'),
            const Gap(12),
            _feeField(controller: _sportsFeeCtrl, label: 'Sports Fee (SAR)', monthKey: 'sports'),
            const Gap(12),
            _feeField(controller: _artsFeeCtrl, label: 'Arts Fee (SAR)', monthKey: 'arts'),
            const Gap(12),
            _feeField(controller: _exam1FeeCtrl, label: 'Exam-1 Fee (SAR)', monthKey: 'exam1'),
            const Gap(12),
            _feeField(controller: _exam2FeeCtrl, label: 'Exam-2 Fee (SAR)', monthKey: 'exam2'),
            const Gap(12),
            _feeField(controller: _tourFeeCtrl, label: 'Tour Fee (SAR)', monthKey: 'tour'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  // A fee amount field with an optional "Billed in <months>" selector beneath it.
  Widget _feeField({
    required TextEditingController controller,
    required String label,
    String? monthKey,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label, hintText: '0'),
          keyboardType: TextInputType.number,
        ),
        if (monthKey != null)
          InkWell(
            onTap: () => _openMonthPicker(monthKey, label),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                children: [
                  Icon(LucideIcons.calendarDays, size: 14, color: colors.textSecondary),
                  const Gap(6),
                  Text('Billed in: ',
                      style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
                  Expanded(
                    child: Text(
                      _monthsSummary(_months[monthKey]!),
                      style: context.typography.bodySmall
                          .copyWith(color: colors.primary, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 14, color: colors.textSecondary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _monthsSummary(List<int> months) {
    if (months.isEmpty) return 'Every month';
    final sorted = [...months]..sort();
    return sorted.map((m) => _monthAbbr[m - 1]).join(', ');
  }

  Future<void> _openMonthPicker(String key, String label) async {
    final temp = List<int>.of(_months[key]!);
    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Billed months — $label'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temp.isEmpty
                      ? 'Currently billed every month (skipped during vacation).'
                      : 'Billed only in the selected months.',
                  style: context.typography.bodySmall
                      .copyWith(color: context.colors.textSecondary),
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(12, (i) {
                    final m = i + 1;
                    return FilterChip(
                      label: Text(_monthAbbr[i]),
                      selected: temp.contains(m),
                      onSelected: (on) => setLocal(() {
                        if (on) {
                          temp.add(m);
                        } else {
                          temp.remove(m);
                        }
                      }),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setLocal(temp.clear),
              child: const Text('Every month'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, temp),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() => _months[key] = result..sort());
    }
  }

  Future<void> _submit() async {
    final grade = _effectiveGrade;

    final admissionFee = double.tryParse(_admissionFeeCtrl.text.trim()) ?? 0;
    final monthlyFee = double.tryParse(_monthlyFeeCtrl.text.trim()) ?? 0;
    final sportsFee = double.tryParse(_sportsFeeCtrl.text.trim()) ?? 0;
    final artsFee = double.tryParse(_artsFeeCtrl.text.trim()) ?? 0;
    final exam1Fee = double.tryParse(_exam1FeeCtrl.text.trim()) ?? 0;
    final exam2Fee = double.tryParse(_exam2FeeCtrl.text.trim()) ?? 0;
    final tourFee = double.tryParse(_tourFeeCtrl.text.trim()) ?? 0;

    final hasAnyFee = admissionFee > 0 || monthlyFee > 0 || sportsFee > 0 || artsFee > 0 || exam1Fee > 0 || exam2Fee > 0 || tourFee > 0;

    if (grade.isEmpty || !hasAnyFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid grade and at least one fee amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final lineItems = <AccountLineItem>[];
    // Admission is one-time (charged once per student, ever) — no month billing.
    if (admissionFee > 0) lineItems.add(AccountLineItem(title: 'Admission Fee', amount: admissionFee));
    if (monthlyFee > 0) lineItems.add(AccountLineItem(title: 'Monthly Tuition Fee', amount: monthlyFee, months: _months['monthly']!));
    if (sportsFee > 0) lineItems.add(AccountLineItem(title: 'Sports Fee', amount: sportsFee, months: _months['sports']!));
    if (artsFee > 0) lineItems.add(AccountLineItem(title: 'Arts Fee', amount: artsFee, months: _months['arts']!));
    if (exam1Fee > 0) lineItems.add(AccountLineItem(title: 'Exam-1 Fee', amount: exam1Fee, months: _months['exam1']!));
    if (exam2Fee > 0) lineItems.add(AccountLineItem(title: 'Exam-2 Fee', amount: exam2Fee, months: _months['exam2']!));
    if (tourFee > 0) lineItems.add(AccountLineItem(title: 'Tour Fee', amount: tourFee, months: _months['tour']!));

    final totalAmount = lineItems.fold(0.0, (sum, item) => sum + item.amount);

    try {
      final model = FeeStructureModel(
        id: widget.existing?.id ?? '',
        instituteId: widget.existing?.instituteId ?? '664c39f00000000000000001',
        grade: grade,
        totalAmount: totalAmount,
        lineItems: lineItems,
      );

      if (_isEdit) {
        await ref.read(feeStructureControllerProvider.notifier).updateStructure(model);
      } else {
        await ref.read(feeStructureControllerProvider.notifier).create(model);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ─── Fee Tracking + Holiday Months dialog (institute-wide) ───────────────────

class _FeeTrackingDialog extends ConsumerStatefulWidget {
  const _FeeTrackingDialog({required this.instituteId});
  final String instituteId;
  @override
  ConsumerState<_FeeTrackingDialog> createState() => _FeeTrackingDialogState();
}

class _FeeTrackingDialogState extends ConsumerState<_FeeTrackingDialog> {
  DateTime? _startMonth;
  final List<VacationPeriod> _vacationPeriods = [];
  bool _loading = true, _saving = false;
  String? _error;

  // Automatic sibling / multi-child discount config.
  bool _siblingEnabled = false;
  final _siblingFromChildCtrl = TextEditingController(text: '3');
  final _siblingAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _siblingFromChildCtrl.dispose();
    _siblingAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cfg = await ref.read(accountRepositoryProvider).getInstituteFeeConfig(widget.instituteId);
      if (mounted) {
        setState(() {
          _startMonth = cfg.feesStartMonth;
          _vacationPeriods
            ..clear()
            ..addAll(cfg.vacationPeriods);
          _siblingEnabled = cfg.siblingDiscountEnabled;
          _siblingFromChildCtrl.text = cfg.siblingDiscountFromChild.toString();
          _siblingAmountCtrl.text = cfg.siblingDiscountAmount == 0 ? '' : cfg.siblingDiscountAmount.toStringAsFixed(0);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<DateTime?> _pickMonth(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        helpText: 'Pick any day in the month',
      );

  Future<DateTimeRange?> _pickDateRange() => showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        helpText: 'Select holiday period',
      );

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(accountRepositoryProvider).setInstituteFeeConfig(
            widget.instituteId,
            feesStartMonth: _startMonth,
            waivedMonths: [], // Kept empty as we moved to vacationPeriods
            vacationPeriods: _vacationPeriods,
            siblingDiscountEnabled: _siblingEnabled,
            siblingDiscountFromChild: int.tryParse(_siblingFromChildCtrl.text.trim()) ?? 3,
            siblingDiscountAmount: double.tryParse(_siblingAmountCtrl.text.trim()) ?? 0,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = friendlyErrorMessage(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = context.isMobile;
    final dialogWidth = isMobile ? MediaQuery.sizeOf(context).width * 0.95 : 540.0;
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      backgroundColor: colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Dialog Header ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.05),
                      border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.7))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(LucideIcons.slidersHorizontal, color: colors.primary, size: 20),
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fee Rules & Sibling Discount',
                                style: context.typography.h4.copyWith(fontSize: 18),
                              ),
                              const Gap(2),
                              Text(
                                'Tracking timeline, holidays & multi-child discounts',
                                style: context.typography.bodySmall.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          color: colors.textSecondary,
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable Body ─────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Fee Dues Start Month
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.calendarCheck, size: 18, color: colors.primary),
                                    const Gap(8),
                                    Text('Track Fee Dues From', style: context.typography.bodyMediumSemiBold),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  'Dues and arrears are only calculated from this month onward.',
                                  style: context.typography.bodySmall.copyWith(color: colors.textSecondary),
                                ),
                                const Gap(12),
                                InkWell(
                                  onTap: () async {
                                    final d = await _pickMonth(_startMonth ?? DateTime.now());
                                    if (d != null) setState(() => _startMonth = DateTime(d.year, d.month, 1));
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: colors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(LucideIcons.calendar, size: 16, color: colors.primary),
                                        ),
                                        const Gap(12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _startMonth != null
                                                    ? DateFormat('MMMM yyyy').format(_startMonth!)
                                                    : 'Current Month (Default)',
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                              Text(
                                                _startMonth != null ? 'Custom start period' : 'Auto tracking from current month',
                                                style: TextStyle(fontSize: 11, color: colors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Gap(16),

                          // 2. Madrasa Holiday Periods (Fee Waiver)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.calendarOff, size: 18, color: colors.primary),
                                    const Gap(8),
                                    Text('Madrasa Holiday Periods', style: context.typography.bodyMediumSemiBold),
                                    const Spacer(),
                                    if (_vacationPeriods.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_vacationPeriods.length} ${_vacationPeriods.length == 1 ? 'period' : 'periods'}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.primary),
                                        ),
                                      ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  'Madrasa closure periods where recurring monthly tuition fees are automatically waived.',
                                  style: context.typography.bodySmall.copyWith(color: colors.textSecondary),
                                ),
                                const Gap(12),
                                if (_vacationPeriods.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No holiday periods set. Regular fees apply every month.',
                                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: _vacationPeriods.map((vp) {
                                      final days = vp.to.difference(vp.from).inDays + 1;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(LucideIcons.calendarDays, size: 16, color: colors.primary),
                                            const Gap(10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${DateFormat('MMM d, yyyy').format(vp.from)}  –  ${DateFormat('MMM d, yyyy').format(vp.to)}',
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                  ),
                                                  Text(
                                                    '$days days fee waived',
                                                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                              onPressed: () => setState(() => _vacationPeriods.remove(vp)),
                                              tooltip: 'Delete holiday period',
                                              visualDensity: VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                const Gap(6),
                                OutlinedButton.icon(
                                  icon: const Icon(LucideIcons.plus, size: 15),
                                  label: const Text('Add Holiday Period'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    final range = await _pickDateRange();
                                    if (range != null) {
                                      setState(() => _vacationPeriods.add(VacationPeriod(
                                        name: 'Vacation',
                                        from: range.start,
                                        to: range.end,
                                      )));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          const Gap(16),

                          // 3. Automatic Sibling Discount
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _siblingEnabled ? colors.primary.withValues(alpha: 0.04) : colors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _siblingEnabled ? colors.primary.withValues(alpha: 0.35) : colors.border.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.users,
                                      size: 18,
                                      color: _siblingEnabled ? colors.primary : colors.textSecondary,
                                    ),
                                    const Gap(8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Automatic Sibling Discount', style: context.typography.bodyMediumSemiBold),
                                          const Gap(2),
                                          Text(
                                            'Auto-reduce tuition for a family\'s Nth child onward. (A student\'s manual discount always overrides this).',
                                            style: context.typography.bodySmall.copyWith(color: colors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _siblingEnabled,
                                      activeThumbColor: colors.primary,
                                      activeTrackColor: colors.primary.withValues(alpha: 0.35),
                                      onChanged: (v) => setState(() => _siblingEnabled = v),
                                    ),
                                  ],
                                ),
                                if (_siblingEnabled) ...[
                                  const Gap(14),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.info, size: 14, color: colors.primary),
                                        const Gap(8),
                                        Expanded(
                                          child: Text(
                                            'Students sharing the same Parent Iqama are ordered by age. Tuition will be reduced by this amount for the designated child and all younger siblings.',
                                            style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap(14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('From Child #', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                                            const Gap(6),
                                            TextField(
                                              controller: _siblingFromChildCtrl,
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                prefixIcon: const Icon(LucideIcons.hash, size: 16),
                                                hintText: '3',
                                                helperText: 'e.g. 3 (3rd child onwards)',
                                                isDense: true,
                                                filled: true,
                                                fillColor: colors.white,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Gap(14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Discount Amount (SAR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                                            const Gap(6),
                                            TextField(
                                              controller: _siblingAmountCtrl,
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                prefixIcon: const Icon(LucideIcons.banknote, size: 16),
                                                hintText: 'e.g. 35',
                                                helperText: 'SAR off tuition monthly',
                                                isDense: true,
                                                filled: true,
                                                fillColor: colors.white,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          if (_error != null) ...[
                            const Gap(14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFDC2626)),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: context.typography.bodySmall.copyWith(color: const Color(0xFFDC2626)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Dialog Footer Actions ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.white,
                      border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.7))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const Gap(10),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(LucideIcons.check, size: 16, color: Colors.white),
                          label: Text(
                            _saving ? 'Saving...' : 'Save Settings',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
