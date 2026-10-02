import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/money.dart';
import 'package:abm_madrasa/features/finance/data/finance_repository.dart';
import 'package:abm_madrasa/features/finance/domain/payroll_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _green = Color(0xFF1B3D2F); // brand primary
const _gold = Color(0xFFD6B64C);
const _present = Color(0xFF2F855A);
const _absent = Color(0xFFC53030);

final _payrollProvider = FutureProvider.autoDispose
    .family<PayrollPreview, ({String month, num deduction, bool autoDeduct, String instituteId, String shift})>((ref, args) async {
  return ref.watch(madrassaFinanceRepositoryProvider).getSalaryPreview(
        month: args.month,
        instituteId: args.instituteId,
        deductionPerClass: args.deduction,
        autoDeduct: args.autoDeduct,
        shift: args.shift == 'All' ? null : args.shift,
      );
});

String _money(num v) => sar(v);

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _deductionCtrl = TextEditingController(text: '0');
  num _deduction = 0;
  bool _isAutoCalculate = true; // Auto calculate pro-rata deduction by default
  String _selectedShift = 'All'; // 'All', 'Shift-1', 'Shift-2'

  String get _monthStr => DateFormat('yyyy-MM').format(_month);

  @override
  void dispose() {
    _deductionCtrl.dispose();
    super.dispose();
  }

  void _applyDeduction() {
    setState(() => _deduction = num.tryParse(_deductionCtrl.text.trim()) ?? 0);
  }

  ({String month, num deduction, bool autoDeduct, String instituteId, String shift}) get _args => (
        month: _monthStr,
        deduction: _isAutoCalculate ? 0 : _deduction,
        autoDeduct: _isAutoCalculate,
        instituteId: ref.read(selectedInstituteProvider).id,
        shift: _selectedShift,
      );

  Future<void> _pay(PayrollRow row) async {
    final messenger = ScaffoldMessenger.of(context);
    String shiftInfo = '';
    if (row.isDualShift && row.shiftsBreakdown.isNotEmpty) {
      final details = row.shiftsBreakdown
          .map((s) => '• ${s.shift}: ${_money(s.net)} (Gross ${_money(s.gross)}, ${s.attended}/${s.expected} classes)')
          .join('\n');
      shiftInfo = '\n\nShift Breakdown:\n$details';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm salary'),
        content: Text(
          'Pay ${_money(row.net)} to ${row.teacherName} for ${DateFormat('MMMM yyyy').format(_month)}?'
          '${row.missed > 0 ? '\n\n(${row.attended}/${row.expected} total classes attended · ${_money(row.deduction)} deducted for ${row.missed} missed${_isAutoCalculate ? ' [Auto Pro-rata]' : ''}.)' : '\n\nFull attendance — full salary.'}'
          '$shiftInfo',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            child: const Text('Pay & post to accounts'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(madrassaFinanceRepositoryProvider).processSalary(
            teacherId: row.teacherId,
            month: _monthStr,
            deductionPerClass: _isAutoCalculate ? 0 : _deduction,
            autoDeduct: _isAutoCalculate,
          );
      ref.invalidate(_payrollProvider);
      messenger.showSnackBar(SnackBar(
        content: Text('Paid ${_money(row.net)} to ${row.teacherName}'),
        backgroundColor: _present,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(friendlyErrorMessage(e)),
        backgroundColor: _absent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(_payrollProvider(_args));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _green)),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(friendlyErrorMessage(e),
                      textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
                ),
              ),
              data: (p) => _body(context, p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final typography = context.typography;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wallet, color: _gold, size: 22),
              const Gap(10),
              Text('Payroll', style: typography.h3.copyWith(color: Colors.white)),
              const Spacer(),
              IconButton(
                onPressed: () => ref.invalidate(_payrollProvider),
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white70, size: 20),
                tooltip: 'Refresh',
              ),
            ],
          ),
          Text('Salary is full pay minus a penalty per missed class. Holidays & paid leave are excused.',
              style: typography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
          const Gap(14),
          _monthDeductionControls(),
          const Gap(12),
          _shiftFilterSelector(),
        ],
      ),
    );
  }

  Widget _shiftFilterSelector() {
    final shifts = ['All', 'Shift-1', 'Shift-2'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: shifts.map((s) {
          final isSelected = _selectedShift == s;
          final label = s == 'All' ? 'All Shifts' : (s == 'Shift-1' ? 'Shift 1' : 'Shift 2');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected ? _gold : Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => setState(() => _selectedShift = s),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _gold : Colors.white.withValues(alpha: 0.45),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(LucideIcons.check, size: 14, color: _green),
                        const Gap(6),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? _green : Colors.white,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showEditManualRateDialog() async {
    final controller = TextEditingController(
      text: _deduction > 0 ? _deduction.toString() : '50',
    );
    final typography = context.typography;
    final colors = context.colors;

    final newRate = await showDialog<num>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.edit3, color: _gold, size: 20),
              ),
              const Gap(12),
              const Text('Manual Deduction Rate'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the penalty amount in SAR to deduct for each missed class:',
                style: typography.bodySmall.copyWith(color: colors.textSecondary),
              ),
              const Gap(16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: InputDecoration(
                  prefixText: 'SAR ',
                  labelText: 'Deduction per missed class',
                  hintText: 'e.g. 50',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const Gap(14),
              Text(
                'Quick presets:',
                style: typography.caption.copyWith(color: colors.textSecondary),
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                children: [25, 50, 75, 100].map((preset) {
                  return ActionChip(
                    label: Text('SAR $preset'),
                    onPressed: () {
                      setDialogState(() {
                        controller.text = preset.toString();
                      });
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = num.tryParse(controller.text.trim()) ?? 0;
                Navigator.pop(ctx, val);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Apply Rate'),
            ),
          ],
        ),
      ),
    );

    if (newRate != null) {
      setState(() {
        _isAutoCalculate = false;
        _deduction = newRate;
        _deductionCtrl.text = newRate.toString();
      });
    }
  }

  Widget _calculationModeToggle() {
    final manualLabel = !_isAutoCalculate && _deduction > 0
        ? 'Manual: SAR ${_deduction.toStringAsFixed(0)}'
        : 'Manual Rate';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeOption(
            label: 'Auto Calculate',
            icon: LucideIcons.sparkles,
            isSelected: _isAutoCalculate,
            onTap: () => setState(() => _isAutoCalculate = true),
          ),
          const Gap(4),
          _modeOption(
            label: manualLabel,
            icon: LucideIcons.edit3,
            isSelected: !_isAutoCalculate,
            showEditIcon: !_isAutoCalculate,
            onTap: () {
              if (_isAutoCalculate) {
                setState(() => _isAutoCalculate = false);
                _showEditManualRateDialog();
              } else {
                _showEditManualRateDialog();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _modeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    bool showEditIcon = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? _gold : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: isSelected ? _green : Colors.white),
              const Gap(5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _green : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
              if (showEditIcon) ...[
                const Gap(5),
                Icon(LucideIcons.pencil, size: 11, color: isSelected ? _green : Colors.white70),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _autoCalculateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.calculator, color: _gold, size: 14),
          const Gap(6),
          Text(
            'Auto: Pro-rata per missed class',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Month stepper + calculation mode + per-missed-class deduction field.
  Widget _monthDeductionControls() {
    final typography = context.typography;
    final leftBtn = _pillButton(
        icon: LucideIcons.chevronLeft,
        onTap: () => setState(() => _month = DateTime(_month.year, _month.month - 1)));
    final rightBtn = _pillButton(
        icon: LucideIcons.chevronRight,
        onTap: () => setState(() => _month = DateTime(_month.year, _month.month + 1)));
    final monthLabel = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(DateFormat('MMMM yyyy').format(_month),
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: typography.bodyMediumSemiBold.copyWith(color: Colors.white)),
    );
    Widget deductionField({required bool fullWidth}) => SizedBox(
          width: fullWidth ? double.infinity : 200,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deductionCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    final n = num.tryParse(val.trim());
                    if (n != null && n != _deduction) {
                      setState(() => _deduction = n);
                    }
                  },
                  onSubmitted: (_) => _applyDeduction(),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: 'SAR ',
                    prefixStyle: const TextStyle(color: Colors.white70),
                    labelText: 'Deduct / missed class',
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Gap(6),
              IconButton(
                icon: const Icon(LucideIcons.pencil, color: _gold, size: 18),
                tooltip: 'Edit Amount',
                onPressed: _showEditManualRateDialog,
              ),
            ],
          ),
        );

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [leftBtn, const Gap(8), Expanded(child: monthLabel), const Gap(8), rightBtn]),
          const Gap(10),
          _calculationModeToggle(),
          const Gap(10),
          if (_isAutoCalculate)
            _autoCalculateBadge()
          else
            deductionField(fullWidth: true),
        ],
      );
    }
    return Row(
      children: [
        leftBtn, const Gap(8), monthLabel, const Gap(8), rightBtn,
        const Gap(14),
        _calculationModeToggle(),
        const Spacer(),
        if (_isAutoCalculate)
          _autoCalculateBadge()
        else
          deductionField(fullWidth: false),
      ],
    );
  }

  Widget _pillButton({required IconData icon, required VoidCallback onTap}) => Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(padding: const EdgeInsets.all(9), child: Icon(icon, color: Colors.white, size: 18)),
        ),
      );

  Widget _body(BuildContext context, PayrollPreview p) {
    if (p.rows.isEmpty) {
      return Center(child: Text('No teachers found.', style: TextStyle(color: context.colors.textSecondary)));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            itemCount: p.rows.length,
            itemBuilder: (_, i) => _teacherCard(context, p.rows[i]),
          ),
        ),
        _totalsBar(context, p),
      ],
    );
  }

  Widget _teacherCard(BuildContext context, PayrollRow r) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _green.withValues(alpha: 0.1),
                child: Text(r.teacherName.isNotEmpty ? r.teacherName[0].toUpperCase() : '?',
                    style: typography.bodyMediumSemiBold.copyWith(color: _green)),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(r.teacherName,
                              style: typography.bodyMediumSemiBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const Gap(6),
                        if (r.isDualShift)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                            ),
                            child: const Text('Dual Shift',
                                style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w600)),
                          )
                        else if (r.shifts.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.shifts.first == 'Shift-1' ? 'Shift 1' : 'Shift 2',
                              style: TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const Gap(3),
                    Text(
                      r.basis == 'checkin'
                          ? '${r.presentDays ?? 0} days present · self check-in'
                          : r.expected == 0
                              ? 'No classes this month'
                              : 'Total classes: ${r.attended}/${r.expected}'
                                  '${r.missed > 0 ? ' · ${r.missed} missed' : ''}'
                                  '${r.onLeave > 0 ? ' · ${r.onLeave} leave' : ''}',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_money(r.net), style: typography.bodyLargeSemiBold.copyWith(color: _green)),
                  if (r.deduction > 0)
                    Text('−${_money(r.deduction)}', style: typography.caption.copyWith(color: _absent))
                  else if (r.fullyAttended && r.expected > 0)
                    Text('full', style: typography.caption.copyWith(color: _present)),
                ],
              ),
              const Gap(12),
              r.alreadyPaid
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: _present.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(LucideIcons.checkCircle2, size: 14, color: _present),
                        const Gap(4),
                        Text('Paid', style: typography.caption.copyWith(color: _present, fontWeight: FontWeight.w600)),
                      ]),
                    )
                  : SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () => _pay(r),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Pay'),
                      ),
                    ),
            ],
          ),
          if (r.isDualShift && r.shiftsBreakdown.isNotEmpty) ...[
            const Gap(10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: r.shiftsBreakdown.map((sb) {
                  final sLabel = sb.shift == 'Shift-1' ? 'Shift 1' : (sb.shift == 'Shift-2' ? 'Shift 2' : sb.shift);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: sb.shift == 'Shift-1' ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Gap(8),
                        Text(sLabel, style: typography.caption.copyWith(fontWeight: FontWeight.w600)),
                        const Gap(8),
                        Text(
                          '${sb.attended}/${sb.expected} classes',
                          style: typography.caption.copyWith(color: colors.textSecondary),
                        ),
                        if (sb.deduction > 0) ...[
                          const Gap(6),
                          Text('(-${_money(sb.deduction)})', style: typography.caption.copyWith(color: _absent)),
                        ],
                        const Spacer(),
                        Text(
                          _money(sb.net),
                          style: typography.caption.copyWith(fontWeight: FontWeight.w700, color: _green),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _totalsBar(BuildContext context, PayrollPreview p) {
    final typography = context.typography;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: context.colors.border))),
      child: Row(
        children: [
          _total('Gross', p.grossTotal, context.colors.textSecondary),
          const Gap(18),
          _total('Deductions', p.deductionTotal, _absent),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Net payable', style: typography.caption.copyWith(color: context.colors.textSecondary)),
              Text(_money(p.netTotal), style: typography.h4.copyWith(color: _green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _total(String label, num v, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.typography.caption.copyWith(color: context.colors.textSecondary)),
          Text(_money(v), style: context.typography.bodyMediumSemiBold.copyWith(color: color)),
        ],
      );
}
