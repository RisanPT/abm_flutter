import 'dart:async';
import 'dart:typed_data';
import 'package:abm_madrasa/core/error/error_utils.dart';

import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/teachers/data/teacher_repository.dart';
import 'package:abm_madrasa/features/teachers/domain/teacher_model.dart';
import 'package:abm_madrasa/features/teachers/presentation/teacher_controller.dart';
import 'package:abm_madrasa/features/timetable/presentation/timetable_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TeacherManagementScreen extends ConsumerStatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  ConsumerState<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends ConsumerState<TeacherManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedTeacherId;
  String _selectedShiftFilter = 'All';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportTeachersPdf(List<TeacherModel> teachers) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Teacher Directory Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Total Teachers: ${teachers.length}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Employee ID', 'Full Name', 'Title', 'Specialty', 'Email', 'Monthly Salary'],
            data: teachers.map((t) => [
              t.employeeId,
              t.fullName,
              t.title,
              t.specialty,
              t.email,
              'SAR ${t.monthlySalary.toStringAsFixed(2)}',
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
    // Paginated directory (infinite scroll) for the current search query.
    final teachersAsync = ref.watch(teacherDirectoryProvider(_query));
    // Unfiltered full list drives the summary stats so the "Total Teachers"
    // count / payroll stay accurate even while the directory is filtered.
    final allTeachers = ref.watch(teacherListProvider('')).value;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.isMobile ? 16 : 24,
            context.isMobile ? 8 : 24,
            context.isMobile ? 16 : 24,
            0,
          ),
          child: teachersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Failed to load teachers. ${friendlyErrorMessage(error)}')),
          data: (dir) {
            final allItems = allTeachers ?? dir.items;

            if (allItems.isEmpty) {
              return _TeacherEmptyState(onAdd: () => _showTeacherForm(context));
            }

            final countAll = allItems.length;
            final countShift1 = allItems.where((t) => t.hasShift1 && !t.isDualShift).length;
            final countShift2 = allItems.where((t) => t.hasShift2 && !t.isDualShift).length;
            final countDual = allItems.where((t) => t.isDualShift).length;

            final displayedTeachers = allItems.where((t) {
              if (_query.isNotEmpty) {
                final q = _query.toLowerCase();
                final match = t.fullName.toLowerCase().contains(q) ||
                    t.employeeId.toLowerCase().contains(q) ||
                    t.email.toLowerCase().contains(q) ||
                    t.specialty.toLowerCase().contains(q);
                if (!match) return false;
              }
              if (_selectedShiftFilter == 'Shift 1') {
                return t.hasShift1 && !t.isDualShift;
              } else if (_selectedShiftFilter == 'Shift 2') {
                return t.hasShift2 && !t.isDualShift;
              } else if (_selectedShiftFilter == 'Shift 1 + Shift 2') {
                return t.isDualShift;
              }
              return true;
            }).toList();

            final selectedTeacher = _resolveSelectedTeacher(displayedTeachers);
            final statsSource = allItems;
            void goToPage(int p) =>
                ref.read(teacherDirectoryProvider(_query).notifier).goToPage(p);

            final shiftCounts = {
              'All': countAll,
              'Shift 1': countShift1,
              'Shift 2': countShift2,
              'Shift 1 + Shift 2': countDual,
            };

            if (context.isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeacherScreenHeader(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onAddTeacher: () => _showTeacherForm(context),
                    onExportPdf: () => _exportTeachersPdf(displayedTeachers),
                  ),
                  const Gap(16),
                  _TeacherStatsBar(teachers: statsSource),
                  const Gap(16),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(bottom: context.isMobile ? 100 : 16),
                      children: [
                        // Use constrained box so the directory has a sensible
                        // height range on mobile — not a fixed 360px.
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 260, maxHeight: 400),
                          child: _TeacherDirectory(
                            teachers: displayedTeachers,
                            totalCount: displayedTeachers.length,
                            isSearching: _query.isNotEmpty || _selectedShiftFilter != 'All',
                            page: dir.page,
                            totalPages: dir.totalPages,
                            pageLoading: dir.pageLoading,
                            onPage: goToPage,
                            selectedTeacherId: _selectedTeacherId,
                            selectedShift: _selectedShiftFilter,
                            onShiftChanged: (shift) =>
                                setState(() => _selectedShiftFilter = shift),
                            shiftCounts: shiftCounts,
                            onSelect: (teacher) =>
                                setState(() => _selectedTeacherId = teacher.id),
                            onEdit: (teacher) => _showTeacherForm(context, teacher),
                            onDelete: (teacher) => _deleteTeacher(context, teacher),
                          ),
                        ),
                        const Gap(16),
                        if (selectedTeacher != null)
                          _TeacherDetailsCard(
                            teacher: selectedTeacher,
                            onEdit: () => _showTeacherForm(context, selectedTeacher),
                            onDelete: () => _deleteTeacher(context, selectedTeacher),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }


            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeacherScreenHeader(
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                  onAddTeacher: () => _showTeacherForm(context),
                  onExportPdf: () => _exportTeachersPdf(displayedTeachers),
                ),
                const Gap(20),
                _TeacherStatsBar(teachers: statsSource),
                const Gap(20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 360,
                        child: _TeacherDirectory(
                          teachers: displayedTeachers,
                          totalCount: displayedTeachers.length,
                          isSearching: _query.isNotEmpty || _selectedShiftFilter != 'All',
                          page: dir.page,
                          totalPages: dir.totalPages,
                          pageLoading: dir.pageLoading,
                          onPage: goToPage,
                          selectedTeacherId: _selectedTeacherId,
                          selectedShift: _selectedShiftFilter,
                          onShiftChanged: (shift) =>
                              setState(() => _selectedShiftFilter = shift),
                          shiftCounts: shiftCounts,
                          onSelect: (teacher) =>
                              setState(() => _selectedTeacherId = teacher.id),
                          onEdit: (teacher) => _showTeacherForm(context, teacher),
                          onDelete: (teacher) => _deleteTeacher(context, teacher),
                        ),
                      ),
                      const Gap(20),
                      Expanded(
                        child: selectedTeacher == null
                            ? const SizedBox.shrink()
                            : _TeacherDetailsCard(
                                teacher: selectedTeacher,
                                onEdit: () =>
                                    _showTeacherForm(context, selectedTeacher),
                                onDelete: () =>
                                    _deleteTeacher(context, selectedTeacher),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  TeacherModel? _resolveSelectedTeacher(List<TeacherModel> teachers) {
    if (teachers.isEmpty) {
      return null;
    }
    final selected = teachers.where((item) => item.id == _selectedTeacherId);
    if (selected.isNotEmpty) {
      return selected.first;
    }
    return teachers.first;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _showTeacherForm(
    BuildContext context, [
    TeacherModel? teacher,
  ]) async {
    // Resolve the correct institute to scope this teacher to.
    // IT Admin can freely choose; all other roles are locked to their own institute.
    final user = ref.read(authControllerProvider).value;
    final isAdmin = user?.role == AppRoles.itAdmin || user?.role == AppRoles.superAdmin;
    final selectedInstitute = ref.read(selectedInstituteProvider);
    final instituteId = isAdmin
        ? selectedInstitute.id
        : (user?.instituteId ?? selectedInstitute.id);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _TeacherFormDialog(
        existingTeacher: teacher,
        instituteId: instituteId,
        isAdmin: isAdmin,
      ),
    );
    ref.invalidate(teacherListProvider(''));
    ref.invalidate(teacherDirectoryProvider(_query));
    ref.invalidate(teacherDirectoryProvider(''));
    ref.invalidate(timetableDataProvider);
  }

  Future<void> _deleteTeacher(BuildContext context, TeacherModel teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Delete ${teacher.fullName} and remove their class assignments?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(teacherRepositoryProvider).deleteTeacher(teacher.id);
      if (!context.mounted) return;
      ref.invalidate(teacherListProvider(''));
      ref.invalidate(teacherDirectoryProvider(_query));
      ref.invalidate(teacherDirectoryProvider(''));
      ref.invalidate(timetableDataProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e))),
      );
    }
  }
}

