import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/students/domain/student_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/features/students/presentation/student_controller.dart';
import 'package:abm_madrasa/features/students/presentation/widgets/student_list_widgets.dart';
import 'package:abm_madrasa/features/students/data/student_repository.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  final String? initialClass;
  const StudentListScreen({super.key, this.initialClass});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  String? selectedClass;
  String? selectedShift;
  String selectedStatus = 'active'; // 'active' | 'inactive' | 'all'
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialClass != null) {
      selectedClass = widget.initialClass;
      Future.microtask(() {
        ref.read(studentControllerProvider.notifier).filter(selectedClass, selectedShift);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Load the next page when the user nears the bottom of the directory.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(studentControllerProvider.notifier).loadMore();
    }
  }

  // Export the FULL directory (not just the loaded pages).
  Future<void> _handleExportPdf() async {
    try {
      final students = await ref.read(allStudentsProvider.future);
      await _exportStudentsPdf(students);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  Future<void> _exportStudentsPdf(List<StudentModel> students) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Student Directory Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Total Students: ${students.length}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Student ID', 'Full Name', 'Gender', 'Class', 'Parent Contact', 'Address'],
            data: students.map((s) => [
              s.admissionNumber,
              s.fullName,
              s.gender.name,
              s.classroom,
              s.guardianContact,
              s.address,
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
    final studentsAsync = ref.watch(studentControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: ABMPageHeader(
              title: 'Student Directory',
              subtitle: studentsAsync.maybeWhen(
                data: (s) => selectedStatus == 'active'
                    ? '${s.total} active students'
                    : selectedStatus == 'inactive'
                        ? '${s.total} inactive students'
                        : '${s.total} students',
                orElse: () => 'Manage all enrolled students',
              ),
              showBackButton: false,
              actions: [
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 20),
                    tooltip: 'Refresh',
                    onPressed: () => ref.read(studentControllerProvider.notifier).refresh(),
                  ),
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(LucideIcons.table, color: Colors.white, size: 20),
                    tooltip: 'Bulk Add / Import CSV',
                    onPressed: () => context.push(RouteNames.bulkAddStudents),
                  ),
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowUpCircle, color: Colors.white, size: 20),
                    tooltip: 'Promote Eligible Students',
                    onPressed: () => _handlePromoteStudents(context),
                  ),
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(LucideIcons.download, color: Colors.white, size: 20),
                    onPressed: _handleExportPdf,
                    tooltip: 'Export PDF (all)',
                  ),
                ),
              ],
              bottomChild: StudentSearchField(
                onChanged: (val) => ref.read(studentControllerProvider.notifier).search(val),
              ),
            ),
          ),
          _buildFilters(context),
          _buildStudentContent(context, studentsAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addStudent),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _handlePromoteStudents(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Promotion'),
        content: const Text('Are you sure you want to promote all students who have "Passed" their evaluation? This will increment their grade level.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Promote')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final count = await ref.read(studentRepositoryProvider).promoteStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully promoted $count students.')));
          ref.read(studentControllerProvider.notifier).refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        }
      }
    }
  }

  Widget _buildFilters(BuildContext context) {
    final colors = context.colors;
    final classroomsAsync = ref.watch(classroomControllerProvider);

    return SliverToBoxAdapter(
      child: classroomsAsync.when(
        data: (classes) {
          final filterOptions = ['All', ...classes.map((c) => c.name)];
          final shiftOptions = ['All', 'Shift-1', 'Shift-2'];
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: filterOptions.map((c) {
                      final isSelected = (selectedClass ?? 'All') == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(c),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => selectedClass = c == 'All' ? null : c);
                            ref.read(studentControllerProvider.notifier).filter(selectedClass, selectedShift);
                          },
                          backgroundColor: colors.white,
                          selectedColor: colors.primary.withValues(alpha: 0.1),
                          checkmarkColor: colors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF163D32) : const Color(0xFF3B4C45),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? colors.primary : colors.border),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Gap(12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: shiftOptions.map((s) {
                      final isSelected = (selectedShift ?? 'All') == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(s),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => selectedShift = s == 'All' ? null : s);
                            ref.read(studentControllerProvider.notifier).filter(selectedClass, selectedShift);
                          },
                          backgroundColor: colors.white,
                          selectedColor: colors.primary.withValues(alpha: 0.1),
                          checkmarkColor: colors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF163D32) : const Color(0xFF3B4C45),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? colors.primary : colors.border),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Gap(12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: const [('active', 'Active'), ('inactive', 'Inactive'), ('all', 'All')].map((opt) {
                      final isSelected = selectedStatus == opt.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(opt.$2),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => selectedStatus = opt.$1);
                            ref.read(studentControllerProvider.notifier).setStatus(opt.$1);
                          },
                          backgroundColor: colors.white,
                          selectedColor: colors.primary.withValues(alpha: 0.1),
                          checkmarkColor: colors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF163D32) : const Color(0xFF3B4C45),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? colors.primary : colors.border),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(friendlyErrorMessage(err))),
      ),
    );
  }

  Widget _buildStudentContent(BuildContext context, AsyncValue<StudentListState> studentsAsync) {
    return studentsAsync.when(
      data: (s) {
        final students = s.items;
        if (students.isEmpty) {
          final filtering = selectedClass != null || selectedShift != null || selectedStatus != 'active';
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(filtering ? LucideIcons.filterX : LucideIcons.users,
                        size: 48, color: context.colors.textSecondary),
                    const Gap(12),
                    Text(
                      filtering ? 'No students match these filters' : 'No students yet',
                      style: context.typography.bodyLargeSemiBold.copyWith(color: context.colors.textPrimary),
                    ),
                    const Gap(6),
                    Text(
                      filtering
                          ? 'Try clearing the class, shift or status filters.'
                          : 'Tap "Add Student" to enroll your first student.',
                      textAlign: TextAlign.center,
                      style: context.typography.bodyMedium.copyWith(color: context.colors.textSecondary),
                    ),
                    const Gap(16),
                    if (filtering)
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedClass = null;
                            selectedShift = null;
                            selectedStatus = 'active';
                          });
                          ref.read(studentControllerProvider.notifier).filter(null, null);
                          ref.read(studentControllerProvider.notifier).setStatus('active');
                        },
                        icon: const Icon(LucideIcons.x, size: 16),
                        label: const Text('Clear filters'),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => context.push(RouteNames.addStudent),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Add Student'),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: context.width > 600 ? 2.5 : 1.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => StudentCard(student: students[index]),
                  childCount: students.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _PagingFooter(
                loading: s.loadingMore,
                hasMore: s.hasMore,
                shown: students.length,
                total: s.total,
              ),
            ),
          ],
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (err, _) => SliverFillRemaining(child: Center(child: Text(friendlyErrorMessage(err)))),
    );
  }
}

/// Footer under the directory grid: a spinner while a page is loading, and a
/// subtle "showing all" line once every student has been fetched.
class _PagingFooter extends StatelessWidget {
  const _PagingFooter({
    required this.loading,
    required this.hasMore,
    required this.shown,
    required this.total,
  });

  final bool loading;
  final bool hasMore;
  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 96),
        child: Center(
          child: SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
      child: Center(
        child: Text(
          hasMore ? 'Showing $shown of $total' : 'All $total students loaded',
          style: context.typography.bodySmall.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
