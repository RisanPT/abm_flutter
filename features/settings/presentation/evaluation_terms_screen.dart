import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/timetable/data/planner_repository.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

const List<String> kDefaultEvaluationTerms = ['Exam-1', 'Exam-2', 'Term-1', 'Term-2'];

/// The institute's evaluation terms (progress-report term options). Falls back to
/// the defaults on any error so the progress-report screen always has options.
final evaluationTermsProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, instituteId) async {
  try {
    final terms = await ref.read(plannerRepositoryProvider).getEvaluationTerms(instituteId);
    return terms.isNotEmpty ? terms : kDefaultEvaluationTerms;
  } catch (_) {
    return kDefaultEvaluationTerms;
  }
});

/// Admin / principal screen to add, rename, reorder and delete the evaluation
/// terms offered when uploading a student's progress report.
class EvaluationTermsScreen extends ConsumerStatefulWidget {
  const EvaluationTermsScreen({super.key});

  @override
  ConsumerState<EvaluationTermsScreen> createState() => _EvaluationTermsScreenState();
}

class _EvaluationTermsScreenState extends ConsumerState<EvaluationTermsScreen> {
  final _addController = TextEditingController();
  List<String> _terms = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final id = ref.read(selectedInstituteProvider).id;
      final list = await ref.read(plannerRepositoryProvider).getEvaluationTerms(id);
      if (mounted) {
        setState(() {
          _terms = list.isNotEmpty ? List<String>.from(list) : List<String>.from(kDefaultEvaluationTerms);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = friendlyErrorMessage(e); });
    }
  }

  bool _exists(String name, {int? ignoreIndex}) {
    final k = name.trim().toLowerCase();
    for (var i = 0; i < _terms.length; i++) {
      if (i == ignoreIndex) continue;
      if (_terms[i].toLowerCase() == k) return true;
    }
    return false;
  }

  void _add() {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    if (_exists(name)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That term already exists.')));
      return;
    }
    setState(() {
      _terms.add(name);
      _addController.clear();
    });
  }

  Future<void> _rename(int index) async {
    final controller = TextEditingController(text: _terms[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename term'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Term name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    if (_exists(result, ignoreIndex: index)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That term already exists.')));
      return;
    }
    setState(() => _terms[index] = result);
  }

  Future<void> _save() async {
    if (_terms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one term.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final id = ref.read(selectedInstituteProvider).id;
      final saved = await ref.read(plannerRepositoryProvider).setEvaluationTerms(id, _terms);
      ref.invalidate(evaluationTermsProvider(id));
      if (mounted) {
        setState(() => _terms = saved.isNotEmpty ? saved : _terms);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation terms saved'), backgroundColor: Color(0xFF2F855A)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text('Evaluation Terms', style: typography.h3.copyWith(color: colors.primary))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'These are the terms teachers pick when uploading a progress report (e.g. Exam-1, Term-1). '
                      'Add, rename, reorder or remove them, then Save. Existing reports keep their saved term.',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                    const Gap(16),
                    // Add a new term.
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'New term name (e.g. Mid-Term)',
                              filled: true,
                              fillColor: colors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: colors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                            onSubmitted: (_) => _add(),
                          ),
                        ),
                        const Gap(10),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _add,
                            icon: const Icon(LucideIcons.plus, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    if (_terms.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No terms yet — add one above.',
                              style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.06)),
                        ),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _terms.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = _terms.removeAt(oldIndex);
                              _terms.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            final term = _terms[index];
                            return ListTile(
                              key: ValueKey('$term-$index'),
                              leading: Icon(LucideIcons.gripVertical, size: 18, color: colors.textSecondary),
                              title: Text(term, style: typography.bodyMedium.copyWith(color: colors.textPrimary)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(LucideIcons.pencil, size: 18, color: colors.primary),
                                    tooltip: 'Rename',
                                    onPressed: () => _rename(index),
                                  ),
                                  IconButton(
                                    icon: Icon(LucideIcons.trash2, size: 18, color: colors.red),
                                    tooltip: 'Remove',
                                    onPressed: () => setState(() => _terms.removeAt(index)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const Gap(24),
                    ABMButton(text: 'Save', isLoading: _saving, onPressed: _saving ? null : _save),
                    const Gap(24),
                  ],
                ),
    );
  }
}
