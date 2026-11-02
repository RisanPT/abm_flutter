import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

const _feePresets = ['Books Fee', 'Uniform Fee', 'Exam Fee', 'Transport Fee', 'Other'];

String _shortMonth(String label) {
  try {
    return DateFormat('MMM yy').format(DateFormat('MMMM yyyy').parse(label));
  } catch (_) {
    return label;
  }
}

List<String> _sortedMonths(Set<String> months) => months.toList()
  ..sort((a, b) => DateFormat('MMMM yyyy').parse(a).compareTo(DateFormat('MMMM yyyy').parse(b)));

/// Manual/ad-hoc charge (Books fee, uniform, exam, or any additional collection)
/// applied to one or more months on top of the fee template, for ONE student.
/// Pops `{title, amount, count}` on success.
class AddChargeDialog extends ConsumerStatefulWidget {
  const AddChargeDialog({
    super.key,
    required this.studentId,
    required this.monthOptions,
    required this.initialMonths,
  });

  final String studentId;
  final List<String> monthOptions;
  final List<String> initialMonths;

  @override
  ConsumerState<AddChargeDialog> createState() => _AddChargeDialogState();
}

class _AddChargeDialogState extends ConsumerState<AddChargeDialog> {
  String _preset = 'Books Fee';
  final _customCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  late final Set<String> _months = widget.initialMonths.toSet();
  bool _saving = false;

  @override
  void dispose() {
    _customCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String get _title => _preset == 'Other' ? _customCtrl.text.trim() : _preset;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (_title.isEmpty) return _snack('Enter a charge name');
    if (amount == null || amount <= 0) return _snack('Enter a valid amount');
    if (_months.isEmpty) return _snack('Select at least one month');

    setState(() => _saving = true);
    try {
      final applied = await ref.read(accountRepositoryProvider).addCharge(
            widget.studentId,
            title: _title,
            amount: amount,
            monthLabels: _sortedMonths(_months),
          );
      if (!mounted) return;
      Navigator.of(context).pop(<String, dynamic>{
        'title': _title,
        'amount': amount,
        'count': applied.length,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(friendlyErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ChargeForm(
      title: 'Add Charge',
      saving: _saving,
      preset: _preset,
      customCtrl: _customCtrl,
      amountCtrl: _amountCtrl,
      monthOptions: widget.monthOptions,
      selectedMonths: _months,
      onPreset: (p) => setState(() => _preset = p),
      onCustomChanged: () => setState(() {}),
      onToggleMonth: (m) => setState(() => _months.contains(m) ? _months.remove(m) : _months.add(m)),
      onSubmit: _submit,
      submitLabel: 'Add Charge',
    );
  }
}

/// Charge a fee (e.g. a Books Fee) to EVERY active student in a class at once.
/// Pops a result map on success.
class ClassChargeDialog extends ConsumerStatefulWidget {
  const ClassChargeDialog({
    super.key,
    required this.classOptions,
    required this.monthOptions,
    required this.initialMonths,
  });

  final List<String> classOptions; // grade names (no 'All')
  final List<String> monthOptions;
  final List<String> initialMonths;

  @override
  ConsumerState<ClassChargeDialog> createState() => _ClassChargeDialogState();
}

class _ClassChargeDialogState extends ConsumerState<ClassChargeDialog> {
  String? _grade;
  String _preset = 'Books Fee';
  final _customCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  late final Set<String> _months = widget.initialMonths.toSet();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.classOptions.isNotEmpty) _grade = widget.classOptions.first;
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String get _title => _preset == 'Other' ? _customCtrl.text.trim() : _preset;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (_grade == null || _grade!.isEmpty) return _snack('Select a class');
    if (_title.isEmpty) return _snack('Enter a charge name');
    if (amount == null || amount <= 0) return _snack('Enter a valid amount');
    if (_months.isEmpty) return _snack('Select at least one month');

    setState(() => _saving = true);
    try {
      final res = await ref.read(accountRepositoryProvider).chargeClass(
            grade: _grade!,
            title: _title,
            amount: amount,
            monthLabels: _sortedMonths(_months),
          );
      if (!mounted) return;
      Navigator.of(context).pop(res);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(friendlyErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return _ChargeForm(
      title: 'Charge a Class',
      saving: _saving,
      preset: _preset,
      customCtrl: _customCtrl,
      amountCtrl: _amountCtrl,
      monthOptions: widget.monthOptions,
      selectedMonths: _months,
      onPreset: (p) => setState(() => _preset = p),
      onCustomChanged: () => setState(() {}),
      onToggleMonth: (m) => setState(() => _months.contains(m) ? _months.remove(m) : _months.add(m)),
      onSubmit: _submit,
      submitLabel: 'Charge Class',
      header: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
            const Gap(8),
            DropdownButtonFormField<String>(
              initialValue: _grade,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: widget.classOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _grade = v),
            ),
            const Gap(6),
            Text('The fee is added to every active student in this class.',
                style: typography.bodySmall.copyWith(color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Shared charge form body used by both dialogs.
class _ChargeForm extends StatelessWidget {
  const _ChargeForm({
    required this.title,
    required this.saving,
    required this.preset,
    required this.customCtrl,
    required this.amountCtrl,
    required this.monthOptions,
    required this.selectedMonths,
    required this.onPreset,
    required this.onCustomChanged,
    required this.onToggleMonth,
    required this.onSubmit,
    required this.submitLabel,
    this.header,
  });

  final String title;
  final bool saving;
  final String preset;
  final TextEditingController customCtrl;
  final TextEditingController amountCtrl;
  final List<String> monthOptions;
  final Set<String> selectedMonths;
  final ValueChanged<String> onPreset;
  final VoidCallback onCustomChanged;
  final ValueChanged<String> onToggleMonth;
  final VoidCallback onSubmit;
  final String submitLabel;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ?header,
              Text('Fee type', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _feePresets.map((p) {
                  return ChoiceChip(
                    label: Text(p),
                    selected: preset == p,
                    onSelected: saving ? null : (_) => onPreset(p),
                  );
                }).toList(),
              ),
              if (preset == 'Other') ...[
                const Gap(12),
                TextField(
                  controller: customCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Charge name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => onCustomChanged(),
                ),
              ],
              const Gap(16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (SAR)',
                  prefixText: 'SAR ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Text('Apply to month(s)',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                  const Spacer(),
                  if (selectedMonths.isNotEmpty)
                    Text('${selectedMonths.length} selected',
                        style: typography.bodySmall.copyWith(color: colors.primary)),
                ],
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: monthOptions.map((m) {
                  return FilterChip(
                    label: Text(_shortMonth(m)),
                    selected: selectedMonths.contains(m),
                    onSelected: saving ? null : (_) => onToggleMonth(m),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : onSubmit,
          child: saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(submitLabel),
        ),
      ],
    );
  }
}
