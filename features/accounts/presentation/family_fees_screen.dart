import 'dart:async';
import 'dart:io';

import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/money.dart';
import 'package:abm_madrasa/core/whatsapp/whatsapp_service.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:abm_madrasa/features/accounts/presentation/finance_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:abm_madrasa/features/accounts/presentation/widgets/charge_dialogs.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FamilyQuery {
  const FamilyQuery({this.search = '', this.page = 1, this.status = 'all'});
  final String search;
  final int page;
  final String status; // 'all' | 'pending' | 'paid'

  @override
  bool operator ==(Object other) =>
      other is FamilyQuery && search == other.search && page == other.page && status == other.status;

  @override
  int get hashCode => Object.hash(search, page, status);
}

final familiesPageProvider =
    FutureProvider.autoDispose.family<PagedResult<FamilySummary>, FamilyQuery>((ref, q) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref.read(accountRepositoryProvider).getFamiliesPage(
        instituteId: instituteId,
        search: q.search.isEmpty ? null : q.search,
        status: q.status,
        page: q.page,
        limit: 20,
      );
});

// Families matching a (debounced) parent/child search. Empty search browses real
// sibling groups (2+ children).
final familiesProvider =
    FutureProvider.autoDispose.family<List<FamilySummary>, String>((ref, search) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref.read(accountRepositoryProvider).getFamilies(instituteId: instituteId, search: search);
});

final familyDetailProvider =
    FutureProvider.autoDispose.family<FamilyDetail, String>((ref, key) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref.read(accountRepositoryProvider).getFamilyDetail(key, instituteId: instituteId);
});

// ─── Family list screen ──────────────────────────────────────────────────────

class FamilyFeesScreen extends ConsumerStatefulWidget {
  const FamilyFeesScreen({super.key});

  @override
  ConsumerState<FamilyFeesScreen> createState() => _FamilyFeesScreenState();
}

