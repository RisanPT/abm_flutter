import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/materials/data/materials_repository.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Staff screen to add study materials (links) that students see in their portal.
class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(materialsListProvider);
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Study Materials',
            subtitle: 'Share notes and resources with students',
            height: context.isMobile ? 160 : 180,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(materialsListProvider),
              child: async.when(
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(children: const [
                      Gap(60),
                      AbmEmptyState(
                        icon: LucideIcons.folderOpen,
                        title: 'No materials yet',
                        message: 'Tap "Add material" to share a resource link with students.',
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Gap(10),
                    itemBuilder: (_, i) => _MaterialCard(
                      item: items[i],
                      onOpen: () => launchUrl(Uri.parse(items[i].url), mode: LaunchMode.externalApplication),
                      onDelete: () => _delete(context, ref, items[i]),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AbmErrorView(message: friendlyErrorMessage(e), onRetry: () => ref.invalidate(materialsListProvider)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, StudyMaterialItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmActionDialog(context, title: 'Delete material', message: 'Remove "${item.title}"?', icon: LucideIcons.trash2);
    if (!ok) return;
    try {
      await ref.read(materialsRepositoryProvider).delete(item.id);
      ref.invalidate(materialsListProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Material deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final classes = ref.read(classroomControllerProvider).maybeWhen(data: (c) => c.map((e) => e.name).toList(), orElse: () => <String>[]);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MaterialForm(classes: classes),
    );
    if (ok == true) ref.invalidate(materialsListProvider);
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.item, required this.onOpen, required this.onDelete});
  final StudyMaterialItem item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AbmListRow(
      onTap: onOpen,
      leading: CircleAvatar(radius: 20, backgroundColor: colors.primary.withValues(alpha: 0.12), child: Icon(LucideIcons.fileText, color: colors.primary, size: 18)),
      title: item.title,
      subtitle: [
        if (item.subject.isNotEmpty) item.subject,
        item.grade == 'all' ? 'All classes' : item.grade,
      ].join(' · '),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.externalLink, size: 16, color: colors.textSecondary),
        IconButton(icon: Icon(LucideIcons.trash2, size: 18, color: colors.red), tooltip: 'Delete', onPressed: onDelete),
      ]),
    );
  }
}

class _MaterialForm extends ConsumerStatefulWidget {
  const _MaterialForm({required this.classes});
  final List<String> classes;
  @override
  ConsumerState<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends ConsumerState<_MaterialForm> {
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _desc = TextEditingController();
  final _url = TextEditingController();
  String _grade = 'all';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _desc.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_title.text.trim().isEmpty) { messenger.showSnackBar(const SnackBar(content: Text('Enter a title.'))); return; }
    if (_url.text.trim().isEmpty) { messenger.showSnackBar(const SnackBar(content: Text('Add a resource link (URL).'))); return; }
    setState(() => _saving = true);
    try {
      await ref.read(materialsRepositoryProvider).create(
            title: _title.text.trim(), url: _url.text.trim(), subject: _subject.text.trim(),
            description: _desc.text.trim(), grade: _grade);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) { setState(() => _saving = false); messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e)))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final gradeOptions = ['all', ...widget.classes];
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)))),
            const Gap(14),
            Text('Add study material', style: context.typography.h4),
            const Gap(16),
            ABMTextField(label: 'Title', hint: 'e.g. Tajweed rules notes', controller: _title),
            const Gap(12),
            ABMTextField(label: 'Resource link (URL)', hint: 'https://…', controller: _url, keyboardType: TextInputType.url),
            const Gap(12),
            ABMTextField(label: 'Subject (optional)', hint: 'e.g. Tajweed', controller: _subject),
            const Gap(12),
            ABMTextField(label: 'Description (optional)', hint: 'What is this?', controller: _desc, maxLines: 2),
            const Gap(12),
            DropdownButtonFormField<String>(
              initialValue: _grade,
              decoration: const InputDecoration(labelText: 'Visible to', border: OutlineInputBorder()),
              items: gradeOptions
                  .map((g) => DropdownMenuItem(value: g, child: Text(g == 'all' ? 'All classes' : g)))
                  .toList(),
              onChanged: (v) => setState(() => _grade = v ?? 'all'),
            ),
            const Gap(18),
            ABMButton(text: 'Add material', isLoading: _saving, onPressed: _save),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}
