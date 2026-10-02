import 'dart:async';

import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/network/paged_result.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/money.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:abm_madrasa/features/accounts/presentation/finance_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FamilyQuery {
  const FamilyQuery({this.search = '', this.page = 1});
  final String search;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is FamilyQuery && search == other.search && page == other.page;

  @override
  int get hashCode => Object.hash(search, page);
}

final familiesPageProvider =
    FutureProvider.autoDispose.family<PagedResult<FamilySummary>, FamilyQuery>((ref, q) {
  final instituteId = ref.watch(selectedInstituteProvider).id;
  return ref.read(accountRepositoryProvider).getFamiliesPage(
        instituteId: instituteId,
        search: q.search.isEmpty ? null : q.search,
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
  Timer? _debounce;

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
    final familyQuery = FamilyQuery(search: _query, page: _page);
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
          const Gap(12),
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

    return Dialog(
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
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _printInvoice(),
                      icon: const Icon(LucideIcons.printer, size: 16),
                      label: const Text('Print Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
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
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(children: [
                pw.Text('ANAS BIN MALIK MADRASA',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 4),
                pw.Text('FAMILY FEE RECEIPT', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
              ]),
            ),
            pw.SizedBox(height: 14),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Receipt #: ${receipt.receiptNumber}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text('Date: ${DateFormat('dd MMM yyyy').format(receipt.paidOn)}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text('Guardian: ${receipt.guardianName}', style: const pw.TextStyle(fontSize: 11)),
            if (receipt.parentContact.isNotEmpty)
              pw.Text('Contact: ${receipt.parentContact}', style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Text('Children', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 6),
            ...receipt.children.map((c) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${c.fullName}  (${c.classroom} • ${c.monthLabel})',
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Text('SAR ${c.amountPaid.toStringAsFixed(0)}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                )),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('SAR ${receipt.totalCollected.toStringAsFixed(0)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text('Thank you! May Allah bless you.',
                  style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic, color: PdfColors.grey600, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}
