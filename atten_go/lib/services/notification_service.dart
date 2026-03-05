import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';

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
        createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      );
}

class NotificationService {
  static final _db = DatabaseService.client;
  static String? get _uid => AuthService.currentUserId;

  static Future<List<AppNotification>> loadAll() async {
    if (_uid == null) return [];
    try {
      final rows = await _db
          .from('notifications')
          .select()
          .eq('user_id', _uid!)
          .order('created_at', ascending: false)
          .limit(50);
      return (rows as List).map((r) => AppNotification.fromRow(r)).toList();
    } catch (e) {
      developer.log('[NotificationService] loadAll error: $e');
      return [];
    }
  }

  static Future<int> unreadCount() async {
    if (_uid == null) return 0;
    try {
      final rows = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', _uid!)
          .eq('is_read', false);
      return (rows as List).length;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      await _db.from('notifications').update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      developer.log('[NotificationService] markAsRead error: $e');
    }
  }

  static Future<void> markAllAsRead() async {
    if (_uid == null) return;
    try {
      await _db.from('notifications').update({'is_read': true}).eq('user_id', _uid!).eq('is_read', false);
    } catch (e) {
      developer.log('[NotificationService] markAllAsRead error: $e');
    }
  }

  static Future<void> delete(int notificationId) async {
    try {
      await _db.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      developer.log('[NotificationService] delete error: $e');
    }
  }
}
