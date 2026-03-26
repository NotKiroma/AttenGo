import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_service.dart';
import 'group_service.dart';

/// Централизованный сервис Realtime-подписок.
///
/// Подписывается на все таблицы один раз и рассылает события
/// через стримы. Экраны слушают нужные стримы и обновляются.
///
/// Использование:
///   RealtimeService.init();  // в main.dart или MainScreen.initState
///   RealtimeService.onScheduleChanged.listen((_) => _refresh());
///   RealtimeService.dispose(); // при выходе
class RealtimeService {
  RealtimeService._();

  // ── Стрим-контроллеры (broadcast — несколько слушателей) ──
  static final _scheduleCtrl = StreamController<void>.broadcast();
  static final _studentsCtrl = StreamController<void>.broadcast();
  static final _attendanceLessonsCtrl = StreamController<void>.broadcast();
  static final _attendanceRecordsCtrl = StreamController<void>.broadcast();
  static final _groupMembersCtrl = StreamController<void>.broadcast();
  static final _announcementsCtrl = StreamController<void>.broadcast();
  static final _notificationsCtrl = StreamController<void>.broadcast();
  static final _invitationsCtrl = StreamController<void>.broadcast();
  static final _profilesCtrl = StreamController<void>.broadcast();
  static final _groupsCtrl = StreamController<void>.broadcast();

  // ── Публичные стримы для экранов ──
  static Stream<void> get onScheduleChanged => _scheduleCtrl.stream;
  static Stream<void> get onStudentsChanged => _studentsCtrl.stream;
  static Stream<void> get onAttendanceLessonsChanged => _attendanceLessonsCtrl.stream;
  static Stream<void> get onAttendanceRecordsChanged => _attendanceRecordsCtrl.stream;
  static Stream<void> get onGroupMembersChanged => _groupMembersCtrl.stream;
  static Stream<void> get onAnnouncementsChanged => _announcementsCtrl.stream;
  static Stream<void> get onNotificationsChanged => _notificationsCtrl.stream;
  static Stream<void> get onInvitationsChanged => _invitationsCtrl.stream;
  static Stream<void> get onProfilesChanged => _profilesCtrl.stream;
  static Stream<void> get onGroupsChanged => _groupsCtrl.stream;

  /// Комбинированный стрим — любое изменение посещаемости
  static Stream<void> get onAttendanceChanged =>
      StreamGroup.merge([_attendanceLessonsCtrl.stream, _attendanceRecordsCtrl.stream]);

  // ── Внутреннее состояние ──
  static RealtimeChannel? _channel;
  static bool _initialized = false;

  // Debounce таймеры (чтобы не дёргать 10 раз за секунду)
  static final Map<String, Timer?> _debounceTimers = {};

  /// Инициализация — вызвать один раз после авторизации
  static void init() {
    if (_initialized) return;
    _initialized = true;
    _subscribe();
    developer.log('[RealtimeService] Initialized');
  }

  /// Переподписка (вызывать при resume из background или после смены группы)
  static void reconnect() {
    _unsubscribe();
    _subscribe();
    developer.log('[RealtimeService] Reconnected');
  }

  /// Отписка от всего
  static void dispose() {
    _unsubscribe();
    _initialized = false;
    developer.log('[RealtimeService] Disposed');
  }

  // ── Подписка на все таблицы одним каналом ──
  static void _subscribe() {
    final client = DatabaseService.client;

    _channel = client
        .channel('app_realtime')
        // Расписание
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'schedule',
          callback: (payload) => _emit('schedule', _scheduleCtrl, payload),
        )
        // Студенты
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'students',
          callback: (payload) => _emit('students', _studentsCtrl, payload),
        )
        // Уроки посещаемости
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_lessons',
          callback: (payload) => _emit('attendance_lessons', _attendanceLessonsCtrl, payload),
        )
        // Записи посещаемости
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_records',
          callback: (payload) => _emit('attendance_records', _attendanceRecordsCtrl, payload),
        )
        // Участники группы
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          callback: (payload) {
            _emit('group_members', _groupMembersCtrl, payload);
            // Инвалидируем кеш группы при любом изменении
            GroupService.invalidateCache();
          },
        )
        // Объявления
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (payload) => _emit('announcements', _announcementsCtrl, payload),
        )
        // Уведомления
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) => _emit('notifications', _notificationsCtrl, payload),
        )
        // Приглашения
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invitations',
          callback: (payload) => _emit('invitations', _invitationsCtrl, payload),
        )
        // Профили
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) => _emit('profiles', _profilesCtrl, payload),
        )
        // Группы
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'groups',
          callback: (payload) => _emit('groups', _groupsCtrl, payload),
        )
        .subscribe((status, [error]) {
          developer.log('[RealtimeService] Channel status: $status${error != null ? ' error: $error' : ''}');
        });
  }

  static void _unsubscribe() {
    // Отменяем все debounce-таймеры
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();

    if (_channel != null) {
      DatabaseService.client.removeChannel(_channel!);
      _channel = null;
    }
  }

  /// Debounced emit — ждём 300ms тишины перед отправкой события.
  /// Это предотвращает 10 обновлений за секунду при batch-операциях.
  static void _emit(String table, StreamController<void> ctrl, PostgresChangePayload payload) {
    developer.log('[Realtime] $table ${payload.eventType}');

    _debounceTimers[table]?.cancel();
    _debounceTimers[table] = Timer(const Duration(milliseconds: 300), () {
      if (!ctrl.isClosed) {
        ctrl.add(null);
      }
    });
  }
}

/// Простой StreamGroup.merge — объединяет несколько стримов в один.
class StreamGroup {
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>.broadcast();
    final subscriptions = <StreamSubscription<T>>[];

    for (final stream in streams) {
      subscriptions.add(stream.listen(
        (data) => controller.add(data),
        onError: (e) => controller.addError(e),
      ));
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }
}
