import 'dart:typed_data';

import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/teachers/data/teacher_repository.dart';
import 'package:abm_madrasa/features/teachers/domain/teacher_model.dart';
import 'package:abm_madrasa/features/teachers/presentation/teacher_controller.dart';
import 'package:abm_madrasa/features/timetable/presentation/timetable_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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

  @override
  void dispose() {
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
              'RM ${t.monthlySalary.toStringAsFixed(2)}',
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
    final teachersAsync = ref.watch(teacherListProvider(_query));

    return Scaffold(
      backgroundColor: colors.background,
      body: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 24),
        child: teachersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Failed to load teachers: $error')),
          data: (teachers) {
            final selectedTeacher = _resolveSelectedTeacher(teachers);

            if (teachers.isEmpty) {
              return _TeacherEmptyState(onAdd: () => _showTeacherForm(context));
            }

            if (context.isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeacherScreenHeader(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onAddTeacher: () => _showTeacherForm(context),
                    onExportPdf: () => _exportTeachersPdf(teachers),
                  ),
                  const Gap(16),
                  Expanded(
                    child: ListView(
                      children: [
                        SizedBox(
                          height: 260,
                          child: _TeacherDirectory(
                            teachers: teachers,
                            selectedTeacherId: _selectedTeacherId,
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
                  onExportPdf: () => _exportTeachersPdf(teachers),
                ),
                const Gap(20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 340,
                        child: _TeacherDirectory(
                          teachers: teachers,
                          selectedTeacherId: _selectedTeacherId,
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
    );
  }

  TeacherModel? _resolveSelectedTeacher(List<TeacherModel> teachers) {
    if (teachers.isEmpty) {
      _selectedTeacherId = null;
      return null;
    }
    final selected = teachers.where((item) => item.id == _selectedTeacherId);
    if (selected.isNotEmpty) {
      return selected.first;
    }
    _selectedTeacherId = teachers.first.id;
    return teachers.first;
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim());
  }

  Future<void> _showTeacherForm(
    BuildContext context, [
    TeacherModel? teacher,
  ]) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _TeacherFormDialog(existingTeacher: teacher),
    );
    ref.invalidate(teacherListProvider(_query));
    ref.invalidate(teacherListProvider(''));
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
      ref.invalidate(teacherListProvider(_query));
      ref.invalidate(teacherListProvider(''));
      ref.invalidate(timetableDataProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
          intro,
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
      ],
    );
  }
}

class _TeacherDirectory extends StatelessWidget {
  const _TeacherDirectory({
    required this.teachers,
    required this.selectedTeacherId,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TeacherModel> teachers;
  final String? selectedTeacherId;
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
      child: ListView.separated(
        itemCount: teachers.length,
        separatorBuilder: (_, index) => const Gap(10),
        itemBuilder: (context, index) {
          final teacher = teachers[index];
          final selected = teacher.id == selectedTeacherId;
          return InkWell(
            onTap: () => onSelect(teacher),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? colors.secondary.withValues(alpha: 0.22)
                    : colors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? colors.secondary : Colors.transparent,
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
                        Text(
                          teacher.fullName,
                          style: context.typography.bodyMediumSemiBold.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          teacher.title,
                          style: context.typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final item in teacher.classes.take(2))
                              _Chip(text: item),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit(teacher);
                      if (value == 'delete') onDelete(teacher);
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
        },
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
                          Text(teacher.fullName, style: context.typography.h2),
                          const Gap(6),
                          Text(
                            '${teacher.title} • ${teacher.specialty.isEmpty ? 'Class Teacher' : teacher.specialty}',
                            style: context.typography.bodyLarge.copyWith(
                              color: colors.textSecondary,
                            ),
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
                    children: [
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
                          'RM ${teacher.monthlySalary.toStringAsFixed(0)}',
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
  const _TeacherFormDialog({this.existingTeacher});

  final TeacherModel? existingTeacher;

  @override
  ConsumerState<_TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends ConsumerState<_TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _salaryController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();
  late List<TeacherScheduleEntry> _currentSchedule;

  DateTime _joinedDate = DateTime.now();
  bool _isActive = true;
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
      _phoneController.text = teacher.phone;
      _emailController.text = teacher.email;
      _specialtyController.text = teacher.specialty;
      _salaryController.text = teacher.monthlySalary.toStringAsFixed(0);
      _joinedDate = teacher.joinedDate;
      _isActive = teacher.isActive;
      _photoUrl = teacher.photoUrl;
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _fullNameController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _salaryController.dispose();
    _passwordController.dispose();
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
      ABMTextField(
        label: 'Employee ID',
        hint: 'T001',
        controller: _employeeIdController,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Employee ID is required' : null,
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
      ABMTextField(
        label: 'Phone',
        hint: '+60 12 345 6789',
        controller: _phoneController,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Phone is required' : null,
      ),
      ABMTextField(
        label: 'Email',
        hint: 'teacher@anasbinmalik.edu',
        controller: _emailController,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Email is required' : null,
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

      final teacher = TeacherModel(
        id: widget.existingTeacher?.id ?? '',
        employeeId: _employeeIdController.text.trim(),
        fullName: _fullNameController.text.trim(),
        title: _titleController.text.trim(),
        phone: _phoneController.text.trim(),
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
      );

      if (_isEdit) {
        await ref.read(teacherRepositoryProvider).updateTeacher(teacher);
      } else {
        await ref.read(teacherRepositoryProvider).addTeacher(teacher);
      }

      ref.invalidate(timetableDataProvider);

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
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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

    return Row(
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
        Column(
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
      ],
    );
  }
}

