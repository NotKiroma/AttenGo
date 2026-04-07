// lib/local/sync_service.dart

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:drift/drift.dart';

import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import 'local_db.dart';

class SyncService {
  SyncService._();

  static final _local = LocalDatabase();

  static LocalDatabase get db => _local;

  // ─────────────────────────────────────────────────────────────────────────
  // ПОЛНАЯ СИНХРОНИЗАЦИЯ
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> syncAll() async {
    try {
      final uid = AuthService.currentUserId;
      if (uid == null) {
        developer.log('[SyncService] syncAll: no user');
        return;
      }
      developer.log('[SyncService] syncAll start uid=$uid');

      await syncProfile(uid);
      await syncGroup(uid);

      final gid = GroupService.cachedGroupId;
      final email = DatabaseService.client.auth.currentUser?.email;
      developer.log('[SyncService] syncAll: gid=$gid email=$email');

      await Future.wait([if (gid != null) syncStudents(gid), if (gid != null) syncSchedule(gid), if (gid != null) syncAttendance(gid), if (gid != null) syncAnnouncements(gid), syncNotifications(uid), if (email != null) syncInvitations(email)]);

      developer.log('[SyncService] syncAll done');
    } catch (e, st) {
      developer.log('[SyncService] syncAll error: $e\n$st');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ПРОФИЛЬ
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> syncProfile(String uid) async {
    try {
      final rows = await DatabaseService.client.from('profiles').select('id, email, first_name, last_name, avatar_url, created_at').eq('id', uid).limit(1);

      if ((rows as List).isEmpty) {
        developer.log('[SyncService] syncProfile: not found');
        return;
      }
      final r = rows.first;
      await _local.upsertProfile(
        LocalProfilesCompanion(id: Value(r['id'] as String), email: Value(r['email'] as String? ?? ''), firstName: Value(r['first_name'] as String? ?? ''), lastName: Value(r['last_name'] as String? ?? ''), avatarUrl: Value(r['avatar_url'] as String?), createdAt: Value(r['created_at'] as String?)),
      );
      developer.log('[SyncService] syncProfile done');
    } catch (e) {
      developer.log('[SyncService] syncProfile error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ГРУППА + УЧАСТНИКИ
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> syncGroup(String uid) async {
    try {
      developer.log('[SyncService] syncGroup uid=$uid');
      final supa = DatabaseService.client;

      // Членство текущего пользователя с вложенной группой
      final ms = await supa.from('group_members').select('id, group_id, user_id, role, is_student, groups(id, name, owner_id)').eq('user_id', uid);

      developer.log('[SyncService] syncGroup memberships=${(ms as List).length}');
      if ((ms as List).isEmpty) return;

      final gid = ms.first['group_id'] as String;
      final groupData = ms.first['groups'] as Map<String, dynamic>?;

      if (groupData == null) {
        developer.log('[SyncService] syncGroup: embedded group is null');
        return;
      }

      await _local.upsertGroup(LocalGroupsCompanion(id: Value(groupData['id'] as String), name: Value(groupData['name'] as String? ?? 'Группа'), ownerId: Value(groupData['owner_id'] as String)));

      // Все участники группы
      final allMembers = await supa.from('group_members').select('id, group_id, user_id, role, is_student').eq('group_id', gid);

      final userIds = (allMembers as List).map((r) => r['user_id'] as String).toSet().toList();

      // Один запрос для всех профилей участников
      final profileRows = await supa.from('profiles').select('id, email, first_name, last_name, avatar_url').inFilter('id', userIds);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in profileRows as List) {
        profileMap[p['id'] as String] = p as Map<String, dynamic>;
      }

      // Batch-вставка участников
      await _local.clearGroupMembers(gid);
      final memberCompanions = (allMembers as List).map((r) {
        return LocalGroupMembersCompanion(id: Value(r['id'] as int), groupId: Value(r['group_id'] as String), userId: Value(r['user_id'] as String), role: Value(r['role'] as String), isStudent: Value(r['is_student'] as bool? ?? false));
      }).toList();
      await _local.upsertGroupMembers(memberCompanions);

      // Batch-вставка профилей участников
      final profileCompanions = profileMap.values.map((p) {
        return LocalProfilesCompanion(id: Value(p['id'] as String), email: Value(p['email'] as String? ?? ''), firstName: Value(p['first_name'] as String? ?? ''), lastName: Value(p['last_name'] as String? ?? ''), avatarUrl: Value(p['avatar_url'] as String?));
      }).toList();
      await _local.upsertProfiles(profileCompanions);

      GroupService.setCachedGroupId(gid);
      developer.log('[SyncService] syncGroup done gid=$gid members=${memberCompanions.length}');
    } catch (e, st) {
      developer.log('[SyncService] syncGroup error: $e\n$st');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // СТУДЕНТЫ — один запрос к profiles вместо N
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> syncStudents(String groupId) async {
    try {
      developer.log('[SyncService] syncStudents gid=$groupId');
      final supa = DatabaseService.client;

      final rows = await supa
          .from('students')
          .select(
            'id, group_id, last_name, first_name, middle_name, birth_day, '
            'birth_month, birth_year, is_male, status, linked_user_id',
          )
          .eq('group_id', groupId)
          .neq('status', 'inactive')
          .order('last_name', ascending: true);

      developer.log('[SyncService] syncStudents count=${(rows as List).length}');

      // Собираем все linked_user_id одним set'ом → один запрос к profiles
      final linkedIds = (rows as List).map((r) => r['linked_user_id'] as String?).whereType<String>().toSet().toList();

      final avatarMap = <String, String?>{};
      if (linkedIds.isNotEmpty) {
        final profileRows = await supa.from('profiles').select('id, avatar_url').inFilter('id', linkedIds);
        for (final p in profileRows as List) {
          avatarMap[p['id'] as String] = p['avatar_url'] as String?;
        }
      }

      await _local.clearStudents(groupId);

      final companions = (rows as List).map((r) {
        final linkedId = r['linked_user_id'] as String?;
        return LocalStudentsCompanion(
          id: Value(r['id'] as String),
          groupId: Value(r['group_id'] as String),
          lastName: Value(r['last_name'] as String? ?? ''),
          firstName: Value(r['first_name'] as String? ?? ''),
          middleName: Value(r['middle_name'] as String? ?? ''),
          birthDay: Value(r['birth_day'] as String? ?? ''),
          birthMonth: Value(r['birth_month'] as String? ?? ''),
          birthYear: Value(r['birth_year'] as String? ?? ''),
          isMale: Value(r['is_male'] as bool? ?? true),
          status: Value(r['status'] as String? ?? 'active'),
          linkedUserId: Value(linkedId),
          avatarUrl: Value(linkedId != null ? avatarMap[linkedId] : null),
        );
      }).toList();

      await _local.upsertStudents(companions);
      developer.log('[SyncService] syncStudents done');
    } catch (e) {
      developer.log('[SyncService] syncStudents error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // РАСПИСАНИЕ — batch
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> syncSchedule(String groupId) async {
    try {
      developer.log('[SyncService] syncSchedule gid=$groupId');
      final rows = await DatabaseService.client.from('schedule').select('id, group_id, day_index, time_start, time_end, subject, room, teacher').eq('group_id', groupId).order('day_index', ascending: true).order('time_start', ascending: true);

      developer.log('[SyncService] syncSchedule count=${(rows as List).length}');
      await _local.clearSchedule(groupId);

      final companions = (rows as List)
          .map(
            (r) => LocalScheduleCompanion(
              id: Value(r['id'] as int),
              groupId: Value(r['group_id'] as String),
              dayIndex: Value(r['day_index'] as int),
              timeStart: Value(r['time_start'] as String),
              timeEnd: Value(r['time_end'] as String),
              subject: Value(r['subject'] as String),
              room: Value(r['room'] as String),
              teacher: Value(r['teacher'] as String),
            ),
          )
          .toList();

      await _local.upsertLessons(companions);
      developer.log('[SyncService] syncSchedule done');
    } catch (e) {
      developer.log('[SyncService] syncSchedule error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ПОСЕЩАЕМОСТЬ — два batch вместо N*M запросов
  // ─────────────────────────────────────────────────────────────────────────

  // Внутри класса SyncService замените метод syncAttendance:

  static Future<void> syncAttendance(String groupId) async {
    try {
      // Получаем данные из Supabase
      final lessons = await DatabaseService.client.from('attendance_lessons').select('*, attendance_records(*)').eq('group_id', groupId);

      // Используем транзакцию Drift для атомарности
      await _local.transaction(() async {
        // Очищаем старые записи для этой группы перед вставкой новых
        // (Или используем insertAllOnConflictUpdate, если id совпадают)

        final lessonCompanions = (lessons as List).map((l) => LocalAttendanceLessonsCompanion(id: Value(l['id'] as int), groupId: Value(l['group_id'] as String), date: Value(l['date'] as String), lessonKey: Value(l['lesson_key'] as String), subject: Value(l['subject'] as String))).toList();

        await _local.upsertAttendanceLessons(lessonCompanions);

        List<LocalAttendanceRecordsCompanion> recordCompanions = [];
        for (var l in lessons) {
          final records = l['attendance_records'] as List;
          for (var r in records) {
            recordCompanions.add(LocalAttendanceRecordsCompanion(id: Value(r['id'] as int), lessonId: Value(r['lesson_id'] as int), studentId: Value(r['student_id'] as String), status: Value(r['status'] as String?)));
          }
        }
        await _local.upsertAttendanceRecords(recordCompanions);
      });

      developer.log('[SyncService] syncAttendance success for group $groupId');
    } catch (e) {
      developer.log('[SyncService] syncAttendance error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ОБЪЯВЛЕНИЯ — batch + отдельный запрос к profiles (нет embedded join)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> syncAnnouncements(String groupId) async {
    try {
      developer.log('[SyncService] syncAnnouncements gid=$groupId');
      final supa = DatabaseService.client;

      final list = await supa
          .from('announcements')
          .select(
            'id, group_id, author_id, title, body, is_cancel, '
            'cancel_date, cancel_key, expires_at, created_at',
          )
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      // Один запрос для всех авторов
      final authorIds = (list as List).map((r) => r['author_id'] as String).toSet().toList();

      final profileMap = <String, String>{};
      if (authorIds.isNotEmpty) {
        final profiles = await supa.from('profiles').select('id, first_name, last_name').inFilter('id', authorIds);
        for (final p in profiles as List) {
          final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
          profileMap[p['id'] as String] = name;
        }
      }

      await _local.clearAnnouncements(groupId);

      final companions = (list as List).map((r) {
        final name = profileMap[r['author_id'] as String];
        return LocalAnnouncementsCompanion(
          id: Value(r['id'] as int),
          groupId: Value(r['group_id'] as String),
          authorId: Value(r['author_id'] as String),
          title: Value(r['title'] as String? ?? ''),
          body: Value(r['body'] as String? ?? ''),
          isCancel: Value(r['is_cancel'] as bool? ?? false),
          cancelDate: Value(r['cancel_date'] as String?),
          cancelKey: Value(r['cancel_key'] as String?),
          expiresAt: Value(r['expires_at'] as String?),
          createdAt: Value(r['created_at'] as String?),
          authorName: Value(name == null || name.isEmpty ? null : name),
        );
      }).toList();

      await _local.upsertAnnouncements(companions);
      developer.log('[SyncService] syncAnnouncements done count=${companions.length}');
    } catch (e) {
      developer.log('[SyncService] syncAnnouncements error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // УВЕДОМЛЕНИЯ — batch
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> syncNotifications(String userId) async {
    try {
      developer.log('[SyncService] syncNotifications uid=$userId');
      final rows = await DatabaseService.client.from('notifications').select('id, user_id, type, title, body, data, is_read, created_at').eq('user_id', userId).order('created_at', ascending: false).limit(50);

      await _local.clearNotifications(userId);

      final companions = (rows as List)
          .map(
            (r) => LocalNotificationsCompanion(
              id: Value(r['id'] as int),
              userId: Value(r['user_id'] as String),
              type: Value(r['type'] as String? ?? ''),
              title: Value(r['title'] as String? ?? ''),
              body: Value(r['body'] as String? ?? ''),
              data: Value(jsonEncode(r['data'] ?? {})),
              isRead: Value(r['is_read'] as bool? ?? false),
              createdAt: Value(r['created_at'] as String?),
            ),
          )
          .toList();

      await _local.upsertNotifications(companions);
      developer.log('[SyncService] syncNotifications done count=${companions.length}');
    } catch (e) {
      developer.log('[SyncService] syncNotifications error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ПРИГЛАШЕНИЯ — batch + отдельные запросы к profiles и groups
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> syncInvitations(String email) async {
    try {
      developer.log('[SyncService] syncInvitations email=$email');
      final supa = DatabaseService.client;

      final rows = await supa.from('invitations').select('id, group_id, sender_id, recipient_email, role, status, created_at').eq('recipient_email', email).eq('status', 'pending').order('created_at', ascending: false);

      final list = rows as List;

      // Два параллельных запроса вместо N
      final senderIds = list.map((r) => r['sender_id'] as String).toSet().toList();
      final groupIds = list.map((r) => r['group_id'] as String).toSet().toList();

      final senderMap = <String, String>{};
      final groupMap = <String, String>{};

      await Future.wait([
        if (senderIds.isNotEmpty)
          supa.from('profiles').select('id, first_name, last_name').inFilter('id', senderIds).then((profiles) {
            for (final p in profiles as List) {
              senderMap[p['id'] as String] = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
            }
          }),
        if (groupIds.isNotEmpty)
          supa.from('groups').select('id, name').inFilter('id', groupIds).then((groups) {
            for (final g in groups as List) {
              groupMap[g['id'] as String] = g['name'] as String? ?? '';
            }
          }),
      ]);

      await _local.clearInvitations(email);

      final companions = list.map((r) {
        final senderName = senderMap[r['sender_id'] as String];
        return LocalInvitationsCompanion(
          id: Value(r['id'] as int),
          groupId: Value(r['group_id'] as String),
          senderId: Value(r['sender_id'] as String),
          recipientEmail: Value(r['recipient_email'] as String),
          role: Value(r['role'] as String? ?? 'member'),
          status: Value(r['status'] as String),
          createdAt: Value(r['created_at'] as String?),
          senderName: Value(senderName == null || senderName.isEmpty ? null : senderName),
          groupName: Value(groupMap[r['group_id'] as String]),
        );
      }).toList();

      await _local.upsertInvitations(companions);
      developer.log('[SyncService] syncInvitations done count=${companions.length}');
    } catch (e) {
      developer.log('[SyncService] syncInvitations error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ОЧИСТКА
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await _local.clearAll();
    developer.log('[SyncService] clearAll done');
  }
}
