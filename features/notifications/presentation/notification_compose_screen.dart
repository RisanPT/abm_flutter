import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/utils/class_sort.dart';
import 'package:abm_madrasa/features/notifications/data/notification_repository.dart';
import 'package:abm_madrasa/features/notifications/presentation/notifications_screen.dart';
import 'package:abm_madrasa/features/students/presentation/classroom_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Admin/staff screen to compose a broadcast notification and manage recent ones.
class NotificationComposeScreen extends ConsumerStatefulWidget {
  const NotificationComposeScreen({super.key});

  @override
  ConsumerState<NotificationComposeScreen> createState() => _NotificationComposeScreenState();
}

class _NotificationComposeScreenState extends ConsumerState<NotificationComposeScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  // FeeDue is generated (Outstanding Dues → Send reminders), never composed here.
  static const _types = ['Announcement', 'General', 'Event', 'Holiday'];
  static const _audiences = [('all', 'Everyone'), ('students', 'Students'), ('teachers', 'Teachers')];

  String _type = 'Announcement';
  String _audience = 'all';
  String _grade = ''; // '' = all grades
  bool _important = false;
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A title is required.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(notificationRepositoryProvider).compose(
            title: title,
            body: _bodyCtrl.text.trim(),
            type: _type,
            priority: _important ? 'Important' : 'Normal',
            audienceRole: _audience,
            grade: _audience == 'students' ? _grade : '',
          );
      ref.invalidate(adminNotificationsProvider);
      ref.invalidate(myNotificationsProvider);
      if (!mounted) return;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() {
        _important = false;
        _sending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send. ${friendlyErrorMessage(e)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final recent = ref.watch(adminNotificationsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const ABMPageHeader(
            title: 'Compose Notification',
            subtitle: 'Send a notice to students and teachers.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _card(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Title'),
                      TextField(
                        controller: _titleCtrl,
                        decoration: _dec(context, 'e.g. Parent meeting on Friday'),
                        textInputAction: TextInputAction.next,
                      ),
                      const Gap(18),
                      _label(context, 'Message'),
                      TextField(
                        controller: _bodyCtrl,
                        decoration: _dec(context, 'Write the details…'),
                        minLines: 3,
                        maxLines: 6,
                      ),
                      const Gap(18),
                      _label(context, 'Type'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final ty in _types) _choice(context, ty, _type == ty, () => setState(() => _type = ty)),
                        ],
                      ),
                      const Gap(18),
                      _label(context, 'Audience'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in _audiences) _choice(context, a.$2, _audience == a.$1, () => setState(() => _audience = a.$1)),
                        ],
                      ),
                      if (_audience == 'students') ...[
                        const Gap(18),
                        _label(context, 'Class (optional)'),
                        _gradeDropdown(context),
                      ],
                      const Gap(6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Mark as Important', style: t.bodyMediumSemiBold),
                        subtitle: Text('Highlights the notice and shows it as an urgent circular.',
                            style: t.bodySmall.copyWith(color: colors.textSecondary)),
                        value: _important,
                        activeThumbColor: colors.primary,
                        onChanged: (v) => setState(() => _important = v),
                      ),
                      const Gap(14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(LucideIcons.send, size: 18),
                          label: Text(_sending ? 'Sending…' : 'Send notification',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                Row(
                  children: [
                    Icon(LucideIcons.history, size: 18, color: colors.primary),
                    const Gap(8),
                    Text('Recently sent', style: t.bodyLargeSemiBold),
                  ],
                ),
                const Gap(12),
                recent.when(
                  loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text('Couldn’t load recent notices.', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                  data: (items) => items.isEmpty
                      ? _card(context, child: Row(children: [
                          Icon(LucideIcons.inbox, size: 18, color: colors.textSecondary),
                          const Gap(10),
                          Text('Nothing sent yet.', style: t.bodyMedium.copyWith(color: colors.textSecondary)),
                        ]))
                      : Column(children: [for (final n in items) _recentTile(context, n)]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: child,
      );

  Widget _choice(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: selected ? colors.primary : colors.border, width: selected ? 1.4 : 1)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(label,
              style: context.typography.bodySmall.copyWith(
                color: selected ? colors.primary : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              )),
        ),
      ),
    );
  }

  Widget _gradeDropdown(BuildContext context) {
    final colors = context.colors;
    final classes = ref.watch(classroomControllerProvider);
    return classes.maybeWhen(
      data: (list) {
        final names = sortClassNames(list.map((c) => c.name).toSet());
        return DropdownButtonFormField<String>(
          initialValue: _grade,
          decoration: _dec(context, 'All classes'),
          items: [
            const DropdownMenuItem(value: '', child: Text('All classes')),
            for (final n in names) DropdownMenuItem(value: n, child: Text(n)),
          ],
          onChanged: (v) => setState(() => _grade = v ?? ''),
        );
      },
      orElse: () => Text('Loading classes…', style: context.typography.bodySmall.copyWith(color: colors.textSecondary)),
    );
  }

  Widget _recentTile(BuildContext context, NotificationItem n) {
    final colors = context.colors;
    final t = context.typography;
    final v = notificationVisual(context, n.type);
    final audience = n.audienceRole == 'students'
        ? (n.grade.isEmpty ? 'Students' : n.grade)
        : n.audienceRole == 'teachers'
            ? 'Teachers'
            : 'Everyone';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
      child: Row(
        children: [
          Icon(v.icon, size: 18, color: v.color),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: t.bodyMediumSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                const Gap(2),
                Text(
                  [
                    'To: $audience',
                    if (n.createdAt != null) DateFormat('dd MMM').format(n.createdAt!.toLocal()),
                  ].join('  ·  '),
                  style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, size: 18, color: colors.red),
            tooltip: 'Delete notification',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await confirmActionDialog(
                context,
                title: 'Delete Notification',
                message: 'Delete "${n.title}"? This cannot be undone.',
                icon: LucideIcons.trash2,
              );
              if (!ok) return;
              try {
                await ref.read(notificationRepositoryProvider).delete(n.id);
                ref.invalidate(adminNotificationsProvider);
                ref.invalidate(myNotificationsProvider);
                messenger.showSnackBar(const SnackBar(content: Text('Notification deleted.')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s, style: context.typography.bodyMediumSemiBold),
      );

  InputDecoration _dec(BuildContext context, String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
