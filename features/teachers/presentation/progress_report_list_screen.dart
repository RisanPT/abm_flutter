import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _madrasaGreen = Color(0xFF1B3D2F);
const _madrasaGold = Color(0xFFB8860B);

final progressReportsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final instituteId = ref.watch(selectedInstituteProvider).id;
  final res = await dio.get('/progress-reports', queryParameters: {
    'instituteId': instituteId,
  });
  return res.data as List<dynamic>;
});

class ProgressReportListScreen extends ConsumerStatefulWidget {
  const ProgressReportListScreen({super.key});

  @override
  ConsumerState<ProgressReportListScreen> createState() => _ProgressReportListScreenState();
}

class _ProgressReportListScreenState extends ConsumerState<ProgressReportListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedGrade;
  String? _selectedTerm;
  String _selectedStatus = 'All'; // 'All', 'Passed', 'Failed'
  int _page = 1;
  static const int _pageSize = 8;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final reportsAsync = ref.watch(progressReportsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Progress Reports',
            subtitle: 'View, filter, and manage student academic progress records',
            showBackButton: false,
            compact: true,
            actions: [
              FilledButton.icon(
                onPressed: () {
                  context.push(RouteNames.addProgressReport).then((_) {
                    ref.invalidate(progressReportsProvider);
                  });
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('New Report'),
                style: FilledButton.styleFrom(
                  backgroundColor: _madrasaGold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Gap(8),
              IconButton(
                onPressed: () => ref.invalidate(progressReportsProvider),
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                tooltip: 'Refresh Reports',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          Expanded(
            child: reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 40),
                      const Gap(12),
                      Text(friendlyErrorMessage(e), textAlign: TextAlign.center),
                      const Gap(16),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(progressReportsProvider),
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Try Again'),
                        style: FilledButton.styleFrom(backgroundColor: _madrasaGreen),
                      ),
                    ],
                  ),
                ),
              ),
              data: (allReports) {
                // Collect distinct classrooms and terms for filter dropdowns
                final gradesSet = <String>{};
                final termsSet = <String>{};
                int passedCount = 0;
                int failedCount = 0;

                for (final item in allReports) {
                  final r = item as Map<String, dynamic>;
                  final studentData = r['studentId'];
                  if (studentData is Map && studentData['grade'] != null) {
                    final g = studentData['grade'].toString().trim();
                    if (g.isNotEmpty) gradesSet.add(g);
                  }
                  if (r['term'] != null && r['term'].toString().trim().isNotEmpty) {
                    termsSet.add(r['term'].toString().trim());
                  }

                  // Determine status
                  final status = (r['evaluationStatus'] ?? 'Passed').toString().toLowerCase();
                  if (status == 'passed') {
                    passedCount++;
                  } else {
                    failedCount++;
                  }
                }

                final distinctGrades = gradesSet.toList()..sort();
                final distinctTerms = termsSet.toList()..sort();

                // Apply live search & filters
                final filtered = allReports.where((item) {
                  final r = item as Map<String, dynamic>;
                  final studentData = r['studentId'];
                  final studentName = (studentData is Map ? studentData['fullName'] : null)?.toString() ?? '';
                  final admNo = (studentData is Map ? studentData['studentId'] : null)?.toString() ?? '';
                  final grade = (studentData is Map ? studentData['grade'] : null)?.toString() ?? '';
                  final term = (r['term'] ?? '').toString();
                  final remarks = (r['remarks'] ?? '').toString();
                  final gradesList = (r['grades'] as List?) ?? [];
                  final subjectsText = gradesList.map((g) => (g['subject'] ?? '').toString()).join(' ');

                  // Search match
                  final matchesSearch = _searchQuery.isEmpty ||
                      studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      admNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      remarks.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      subjectsText.toLowerCase().contains(_searchQuery.toLowerCase());

                  // Grade filter
                  final matchesGrade = _selectedGrade == null || grade.toLowerCase() == _selectedGrade!.toLowerCase();

                  // Term filter
                  final matchesTerm = _selectedTerm == null || term.toLowerCase() == _selectedTerm!.toLowerCase();

                  // Status filter
                  final status = (r['evaluationStatus'] ?? 'Passed').toString().toLowerCase();
                  final matchesStatus = _selectedStatus == 'All' ||
                      (_selectedStatus == 'Passed' && status == 'passed') ||
                      (_selectedStatus == 'Failed' && status != 'passed');

                  return matchesSearch && matchesGrade && matchesTerm && matchesStatus;
                }).toList();

                final passRate = allReports.isNotEmpty ? ((passedCount / allReports.length) * 100).toInt() : 0;

                // Pagination calculations
                final totalCount = filtered.length;
                final totalPages = totalCount == 0 ? 1 : (totalCount / _pageSize).ceil();
                final effectivePage = _page.clamp(1, totalPages);
                final startIndex = totalCount == 0 ? 0 : (effectivePage - 1) * _pageSize;
                final endIndex = (startIndex + _pageSize).clamp(0, totalCount);
                final pagedItems = totalCount == 0 ? <dynamic>[] : filtered.sublist(startIndex, endIndex);

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                    children: [
                      // Top KPI Stat Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          final kpis = [
                            _ProgressKpiCard(
                              title: 'Total Reports Filed',
                              value: '${allReports.length}',
                              subtext: '${distinctGrades.length} classes evaluated',
                              icon: LucideIcons.fileText,
                              color: const Color(0xFF2563EB),
                              badge: 'All Terms',
                            ),
                            _ProgressKpiCard(
                              title: 'Passed Evaluations',
                              value: '$passedCount',
                              subtext: '$passRate% overall success rate',
                              icon: LucideIcons.checkCircle2,
                              color: const Color(0xFF059669),
                              badge: '$passRate% Pass Rate',
                            ),
                            _ProgressKpiCard(
                              title: 'Needs Attention',
                              value: '$failedCount',
                              subtext: 'Requires remedial follow-up',
                              icon: LucideIcons.alertCircle,
                              color: const Color(0xFFDC2626),
                              badge: failedCount == 0 ? 'Zero Backlogs' : '$failedCount Retakes',
                            ),
                          ];

                          if (isWide) {
                            return Row(
                              children: [
                                for (int i = 0; i < kpis.length; i++) ...[
                                  if (i > 0) const Gap(12),
                                  Expanded(child: kpis[i]),
                                ],
                              ],
                            );
                          }
                          return Column(
                            children: [
                              for (int i = 0; i < kpis.length; i++) ...[
                                if (i > 0) const Gap(8),
                                kpis[i],
                              ],
                            ],
                          );
                        },
                      ),

                      const Gap(14),

                      // Filter & Search Toolbar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search row
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (val) => setState(() {
                                      _searchQuery = val.trim();
                                      _page = 1;
                                    }),
                                    decoration: InputDecoration(
                                      hintText: 'Search by student name, admission ID, subject, or remarks...',
                                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty || _selectedGrade != null || _selectedTerm != null || _selectedStatus != 'All') ...[
                                  const Gap(8),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedGrade = null;
                                        _selectedTerm = null;
                                        _selectedStatus = 'All';
                                        _page = 1;
                                      });
                                    },
                                    icon: const Icon(LucideIcons.rotateCcw, size: 14),
                                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ],
                            ),

                            const Gap(10),

                            // Dropdown filters row
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                // Class / Grade filter
                                SizedBox(
                                  width: 170,
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: _selectedGrade,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Class / Grade',
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(LucideIcons.graduationCap, size: 16),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('All Classes', style: TextStyle(fontSize: 12))),
                                      ...distinctGrades.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))),
                                    ],
                                    onChanged: (val) => setState(() {
                                      _selectedGrade = val;
                                      _page = 1;
                                    }),
                                  ),
                                ),

                                // Term filter
                                SizedBox(
                                  width: 160,
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: _selectedTerm,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Evaluation Term',
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(LucideIcons.calendar, size: 16),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('All Terms', style: TextStyle(fontSize: 12))),
                                      ...distinctTerms.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))),
                                    ],
                                    onChanged: (val) => setState(() {
                                      _selectedTerm = val;
                                      _page = 1;
                                    }),
                                  ),
                                ),

                                // Status filter segmented buttons
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(value: 'All', label: Text('All Results', style: TextStyle(fontSize: 11))),
                                    ButtonSegment(value: 'Passed', label: Text('Passed', style: TextStyle(fontSize: 11))),
                                    ButtonSegment(value: 'Failed', label: Text('Failed', style: TextStyle(fontSize: 11))),
                                  ],
                                  selected: {_selectedStatus},
                                  onSelectionChanged: (set) => setState(() {
                                    _selectedStatus = set.first;
                                    _page = 1;
                                  }),
                                  style: const ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Gap(16),

                      // Results header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            totalCount == 0
                                ? 'Progress Records (0)'
                                : 'Progress Records ($totalCount) · Showing ${startIndex + 1}–$endIndex',
                            style: typography.bodyMediumSemiBold,
                          ),
                          if (_selectedGrade != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _madrasaGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Filtered by $_selectedGrade',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _madrasaGreen),
                              ),
                            ),
                        ],
                      ),

                      const Gap(10),

                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _madrasaGreen.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.fileSearch, size: 36, color: _madrasaGreen),
                              ),
                              const Gap(12),
                              Text('No matching progress reports', style: typography.bodyLargeSemiBold),
                              const Gap(6),
                              Text(
                                'Try adjusting your search query, class, or term filters.',
                                style: typography.bodySmall.copyWith(color: colors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const Gap(16),
                              FilledButton.icon(
                                onPressed: () {
                                  context.push(RouteNames.addProgressReport).then((_) {
                                    ref.invalidate(progressReportsProvider);
                                  });
                                },
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Add Progress Report'),
                                style: FilledButton.styleFrom(backgroundColor: _madrasaGreen),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        for (final item in pagedItems) ...[
                          _buildReportCard(context, ref, item as Map<String, dynamic>),
                          const Gap(12),
                        ],
                        if (totalPages > 1) ...[
                          const Gap(10),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: AbmPaginationBar(
                                page: effectivePage,
                                totalPages: totalPages,
                                total: totalCount,
                                onPage: (p) {
                                  setState(() => _page = p);
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                },
                              ),
                            ),
                          ),
                          const Gap(6),
                          Center(
                            child: Text(
                              'Showing ${startIndex + 1}–$endIndex of $totalCount reports · $_pageSize per page',
                              style: typography.bodySmall.copyWith(color: colors.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RouteNames.addProgressReport).then((_) {
            ref.invalidate(progressReportsProvider);
          });
        },
        backgroundColor: _madrasaGreen,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, WidgetRef ref, Map<String, dynamic> report) {
    final colors = context.colors;
    final typography = context.typography;
    final studentData = report['studentId'];

    // Resolve student info safely
    String studentName = 'Student';
    String studentGrade = 'No Class';
    String studentAdm = '';

    if (studentData is Map) {
      studentName = studentData['fullName']?.toString() ?? 'Student';
      studentGrade = studentData['grade']?.toString() ?? 'Class';
      studentAdm = studentData['studentId']?.toString() ?? '';
    }

    final term = (report['term'] ?? 'Term').toString();
    final academicYear = (report['academicYear'] ?? '').toString();
    final remarks = (report['remarks'] ?? '').toString().trim();
    final grades = (report['grades'] as List?) ?? [];

    // Calculate marks summary
    double totalMark = 0;
    for (final g in grades) {
      totalMark += ((g['mark'] as num?) ?? 0).toDouble();
    }
    final avgMark = grades.isNotEmpty ? (totalMark / grades.length) : 0.0;
    final isPassed = avgMark >= 50;
    final statusText = isPassed ? 'PASSED' : 'FAILED';

    final reportId = report['_id']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(RouteNames.editProgressReport, extra: report).then((_) {
              ref.invalidate(progressReportsProvider);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Student avatar, name, grade badge, status pill & popup
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _madrasaGreen.withValues(alpha: 0.12),
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                        style: const TextStyle(color: _madrasaGreen, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentName, style: typography.bodyLargeSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const Gap(3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              // Class badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  studentGrade,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                ),
                              ),
                              if (studentAdm.isNotEmpty)
                                Text('Adm: $studentAdm', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                              if (academicYear.isNotEmpty)
                                Text('· $academicYear', style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    // Result pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isPassed ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPassed ? LucideIcons.check : LucideIcons.x,
                            size: 13,
                            color: isPassed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          ),
                          const Gap(4),
                          Text(
                            '$statusText · ${avgMark.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPassed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(6),
                    PopupMenuButton<String>(
                      icon: const Icon(LucideIcons.moreVertical, size: 18),
                      onSelected: (val) {
                        if (val == 'edit') {
                          context.push(RouteNames.editProgressReport, extra: report).then((_) {
                            ref.invalidate(progressReportsProvider);
                          });
                        } else if (val == 'delete' && reportId.isNotEmpty) {
                          _deleteReport(context, ref, reportId, studentName);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit Report')),
                        PopupMenuItem(value: 'delete', child: Text('Delete Report', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),

                const Gap(12),
                const Divider(height: 1),
                const Gap(10),

                // Evaluation Term & Subject Chips row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF4B5563)),
                          const Gap(4),
                          Text(term, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Text('${grades.length} Subjects Evaluated', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                  ],
                ),

                const Gap(8),

                // Subject Scores visual chips
                if (grades.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: grades.map((g) {
                      final sName = (g['subject'] ?? '').toString();
                      final sMark = (g['mark'] ?? 0).toString();
                      final sGrade = (g['grade'] ?? '').toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '$sName: $sMark ${sGrade.isNotEmpty ? "($sGrade)" : ""}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),

                if (remarks.isNotEmpty) ...[
                  const Gap(10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.quote, size: 12, color: Colors.grey),
                        const Gap(6),
                        Expanded(
                          child: Text(
                            remarks,
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Future<void> _deleteReport(BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Progress Report?'),
        content: Text('Delete progress report for "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(dioProvider).delete('/progress-reports/$id');
        ref.invalidate(progressReportsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted successfully')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        }
      }
    }
  }
}

class _ProgressKpiCard extends StatelessWidget {
  const _ProgressKpiCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.badge,
  });

  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Gap(8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
          const Gap(2),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
          const Gap(1),
          Text(subtext, style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}
