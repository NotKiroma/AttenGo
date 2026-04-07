// lib/services/announcement_service.dart
//
// Исправления vs предыдущей версии:
//  • Восстановлен _sendNotifications (участники получают уведомления)
//  • Восстановлен resolvedExpiresAt для isCancel (объявления не висят вечно)
//  • Добавлен cancelAll getter в модель
//  • delete() возвращает void как в оригинале

import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';
import 'group_service.dart';
import '../local/sync_service.dart';

class Announcement {
  final int id;
  final String groupId;
  final String authorId;
  final String title;
  final String body;
  final bool isCancel;
  final String? cancelDate;
  final String? cancelKey;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? authorName;

  Announcement({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.title,
    required this.body,
    this.isCancel = false,
    this.cancelDate,
    this.cancelKey,
    this.expiresAt,
    this.createdAt,
    this.authorName,
  });

  bool get cancelAll => cancelKey == 'all';

  factory Announcement.fromRow(Map<String, dynamic> r, {String? authorName}) =>
      Announcement(
        id: r['id'] as int,
        groupId: r['group_id'] as String,
        authorId: r['author_id'] as String,
        title: r['title'] as String? ?? '',
        body: r['body'] as String? ?? '',
        isCancel: r['is_cancel'] as bool? ?? false,
        cancelDate: r['cancel_date'] as String?,
        cancelKey: r['cancel_key'] as String?,
        expiresAt: r['expires_at'] != null ? DateTime.tryParse(r['expires_at'] as String) : null,
        createdAt: r['created_at'] != null ? DateTime.tryParse(r['created_at'] as String) : null,
        authorName: authorName,
      );
}

class AnnouncementService {
  static final _supa = DatabaseService.client;
  static final _local = SyncService.db;
  static String? get _uid => AuthService.currentUserId;

  // ── ЧТЕНИЕ ИЗ ЛОКАЛЬНОЙ БД ────────────────────────────────────────────────

  static Future<List<Announcement>> loadAll() async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return [];
    final rows = await _local.getAnnouncements(gid);
    final now = DateTime.now();
    return rows
        .where((r) =>
            r.expiresAt == null ||
            DateTime.tryParse(r.expiresAt!)?.isAfter(now) == true)
        .map((r) => Announcement(
              id: r.id,
              groupId: r.groupId,
              authorId: r.authorId,
              title: r.title,
              body: r.body,
              isCancel: r.isCancel,
              cancelDate: r.cancelDate,
              cancelKey: r.cancelKey,
              expiresAt: r.expiresAt != null ? DateTime.tryParse(r.expiresAt!) : null,
              createdAt: r.createdAt != null ? DateTime.tryParse(r.createdAt!) : null,
              authorName: r.authorName,
            ))
        .toList();
  }

  /// Проверить отменена ли пара — из локальной БД, без сетевого запроса.
  static Future<bool> isCancelled({
    required String date,
    required String lessonKey,
  }) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return false;
    final rows = await _local.getAnnouncements(gid);
    return rows.any((r) =>
        r.isCancel &&
        r.cancelDate == date &&
        (r.cancelKey == lessonKey || r.cancelKey == 'all'));
  }

  /// Получить все ключи отменённых пар за дату одним вызовом.
  /// Заменяет множественные isCancelled() в экранах.
  static Future<Set<String>> getCancelledLessonKeys({required String date}) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return {};
    final rows = await _local.getAnnouncements(gid);
    return rows
        .where((r) => r.isCancel && r.cancelDate == date)
        .map((r) => r.cancelKey ?? 'all')
        .toSet();
  }

  // ── ЗАПИСЬ В SUPABASE + СИНХРОНИЗАЦИЯ ─────────────────────────────────────

  static Future<({bool success, String? error})> create({
    required String title,
    required String body,
    bool isCancel = false,
    String? cancelDate,
    String? cancelKey,
    DateTime? expiresAt,
  }) async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return (success: false, error: 'Группа не найдена');
    if (!(await GroupService.canManage())) return (success: false, error: 'Нет прав');

    try {
      // Для отмены пары — автоматически expires_at = cancelDate + 1 день
      String? resolvedExpiresAt;
      if (isCancel && cancelDate != null) {
        resolvedExpiresAt = DateTime.parse(cancelDate)
            .add(const Duration(days: 1))
            .toIso8601String();
      } else if (expiresAt != null) {
        resolvedExpiresAt = expiresAt.toIso8601String();
      }

      await _supa.from('announcements').insert({
        'group_id': gid,
        'author_id': _uid!,
        'title': title.trim(),
        'body': body.trim(),
        'is_cancel': isCancel,
        'cancel_date': cancelDate,
        'cancel_key': cancelKey,
        'expires_at': resolvedExpiresAt,
      });

      // Уведомляем всех участников группы (кроме автора)
      await _sendNotifications(gid: gid, title: title.trim(), body: body.trim());

      // Синкаем локальную БД
      await SyncService.syncAnnouncements(gid);

      return (success: true, error: null);
    } catch (e) {
      developer.log('[AnnouncementService] create error: $e');
      return (success: false, error: 'Ошибка: $e');
    }
  }

  static Future<void> delete(int id) async {
    final gid = await GroupService.getCurrentGroupId();
    try {
      await _supa.from('announcements').delete().eq('id', id);
      if (gid != null) await SyncService.syncAnnouncements(gid);
    } catch (e) {
      developer.log('[AnnouncementService] delete error: $e');
    }
  }

  // ── ВСПОМОГАТЕЛЬНЫЕ ───────────────────────────────────────────────────────

  static Future<void> _sendNotifications({
    required String gid,
    required String title,
    required String body,
  }) async {
    try {
      final members = await _supa
          .from('group_members')
          .select('user_id')
          .eq('group_id', gid);

      final notifications = (members as List)
          .where((m) => m['user_id'] as String != _uid)
          .map((m) => {
                'user_id': m['user_id'],
                'type': 'announcement',
                'title': title,
                'body': body,
                'data': {'group_id': gid},
                'is_read': false,
              })
          .toList();

      if (notifications.isNotEmpty) {
        await _supa.from('notifications').insert(notifications);
      }
    } catch (e) {
      developer.log('[AnnouncementService] _sendNotifications error: $e');
    }
  }
}
