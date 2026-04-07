// lib/services/notification_service.dart
//
// Читает из LocalDatabase, пишет в Supabase → триггерит синхронизацию.

import 'dart:convert';
import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';
import '../local/sync_service.dart';

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromRow(Map<String, dynamic> row) => AppNotification(
        id: row['id'] as int,
        type: row['type'] as String? ?? '',
        title: row['title'] as String? ?? '',
        body: row['body'] as String? ?? '',
        data: row['data'] as Map<String, dynamic>? ?? {},
        isRead: row['is_read'] as bool? ?? false,
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'] as String)
            : null,
      );
}

class NotificationService {
  static final _supa = DatabaseService.client;
  static final _local = SyncService.db;
  static String? get _uid => AuthService.currentUserId;

  // ── ЧТЕНИЕ ИЗ ЛОКАЛЬНОЙ БД ────────────────────────────────────────────────

  static Future<List<AppNotification>> loadAll() async {
    if (_uid == null) return [];
    final rows = await _local.getNotifications(_uid!);
    return rows
        .map((r) => AppNotification(
              id: r.id,
              type: r.type,
              title: r.title,
              body: r.body,
              data: _parseJson(r.data),
              isRead: r.isRead,
              createdAt: r.createdAt != null
                  ? DateTime.tryParse(r.createdAt!)
                  : null,
            ))
        .toList();
  }

  static Future<int> unreadCount() async {
    if (_uid == null) return 0;
    return _local.getUnreadCount(_uid!);
  }

  // ── ЗАПИСЬ В SUPABASE + СИНХРОНИЗАЦИЯ ─────────────────────────────────────

  static Future<void> markAsRead(int notificationId) async {
    try {
      await _supa
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
      // Оптимистично обновляем локальную БД
      await _local.markNotificationRead(notificationId);
    } catch (e) {
      developer.log('[NotificationService] markAsRead error: $e');
    }
  }

  static Future<void> markAllAsRead() async {
    if (_uid == null) return;
    try {
      await _supa
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _uid!)
          .eq('is_read', false);
      await _local.markAllNotificationsRead(_uid!);
    } catch (e) {
      developer.log('[NotificationService] markAllAsRead error: $e');
    }
  }

  static Future<void> delete(int notificationId) async {
    try {
      await _supa.from('notifications').delete().eq('id', notificationId);
      await _local.deleteNotification(notificationId);
    } catch (e) {
      developer.log('[NotificationService] delete error: $e');
    }
  }

  // ── УТИЛИТЫ ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _parseJson(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
