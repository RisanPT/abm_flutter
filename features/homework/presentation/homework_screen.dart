import 'dart:convert';
import 'dart:typed_data';

import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/homework/data/homework_repository.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  String _classFilter = 'All';
  int _page = 1;

  bool _canManage(String? role) => role != null &&
      role != AppRoles.student &&
      [
        AppRoles.teacher,
        AppRoles.headMaster,
        AppRoles.principal,
        AppRoles.itAdmin,
        AppRoles.superAdmin,
        AppRoles.staff,
      ].contains(role);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authControllerProvider).value;
    final isStudent = user?.role == AppRoles.student;
    final canManage = _canManage(user?.role);
    // Students always see their own class (backend scopes it); staff can filter.
    final listKey = isStudent ? '' : _classFilter;
    final hwQuery = HomeworkQuery(classroom: listKey, page: _page);
    final hwAsync = ref.watch(homeworkPageProvider(hwQuery));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Homework',
            subtitle: isStudent ? 'Assignments for your class' : 'Post and track class assignments',
            height: context.isMobile ? 165 : 185,
          ),
          if (canManage) _buildClassFilter(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(homeworkPageProvider);
                ref.invalidate(homeworkListProvider);
              },
              child: hwAsync.when(
                data: (pagedResult) {
                  final items = pagedResult.items;
                  if (items.isEmpty) {
                    return ListView(children: [
                      const Gap(60),
                      AbmEmptyState(
                        icon: LucideIcons.bookMarked,
                        title: 'No homework yet',
                        message: isStudent
                            ? 'New assignments for your class will appear here.'
                            : 'Tap "Add homework" to post an assignment.',
                      ),
                    ]);
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Gap(12),
                          itemBuilder: (_, i) => _HomeworkCard(
                            hw: items[i],
                            canManage: canManage,
                            isStudent: isStudent,
                            onToggleDone: (done) => _toggleDone(items[i], done),
                            onEdit: () => _showForm(context, existing: items[i]),
                            onDelete: () => _delete(items[i]),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AbmErrorView(
                  message: friendlyErrorMessage(e),
                  onRetry: () => ref.invalidate(homeworkPageProvider(hwQuery)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context),
              backgroundColor: colors.primary,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              label: const Text('Add homework', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildClassFilter(BuildContext context) {
    final colors = context.colors;
    final classesAsync = ref.watch(classroomControllerProvider);
    final options = classesAsync.maybeWhen(
      data: (classes) => ['All', ...classes.map((c) => c.name)],
      orElse: () => <String>['All'],
    );
    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((c) {
            final selected = c == _classFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) => setState(() {
                  _classFilter = c;
                  _page = 1;
                }),
                selectedColor: colors.primary.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: selected ? colors.primary : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _toggleDone(Homework hw, bool done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(homeworkRepositoryProvider).toggleComplete(hw.id, done);
      ref.invalidate(homeworkPageProvider);
      ref.invalidate(homeworkListProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _delete(Homework hw) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmActionDialog(
      context,
      title: 'Delete homework',
      message: 'Delete "${hw.title}"? This cannot be undone.',
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    try {
      await ref.read(homeworkRepositoryProvider).delete(hw.id);
      ref.invalidate(homeworkPageProvider);
      ref.invalidate(homeworkListProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Homework deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _showForm(BuildContext context, {Homework? existing}) async {
    final classesAsync = ref.read(classroomControllerProvider);
    final classes = classesAsync.maybeWhen(data: (c) => c.map((e) => e.name).toList(), orElse: () => <String>[]);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HomeworkForm(existing: existing, classes: classes),
    );
    if (saved == true) {
      ref.invalidate(homeworkPageProvider);
      ref.invalidate(homeworkListProvider);
    }
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({
    required this.hw,
    required this.canManage,
    required this.isStudent,
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
  });

  final Homework hw;
  final bool canManage;
  final bool isStudent;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;

    // Due-date chip colour: overdue = red, due within 2 days = amber, else normal.
    Widget? dueChip;
    if (hw.dueDate != null) {
      final now = DateTime.now();
      final due = hw.dueDate!;
      final days = due.difference(DateTime(now.year, now.month, now.day)).inDays;
      Color c;
      String label;
      if (days < 0) {
        c = colors.red;
        label = 'Overdue · ${DateFormat('dd MMM').format(due)}';
      } else if (days <= 2) {
        c = colors.warning;
        label = 'Due ${DateFormat('dd MMM').format(due)}';
      } else {
        c = colors.textSecondary;
        label = 'Due ${DateFormat('dd MMM').format(due)}';
      }
      dueChip = AbmStatusPill(label: label, color: c, icon: LucideIcons.calendar);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (hw.subject.isNotEmpty) ...[
                          _Tag(text: hw.subject, color: colors.primary),
                          const Gap(6),
                        ],
                        _Tag(text: hw.classroom, color: colors.secondary),
                      ],
                    ),
                    const Gap(8),
                    Text(hw.title, style: t.bodyLargeSemiBold.copyWith(color: colors.textPrimary)),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.moreVertical, size: 18, color: colors.textSecondary),
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          if (hw.description.isNotEmpty) ...[
            const Gap(6),
            Text(hw.description, style: t.bodyMedium.copyWith(color: colors.textSecondary)),
          ],
          const Gap(10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (dueChip != null) dueChip,
              if (hw.assignedByName.isNotEmpty)
                Text('by ${hw.assignedByName}', style: t.bodySmall.copyWith(color: colors.textSecondary)),
              if (hw.hasAttachment)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(hw.attachmentUrl), mode: LaunchMode.externalApplication),
                  icon: const Icon(LucideIcons.paperclip, size: 15),
                  label: const Text('Attachment'),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: const Size(0, 32)),
                ),
              if (canManage && !isStudent)
                Text('${hw.completedCount} done', style: t.bodySmall.copyWith(color: colors.green)),
            ],
          ),
          if (isStudent) ...[
            const Divider(height: 20),
            InkWell(
              onTap: () => onToggleDone(!hw.completed),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(hw.completed ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: hw.completed ? colors.green : colors.textSecondary, size: 20),
                  const Gap(8),
                  Text(hw.completed ? 'Done' : 'Mark as done',
                      style: t.bodyMediumSemiBold.copyWith(
                          color: hw.completed ? colors.green : colors.textPrimary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: context.typography.bodySmallSemiBold.copyWith(color: color)),
      );
}

/// Add / edit homework form (bottom sheet).
class _HomeworkForm extends ConsumerStatefulWidget {
  const _HomeworkForm({this.existing, required this.classes});
  final Homework? existing;
  final List<String> classes;

  @override
  ConsumerState<_HomeworkForm> createState() => _HomeworkFormState();
}

class _HomeworkFormState extends ConsumerState<_HomeworkForm> {
  late final TextEditingController _title = TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _subject = TextEditingController(text: widget.existing?.subject ?? '');
  late final TextEditingController _desc = TextEditingController(text: widget.existing?.description ?? '');
  late String? _classroom = widget.existing?.classroom;
  late DateTime? _dueDate = widget.existing?.dueDate;
  Uint8List? _imageBytes;
  String _imageName = '';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1400);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (mounted) setState(() { _imageBytes = bytes; _imageName = f.name; });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if ((_classroom == null || _classroom!.isEmpty)) {
      messenger.showSnackBar(const SnackBar(content: Text('Please choose a class.')));
      return;
    }
    if (_title.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Please add a title.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(homeworkRepositoryProvider);
      if (widget.existing == null) {
        String? attachment;
        if (_imageBytes != null) {
          final mime = _imageName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
          attachment = 'data:$mime;base64,${base64Encode(_imageBytes!)}';
        }
        await repo.create(
          classroom: _classroom!,
          title: _title.text.trim(),
          subject: _subject.text.trim(),
          description: _desc.text.trim(),
          dueDate: _dueDate,
          attachment: attachment,
        );
      } else {
        await repo.update(
          widget.existing!.id,
          classroom: _classroom,
          title: _title.text.trim(),
          subject: _subject.text.trim(),
          description: _desc.text.trim(),
          dueDate: _dueDate,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: colors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const Gap(14),
            Text(isEdit ? 'Edit homework' : 'Add homework', style: context.typography.h4),
            const Gap(16),
            DropdownButtonFormField<String>(
              initialValue: (_classroom != null && widget.classes.contains(_classroom)) ? _classroom : null,
              decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
              items: widget.classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _classroom = v),
            ),
            const Gap(12),
            ABMTextField(label: 'Title', hint: 'e.g. Read Surah Al-Mulk', controller: _title),
            const Gap(12),
            ABMTextField(label: 'Subject (optional)', hint: 'e.g. Hifz', controller: _subject),
            const Gap(12),
            ABMTextField(label: 'Details (optional)', hint: 'Instructions…', controller: _desc, maxLines: 3),
            const Gap(12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due date', border: OutlineInputBorder()),
                child: Text(_dueDate == null ? 'Pick a date' : DateFormat('EEE, dd MMM yyyy').format(_dueDate!),
                    style: context.typography.bodyMedium),
              ),
            ),
            if (!isEdit) ...[
              const Gap(12),
              if (_imageBytes == null)
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(LucideIcons.imagePlus, size: 18),
                  label: const Text('Attach a photo (optional)'),
                )
              else
                Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_imageBytes!, width: 48, height: 48, fit: BoxFit.cover)),
                  const Gap(10),
                  Expanded(child: Text(_imageName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.typography.bodySmall)),
                  IconButton(onPressed: () => setState(() { _imageBytes = null; _imageName = ''; }),
                      icon: Icon(LucideIcons.x, size: 18, color: colors.red)),
                ]),
            ],
            const Gap(20),
            ABMButton(text: isEdit ? 'Save changes' : 'Post homework', isLoading: _saving, onPressed: _save),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}
