import 'package:abm_madrasa/core/router/route_names.dart';
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
          : null,
    );
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
