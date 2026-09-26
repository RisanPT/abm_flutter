import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/notifications/data/notification_repository.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// The one inbox screen used by every role. It is theme-agnostic (all colours
/// come from `context.colors`), so it renders correctly both when pushed from
/// the green student portal and when opened inside the admin shell.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _manageRoles = {
    AppRoles.itAdmin,
    AppRoles.headMaster,
    AppRoles.principal,
    AppRoles.superAdmin,
    AppRoles.staff,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final feedAsync = ref.watch(myNotificationsProvider);
    final role = ref.watch(authControllerProvider).value?.role ?? '';
    final canManage = _manageRoles.contains(role);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Notifications',
            subtitle: 'Your notices, circulars and reminders.',
            actions: [
              feedAsync.maybeWhen(
                data: (f) => f.unreadCount > 0
                    ? TextButton.icon(
                        onPressed: () async {
                          await ref.read(notificationRepositoryProvider).markAllRead();
                          ref.invalidate(myNotificationsProvider);
                        },
                        icon: const Icon(LucideIcons.checkCheck, size: 16, color: Colors.white),
                        label: const Text('Mark all read', style: TextStyle(color: Colors.white)),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          Expanded(
            child: feedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _empty(context, LucideIcons.wifiOff, 'Couldn’t load', 'Please pull to refresh.'),
              data: (feed) => feed.items.isEmpty
                  ? _empty(context, LucideIcons.bellOff, 'No notifications', 'You’re all caught up.')
                  : RefreshIndicator(
                      color: colors.primary,
                      onRefresh: () async => ref.invalidate(myNotificationsProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: feed.items.length,
                        itemBuilder: (_, i) => _NotificationTile(
                          item: feed.items[i],
                          onTap: () => _markRead(ref, feed.items[i]),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus),
              label: const Text('Compose'),
              onPressed: () => context.push(RouteNames.notificationsCompose),
            )
          : (role == AppRoles.teacher
              ? FloatingActionButton.extended(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(LucideIcons.send),
                  label: const Text('Message Office'),
                  onPressed: () => _messageOffice(context, ref),
                )
              : null),
    );
  }

  /// Teacher → Head Master / office admin message.
  Future<void> _messageOffice(BuildContext context, WidgetRef ref) async {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Message the Office'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleC,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const Gap(10),
            TextField(
              controller: bodyC,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (send == true) {
      final title = titleC.text.trim();
      if (title.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a subject.')));
        }
      } else {
        try {
          await ref.read(notificationRepositoryProvider).messageAdmin(title: title, body: bodyC.text.trim());
          ref.invalidate(myNotificationsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message sent to the office'), backgroundColor: Color(0xFF2F855A)),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
          }
        }
      }
    }
    titleC.dispose();
    bodyC.dispose();
  }

  Future<void> _markRead(WidgetRef ref, NotificationItem item) async {
    if (item.read) return;
    await ref.read(notificationRepositoryProvider).markRead(item.id);
    ref.invalidate(myNotificationsProvider);
  }

  Widget _empty(BuildContext context, IconData icon, String title, String sub) {
    final colors = context.colors;
    return ListView(
      // A scrollable so pull-to-refresh still works on the empty state.
      children: [
        const Gap(120),
        Icon(icon, size: 46, color: colors.textSecondary),
        const Gap(14),
        Center(child: Text(title, style: context.typography.bodyLargeSemiBold)),
        const Gap(4),
        Center(child: Text(sub, style: context.typography.bodySmall.copyWith(color: colors.textSecondary))),
      ],
    );
  }
}

/// Icon + tint for a notification type.
({IconData icon, Color color}) notificationVisual(BuildContext context, String type) {
  final colors = context.colors;
  switch (type) {
    case 'Event':
      return (icon: LucideIcons.calendarDays, color: colors.accent);
    case 'FeeDue':
      return (icon: LucideIcons.wallet, color: colors.red);
    case 'Holiday':
      return (icon: LucideIcons.palmtree, color: colors.secondary);
    case 'Message':
      return (icon: LucideIcons.messageSquare, color: colors.accent);
    case 'BugReport':
      return (icon: LucideIcons.bug, color: colors.red);
    case 'Announcement':
    case 'General':
    default:
      return (icon: LucideIcons.megaphone, color: colors.primary);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final v = notificationVisual(context, item.type);
    final unread = !item.read;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: unread ? v.color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: unread ? v.color.withValues(alpha: 0.35) : colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: v.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: Icon(v.icon, size: 19, color: v.color),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: unread ? t.bodyMediumSemiBold : t.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread) ...[
                          const Gap(8),
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: v.color, shape: BoxShape.circle)),
                        ],
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const Gap(4),
                      Text(
                        item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                    ],
                    if (item.hasImage) ...[
                      const Gap(8),
                      GestureDetector(
                        onTap: () => _showFullImage(context, item.imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.imageUrl,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, child, progress) => progress == null
                                ? child
                                : Container(
                                    height: 130,
                                    alignment: Alignment.center,
                                    color: colors.background,
                                    child: const SizedBox(
                                      height: 22, width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                            errorBuilder: (c, e, s) => Container(
                              height: 130,
                              alignment: Alignment.center,
                              color: colors.background,
                              child: Icon(LucideIcons.imageOff, color: colors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Gap(8),
                    Row(
                      children: [
                        if (item.isImportant) ...[
                          _tag(context, 'Important', colors.red),
                          const Gap(8),
                        ],
                        Text(
                          [
                            if (item.postedByName.isNotEmpty) item.postedByName,
                            if (item.createdAt != null) DateFormat('dd MMM · h:mm a').format(item.createdAt!.toLocal()),
                          ].join('  ·  '),
                          style: t.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: context.typography.bodySmall.copyWith(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

/// Full-screen, pinch-to-zoom viewer for a notification's attached image
/// (e.g. a bug-report screenshot).
void _showFullImage(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(LucideIcons.imageOff, color: Colors.white, size: 48),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}