class _TeacherScreenHeader extends StatelessWidget {
  const _TeacherScreenHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.onAddTeacher,
    this.onExportPdf,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddTeacher;
  final VoidCallback? onExportPdf;

  @override
  Widget build(BuildContext context) {
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Teacher Management', style: context.typography.h2),
        const Gap(6),
        Text(
          'Manage teacher profiles, images, and class schedules from one place.',
          style: context.typography.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );

    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search teachers...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: context.colors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: context.colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: context.colors.border),
        ),
      ),
    );

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 48, right: 96),
            child: intro,
          ),
          const Gap(16),
          search,
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddTeacher,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Teacher'),
                ),
              ),
              if (onExportPdf != null) ...[
                const Gap(12),
                IconButton(
                  icon: const Icon(LucideIcons.download),
                  onPressed: onExportPdf,
                  tooltip: 'Export PDF',
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: intro),
        const Gap(16),
        SizedBox(width: 280, child: search),
        const Gap(12),
        ElevatedButton.icon(
          onPressed: onAddTeacher,
          icon: const Icon(Icons.add),
          label: const Text('Add Teacher'),
        ),
        if (onExportPdf != null) ...[
          const Gap(12),
          IconButton(
            icon: const Icon(LucideIcons.download),
            onPressed: onExportPdf,
            tooltip: 'Export PDF',
          ),
        ],
        const Gap(152),
      ],
    );
  }
}

