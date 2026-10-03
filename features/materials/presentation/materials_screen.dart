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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Staff screen to organize, filter class-wise, and manage study materials (PDFs, notes, docs, videos).
class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  String _selectedClass = 'all'; // 'all' = all materials, 'general' = all classes, or specific grade
  String _selectedSubject = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDesktop = context.isDesktop;
    final async = ref.watch(materialsListProvider);
    final classroomsAsync = ref.watch(classroomControllerProvider);
    final classroomList = classroomsAsync.value?.map((c) => c.name).toList() ?? <String>[];

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Study Materials',
            subtitle: 'Share class notes, guides, PDFs & digital learning resources',
            height: context.isMobile ? 150 : 170,
            actions: [
              IconButton(
                tooltip: 'Student Access Guide',
                icon: const Icon(LucideIcons.helpCircle, size: 18, color: Colors.white),
                onPressed: () => _showStudentAccessGuide(context),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(LucideIcons.refreshCw, size: 17, color: Colors.white),
                onPressed: () => ref.invalidate(materialsListProvider),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.primary,
              onRefresh: () async => ref.invalidate(materialsListProvider),
              child: async.when(
                data: (allItems) {
                  // Filter items
                  var items = allItems;

                  if (_selectedClass == 'general') {
                    items = items.where((m) => m.grade == 'all').toList();
                  } else if (_selectedClass != 'all') {
                    items = items.where((m) => m.grade == _selectedClass).toList();
                  }

                  if (_selectedSubject != 'all') {
                    items = items.where((m) => m.subject.toLowerCase() == _selectedSubject.toLowerCase()).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    items = items.where((m) {
                      return m.title.toLowerCase().contains(q) ||
                          m.subject.toLowerCase().contains(q) ||
                          m.description.toLowerCase().contains(q) ||
                          m.grade.toLowerCase().contains(q);
                    }).toList();
                  }

                  // Available subjects for dropdown
                  final allSubjects = allItems
                      .map((m) => m.subject.trim())
                      .where((s) => s.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

                  return ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                      vertical: 16,
                    ),
                    children: [
                      // ─── Stat KPI Cards ──────────────────────────────────
                      _buildStatsRow(context, allItems, classroomList),
                      const Gap(16),

                      // ─── Class-wise Filter Tabs Strip ────────────────────
                      _buildClassSelectorStrip(context, allItems, classroomList),
                      const Gap(14),

                      // ─── Search & Subject Filter Bar ─────────────────────
                      _buildSearchToolbar(context, allSubjects),
                      const Gap(16),

                      // ─── Document List ───────────────────────────────────
                      if (items.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: AbmEmptyState(
                            icon: LucideIcons.folderOpen,
                            title: _searchQuery.isNotEmpty
                                ? 'No matching materials'
                                : (_selectedClass != 'all'
                                    ? 'No materials for $_selectedClass'
                                    : 'No study materials yet'),
                            message: _searchQuery.isNotEmpty
                                ? 'Try searching for another keyword or clear filters.'
                                : 'Tap "Add material" below to share class notes or PDF links.',
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Gap(12),
                          itemBuilder: (_, i) => _MaterialCard(
                            item: items[i],
                            onOpen: () => _openUrl(context, items[i].url),
                            onCopy: () => _copyUrl(context, items[i].url),
                            onDelete: () => _delete(context, ref, items[i]),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AbmErrorView(
                  message: friendlyErrorMessage(e),
                  onRetry: () => ref.invalidate(materialsListProvider),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref, classroomList),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'Add material',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    List<StudyMaterialItem> all,
    List<String> classrooms,
  ) {
    final colors = context.colors;
    final isDesktop = context.isDesktop;

    final totalCount = all.length;
    final generalCount = all.where((m) => m.grade == 'all').length;
    final classSpecificCount = all.where((m) => m.grade != 'all').length;
    final subjectsCount = all.map((m) => m.subject.trim().toLowerCase()).where((s) => s.isNotEmpty).toSet().length;

    final cards = [
      _StatMiniCard(
        label: 'Total Materials',
        count: totalCount,
        icon: LucideIcons.bookCopy,
        accentColor: colors.primary,
        bgColor: colors.primary.withValues(alpha: 0.08),
        isSelected: _selectedClass == 'all',
        onTap: () => setState(() => _selectedClass = 'all'),
      ),
      _StatMiniCard(
        label: 'All Classes (General)',
        count: generalCount,
        icon: LucideIcons.globe,
        accentColor: const Color(0xFF0D9488),
        bgColor: const Color(0xFFF0FDFA),
        isSelected: _selectedClass == 'general',
        onTap: () => setState(() => _selectedClass = 'general'),
      ),
      _StatMiniCard(
        label: 'Class-Specific',
        count: classSpecificCount,
        icon: LucideIcons.graduationCap,
        accentColor: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
        isSelected: _selectedClass != 'all' && _selectedClass != 'general',
        onTap: () {
          if (classrooms.isNotEmpty) {
            setState(() => _selectedClass = classrooms.first);
          }
        },
      ),
      _StatMiniCard(
        label: 'Subjects Covered',
        count: subjectsCount,
        icon: LucideIcons.bookmark,
        accentColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        isSelected: false,
        onTap: () {},
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(width: 140, child: c),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildClassSelectorStrip(
    BuildContext context,
    List<StudyMaterialItem> all,
    List<String> classrooms,
  ) {
    final colors = context.colors;

    int countForClass(String g) {
      if (g == 'all') return all.length;
      if (g == 'general') return all.where((m) => m.grade == 'all').length;
      return all.where((m) => m.grade == g).length;
    }

    final options = [
      ('all', 'All Materials'),
      ('general', 'All Classes (General)'),
      ...classrooms.map((c) => (c, c)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSel = _selectedClass == opt.$1;
          final count = countForClass(opt.$1);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedClass = opt.$1),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSel ? colors.primary : colors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel ? colors.primary : colors.border,
                    width: 1.2,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (opt.$1 == 'all')
                      Icon(LucideIcons.layers, size: 13, color: isSel ? Colors.white : colors.textSecondary)
                    else if (opt.$1 == 'general')
                      Icon(LucideIcons.globe, size: 13, color: isSel ? Colors.white : colors.textSecondary)
                    else
                      Icon(LucideIcons.graduationCap, size: 13, color: isSel ? Colors.white : colors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      opt.$2,
                      style: TextStyle(
                        color: isSel ? Colors.white : colors.textPrimary,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSel
                            ? Colors.white.withValues(alpha: 0.22)
                            : colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSel ? Colors.white : colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchToolbar(BuildContext context, List<String> subjects) {
    final colors = context.colors;
    final isDesktop = context.isDesktop;

    final searchField = Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search study material or topic...',
          hintStyle: TextStyle(fontSize: 12, color: colors.textSecondary),
          prefixIcon: Icon(LucideIcons.search, size: 15, color: colors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 14),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        ),
      ),
    );

    final subjectDropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSubject,
          icon: Icon(LucideIcons.chevronDown, size: 15, color: colors.textSecondary),
          style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w500),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Subjects')),
            ...subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
          ],
          onChanged: (val) => setState(() => _selectedSubject = val ?? 'all'),
        ),
      ),
    );

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 12),
            subjectDropdown,
          ],
        ),
      );
    }

    return Column(
      children: [
        searchField,
        const Gap(8),
        Row(
          children: [
            Expanded(child: subjectDropdown),
          ],
        ),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the resource URL.')),
      );
    }
  }

  void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.copy, color: Colors.white, size: 15),
            SizedBox(width: 8),
            Text('Resource link copied to clipboard!'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, StudyMaterialItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmActionDialog(
      context,
      title: 'Delete Material',
      message: 'Remove "${item.title}"? Students in ${item.grade == 'all' ? 'All Classes' : item.grade} will no longer see it.',
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    try {
      await ref.read(materialsRepositoryProvider).delete(item.id);
      ref.invalidate(materialsListProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Study material deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref, List<String> classes) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _MaterialForm(classes: classes),
    );
    if (ok == true) ref.invalidate(materialsListProvider);
  }

  void _showStudentAccessGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.info, size: 20, color: Theme.of(ctx).primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'How Students Access Documents',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Gap(16),
            _guideStep(
              '1',
              'Class-Scoped Access',
              'When you assign a document to a specific class (e.g. "Grade 1"), only students registered in Grade 1 can view it.',
            ),
            const Gap(12),
            _guideStep(
              '2',
              'All-Classes (General) Resources',
              'Materials set to "All classes" are accessible by every enrolled student in the Madrasa.',
            ),
            const Gap(12),
            _guideStep(
              '3',
              'Student Portal Access',
              'Students open the Student Portal app or web portal, tap the "Materials" (Kitab) tile in Quick Services, and can open or download docs directly.',
            ),
            const Gap(12),
            _guideStep(
              '4',
              'Supported Formats',
              'You can share Google Drive folders, PDF documents, YouTube video lessons, and digital audio recitations.',
            ),
            const Gap(20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Got it, thanks!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideStep(String num, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey[700],
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stat Mini Card ──────────────────────────────────────────────────────────

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : colors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? accentColor : colors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Material Card ───────────────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.item,
    required this.onOpen,
    required this.onCopy,
    required this.onDelete,
  });

  final StudyMaterialItem item;
  final VoidCallback onOpen;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Visual attributes based on type
    Color typeColor;
    IconData typeIcon;
    String typeLabel = item.displayType;

    if (item.isPdf) {
      typeColor = const Color(0xFFDC2626);
      typeIcon = LucideIcons.fileText;
    } else if (item.isVideo) {
      typeColor = const Color(0xFF7C3AED);
      typeIcon = LucideIcons.video;
    } else if (item.isAudio) {
      typeColor = const Color(0xFF059669);
      typeIcon = LucideIcons.headphones;
    } else if (item.isDrive) {
      typeColor = const Color(0xFF2563EB);
      typeIcon = LucideIcons.hardDrive;
    } else {
      typeColor = colors.primary;
      typeIcon = LucideIcons.globe;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Card Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Class Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.grade == 'all'
                                  ? const Color(0xFF0D9488).withValues(alpha: 0.1)
                                  : const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.grade == 'all' ? LucideIcons.globe : LucideIcons.graduationCap,
                                  size: 11,
                                  color: item.grade == 'all' ? const Color(0xFF0D9488) : const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.grade == 'all' ? 'All Classes' : item.grade,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: item.grade == 'all' ? const Color(0xFF0D9488) : const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Subject Pill
                          if (item.subject.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.subject,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          // Type Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.moreVertical, size: 16, color: colors.textSecondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'open') onOpen();
                    if (val == 'copy') onCopy();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(LucideIcons.externalLink, size: 14),
                          SizedBox(width: 8),
                          Text('Open Resource'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(LucideIcons.copy, size: 14),
                          SizedBox(width: 8),
                          Text('Copy Link'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 14, color: colors.red),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Description Snippet ──────────────────────────────────
          if (item.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ),

          // ─── Footer Action Strip ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.6))),
            ),
            child: Row(
              children: [
                if (item.postedByName.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Shared by ${item.postedByName}',
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(LucideIcons.copy, size: 12),
                  label: const Text('Copy link', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(LucideIcons.externalLink, size: 12, color: Colors.white),
                  label: const Text(
                    'Open Doc',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    visualDensity: VisualDensity.compact,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

// ─── Add Material Form Modal ─────────────────────────────────────────────────

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
  String _resourceType = 'Document';
  bool _saving = false;

  final _commonSubjects = [
    'Tajweed',
    'Hifz',
    'Fiqh',
    'Arabic',
    'Hadith',
    'Tafseer',
    'Islamic History',
    'Taleem',
  ];

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
    final title = _title.text.trim();
    final url = _url.text.trim();

    if (title.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }
    if (url.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Please enter a resource link (URL).')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(materialsRepositoryProvider).create(
            title: title,
            url: url,
            subject: _subject.text.trim(),
            description: _desc.text.trim(),
            grade: _grade,
            resourceType: _resourceType,
          );
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
    final gradeOptions = ['all', ...widget.classes];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.filePlus, size: 18, color: colors.primary),
                ),
                const SizedBox(width: 10),
                Text('Add Study Material', style: context.typography.h4),
              ],
            ),
            const Gap(16),

            // Target Class Dropdown (Visible to)
            DropdownButtonFormField<String>(
              initialValue: _grade,
              decoration: InputDecoration(
                labelText: 'Visible To (Target Class)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(LucideIcons.graduationCap, size: 18),
                isDense: true,
                helperText: _grade == 'all'
                    ? 'All enrolled students across every grade will see this document.'
                    : 'Only students registered in $_grade will see this document.',
              ),
              items: gradeOptions.map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Text(g == 'all' ? 'All classes (Entire Madrasa)' : g),
                );
              }).toList(),
              onChanged: (v) => setState(() => _grade = v ?? 'all'),
            ),
            const Gap(14),

            // Resource Type Selector
            const Text(
              'Resource Type',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Gap(6),
            Wrap(
              spacing: 8,
              children: [
                ('Document', LucideIcons.fileText),
                ('PDF', LucideIcons.file),
                ('Video', LucideIcons.video),
                ('Audio', LucideIcons.headphones),
                ('Link', LucideIcons.globe),
              ].map((t) {
                final isSel = _resourceType == t.$1;
                return ChoiceChip(
                  avatar: Icon(t.$2, size: 13, color: isSel ? Colors.white : colors.primary),
                  label: Text(t.$1),
                  selected: isSel,
                  selectedColor: colors.primary,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : colors.textPrimary,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _resourceType = t.$1),
                );
              }).toList(),
            ),
            const Gap(12),

            // Title
            ABMTextField(
              label: 'Title',
              hint: 'e.g. Tajweed Rules Reference Book',
              controller: _title,
            ),
            const Gap(12),

            // Resource Link
            ABMTextField(
              label: 'Resource link (URL)',
              hint: _resourceType == 'PDF'
                  ? 'https://.../notes.pdf or Google Drive link'
                  : (_resourceType == 'Video'
                      ? 'https://youtube.com/... or Vimeo'
                      : 'https://drive.google.com/... or cloud document URL'),
              controller: _url,
              keyboardType: TextInputType.url,
            ),
            const Gap(12),

            // Subject with quick-chips
            ABMTextField(
              label: 'Subject (optional)',
              hint: 'e.g. Tajweed, Fiqh, Arabic',
              controller: _subject,
            ),
            const Gap(6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _commonSubjects.map((sub) {
                return ActionChip(
                  label: Text(sub, style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _subject.text = sub,
                );
              }).toList(),
            ),
            const Gap(12),

            // Description
            ABMTextField(
              label: 'Description / Instructions (optional)',
              hint: 'e.g. Read chapters 1 to 3 before Thursday\'s class.',
              controller: _desc,
              maxLines: 2,
            ),
            const Gap(20),

            ABMButton(
              text: 'Save & Publish Material',
              isLoading: _saving,
              onPressed: _save,
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }
}
