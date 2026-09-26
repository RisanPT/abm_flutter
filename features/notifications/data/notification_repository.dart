import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Models (plain, no codegen) ───────────────────────────────────────────────

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.link,
    required this.read,
    this.eventId,
    this.audienceRole = 'all',
    this.grade = '',
    this.postedByName = '',
    this.imageUrl = '',
    this.createdAt,
  });

  final String id, title, body, type, priority, link, audienceRole, grade, postedByName, imageUrl;
  final String? eventId;
  final bool read;
  final DateTime? createdAt;

  bool get isImportant => priority == 'Important';
  bool get hasImage => imageUrl.isNotEmpty;

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        type: (j['type'] ?? 'General').toString(),
        priority: (j['priority'] ?? 'Normal').toString(),
        link: (j['link'] ?? '').toString(),
        eventId: j['eventId']?.toString(),
        audienceRole: (j['audienceRole'] ?? 'all').toString(),
        grade: (j['grade'] ?? '').toString(),
        postedByName: (j['postedByName'] ?? '').toString(),
        imageUrl: (j['imageUrl'] ?? '').toString(),
        read: (j['read'] ?? false) as bool,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      );
}

class NotificationFeed {
  const NotificationFeed({required this.items, required this.unreadCount});
  final List<NotificationItem> items;
  final int unreadCount;

  static const empty = NotificationFeed(items: [], unreadCount: 0);
}

// ── Repository + providers ───────────────────────────────────────────────────

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository(ref.watch(dioProvider)));

class NotificationRepository {
  NotificationRepository(this._dio);
  final Dio _dio;

  // Recipient side ────────────────────────────────────────────────────────────

  Future<NotificationFeed> getMine({int limit = 50}) async {
    final r = await _dio.get('/notifications/me', queryParameters: {'limit': limit});
    final items = ((r.data['items'] as List?) ?? [])
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return NotificationFeed(items: items, unreadCount: (r.data['unreadCount'] ?? 0) as int);
  }

  /// Mark one notification read; returns the new unread count.
  Future<int> markRead(String id) async {
    final r = await _dio.post('/notifications/me/$id/read');
    return (r.data['unreadCount'] ?? 0) as int;
  }

  Future<void> markAllRead() async {
    await _dio.post('/notifications/me/read-all');
  }

  // Admin side ──────────────────────────────────────────────────────────────

  Future<void> compose({
    required String title,
    String body = '',
    String type = 'Announcement',
    String priority = 'Normal',
    String audienceRole = 'all',
    String grade = '',
    String? link,
  }) async {
    await _dio.post('/notifications', data: {
      'title': title,
      'body': body,
      'type': type,
      'priority': priority,
      'audienceRole': audienceRole,
      'grade': grade,
      if (link != null && link.isNotEmpty) 'link': link,
    });
  }

  /// A teacher (or staff) sends a message to management (Head Master / office admin).
  Future<void> messageAdmin({required String title, String body = ''}) async {
    await _dio.post('/notifications/to-admin', data: {'title': title, 'body': body});
  }

  /// Any user (teacher / student / principal / staff) reports a bug or issue.
  /// Delivered to the IT Admin only. An optional [screenshot] (a base64 data URI,
  /// e.g. `data:image/jpeg;base64,...`) is uploaded and attached for context.
  Future<void> reportBug({required String title, String body = '', String? screenshot}) async {
    await _dio.post('/notifications/bug-report', data: {
      'title': title,
      'body': body,
      if (screenshot != null && screenshot.isNotEmpty) 'screenshot': screenshot,
    });
  }

  Future<List<NotificationItem>> adminList({int limit = 100}) async {
    final r = await _dio.get('/notifications', queryParameters: {'limit': limit});
    return ((r.data['items'] as List?) ?? [])
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> delete(String id) async {
    await _dio.delete('/notifications/$id');
  }

  /// Generate personal fee-due notices for a month. Returns {month, created, skipped}.
  Future<Map<String, dynamic>> sendFeeReminders({String? month, String? classroom}) async {
    final r = await _dio.post('/notifications/fee-reminders', data: {
      if (month != null && month.isNotEmpty) 'month': month,
      if (classroom != null && classroom.isNotEmpty) 'classroom': classroom,
    });
    return Map<String, dynamic>.from(r.data);
  }
}

/// The current user's inbox (auto-loading, refreshable via invalidate).
final myNotificationsProvider = FutureProvider.autoDispose<NotificationFeed>((ref) {
  return ref.watch(notificationRepositoryProvider).getMine();
});

/// Derived unread badge count — 0 while loading or on error.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(myNotificationsProvider).maybeWhen(
        data: (f) => f.unreadCount,
        orElse: () => 0,
      );
});

/// Admin manage list (all institute-wide broadcasts, newest first).
final adminNotificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) {
  return ref.watch(notificationRepositoryProvider).adminList();
});