/// Summary strip across the top of the Teachers screen — the total teacher
/// count plus active, payroll and subjects-covered at a glance.
class _TeacherStatsBar extends StatelessWidget {
  const _TeacherStatsBar({required this.teachers});

  final List<TeacherModel> teachers;

  @override
  Widget build(BuildContext context) {
    final total = teachers.length;
    final active = teachers.where((t) => t.isActive).length;
    final payroll = teachers.fold<double>(0, (sum, t) => sum + t.monthlySalary);
    final subjects = <String>{
      for (final t in teachers) ...t.subjects.where((s) => s.trim().isNotEmpty),
    }.length;

    final cards = <Widget>[
      _StatCard(
        icon: LucideIcons.users,
        value: '$total',
        label: 'Total Teachers',
        tint: context.colors.primary,
      ),
      _StatCard(
        icon: LucideIcons.userCheck,
        value: '$active',
        label: 'Active',
        tint: const Color(0xFF2F855A),
      ),
      _StatCard(
        icon: LucideIcons.wallet,
        value: 'SAR ${payroll.toStringAsFixed(0)}',
        label: 'Monthly Payroll',
        tint: const Color(0xFFB8912F),
      ),
      _StatCard(
        icon: LucideIcons.bookOpen,
        value: '$subjects',
        label: 'Subjects Covered',
        tint: const Color(0xFF2B6CB0),
      ),
    ];

    if (context.isMobile) {
      return Column(
        children: [
          Row(children: [
            Expanded(child: cards[0]),
            const Gap(12),
            Expanded(child: cards[1]),
          ]),
          const Gap(12),
          Row(children: [
            Expanded(child: cards[2]),
            const Gap(12),
            Expanded(child: cards[3]),
          ]),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const Gap(16),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tint, size: 22),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: context.typography.h3.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Gap(2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherDirectory extends StatelessWidget {
  const _TeacherDirectory({
    required this.teachers,
    required this.totalCount,
    required this.isSearching,
    required this.page,
    required this.totalPages,
    required this.pageLoading,
    required this.onPage,
    required this.selectedTeacherId,
    required this.selectedShift,
    required this.onShiftChanged,
    required this.shiftCounts,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TeacherModel> teachers;
  final int totalCount;
  final bool isSearching;
  final int page;
  final int totalPages;
  final bool pageLoading;
  final ValueChanged<int> onPage;
  final String? selectedTeacherId;
  final String selectedShift;
  final ValueChanged<String> onShiftChanged;
  final Map<String, int> shiftCounts;
  final ValueChanged<TeacherModel> onSelect;
  final ValueChanged<TeacherModel> onEdit;
  final ValueChanged<TeacherModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Directory header with the live count.
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 10),
            child: Row(
              children: [
                Icon(LucideIcons.users, size: 18, color: colors.textSecondary),
                const Gap(8),
                Text('Directory', style: context.typography.bodyMediumSemiBold),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isSearching ? '${teachers.length} of $totalCount' : '$totalCount',
                    style: context.typography.bodySmallSemiBold.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Shift filter selector chips (All, Shift 1, Shift 2, Shift 1 + Shift 2)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: Row(
              children: [
                _ShiftFilterPill(
                  label: 'All',
                  count: shiftCounts['All'] ?? totalCount,
                  isSelected: selectedShift == 'All',
                  onTap: () => onShiftChanged('All'),
                ),
                const Gap(6),
                _ShiftFilterPill(
                  label: 'Shift 1',
                  count: shiftCounts['Shift 1'] ?? 0,
                  isSelected: selectedShift == 'Shift 1',
                  onTap: () => onShiftChanged('Shift 1'),
                ),
                const Gap(6),
                _ShiftFilterPill(
                  label: 'Shift 2',
                  count: shiftCounts['Shift 2'] ?? 0,
                  isSelected: selectedShift == 'Shift 2',
                  onTap: () => onShiftChanged('Shift 2'),
                ),
                const Gap(6),
                _ShiftFilterPill(
                  label: 'S1+S2',
                  count: shiftCounts['Shift 1 + Shift 2'] ?? 0,
                  isSelected: selectedShift == 'Shift 1 + Shift 2',
                  onTap: () => onShiftChanged('Shift 1 + Shift 2'),
                ),
              ],
            ),
          ),
          Expanded(
            child: teachers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.userX, size: 36, color: colors.textSecondary.withValues(alpha: 0.5)),
                          const Gap(10),
                          Text(
                            isSearching
                                ? 'No teachers match your search or shift filter.'
                                : 'No teachers found in this shift.',
                            style: context.typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: teachers.length,
                    separatorBuilder: (_, index) => const Gap(10),
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      final selected = teacher.id == selectedTeacherId;
                      return _TeacherTile(
                        teacher: teacher,
                        selected: selected,
                        onSelect: () => onSelect(teacher),
                        onEdit: () => onEdit(teacher),
                        onDelete: () => onDelete(teacher),
                      );
                    },
                  ),
          ),
          if (totalPages > 1) ...[
            const Gap(10),
            AbmPaginationBar(
              page: page,
              totalPages: totalPages,
              total: totalCount,
              loading: pageLoading,
              onPage: onPage,
            ),
          ],
        ],
      ),
    );
  }
}

class _ShiftFilterPill extends StatelessWidget {
  const _ShiftFilterPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.typography.bodySmallSemiBold.copyWith(
                color: isSelected ? Colors.white : colors.textPrimary,
                fontSize: 12,
              ),
            ),
            const Gap(5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : colors.border.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: context.typography.bodySmallSemiBold.copyWith(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherTile extends StatelessWidget {
  const _TeacherTile({
    required this.teacher,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherModel teacher;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? colors.secondary.withValues(alpha: 0.22)
              : colors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.secondary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _TeacherAvatar(teacher: teacher, radius: 26),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          teacher.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.typography.bodyMediumSemiBold.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (teacher.isHeadMaster) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6B64C).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFD6B64C).withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            'Head Master',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9E7C10),
                            ),
                          ),
                        ),
                      ],
                      if (!teacher.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Inactive',
                            style: context.typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Gap(3),
                  Text(
                    teacher.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _MetaPill(
                        icon: LucideIcons.hash,
                        text: teacher.employeeId.isEmpty ? '—' : teacher.employeeId,
                      ),
                      _MetaPill(
                        icon: LucideIcons.bookOpen,
                        text: '${teacher.classes.length} cl',
                      ),
                      _ShiftPill(teacher: teacher),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(LucideIcons.moreVertical, size: 18, color: colors.textSecondary),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftPill extends StatelessWidget {
  const _ShiftPill({required this.teacher});

  final TeacherModel teacher;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDual = teacher.isDualShift;
    final hasS1 = teacher.hasShift1;
    final hasS2 = teacher.hasShift2;

    Color bg;
    Color fg;
    Color border;
    String label;

    if (isDual) {
      bg = const Color(0xFF6366F1).withValues(alpha: 0.12);
      fg = const Color(0xFF6366F1);
      border = const Color(0xFF6366F1).withValues(alpha: 0.3);
      label = 'Shift 1 + 2';
    } else if (hasS1) {
      bg = colors.primary.withValues(alpha: 0.10);
      fg = colors.primary;
      border = colors.primary.withValues(alpha: 0.25);
      label = 'Shift 1';
    } else if (hasS2) {
      bg = const Color(0xFFD97706).withValues(alpha: 0.12);
      fg = const Color(0xFFD97706);
      border = const Color(0xFFD97706).withValues(alpha: 0.3);
      label = 'Shift 2';
    } else {
      bg = colors.cardBackground;
      fg = colors.textSecondary;
      border = colors.border;
      label = 'No Shift';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 10, color: fg),
          const Gap(4),
          Text(
            label,
            style: context.typography.bodySmallSemiBold.copyWith(
              color: fg,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small icon+text pill used inside a teacher list tile.
class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.textSecondary),
          const Gap(4),
          Text(
            text,
            style: context.typography.bodySmall.copyWith(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherDetailsCard extends StatelessWidget {
  const _TeacherDetailsCard({
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherModel teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TeacherAvatar(teacher: teacher, radius: 44),
                    const Gap(18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher.fullName,
                            style: context.typography.h2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(6),
                          Text(
                            '${teacher.title} • ${teacher.specialty.isEmpty ? 'Class Teacher' : teacher.specialty}',
                            style: context.typography.bodyLarge.copyWith(
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Chip(text: teacher.employeeId),
                              _Chip(text: teacher.phone),
                              _Chip(text: teacher.email),
                              _Chip(
                                text:
                                    'Joined ${DateFormat('dd MMM yyyy').format(teacher.joinedDate)}',
                              ),
                              _ShiftHeaderBadge(teacher: teacher),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        OutlinedButton(
                          onPressed: onEdit,
                          child: const Text('Edit'),
                        ),
                        const Gap(8),
                        TextButton(
                          onPressed: onDelete,
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(24),
                if (context.isMobile)
                  Column(
                    children: [
                      _TeacherInfoCard(
                        title: 'Shift Assignment',
                        child: _TeacherShiftDetailsContent(teacher: teacher),
                      ),
                      const Gap(16),
                      _TeacherInfoCard(
                        title: 'Assigned Classes',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              teacher.classes.map((item) => _Chip(text: item)).toList(),
                        ),
                      ),
                      const Gap(16),
                      _TeacherInfoCard(
                        title: 'Subjects',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: teacher.subjects
                              .map((item) => _Chip(text: item))
                              .toList(),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TeacherInfoCard(
                          title: 'Shift Assignment',
                          child: _TeacherShiftDetailsContent(teacher: teacher),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: _TeacherInfoCard(
                          title: 'Assigned Classes',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: teacher.classes
                                .map((item) => _Chip(text: item))
                                .toList(),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: _TeacherInfoCard(
                          title: 'Subjects',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: teacher.subjects
                                .map((item) => _Chip(text: item))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Gap(18),
          _TeacherInfoCard(
            title: 'Weekly Class Assignments',
            child: teacher.schedule.isEmpty
                ? Text(
                    'No class periods have been assigned yet.',
                    style: context.typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  )
                : Column(
                    children: teacher.schedule
                        .map((entry) => _ScheduleListTile(entry: entry))
                        .toList(),
                  ),
          ),
          const Gap(18),
          _TeacherInfoCard(
            title: 'Payroll Overview',
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Salary',
                          style: context.typography.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'SAR ${teacher.monthlySalary.toStringAsFixed(0)}',
                          style: context.typography.h2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherAvatar extends StatelessWidget {
  const _TeacherAvatar({
    required this.teacher,
    required this.radius,
  });

  final TeacherModel teacher;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.background,
      backgroundImage:
          teacher.photoUrl != null && teacher.photoUrl!.isNotEmpty
              ? NetworkImage(teacher.photoUrl!)
              : null,
      child: teacher.photoUrl == null || teacher.photoUrl!.isEmpty
          ? Text(
              teacher.fullName.isEmpty ? 'T' : teacher.fullName[0].toUpperCase(),
              style: context.typography.h3.copyWith(color: colors.textPrimary),
            )
          : null,
    );
  }
}

class _TeacherInfoCard extends StatelessWidget {
  const _TeacherInfoCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.typography.h4),
          const Gap(16),
          child,
        ],
      ),
    );
  }
}

class _ShiftHeaderBadge extends StatelessWidget {
  const _ShiftHeaderBadge({required this.teacher});

  final TeacherModel teacher;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDual = teacher.isDualShift;
    final hasS1 = teacher.hasShift1;
    final hasS2 = teacher.hasShift2;

    Color bg;
    Color fg;
    Color border;
    String label;

    if (isDual) {
      bg = const Color(0xFF6366F1).withValues(alpha: 0.12);
      fg = const Color(0xFF6366F1);
      border = const Color(0xFF6366F1).withValues(alpha: 0.35);
      label = 'Shift 1 + Shift 2';
    } else if (hasS1) {
      bg = colors.primary.withValues(alpha: 0.10);
      fg = colors.primary;
      border = colors.primary.withValues(alpha: 0.3);
      label = 'Shift 1';
    } else if (hasS2) {
      bg = const Color(0xFFD97706).withValues(alpha: 0.12);
      fg = const Color(0xFFD97706);
      border = const Color(0xFFD97706).withValues(alpha: 0.35);
      label = 'Shift 2';
    } else {
      bg = colors.cardBackground;
      fg = colors.textSecondary;
      border = colors.border;
      label = 'No Shift';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 12, color: fg),
          const Gap(5),
          Text(
            label,
            style: context.typography.bodySmallSemiBold.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherShiftDetailsContent extends StatelessWidget {
  const _TeacherShiftDetailsContent({required this.teacher});

  final TeacherModel teacher;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDual = teacher.isDualShift;
    final hasS1 = teacher.hasShift1;
    final hasS2 = teacher.hasShift2;

    if (!hasS1 && !hasS2 && teacher.shift.isEmpty) {
      return Text(
        'No shift assigned yet.',
        style: context.typography.bodySmall.copyWith(
          color: colors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (hasS1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sun, size: 13, color: colors.primary),
                    const Gap(6),
                    Text(
                      'Shift 1 (Morning)',
                      style: context.typography.bodySmallSemiBold.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            if (hasS2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.clock, size: 13, color: Color(0xFFD97706)),
                    const Gap(6),
                    Text(
                      'Shift 2 (Afternoon)',
                      style: context.typography.bodySmallSemiBold.copyWith(
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (isDual) ...[
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.checkCheck, size: 13, color: Color(0xFF6366F1)),
                const Gap(6),
                Flexible(
                  child: Text(
                    'Dual Shift Active (Both Shifts)',
                    style: context.typography.bodySmall.copyWith(
                      color: const Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduleListTile extends StatelessWidget {
  const _ScheduleListTile({required this.entry});

  final TeacherScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: context.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.day,
                  style: context.typography.bodyMediumSemiBold.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const Gap(6),
                Text(
                  '${entry.startTime} - ${entry.endTime}',
                  style: context.typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const Gap(6),
                Text(
                  '${entry.subject} • ${entry.className}',
                  style: context.typography.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    entry.day,
                    style: context.typography.bodyMediumSemiBold.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${entry.startTime} - ${entry.endTime}',
                    style: context.typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.subject,
                    style: context.typography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.className,
                    style: context.typography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: context.typography.bodySmallSemiBold.copyWith(
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _TeacherEmptyState extends StatelessWidget {
  const _TeacherEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No teachers found', style: context.typography.h3),
          const Gap(8),
          Text(
            'Add the first teacher profile to start assigning classes.',
            style: context.typography.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const Gap(16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Teacher'),
          ),
        ],
      ),
    );
  }
}

class _TeacherFormDialog extends ConsumerStatefulWidget {
  const _TeacherFormDialog({
    this.existingTeacher,
    required this.instituteId,
    required this.isAdmin,
  });

  final TeacherModel? existingTeacher;
  final String instituteId;
  final bool isAdmin;

  @override
  ConsumerState<_TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends ConsumerState<_TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _salaryController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'India');
  final _motherTongueController = TextEditingController();
  final _qualificationIslamicController = TextEditingController();
  final _qualificationAcademicsController = TextEditingController();
  final _picker = ImagePicker();
  late List<TeacherScheduleEntry> _currentSchedule;

  String _fullPhone = '';
  String _fullWhatsapp = '';

  String _phoneCountryCode = 'SA';
  String _phoneNationalNumber = '';
  String _whatsappCountryCode = 'SA';
  String _whatsappNationalNumber = '';

  DateTime _joinedDate = DateTime.now();
  bool _isActive = true;
  bool _shift1 = false;
  bool _shift2 = false;
  String _teacherType = 'Teacher';
  bool _isSaving = false;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _photoUrl;

  bool get _isEdit => widget.existingTeacher != null;

  @override
  void initState() {
    super.initState();
    final teacher = widget.existingTeacher;
    _currentSchedule = teacher?.schedule ?? [];

    if (teacher != null) {
      _employeeIdController.text = teacher.employeeId;
      _fullNameController.text = teacher.fullName;
      _titleController.text = teacher.title;
      _emailController.text = teacher.email;
      _specialtyController.text = teacher.specialty;
      _salaryController.text = teacher.monthlySalary.toStringAsFixed(0);
      _teacherType = teacher.teacherType;
      
      _fullPhone = teacher.phone;
      _fullWhatsapp = teacher.whatsappNumber ?? '';

      void parsePhone(String fullPhone, void Function(String, String) onParsed) {
        if (fullPhone.isNotEmpty && fullPhone.startsWith('+')) {
          try {
            final phone = PhoneNumber.fromCompleteNumber(completeNumber: fullPhone);
            onParsed(phone.countryISOCode, phone.number);
          } catch (_) {
            onParsed('SA', fullPhone);
          }
        } else {
          onParsed('SA', fullPhone);
        }
      }

      parsePhone(_fullPhone, (c, n) {
        _phoneCountryCode = c;
        _phoneNationalNumber = n;
      });
      parsePhone(_fullWhatsapp, (c, n) {
        _whatsappCountryCode = c;
        _whatsappNationalNumber = n;
      });

      _nationalityController.text = teacher.nationality;
      _motherTongueController.text = teacher.motherTongue ?? '';
      _qualificationIslamicController.text = teacher.qualificationIslamic ?? '';
      _qualificationAcademicsController.text = teacher.qualificationAcademics ?? '';
      _joinedDate = teacher.joinedDate;
      _isActive = teacher.isActive;
      _shift1 = teacher.shift.contains('Shift-1');
      _shift2 = teacher.shift.contains('Shift-2');
      _photoUrl = teacher.photoUrl;
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _fullNameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _salaryController.dispose();
    _passwordController.dispose();
    _nationalityController.dispose();
    _motherTongueController.dispose();
    _qualificationIslamicController.dispose();
    _qualificationAcademicsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'Edit Teacher' : 'Add Teacher',
                        style: context.typography.h3,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Gap(8),
                // Institute scope indicator
                _InstituteScopeBadge(
                  instituteId: widget.instituteId,
                  isLocked: !widget.isAdmin,
                ),
                const Gap(16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PhotoPicker(
                          teacherName: _fullNameController.text,
                          photoUrl: _photoUrl,
                          imageBytes: _pickedImageBytes,
                          onPick: _pickImage,
                        ),
                        const Gap(24),
                        _buildFormGrid(context),
                        const Gap(20),
                        SwitchListTile.adaptive(
                          value: _isActive,
                          onChanged: (value) => setState(() => _isActive = value),
                          title: const Text('Active teacher'),
                        ),
                        const Gap(8),
                      ],
                    ),
                  ),
                ),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const Gap(12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: Text(_isSaving ? 'Saving...' : 'Save Teacher'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormGrid(BuildContext context) {
    final children = <Widget>[
      if (_isEdit)
        ABMTextField(
          label: 'Employee ID',
          hint: 'T001',
          controller: _employeeIdController,
          enabled: false,
        )
      else
        ABMTextField(
          label: 'Employee ID',
          hint: 'Auto-generated',
          controller: _employeeIdController,
          enabled: false,
        ),
      ABMTextField(
        label: 'Full Name',
        hint: 'Enter teacher name',
        controller: _fullNameController,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Full name is required' : null,
      ),
      ABMTextField(
        label: 'Title',
        hint: 'Senior Quran Teacher',
        controller: _titleController,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Title is required' : null,
      ),
      DropdownButtonFormField<String>(
        initialValue: _teacherType,
        decoration: InputDecoration(
          labelText: 'Teacher Type / Role',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: const [
          DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
          DropdownMenuItem(value: 'Head Master', child: Text('Head Master')),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _teacherType = val);
        },
      ),
      IntlPhoneField(
        initialCountryCode: _phoneCountryCode,
        initialValue: _phoneNationalNumber,
        decoration: InputDecoration(
          labelText: 'Phone',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (phone) {
          _fullPhone = phone.number.isEmpty ? '' : phone.completeNumber;
        },
      ),
      IntlPhoneField(
        initialCountryCode: _whatsappCountryCode,
        initialValue: _whatsappNationalNumber,
        decoration: InputDecoration(
          labelText: 'WhatsApp Number',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (phone) {
          _fullWhatsapp = phone.number.isEmpty ? '' : phone.completeNumber;
        },
      ),
      ABMTextField(
        label: 'Email',
        hint: 'teacher@anasbinmalik.edu',
        controller: _emailController,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Email is required' : null,
      ),
      Autocomplete<String>(
        initialValue: TextEditingValue(text: _nationalityController.text),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return countries.map((c) => c.name);
          }
          return countries.map((c) => c.name).where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (String selection) {
          _nationalityController.text = selection;
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return ABMTextField(
            label: 'Nationality',
            hint: 'India',
            controller: textEditingController,
            focusNode: focusNode,
            onChanged: (val) => _nationalityController.text = val,
          );
        },
      ),
      ABMTextField(
        label: 'Mother Tongue',
        hint: 'Malayalam',
        controller: _motherTongueController,
      ),
      ABMTextField(
        label: 'Qualification (Islamic)',
        hint: 'Aalim, Hifz, etc.',
        controller: _qualificationIslamicController,
      ),
      ABMTextField(
        label: 'Qualification (Academics)',
        hint: 'BA, MA, B.Ed, etc.',
        controller: _qualificationAcademicsController,
      ),
      ABMTextField(
        label: 'Specialty',
        hint: 'Quran & Tajweed',
        controller: _specialtyController,
      ),
      ABMTextField(
        label: 'Monthly Salary',
        hint: '1200',
        controller: _salaryController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Salary is required' : null,
      ),
      InkWell(
        onTap: _pickJoinedDate,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Joined Date',
            border: OutlineInputBorder(),
          ),
          child: Text(DateFormat('dd MMM yyyy').format(_joinedDate)),
        ),
      ),
      ABMTextField(
        label: _isEdit ? 'New Password (leave blank to keep current)' : 'Password',
        hint: _isEdit ? '••••••••' : 'Enter login password',
        controller: _passwordController,
        isPassword: true,
        validator: (value) {
          if (!_isEdit && (value == null || value.trim().isEmpty)) {
            return 'Password is required for new teachers';
          }
          if (value != null && value.isNotEmpty && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shifts', style: TextStyle(fontWeight: FontWeight.bold)),
          const Gap(8),
          Row(
            children: [
              Checkbox(
                value: _shift1,
                onChanged: (val) => setState(() => _shift1 = val ?? false),
              ),
              const Text('Shift-1'),
              const Gap(16),
              Checkbox(
                value: _shift2,
                onChanged: (val) => setState(() => _shift2 = val ?? false),
              ),
              const Text('Shift-2'),
            ],
          ),
        ],
      ),
    ];

    if (context.isMobile) {
      return Column(
        children: children
            .map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: child,
                ))
            .toList(),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: children
          .map(
            (child) => SizedBox(
              width: 420,
              child: child,
            ),
          )
          .toList(),
    );
  }

  Future<void> _pickJoinedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _joinedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageName = file.name;
    });
  }


  String _resolveMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final schedule = _currentSchedule;

    setState(() => _isSaving = true);

    try {
      String? photoUrl = _photoUrl;
      if (_pickedImageBytes != null && _pickedImageName != null) {
        photoUrl = await ref.read(teacherRepositoryProvider).uploadTeacherImage(
              bytes: _pickedImageBytes!,
              fileName: _pickedImageName!,
              mimeType: _resolveMimeType(_pickedImageName!),
            );
      }

      final subjects = {
        for (final entry in schedule) entry.subject,
      }.toList();
      final classes = {
        for (final entry in schedule) entry.className,
      }.toList();

      final shiftList = <String>[];
      if (_shift1) shiftList.add('Shift-1');
      if (_shift2) shiftList.add('Shift-2');

      final teacher = TeacherModel(
        id: widget.existingTeacher?.id ?? '',
        employeeId: _employeeIdController.text.trim(),
        fullName: _fullNameController.text.trim(),
        title: _titleController.text.trim(),
        phone: _fullPhone,
        email: _emailController.text.trim(),
        specialty: _specialtyController.text.trim(),
        joinedDate: _joinedDate,
        monthlySalary: double.tryParse(_salaryController.text.trim()) ?? 0,
        subjects: subjects,
        classes: classes,
        schedule: schedule,
        photoUrl: photoUrl,
        isActive: _isActive,
        password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
        instituteId: widget.instituteId,
        whatsappNumber: _fullWhatsapp,
        nationality: _nationalityController.text.trim().isEmpty ? 'India' : _nationalityController.text.trim(),
        motherTongue: _motherTongueController.text.trim(),
        qualificationIslamic: _qualificationIslamicController.text.trim(),
        qualificationAcademics: _qualificationAcademicsController.text.trim(),
        shift: shiftList,
        teacherType: _teacherType,
      );

      if (_isEdit) {
        await ref.read(teacherRepositoryProvider).updateTeacher(teacher);
      } else {
        await ref.read(teacherRepositoryProvider).addTeacher(teacher);
      }

      ref.invalidate(timetableDataProvider);
      ref.invalidate(teacherListProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Teacher updated successfully'
                : 'Teacher created successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.teacherName,
    required this.photoUrl,
    required this.imageBytes,
    required this.onPick,
  });

  final String teacherName;
  final String? photoUrl;
  final Uint8List? imageBytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    ImageProvider<Object>? imageProvider;
    if (imageBytes != null) {
      imageProvider = MemoryImage(imageBytes!);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!);
    }

    return context.isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colors.background,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Text(
                            teacherName.isEmpty ? 'T' : teacherName[0].toUpperCase(),
                            style: context.typography.h3,
                          )
                        : null,
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Teacher Image', style: context.typography.h4),
                        const Gap(6),
                        Text(
                          'Upload a profile image for the teacher record.',
                          style: context.typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(16),
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Choose Image'),
              ),
            ],
          )
        : Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colors.background,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        teacherName.isEmpty ? 'T' : teacherName[0].toUpperCase(),
                        style: context.typography.h3,
                      )
                    : null,
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teacher Image', style: context.typography.h4),
                    const Gap(6),
                    Text(
                      'Upload a profile image for the teacher record.',
                      style: context.typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const Gap(10),
                    OutlinedButton.icon(
                      onPressed: onPick,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Choose Image'),
                    ),
                  ],
                ),
              ),
            ],
          );
  }
}

// ─── Institute Scope Badge ─────────────────────────────────────────────────────
/// Shows which institute a record will belong to.
/// Locked (non-admin): read-only padlock chip.
/// Unlocked (IT Admin): editable — but institute choice comes from the sidebar switcher.

class _InstituteScopeBadge extends ConsumerWidget {
  const _InstituteScopeBadge({
    required this.instituteId,
    required this.isLocked,
  });

  final String instituteId;
  final bool isLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final institutesAsync = ref.watch(instituteListProvider);

    final instituteName = institutesAsync.maybeWhen(
      data: (list) {
        final match = list.where((i) => i.id == instituteId);
        return match.isNotEmpty ? match.first.name : instituteId;
      },
      orElse: () => instituteId,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLocked
            ? colors.primary.withValues(alpha: 0.06)
            : colors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLocked
              ? colors.primary.withValues(alpha: 0.2)
              : colors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? LucideIcons.lock : LucideIcons.building2,
            size: 14,
            color: isLocked ? colors.primary : colors.secondary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isLocked
                  ? 'Adding to: $instituteName'
                  : 'Institute: $instituteName (via selected institute)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLocked ? colors.primary : colors.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLocked) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Auto-assigned',
                style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
