import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/finance/data/finance_repository.dart';
import 'package:abm_madrasa/features/finance/domain/payroll_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _green = Color(0xFF0F4A3A);
const _gold = Color(0xFFD6B64C);
const _present = Color(0xFF2F855A);
const _absent = Color(0xFFC53030);

final _payrollProvider = FutureProvider.autoDispose
    .family<PayrollPreview, ({String month, num deduction, String instituteId})>((ref, args) async {
  return ref
      .watch(madrassaFinanceRepositoryProvider)
      .getSalaryPreview(month: args.month, instituteId: args.instituteId, deductionPerClass: args.deduction);
});

String _money(num v) => 'SAR ${v.toStringAsFixed(0)}';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _deductionCtrl = TextEditingController(text: '0');
  num _deduction = 0;

  String get _monthStr => DateFormat('yyyy-MM').format(_month);

  @override
  void dispose() {
    _deductionCtrl.dispose();
    super.dispose();
  }

  void _applyDeduction() {
    setState(() => _deduction = num.tryParse(_deductionCtrl.text.trim()) ?? 0);
  }

  ({String month, num deduction, String instituteId}) get _args =>
      (month: _monthStr, deduction: _deduction, instituteId: ref.read(selectedInstituteProvider).id);

  Future<void> _pay(PayrollRow row) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm salary'),
        content: Text(
          'Pay ${_money(row.net)} to ${row.teacherName} for ${DateFormat('MMMM yyyy').format(_month)}?'
          '${row.missed > 0 ? '\n\n(${row.attended}/${row.expected} classes attended · ${_money(row.deduction)} deducted for ${row.missed} missed.)' : '\n\nFull attendance — full salary.'}',
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
            deductionPerClass: _deduction,
          );
      ref.invalidate(_payrollProvider);
      messenger.showSnackBar(SnackBar(
        content: Text('Paid ${_money(row.net)} to ${row.teacherName}'),
        backgroundColor: _present,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
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
                  child: Text(e.toString().replaceFirst('Exception: ', ''),
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
          Row(
            children: [
              // month stepper
              _pillButton(icon: LucideIcons.chevronLeft, onTap: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(DateFormat('MMMM yyyy').format(_month),
                    style: typography.bodyMediumSemiBold.copyWith(color: Colors.white)),
              ),
              const Gap(8),
              _pillButton(icon: LucideIcons.chevronRight, onTap: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
              const Spacer(),
              // deduction per class
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _deductionCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  style: const TextStyle(color: Colors.white),
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
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.check, color: _gold, size: 18),
                      onPressed: _applyDeduction,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
      child: Row(
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
                Text(r.teacherName, style: typography.bodyMediumSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                const Gap(3),
                Text(
                  r.expected == 0
                      ? 'No classes this month'
                      : 'Attended ${r.attended}/${r.expected}'
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
