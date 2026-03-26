import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';
import 'group_service.dart';

class Announcement {
  final int id;
  final String groupId;
  final String authorId;
  final String title;
  final String body;
  final bool isCancel;
  final String? cancelDate;
  final String? cancelKey; // lesson_key или 'all'
  final DateTime? createdAt;
  final String? authorName;
  final DateTime? expiresAt;

  Announcement({required this.id, required this.groupId, required this.authorId, required this.title, required this.body, this.isCancel = false, this.cancelDate, this.cancelKey, this.createdAt, this.authorName, this.expiresAt});

  factory Announcement.fromRow(Map<String, dynamic> r, {String? authorName}) => Announcement(
    id: r['id'] as int,
    groupId: r['group_id'] as String,
    authorId: r['author_id'] as String,
    title: r['title'] as String,
    body: r['body'] as String? ?? '',
    isCancel: r['is_cancel'] as bool? ?? false,
    cancelDate: r['cancel_date'] as String?,
    cancelKey: r['cancel_key'] as String?,
    createdAt: r['created_at'] != null ? DateTime.tryParse(r['created_at'] as String) : null,
    authorName: authorName,
    expiresAt: r['expires_at'] != null ? DateTime.tryParse(r['expires_at'] as String) : null,
  );

  bool get cancelAll => cancelKey == 'all';
}

class AnnouncementService {
  static final _db = DatabaseService.client;
  static String? get _uid => AuthService.currentUserId;

  // Загрузить объявления группы (последние 20)
  // TODO: оптимизировать — заменить N+1 запросы на один JOIN или batch-запрос
  static Future<List<Announcement>> loadAll() async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return [];
    try {
      final rows = await _db.from('announcements').select().eq('group_id', gid).order('created_at', ascending: false).limit(20);

      final result = <Announcement>[];
      for (final r in rows as List) {
        String? authorName;
        try {
          final pRows = await _db.from('profiles').select('first_name, last_name').eq('id', r['author_id']).limit(1);
          if ((pRows as List).isNotEmpty) {
            authorName = '${pRows.first['first_name'] ?? ''} ${pRows.first['last_name'] ?? ''}'.trim();
          }
        } catch (_) {}
        result.add(Announcement.fromRow(r, authorName: authorName));
      }
      return result;
    } catch (e) {
      developer.log('[AnnouncementService] loadAll error: $e');
      return [];
    }
  }

  // Проверить отменена ли конкретная пара
  static Future<bool> isCancelled({required String date, required String lessonKey}) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return false;
    try {
      final rows = await _db.from('announcements').select('id').eq('group_id', gid).eq('is_cancel', true).eq('cancel_date', date).or('cancel_key.eq.$lessonKey,cancel_key.eq.all').limit(1);
      return (rows as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Создать объявление
  static Future<({bool success, String? error})> create({required String title, required String body, bool isCancel = false, String? cancelDate, String? cancelKey, DateTime? expiresAt}) async {
    if (_uid == null) return (success: false, error: 'Не авторизован');
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return (success: false, error: 'Группа не найдена');
    if (!(await GroupService.canManage())) return (success: false, error: 'Нет прав');

    try {
      // Вычисляем expires_at: для отмены пар — конец дня отмены, иначе — переданное значение
      String? resolvedExpiresAt;
      if (isCancel && cancelDate != null) {
        resolvedExpiresAt = DateTime.parse(cancelDate).add(const Duration(days: 1)).toIso8601String();
      } else if (expiresAt != null) {
        resolvedExpiresAt = expiresAt.toIso8601String();
      }

      await _db.from('announcements').insert({'group_id': gid, 'author_id': _uid!, 'title': title.trim(), 'body': body.trim(), 'is_cancel': isCancel, 'cancel_date': cancelDate, 'cancel_key': cancelKey, 'expires_at': resolvedExpiresAt});

      // Уведомления всем участникам группы
      await _sendNotifications(gid: gid, title: title.trim(), body: body.trim());

      return (success: true, error: null);
    } catch (e) {
      developer.log('[AnnouncementService] create error: $e');
      return (success: false, error: 'Ошибка: $e');
    }
  }

  static Future<void> _sendNotifications({required String gid, required String title, required String body}) async {
    try {
      final members = await _db.from('group_members').select('user_id').eq('group_id', gid);
      for (final m in members as List) {
        final uid = m['user_id'] as String;
        if (uid == _uid) continue; // не отправляем себе
        await _db.from('notifications').insert({
          'user_id': uid,
          'type': 'announcement',
          'title': title,
          'body': body,
          'data': {'group_id': gid},
          'is_read': false,
        });
      }
    } catch (e) {
      developer.log('[AnnouncementService] _sendNotifications error: $e');
    }
  }

  // Удалить объявление
  static Future<void> delete(int id) async {
    try {
      await _db.from('announcements').delete().eq('id', id);
    } catch (e) {
      developer.log('[AnnouncementService] delete error: $e');
    }
  }
}