class _FamilyFeesScreenState extends ConsumerState<FamilyFeesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _page = 1;
  String _status = 'all'; // 'all' | 'pending' | 'paid'
  Timer? _debounce;
  bool _bulkBusy = false;

  void _onStatusChanged(String s) => setState(() {
        _status = s;
        _page = 1;
      });

  Future<void> _bulkEnablePhoneLogin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable phone login for all families?'),
        content: const Text(
          'Every family with a mobile number on file will be able to sign in to the parent portal using just their phone number — no password.\n\n'
          'Anyone who knows an enabled family’s number could view that family’s fees & attendance. You can turn it off per family anytime.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Enable all')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _bulkBusy = true);
    try {
      final res = await ref.read(accountRepositoryProvider).enablePhoneLoginForAll();
      if (!mounted) return;
      setState(() => _bulkBusy = false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Phone login enabled'),
          content: Text(
            '${res.activeTotal} of ${res.totalFamilies} families can now sign in with their mobile number.\n\n'
            '• ${res.created} new logins created\n'
            '• ${res.enabled} existing logins enabled'
            '${res.skippedCount > 0 ? '\n• ${res.skippedCount} skipped (no phone number on file)' : ''}',
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _bulkBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _query = v.trim();
          _page = 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final familyQuery = FamilyQuery(search: _query, page: _page, status: _status);
    final familiesAsync = ref.watch(familiesPageProvider(familyQuery));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          AbmGradientHeader(
            title: 'Family Fees',
            subtitle: 'Pay for all a parent\'s children together',
            leading: AbmHeaderIconButton(
              icon: LucideIcons.arrowLeft,
              tooltip: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
            ),
            trailing: _bulkBusy
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  )
                : AbmHeaderIconButton(
                    icon: LucideIcons.keyRound,
                    tooltip: 'Enable phone login for all families',
                    onTap: _bulkEnablePhoneLogin,
                  ),
            bottom: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              style: typography.bodyMedium.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search parent name, phone, Iqama or child…',
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
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Text('Fees', style: typography.bodySmallSemiBold.copyWith(color: colors.textSecondary)),
                const Gap(10),
                ...const [('All', 'all'), ('Pending', 'pending'), ('Paid', 'paid')].map((opt) {
                  final sel = _status == opt.$2;
                  final accent = opt.$2 == 'pending'
                      ? Colors.red.shade600
                      : opt.$2 == 'paid'
                          ? Colors.green.shade600
                          : colors.primary;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _onStatusChanged(opt.$2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: sel ? accent : colors.border),
                        ),
                        child: Text(opt.$1,
                            style: typography.bodySmallSemiBold.copyWith(
                                color: sel ? Colors.white : colors.textSecondary)),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: familiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AbmErrorView(
                message: friendlyErrorMessage(e),
                onRetry: () {
                  ref.invalidate(familiesPageProvider);
                  ref.invalidate(familiesProvider);
                },
              ),
              data: (pagedResult) {
                final families = pagedResult.items;
                if (families.isEmpty) {
                  return AbmEmptyState(
                    icon: _query.isEmpty ? LucideIcons.users : LucideIcons.searchX,
                    title: _query.isEmpty ? 'No sibling families yet' : 'No families found',
                    message: _query.isEmpty
                        ? 'Families with two or more enrolled children appear here. Search a parent to collect for a single child too.'
                        : 'Try a different parent name, phone number, Iqama ID or child name.',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: families.length,
                        separatorBuilder: (_, _) => const Gap(12),
                        itemBuilder: (context, i) => _FamilyCard(
                          family: families[i],
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => FamilyDetailScreen(familyKey: families[i].key),
                          )),
                        ),
                      ),
                    ),
                    if (pagedResult.totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: AbmPaginationBar(
                          page: pagedResult.page,
                          totalPages: pagedResult.totalPages,
                          total: pagedResult.total,
                          onPage: (p) => setState(() => _page = p),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.family, required this.onTap});
  final FamilySummary family;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final cleared = family.totalBalance <= 0;

    return Material(
      color: colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  abmInitialsAvatar(context, family.guardianName, radius: 20),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(family.guardianName,
                            style: typography.bodyLargeSemiBold.copyWith(color: colors.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            Icon(LucideIcons.users, size: 12, color: colors.textSecondary),
                            const Gap(4),
                            Flexible(
                              child: Text(
                                '${family.childCount} children'
                                '${family.parentContact.isNotEmpty ? ' • ${family.parentContact}' : ''}',
                                style: typography.bodySmall.copyWith(color: colors.textSecondary),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  // Balance pill.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (cleared ? Colors.green : Colors.red).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      cleared ? 'Cleared' : sar(family.totalBalance),
                      style: typography.bodyMediumSemiBold.copyWith(
                        color: cleared ? Colors.green.shade700 : Colors.red.shade600,
                      ),
                    ),
                  ),
                  const Gap(4),
                  Icon(LucideIcons.chevronRight, size: 18, color: colors.textSecondary),
                ],
              ),
              const Gap(10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: family.children
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            '${c.fullName.split(' ').first} · ${c.classroom}',
                            style: typography.bodySmall.copyWith(color: colors.textSecondary),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Family detail + combined collection ─────────────────────────────────────

class FamilyDetailScreen extends ConsumerStatefulWidget {
  const FamilyDetailScreen({super.key, required this.familyKey});
  final String familyKey;

  @override
  ConsumerState<FamilyDetailScreen> createState() => _FamilyDetailScreenState();
}

class _FamilyDetailScreenState extends ConsumerState<FamilyDetailScreen> {
  final Map<String, TextEditingController> _amounts = {};
  final Set<String> _included = {};
  bool _clearArrears = false; // oldest-first allocation across each child's dues
  bool _processing = false;
  bool _seeded = false;

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Pre-fill each child's amount + include-set the first time the detail loads,
  // and whenever the "clear arrears" mode flips (current balance vs full dues).
  void _seed(FamilyDetail detail) {
    for (final c in detail.children) {
      _amounts.putIfAbsent(c.studentId, () => TextEditingController());
      final target = _clearArrears ? c.totalOutstanding : c.currentBalance;
      _amounts[c.studentId]!.text = target > 0 ? target.toStringAsFixed(0) : '0';
      if (target > 0) {
        _included.add(c.studentId);
      } else {
        _included.remove(c.studentId);
      }
    }
  }

  double _grandTotal(FamilyDetail detail) {
    double sum = 0;
    for (final c in detail.children) {
      if (!_included.contains(c.studentId)) continue;
      sum += double.tryParse(_amounts[c.studentId]?.text.trim() ?? '') ?? 0;
    }
    return sum;
  }

  Future<void> _collect(FamilyDetail detail) async {
    final allocations = <Map<String, dynamic>>[];
    for (final c in detail.children) {
      if (!_included.contains(c.studentId)) continue;
      final amt = double.tryParse(_amounts[c.studentId]?.text.trim() ?? '') ?? 0;
      if (amt > 0) allocations.add({'studentId': c.studentId, 'amount': amt});
    }
    if (allocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount for at least one child.')),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      final receipt = await ref.read(accountRepositoryProvider).payFamily(
            allocations: allocations,
            allocate: _clearArrears ? 'oldest' : null,
          );
      // Refresh caches so balances update everywhere.
      ref.invalidate(familyDetailProvider(widget.familyKey));
      ref.invalidate(familiesProvider);
      ref.invalidate(accountsDirectoryProvider);
      if (!mounted) return;
      _seeded = false; // re-seed from fresh balances after the dialog closes
      await showDialog(
        context: context,
        builder: (_) => _FamilyInvoiceDialog(receipt: receipt),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detailAsync = ref.watch(familyDetailProvider(widget.familyKey));

    return Scaffold(
      backgroundColor: colors.background,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AbmErrorView(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.invalidate(familyDetailProvider(widget.familyKey)),
        ),
        data: (detail) {
          if (!_seeded) {
            _seed(detail);
            _seeded = true;
          }
          return _buildContent(context, detail);
        },
      ),
    );
  }

  void _toggleAll(FamilyDetail detail, bool select) {
    setState(() {
      for (final c in detail.children) {
        if (select) {
          _included.add(c.studentId);
        } else {
          _included.remove(c.studentId);
        }
      }
    });
  }

  Future<void> _manageParentLogin(FamilyDetail detail) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ParentLoginDialog(
        familyKey: widget.familyKey,
        guardianName: detail.guardianName,
        defaultUsername: detail.parentContact.trim(),
      ),
    );
  }

  Future<void> _openChildCharge(FamilyChildDetail c) async {
    final now = DateTime.now();
    final labels = <String>{};
    for (int i = -3; i <= 11; i++) {
      labels.add(DateFormat('MMMM yyyy').format(DateTime(now.year, now.month + i, 1)));
    }
    final monthOptions = labels.toList()
      ..sort((a, b) => DateFormat('MMMM yyyy').parse(a).compareTo(DateFormat('MMMM yyyy').parse(b)));
    final current = DateFormat('MMMM yyyy').format(DateTime(now.year, now.month, 1));

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddChargeDialog(
        studentId: c.studentId,
        monthOptions: monthOptions,
        initialMonths: [current],
      ),
    );
    if (res != null && mounted) {
      ref.invalidate(familyDetailProvider(widget.familyKey));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${res['title']} added to ${c.fullName}')),
      );
    }
  }

  Widget _buildContent(BuildContext context, FamilyDetail detail) {
    final colors = context.colors;
    final typography = context.typography;
    final grand = _grandTotal(detail);
    final selectedCount = detail.children.where((c) => _included.contains(c.studentId)).length;
    final allSelected = selectedCount == detail.children.length;

    return Column(
      children: [
        AbmGradientHeader(
          title: detail.guardianName,
          eyebrow: 'FAMILY FEE COLLECTION',
          subtitle: '${detail.childCount} children'
              '${detail.parentContact.isNotEmpty ? ' • ${detail.parentContact}' : ''}',
          leading: AbmHeaderIconButton(
            icon: LucideIcons.arrowLeft,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          trailing: AbmHeaderIconButton(
            icon: LucideIcons.keyRound,
            tooltip: 'Parent login',
            onTap: () => _manageParentLogin(detail),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _familyTotals(context, detail),
              if (detail.siblingDiscount.enabled && detail.siblingDiscount.amount > 0) ...[
                const Gap(12),
                _discountBanner(context, detail.siblingDiscount),
              ],
              const Gap(12),
              _howToBanner(context),
              const Gap(12),
              _arrearsToggle(context),
              const Gap(16),
              // Children section header + select all / none.
              Row(
                children: [
                  Icon(LucideIcons.users, size: 18, color: colors.primary),
                  const Gap(8),
                  Expanded(
                    child: Text('Children  ($selectedCount of ${detail.children.length} selected)',
                        style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                  ),
                  TextButton.icon(
                    onPressed: () => _toggleAll(detail, !allSelected),
                    icon: Icon(allSelected ? LucideIcons.square : LucideIcons.checkSquare, size: 16),
                    label: Text(allSelected ? 'Clear all' : 'Select all'),
                    style: TextButton.styleFrom(foregroundColor: colors.primary),
                  ),
                ],
              ),
              const Gap(8),
              ...detail.children.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _childCard(context, c),
                  )),
            ],
          ),
        ),
        _collectBar(context, detail, grand, selectedCount),
      ],
    );
  }

  // Plain-language guide so office staff know exactly what this screen does.
  Widget _howToBanner(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 18, color: colors.primary),
          const Gap(10),
          Expanded(
            child: Text(
              'Tick the children you\'re collecting for and set each amount (tap "Full" to charge the full balance). '
              'Tap Collect once — a single receipt covers the whole family.',
              style: typography.bodySmall.copyWith(color: colors.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _familyTotals(BuildContext context, FamilyDetail detail) {
    final colors = context.colors;
    final typography = context.typography;
    final cleared = detail.totalOutstanding <= 0;
    Widget cell(String label, double value, Color color) => Expanded(
          child: Column(
            children: [
              Text(sar(value), style: typography.bodyLargeSemiBold.copyWith(color: color)),
              const Gap(2),
              Text(label, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wallet, size: 16, color: colors.textSecondary),
              const Gap(8),
              Text('Family balance',
                  style: typography.bodySmall.copyWith(color: colors.textSecondary)),
              const Spacer(),
              if (cleared)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.checkCircle2, size: 14, color: Colors.green.shade600),
                  const Gap(4),
                  Text('All cleared',
                      style: typography.bodySmall.copyWith(color: Colors.green.shade600)),
                ]),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              cell('Total due', detail.totalOutstanding,
                  detail.totalOutstanding > 0 ? Colors.red.shade600 : Colors.green.shade600),
              _vDivider(colors.border),
              cell('This month', detail.totalCurrentDue, colors.textPrimary),
              _vDivider(colors.border),
              cell('Arrears', detail.totalArrears,
                  detail.totalArrears > 0 ? Colors.orange.shade700 : colors.textPrimary),
              if (detail.totalAdvance > 0) ...[
                _vDivider(colors.border),
                cell('Advance', detail.totalAdvance, Colors.green.shade600),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider(Color c) => Container(width: 1, height: 34, color: c);

  Widget _discountBanner(BuildContext context, SiblingDiscountInfo sd) {
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.badgePercent, size: 18, color: Colors.green.shade700),
          const Gap(10),
          Expanded(
            child: Text(
              'Sibling discount active — ${sar(sd.amount)} off tuition from child #${sd.fromChild}. '
              'It is already applied to each child\'s monthly bill.',
              style: typography.bodySmall.copyWith(color: Colors.green.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrearsToggle(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeThumbColor: colors.primary,
        title: Text('Clear arrears (oldest months first)',
            style: typography.bodyMedium.copyWith(color: colors.textPrimary)),
        subtitle: Text(
          _clearArrears
              ? 'Each child\'s payment clears their oldest dues first; surplus becomes advance credit.'
              : 'Off: collect this month\'s fee for each child.',
          style: typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        value: _clearArrears,
        onChanged: (v) {
          setState(() {
            _clearArrears = v;
            _seeded = false; // re-seed amounts (full dues vs current) on next build
          });
        },
      ),
    );
  }

  Widget _childCard(BuildContext context, FamilyChildDetail c) {
    final colors = context.colors;
    final typography = context.typography;
    final included = _included.contains(c.studentId);
    final controller = _amounts[c.studentId]!;
    final fullValue = _clearArrears ? c.totalOutstanding : c.currentBalance;

    void setInclude(bool v) => setState(() {
          if (v) {
            _included.add(c.studentId);
          } else {
            _included.remove(c.studentId);
          }
        });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: included ? colors.white : colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: included ? colors.primary.withValues(alpha: 0.45) : colors.border,
          width: included ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row with a tappable check to include/exclude the child.
          InkWell(
            onTap: () => setInclude(!included),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Checkbox(
                  value: included,
                  activeColor: colors.primary,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => setInclude(v == true),
                ),
                const Gap(2),
                abmInitialsAvatar(context, c.fullName, radius: 18),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.fullName,
                          style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${c.admissionNumber} • ${c.classroom}',
                          style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
                AbmStatusPill.status(context, c.status),
              ],
            ),
          ),
          const Gap(10),
          // Balance breakdown as clear pills.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _breakdownPill(context, 'This month', c.currentBalance,
                  c.currentBalance > 0 ? Colors.red.shade600 : Colors.green.shade600),
              if (c.arrears > 0)
                _breakdownPill(context, 'Arrears', c.arrears, Colors.orange.shade700),
              if (c.advanceBalance > 0)
                _breakdownPill(context, 'Advance credit', c.advanceBalance, Colors.green.shade600),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openChildCharge(c),
              icon: const Icon(LucideIcons.plus, size: 15),
              label: const Text('Add books / charge'),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const Gap(8),
          // Amount to collect — clearly labelled, with a one-tap "Full" fill.
          Row(
            children: [
              Text('Collect now',
                  style: typography.bodySmall.copyWith(color: colors.textSecondary)),
              const Spacer(),
              if (fullValue > 0)
                _fillButton(context, 'Full', () {
                  controller.text = fullValue.toStringAsFixed(0);
                  setInclude(true);
                }),
              const Gap(8),
              SizedBox(
                width: 128,
                child: TextField(
                  controller: controller,
                  enabled: included,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  textAlign: TextAlign.right,
                  style: typography.bodyLargeSemiBold.copyWith(color: colors.primary),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: 'SAR ',
                    prefixStyle: typography.bodySmall.copyWith(color: colors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: included ? colors.primary.withValues(alpha: 0.06) : colors.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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

  Widget _breakdownPill(BuildContext context, String label, double value, Color color) {
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label · ${sar(value)}',
          style: typography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _fillButton(BuildContext context, String label, VoidCallback onTap) {
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      color: colors.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(label,
              style: typography.bodySmallSemiBold.copyWith(color: colors.primary)),
        ),
      ),
    );
  }

  Widget _collectBar(BuildContext context, FamilyDetail detail, double grand, int selectedCount) {
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      elevation: 8,
      color: colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$selectedCount ${selectedCount == 1 ? 'child' : 'children'}',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                  Text(sar(grand),
                      style: typography.h4.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
              const Gap(16),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: (_processing || grand <= 0) ? null : () => _collect(detail),
                    icon: _processing
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.creditCard, size: 18),
                    label: Text(_processing ? 'Processing…' : 'Collect Combined Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Combined family invoice ─────────────────────────────────────────────────

class _FamilyInvoiceDialog extends StatelessWidget {
  const _FamilyInvoiceDialog({required this.receipt});
  final FamilyReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final screenHeight = MediaQuery.of(context).size.height;

    return SelectionArea(
      child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: screenHeight * 0.88),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.checkCircle2, color: Colors.green.shade600, size: 32),
                      ),
                    ),
                    const Gap(12),
                    Center(
                      child: Text('Payment Recorded',
                          style: typography.h3.copyWith(color: colors.textPrimary)),
                    ),
                    const Gap(4),
                    Center(
                      child: Text('Receipt #${receipt.receiptNumber}',
                          style: typography.bodySmall.copyWith(
                              color: colors.primary, fontFamily: 'monospace')),
                    ),
                    const Gap(16),
                    _kv(context, 'Guardian', receipt.guardianName),
                    if (receipt.parentContact.isNotEmpty) _kv(context, 'Contact', receipt.parentContact),
                    _kv(context, 'Date', DateFormat('dd MMM yyyy').format(receipt.paidOn)),
                    const Gap(12),
                    Divider(color: colors.border),
                    const Gap(8),
                    Text('Children', style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                    const Gap(8),
                    ...receipt.children.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.fullName,
                                        style: typography.bodyMedium.copyWith(color: colors.textPrimary)),
                                    Text('${c.classroom} • ${c.monthLabel}',
                                        style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                                  ],
                                ),
                              ),
                              Text(sar(c.amountPaid),
                                  style: typography.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                            ],
                          ),
                        )),
                    const Gap(4),
                    Divider(color: colors.border),
                    const Gap(8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Total Collected',
                              style: typography.bodyLargeSemiBold.copyWith(color: colors.textPrimary)),
                        ),
                        Text(sar(receipt.totalCollected),
                            style: typography.h4.copyWith(color: Colors.green.shade700)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
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
                      onPressed: () => _printInvoice(),
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
                      onPressed: () => _sendWhatsApp(context),
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

  Widget _kv(BuildContext context, String k, String v) {
    final colors = context.colors;
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(k, style: typography.bodySmall.copyWith(color: colors.textSecondary))),
          Expanded(child: Text(v, style: typography.bodyMedium.copyWith(color: colors.textPrimary))),
        ],
      ),
    );
  }

  Future<void> _printInvoice() async {
    await Printing.layoutPdf(onLayout: (_) => _buildPdf().save());
  }

  String _whatsAppMessage() {
    final b = StringBuffer()
      ..writeln('*Fee Receipt — Anas Bin Malik Madrasa*')
      ..writeln('Receipt: #${receipt.receiptNumber}')
      ..writeln('Guardian: ${receipt.guardianName}')
      ..writeln('Date: ${DateFormat('dd MMM yyyy').format(receipt.paidOn)}')
      ..writeln('');
    for (final c in receipt.children) {
      final tag = [c.classroom, c.monthLabel].where((s) => s.isNotEmpty).join(' • ');
      b.writeln('• ${c.fullName}${tag.isNotEmpty ? ' ($tag)' : ''}: ${sar(c.amountPaid)}');
    }
    b
      ..writeln('')
      ..writeln('Total Paid: ${sar(receipt.totalCollected)}')
      ..writeln('')
      ..writeln('Thank you! May Allah bless you.');
    return b.toString();
  }

  Future<void> _sendWhatsApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // Capture the share-sheet anchor (iPad) synchronously, before any await.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);
    final message = _whatsAppMessage();
    final bytes = await _buildPdf().save();
    final fname = 'receipt-${receipt.receiptNumber}.pdf';

    if (!kIsWeb) {
      // Mobile: one share-sheet action carrying BOTH the PDF (attached) and the
      // receipt text (as caption). Staff pick the guardian's WhatsApp chat → the
      // PDF and message go together. wa.me links can't attach files.
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

    // Web: download the PDF (staff attach it) then open the guardian's chat.
    try {
      await Printing.sharePdf(bytes: bytes, filename: fname);
    } catch (_) {}
    final ok = await WhatsAppService.send(receipt.parentContact, message);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(receipt.parentContact.trim().isEmpty
            ? 'No guardian number on file for this family.'
            : 'Could not open WhatsApp for ${receipt.parentContact}.'),
      ));
    }
  }

  pw.Document _buildPdf() {
    final pdf = pw.Document();
    final green = PdfColor.fromInt(0xFF1B3D2F);
    final gold = PdfColor.fromInt(0xFFB8860B);
    final softBg = PdfColor.fromInt(0xFFF4F6F3);
    final dateStr = DateFormat('dd MMM yyyy').format(receipt.paidOn);

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
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
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
                      pw.Text('FAMILY FEE RECEIPT', style: pw.TextStyle(color: gold, fontSize: 9, letterSpacing: 1.5)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E7D32), borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Text('PAID',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
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
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    cell('Receipt No.', receipt.receiptNumber),
                    cell('Date', dateStr, right: true),
                  ]),
                  pw.SizedBox(height: 18),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(color: softBg, borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('BILLED TO',
                          style: pw.TextStyle(fontSize: 7, color: green, letterSpacing: 0.8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(receipt.guardianName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: green)),
                      pw.SizedBox(height: 10),
                      pw.Row(children: [
                        pw.Expanded(
                            child: receipt.parentContact.isNotEmpty
                                ? cell('Contact', receipt.parentContact)
                                : cell('Family', 'Sibling group')),
                        pw.Expanded(child: cell('Children', '${receipt.children.length}', right: true)),
                      ]),
                    ]),
                  ),
                  pw.SizedBox(height: 18),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: pw.BoxDecoration(color: green, borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('CHILD',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                      pw.Text('AMOUNT',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                    ]),
                  ),
                  ...receipt.children.asMap().entries.map((e) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: e.key.isEven ? PdfColors.white : softBg,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                pw.Text(e.value.fullName, style: const pw.TextStyle(fontSize: 10)),
                                pw.Text(
                                    [e.value.classroom, e.value.monthLabel].where((s) => s.isNotEmpty).join('  •  '),
                                    style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                              ]),
                            ),
                            pw.Text('SAR ${e.value.amountPaid.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      )),
                  pw.SizedBox(height: 14),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: pw.BoxDecoration(color: green, borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text('TOTAL PAID',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                      pw.Text('SAR ${receipt.totalCollected.toStringAsFixed(0)}',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 17, fontWeight: pw.FontWeight.bold)),
                    ]),
                  ),
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
        ),
      ),
    );
    return pdf;
  }
}

