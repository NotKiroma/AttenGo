import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_service.dart';
import '../local/sync_service.dart';
import 'auth_service.dart';

class RealtimeService {
  RealtimeService._();

  static final _scheduleCtrl = StreamController<void>.broadcast();
  static final _studentsCtrl = StreamController<void>.broadcast();
  static final _attendanceRecordsCtrl = StreamController<void>.broadcast();
  static final _attendanceLessonsCtrl = StreamController<void>.broadcast(); // Добавлено
  static final _notificationsCtrl = StreamController<void>.broadcast();
  static final _invitationsCtrl = StreamController<void>.broadcast();
  static final _groupMembersCtrl = StreamController<void>.broadcast(); // Добавлено
  static final _groupsCtrl = StreamController<void>.broadcast(); // Добавлено
  static final _announcementsCtrl = StreamController<void>.broadcast(); // Добавлено

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

  static void init() {
    if (_channel != null) return;

    _channel = DatabaseService.client.channel('public:db_changes');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'schedule',
          callback: (p) => _enqueueUpdate('schedule', _scheduleCtrl, p, onSync: () => SyncService.syncSchedule(p.newRecord['group_id'])),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'students',
          callback: (p) => _enqueueUpdate('students', _studentsCtrl, p, onSync: () => SyncService.syncStudents(p.newRecord['group_id'])),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_lessons',
          callback: (p) => _enqueueUpdate('attendance_lessons', _attendanceLessonsCtrl, p, onSync: () => SyncService.syncAttendance(p.newRecord['group_id'])),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_records',
          callback: (p) => _enqueueUpdate(
            'attendance_records',
            _attendanceRecordsCtrl,
            p,
            onSync: () async {
              final lessonId = p.newRecord['lesson_id'] as int;
              final res = await DatabaseService.client.from('attendance_lessons').select('group_id').eq('id', lessonId).maybeSingle();
              if (res != null) await SyncService.syncAttendance(res['group_id']);
            },
          ),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (p) => _enqueueUpdate('notifications', _notificationsCtrl, p, onSync: () => SyncService.syncNotifications(AuthService.currentUserId!)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (p) => _enqueueUpdate('announcements', _announcementsCtrl, p, onSync: () => SyncService.syncAnnouncements(p.newRecord['group_id'])),
        )
        .subscribe();
  }

  static void reconnect() {
    dispose();
    init();
  }

  static void _enqueueUpdate(String table, StreamController<void> ctrl, PostgresChangePayload payload, {required Future<void> Function() onSync}) {
    _syncQueues[table] = (_syncQueues[table] ?? Future.value()).then((_) async {
      try {
        await onSync();
        if (!ctrl.isClosed) ctrl.add(null);
      } catch (e) {
        developer.log('[Realtime] Error: $e');
      }
    });
  }

  static void dispose() {
    if (_channel != null) {
      DatabaseService.client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
