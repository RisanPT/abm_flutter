import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:abm_madrasa/features/accounts/presentation/fee_structure_controller.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
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
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 20),
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
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
                              Expanded(child: Text(item.title, style: typography.bodyMedium)),
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
  late final TextEditingController _annualFeeCtrl;
  late final TextEditingController _examFeeCtrl;
  late bool _hasTransport;
  late final TextEditingController _transportFeeCtrl;
  bool _isSubmitting = false;

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
    _hasTransport = e?.hasTransport ?? false;

    // Pre-fill from existing line items
    double admission = 0, monthly = 0, annual = 0, exam = 0, transport = 0;
    if (e != null) {
      for (final item in e.lineItems) {
        final name = item.title.toLowerCase();
        if (name.contains('admission')) admission = item.amount;
        else if (name.contains('monthly') || name.contains('tuition')) monthly = item.amount;
        else if (name.contains('annual')) annual = item.amount;
        else if (name.contains('exam')) exam = item.amount;
        else if (name.contains('transport')) transport = item.amount;
      }
      if (transport == 0) transport = e.transportFeeAmount;
    }

    _admissionFeeCtrl = TextEditingController(text: admission > 0 ? admission.toStringAsFixed(0) : '');
    _monthlyFeeCtrl = TextEditingController(text: monthly > 0 ? monthly.toStringAsFixed(0) : '');
    _annualFeeCtrl = TextEditingController(text: annual > 0 ? annual.toStringAsFixed(0) : '');
    _examFeeCtrl = TextEditingController(text: exam > 0 ? exam.toStringAsFixed(0) : '');
    _transportFeeCtrl = TextEditingController(text: transport > 0 ? transport.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _customGradeCtrl.dispose();
    _admissionFeeCtrl.dispose();
    _monthlyFeeCtrl.dispose();
    _annualFeeCtrl.dispose();
    _examFeeCtrl.dispose();
    _transportFeeCtrl.dispose();
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
            const Gap(8),
            TextField(
              controller: _admissionFeeCtrl,
              decoration: const InputDecoration(labelText: 'Admission Fee (SAR)', hintText: '0'),
              keyboardType: TextInputType.number,
            ),
            const Gap(12),
            TextField(
              controller: _monthlyFeeCtrl,
              decoration: const InputDecoration(labelText: 'Monthly Tuition Fee (SAR)', hintText: '0'),
              keyboardType: TextInputType.number,
            ),
            const Gap(12),
            TextField(
              controller: _annualFeeCtrl,
              decoration: const InputDecoration(labelText: 'Annual Fee (SAR)', hintText: '0'),
              keyboardType: TextInputType.number,
            ),
            const Gap(12),
            TextField(
              controller: _examFeeCtrl,
              decoration: const InputDecoration(labelText: 'Examination Fee (SAR)', hintText: '0'),
              keyboardType: TextInputType.number,
            ),
            const Gap(16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Includes Transport?'),
              value: _hasTransport,
              onChanged: (val) => setState(() => _hasTransport = val),
            ),
            if (_hasTransport) ...[
              const Gap(8),
              TextField(
                controller: _transportFeeCtrl,
                decoration: const InputDecoration(labelText: 'Transport Fee (SAR)', hintText: '0'),
                keyboardType: TextInputType.number,
              ),
            ]
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

  Future<void> _submit() async {
    final grade = _effectiveGrade;

    final admissionFee = double.tryParse(_admissionFeeCtrl.text.trim()) ?? 0;
    final monthlyFee = double.tryParse(_monthlyFeeCtrl.text.trim()) ?? 0;
    final annualFee = double.tryParse(_annualFeeCtrl.text.trim()) ?? 0;
    final examFee = double.tryParse(_examFeeCtrl.text.trim()) ?? 0;
    final transportFee = double.tryParse(_transportFeeCtrl.text.trim()) ?? 0;

    final hasAnyFee = admissionFee > 0 || monthlyFee > 0 || annualFee > 0 || examFee > 0 ||
        (_hasTransport && transportFee > 0);

    if (grade.isEmpty || !hasAnyFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid grade and at least one fee amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final lineItems = <AccountLineItem>[];
    if (admissionFee > 0) lineItems.add(AccountLineItem(title: 'Admission Fee', amount: admissionFee));
    if (monthlyFee > 0) lineItems.add(AccountLineItem(title: 'Monthly Fee', amount: monthlyFee));
    if (annualFee > 0) lineItems.add(AccountLineItem(title: 'Annual Fee', amount: annualFee));
    if (examFee > 0) lineItems.add(AccountLineItem(title: 'Examination Fee', amount: examFee));
    if (_hasTransport && transportFee > 0) lineItems.add(AccountLineItem(title: 'Transport Fee', amount: transportFee));

    final totalAmount = lineItems.fold(0.0, (sum, item) => sum + item.amount);

    try {
      final model = FeeStructureModel(
        id: widget.existing?.id ?? '',
        instituteId: widget.existing?.instituteId ?? '664c39f00000000000000001',
        grade: grade,
        hasTransport: _hasTransport,
        transportFeeAmount: _hasTransport ? transportFee : 0,
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
