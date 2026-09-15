import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/features/students/domain/classroom_model.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClassroomSubjectsDialog extends ConsumerStatefulWidget {
  const ClassroomSubjectsDialog({super.key, required this.classroom});
  final ClassroomModel classroom;

  @override
  ConsumerState<ClassroomSubjectsDialog> createState() => _ClassroomSubjectsDialogState();
}

class _ClassroomSubjectsDialogState extends ConsumerState<ClassroomSubjectsDialog> {
  final List<TextEditingController> _controllers = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final s in widget.classroom.subjects) {
      _controllers.add(TextEditingController(text: s));
    }
    // Always show at least one empty row to type into.
    if (_controllers.isEmpty) _controllers.add(TextEditingController());
  }

  void _addRow() => setState(() => _controllers.add(TextEditingController()));

  void _removeRow(int index) {
    setState(() {
      _controllers.removeAt(index).dispose();
      if (_controllers.isEmpty) _controllers.add(TextEditingController());
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final subjects = _controllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await ref
          .read(classroomControllerProvider.notifier)
          .updateSubjects(widget.classroom.id, subjects);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subjects updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Define Subjects', style: context.typography.h3),
                        const Gap(4),
                        Text(
                          'Class: ${widget.classroom.name}',
                          style: context.typography.bodyMedium.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const Gap(24),
              const Text(
                'Add as many subjects as the class needs. These will be available in the timetable grid.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const Gap(20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _controllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ABMTextField(
                              label: 'Subject ${index + 1}',
                              hint: 'e.g. Arabic, Fiqh...',
                              controller: _controllers[index],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: _controllers.length == 1 ? null : () => _removeRow(index),
                            icon: Icon(LucideIcons.trash2, size: 20, color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Gap(8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add subject'),
                ),
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Gap(12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Save Subjects'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
