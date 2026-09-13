import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/notifications/data/notification_repository.dart';
import 'package:abm_madrasa/features/notifications/presentation/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A bell icon with an unread badge that opens the shared [NotificationsScreen].
///
/// [color] defaults to white (for use over a coloured app bar / gradient header);
/// pass a themed colour when placing it on a light surface.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color = Colors.white, this.size = 22});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(LucideIcons.bell, color: color, size: size),
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(color: context.colors.red, borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white, width: 1.4)),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, height: 1),
              ),
            ),
          ),
      ],
    );
  }
}