// ─── Parent login management (office) ────────────────────────────────────────
class _ParentLoginDialog extends ConsumerStatefulWidget {
  const _ParentLoginDialog({
    required this.familyKey,
    required this.guardianName,
    required this.defaultUsername,
  });
  final String familyKey;
  final String guardianName;
  final String defaultUsername;

  @override
  ConsumerState<_ParentLoginDialog> createState() => _ParentLoginDialogState();
}

class _ParentLoginDialogState extends ConsumerState<_ParentLoginDialog> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = true, _saving = false, _obscure = true;
  bool _phoneLogin = true; // passwordless (mobile-number) sign-in
  FamilyLoginStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await ref.read(accountRepositoryProvider).getFamilyLogin(widget.familyKey);
      if (!mounted) return;
      setState(() {
        _status = s;
        _userCtrl.text = s.username ?? widget.defaultUsername;
        _phoneLogin = s.hasLogin ? s.phoneLoginEnabled : true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _userCtrl.text = widget.defaultUsername;
          _loading = false;
        });
      }
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save({required bool enabled}) async {
    final hasLogin = _status?.hasLogin == true;
    if (_userCtrl.text.trim().isEmpty) return _snack('Enter a username');
    if (!hasLogin && !_phoneLogin && _passCtrl.text.trim().isEmpty) {
      return _snack('Set a password, or turn on phone sign-in');
    }
    setState(() => _saving = true);
    try {
      final s = await ref.read(accountRepositoryProvider).setFamilyLogin(
            widget.familyKey,
            username: _userCtrl.text.trim(),
            password: _passCtrl.text.trim(),
            enabled: enabled,
            phoneLogin: _phoneLogin,
          );
      if (!mounted) return;
      setState(() {
        _status = s;
        _saving = false;
      });
      _snack(enabled ? 'Parent login saved' : 'Parent login disabled');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(friendlyErrorMessage(e));
      }
    }
  }

  Future<void> _remove() async {
    setState(() => _saving = true);
    try {
      await ref.read(accountRepositoryProvider).deleteFamilyLogin(widget.familyKey);
      if (!mounted) return;
      setState(() {
        _status = const FamilyLoginStatus(hasLogin: false, username: null, enabled: false);
        _passCtrl.clear();
        _saving = false;
      });
      _snack('Parent login removed');
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
    final t = context.typography;
    final hasLogin = _status?.hasLogin == true;
    final enabled = _status?.enabled == true;

    return AlertDialog(
      title: const Row(
        children: [Icon(LucideIcons.keyRound, size: 18), Gap(8), Text('Parent Login')],
      ),
      content: SizedBox(
        width: 400,
        child: _loading
            ? const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'One login for ${widget.guardianName}\'s family — the parent sees all their children, attendance and fees, and gets absence & fee alerts.',
                      style: t.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                    const Gap(10),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        dense: true,
                        value: _phoneLogin,
                        onChanged: _saving ? null : (v) => setState(() => _phoneLogin = v),
                        title: Text('Sign in with phone number',
                            style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                        subtitle: Text('Parent logs in with just their mobile — no password needed',
                            style: t.bodySmall.copyWith(color: colors.textSecondary)),
                      ),
                    ),
                    const Gap(12),
                    if (hasLogin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: (enabled ? colors.green : colors.warning).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(enabled ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
                                size: 16, color: enabled ? colors.green : colors.warning),
                            const Gap(8),
                            Text(enabled ? 'Login active' : 'Login disabled',
                                style: t.bodySmallSemiBold.copyWith(color: colors.textPrimary)),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username (usually the phone)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(LucideIcons.userCog, size: 18),
                      ),
                    ),
                    const Gap(12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: _phoneLogin
                            ? 'Password (optional)'
                            : (hasLogin ? 'New password (blank = keep current)' : 'Password'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: const Icon(LucideIcons.lock, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    if (_phoneLogin)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Icon(LucideIcons.info, size: 14, color: colors.textSecondary),
                            const Gap(6),
                            Expanded(
                              child: Text(
                                'Parent signs in with just their mobile number — nothing to share.',
                                style: t.bodySmall.copyWith(color: colors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_passCtrl.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Share with parent — ${_userCtrl.text.trim()} / ${_passCtrl.text.trim()}',
                                style: t.bodySmall.copyWith(color: colors.textSecondary),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.copy, size: 16),
                              tooltip: 'Copy',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: 'Username: ${_userCtrl.text.trim()}\nPassword: ${_passCtrl.text.trim()}'));
                                _snack('Credentials copied');
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        if (hasLogin)
          TextButton(
            onPressed: _saving ? null : _remove,
            child: Text('Remove', style: TextStyle(color: Colors.red.shade600)),
          ),
        if (hasLogin)
          TextButton(
            onPressed: _saving ? null : () => _save(enabled: !enabled),
            child: Text(enabled ? 'Disable' : 'Enable'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(enabled: true),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(hasLogin ? 'Update' : 'Create login'),
        ),
      ],
    );
  }
}
