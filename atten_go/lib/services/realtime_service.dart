import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_service.dart';
import '../local/sync_service.dart';
import 'auth_service.dart';
import 'group_service.dart';

class RealtimeService {
  RealtimeService._();

  static final _scheduleCtrl = StreamController<void>.broadcast();
  static final _studentsCtrl = StreamController<void>.broadcast();
  static final _attendanceRecordsCtrl = StreamController<void>.broadcast();
  static final _attendanceLessonsCtrl = StreamController<void>.broadcast();
  static final _notificationsCtrl = StreamController<void>.broadcast();
  static final _invitationsCtrl = StreamController<void>.broadcast();
  static final _groupMembersCtrl = StreamController<void>.broadcast();
  static final _groupsCtrl = StreamController<void>.broadcast();
  static final _announcementsCtrl = StreamController<void>.broadcast();

  static Stream<void> get onScheduleChanged => _scheduleCtrl.stream;
  static Stream<void> get onStudentsChanged => _studentsCtrl.stream;
  static Stream<void> get onAttendanceRecordsChanged => _attendanceRecordsCtrl.stream;
  static Stream<void> get onAttendanceLessonsChanged => _attendanceLessonsCtrl.stream;
  static Stream<void> get onNotificationsChanged => _notificationsCtrl.stream;
  static Stream<void> get onInvitationsChanged => _invitationsCtrl.stream;
  static Stream<void> get onGroupMembersChanged => _groupMembersCtrl.stream;
  static Stream<void> get onGroupsChanged => _groupsCtrl.stream;
  static Stream<void> get onAnnouncementsChanged => _announcementsCtrl.stream;

  static RealtimeChannel? _channel;
  static final Map<String, Future<void>> _syncQueues = {};

  // ─── BUGFIX: безопасно достаём group_id из INSERT/UPDATE И DELETE ────────
  // При DELETE newRecord пустой → берём из oldRecord.
  static String? _groupId(PostgresChangePayload p) => (p.newRecord['group_id'] as String?) ?? (p.oldRecord['group_id'] as String?);

  static void init() {
    if (_channel != null) return;

    final gid = GroupService.cachedGroupId;
    final uid = AuthService.currentUserId;
    if (uid == null) {
      developer.log('[Realtime] init skipped: no user');
      return;
    }

    // Уникальное имя канала, чтобы избежать коллизий при переподключении
    _channel = DatabaseService.client.channel('db_changes_$uid');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'schedule',
          // BUGFIX: фильтруем по своей группе — не слушаем чужие изменения
          filter: gid != null ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: gid) : null,
          callback: (p) {
            final g = _groupId(p);
            if (g == null) return; // BUGFIX: DELETE guard
            _enqueueUpdate('schedule', _scheduleCtrl, () => SyncService.syncSchedule(g));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'students',
          filter: gid != null ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: gid) : null,
          callback: (p) {
            final g = _groupId(p);
            if (g == null) return;
            _enqueueUpdate('students', _studentsCtrl, () => SyncService.syncStudents(g));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_lessons',
          filter: gid != null ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: gid) : null,
          callback: (p) {
            final g = _groupId(p);
            if (g == null) return;
            _enqueueUpdate('attendance_lessons', _attendanceLessonsCtrl, () => SyncService.syncAttendance(g));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_records',
          callback: (p) {
            // BUGFIX: для DELETE берём lesson_id из oldRecord
            final lessonId = (p.newRecord['lesson_id'] ?? p.oldRecord['lesson_id']) as int?;
            if (lessonId == null) return;
            _enqueueUpdate('attendance_records', _attendanceRecordsCtrl, () async {
              final res = await DatabaseService.client.from('attendance_lessons').select('group_id').eq('id', lessonId).maybeSingle();
              if (res != null) {
                await SyncService.syncAttendance(res['group_id'] as String);
              }
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          // Фильтр по user_id — каждый слушает только свои уведомления
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: uid),
          callback: (p) {
            final currentUid = AuthService.currentUserId;
            if (currentUid == null) return;
            _enqueueUpdate('notifications', _notificationsCtrl, () => SyncService.syncNotifications(currentUid));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          filter: gid != null ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: gid) : null,
          callback: (p) {
            final g = _groupId(p);
            if (g == null) return;
            _enqueueUpdate('announcements', _announcementsCtrl, () => SyncService.syncAnnouncements(g));
          },
        )
        .subscribe((status, [err]) {
          developer.log('[Realtime] status=$status err=$err');
        });

    developer.log('[Realtime] init done uid=$uid gid=$gid');
  }

  static void reconnect() {
    dispose();
    init();
  }

  static void _enqueueUpdate(String table, StreamController<void> ctrl, Future<void> Function() onSync) {
    _syncQueues[table] = (_syncQueues[table] ?? Future.value()).then((_) async {
      try {
        await onSync();
        if (!ctrl.isClosed) ctrl.add(null);
      } catch (e) {
        developer.log('[Realtime] error syncing $table: $e');
      }
    });
  }

  static void dispose() {
    if (_channel != null) {
      DatabaseService.client.removeChannel(_channel!);
      _channel = null;
    }
    _syncQueues.clear();
  }
}
