// lib/local/local_db.dart
//
// Локальная SQLite база данных (Drift).
//
// Оптимизации vs v1:
//  • Индексы на все горячие колонки (groupId, userId, lessonId, date, status)
//  • Batch-методы для массовых вставок (insertAll / replaceAll)
//  • COUNT(*) вместо загрузки всех строк для unreadCount
//  • clearAll в одной транзакции
//  • Составной индекс (groupId, date, lessonKey) для getAttendanceLesson
//  • schemaVersion = 2 с MigrationStrategy

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_db.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ТАБЛИЦЫ
// ─────────────────────────────────────────────────────────────────────────────

class LocalProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get firstName => text().withDefault(const Constant(''))();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get createdAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_group_members_group', columns: {#groupId})
@TableIndex(name: 'idx_group_members_user', columns: {#userId})
class LocalGroupMembers extends Table {
  IntColumn get id => integer()();
  TextColumn get groupId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();
  BoolColumn get isStudent => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_students_group_status', columns: {#groupId, #status})
@TableIndex(name: 'idx_students_linked', columns: {#linkedUserId})
class LocalStudents extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get firstName => text().withDefault(const Constant(''))();
  TextColumn get middleName => text().withDefault(const Constant(''))();
  TextColumn get birthDay => text().withDefault(const Constant(''))();
  TextColumn get birthMonth => text().withDefault(const Constant(''))();
  TextColumn get birthYear => text().withDefault(const Constant(''))();
  BoolColumn get isMale => boolean().withDefault(const Constant(true))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get linkedUserId => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_schedule_group_day', columns: {#groupId, #dayIndex})
class LocalSchedule extends Table {
  IntColumn get id => integer()();
  TextColumn get groupId => text()();
  IntColumn get dayIndex => integer()();
  TextColumn get timeStart => text()();
  TextColumn get timeEnd => text()();
  TextColumn get subject => text()();
  TextColumn get room => text()();
  TextColumn get teacher => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// Составной индекс для getAttendanceLesson(groupId, date, lessonKey)
@TableIndex(name: 'idx_att_lessons_group', columns: {#groupId})
@TableIndex(name: 'idx_att_lessons_lookup', columns: {#groupId, #date, #lessonKey}, unique: true)
class LocalAttendanceLessons extends Table {
  IntColumn get id => integer()();
  TextColumn get groupId => text()();
  TextColumn get date => text()();
  TextColumn get lessonKey => text()();
  TextColumn get subject => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_att_records_lesson', columns: {#lessonId})
@TableIndex(name: 'idx_att_records_student', columns: {#studentId})
class LocalAttendanceRecords extends Table {
  IntColumn get id => integer()();
  IntColumn get lessonId => integer()();
  TextColumn get studentId => text()();
  TextColumn get status => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_announcements_group', columns: {#groupId})
@TableIndex(name: 'idx_announcements_cancel', columns: {#groupId, #isCancel, #cancelDate})
class LocalAnnouncements extends Table {
  IntColumn get id => integer()();
  TextColumn get groupId => text()();
  TextColumn get authorId => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  BoolColumn get isCancel => boolean().withDefault(const Constant(false))();
  TextColumn get cancelDate => text().nullable()();
  TextColumn get cancelKey => text().nullable()();
  TextColumn get expiresAt => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get authorName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_notifications_user', columns: {#userId})
@TableIndex(name: 'idx_notifications_unread', columns: {#userId, #isRead})
class LocalNotifications extends Table {
  IntColumn get id => integer()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get data => text().withDefault(const Constant('{}'))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_invitations_email', columns: {#recipientEmail, #status})
class LocalInvitations extends Table {
  IntColumn get id => integer()();
  TextColumn get groupId => text()();
  TextColumn get senderId => text()();
  TextColumn get recipientEmail => text()();
  TextColumn get role => text()();
  TextColumn get status => text()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get senderName => text().nullable()();
  TextColumn get groupName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────────────────────
// БАЗА ДАННЫХ
// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [LocalProfiles, LocalGroups, LocalGroupMembers, LocalStudents, LocalSchedule, LocalAttendanceLessons, LocalAttendanceRecords, LocalAnnouncements, LocalNotifications, LocalInvitations])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2: создаём все индексы
      if (from < 2) {
        await m.createAll();
      }
    },
  );

  // ── Profiles ──────────────────────────────────────────────────────────────

  Future<LocalProfile?> getProfile(String id) => (select(localProfiles)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertProfile(LocalProfilesCompanion data) => into(localProfiles).insertOnConflictUpdate(data);

  /// Batch-вставка профилей — один SQLite statement вместо N
  Future<void> upsertProfiles(List<LocalProfilesCompanion> items) async {
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localProfiles, items);
    });
  }

  // ── Groups ────────────────────────────────────────────────────────────────

  Future<LocalGroup?> getGroup(String id) => (select(localGroups)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertGroup(LocalGroupsCompanion data) => into(localGroups).insertOnConflictUpdate(data);

  // ── Group Members ─────────────────────────────────────────────────────────

  Future<List<LocalGroupMember>> getMembersForGroup(String groupId) => (select(localGroupMembers)..where((t) => t.groupId.equals(groupId))).get();

  Future<LocalGroupMember?> getMembership(String groupId, String userId) => (select(localGroupMembers)..where((t) => t.groupId.equals(groupId) & t.userId.equals(userId))).getSingleOrNull();

  Future<void> clearGroupMembers(String groupId) => (delete(localGroupMembers)..where((t) => t.groupId.equals(groupId))).go();

  Future<void> upsertGroupMembers(List<LocalGroupMembersCompanion> items) async {
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localGroupMembers, items);
    });
  }

  // ── Students ──────────────────────────────────────────────────────────────

  Future<List<LocalStudent>> getStudentsForGroup(String groupId) =>
      (select(localStudents)
            ..where((t) => t.groupId.equals(groupId) & t.status.isNotValue('inactive'))
            ..orderBy([(t) => OrderingTerm(expression: t.lastName)]))
          .get();

  Future<void> clearStudents(String groupId) => (delete(localStudents)..where((t) => t.groupId.equals(groupId))).go();

  Future<void> deleteStudent(String studentId) => (delete(localStudents)..where((t) => t.id.equals(studentId))).go();

  Future<void> upsertStudents(List<LocalStudentsCompanion> items) async {
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localStudents, items);
    });
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  Future<List<LocalScheduleData>> getLessonsForDay(String groupId, int dayIndex) =>
      (select(localSchedule)
            ..where((t) => t.groupId.equals(groupId) & t.dayIndex.equals(dayIndex))
            ..orderBy([(t) => OrderingTerm(expression: t.timeStart)]))
          .get();

  Future<List<LocalScheduleData>> getAllLessons(String groupId) =>
      (select(localSchedule)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm(expression: t.dayIndex), (t) => OrderingTerm(expression: t.timeStart)]))
          .get();

  Future<void> clearSchedule(String groupId) => (delete(localSchedule)..where((t) => t.groupId.equals(groupId))).go();

  Future<void> deleteLesson(int lessonId) => (delete(localSchedule)..where((t) => t.id.equals(lessonId))).go();

  Future<void> upsertLesson(LocalScheduleCompanion data) => into(localSchedule).insertOnConflictUpdate(data);

  Future<void> upsertLessons(List<LocalScheduleCompanion> items) async {
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localSchedule, items);
    });
  }

  // ── Attendance Lessons ────────────────────────────────────────────────────

  Future<List<LocalAttendanceLesson>> getAttendanceLessons(String groupId) =>
      (select(localAttendanceLessons)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
          .get();

  Future<LocalAttendanceLesson?> getAttendanceLesson(String groupId, String date, String lessonKey) => (select(localAttendanceLessons)..where((t) => t.groupId.equals(groupId) & t.date.equals(date) & t.lessonKey.equals(lessonKey))).getSingleOrNull();

  Future<void> clearAttendanceLessons(String groupId) => (delete(localAttendanceLessons)..where((t) => t.groupId.equals(groupId))).go();

  Future<void> upsertAttendanceLessons(List<LocalAttendanceLessonsCompanion> items) async {
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localAttendanceLessons, items);
    });
  }

  Future<void> upsertAttendanceLesson(LocalAttendanceLessonsCompanion data) => into(localAttendanceLessons).insertOnConflictUpdate(data);

  // ── Attendance Records ────────────────────────────────────────────────────

  Future<List<LocalAttendanceRecord>> getRecordsForLesson(int lessonId) => (select(localAttendanceRecords)..where((t) => t.lessonId.equals(lessonId))).get();

  /// Получить все записи для списка уроков одним запросом (нет N+1)
  Future<Map<int, List<LocalAttendanceRecord>>> getRecordsForLessons(List<int> lessonIds) async {
    if (lessonIds.isEmpty) return {};
    final rows = await (select(localAttendanceRecords)..where((t) => t.lessonId.isIn(lessonIds))).get();
    final map = <int, List<LocalAttendanceRecord>>{};
    for (final r in rows) {
      map.putIfAbsent(r.lessonId, () => []).add(r);
    }
    return map;
  }

  Future<void> upsertAttendanceRecord(LocalAttendanceRecordsCompanion data) => into(localAttendanceRecords).insertOnConflictUpdate(data);

  Future<void> upsertAttendanceRecords(List<LocalAttendanceRecordsCompanion> items) async {
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localAttendanceRecords, items);
    });
  }

  Future<void> clearAttendanceRecordsForGroup(String groupId) async {
    final ids = await (select(localAttendanceLessons)..where((t) => t.groupId.equals(groupId))).map((r) => r.id).get();
    if (ids.isEmpty) return;
    await (delete(localAttendanceRecords)..where((t) => t.lessonId.isIn(ids))).go();
  }

  // ── Announcements ─────────────────────────────────────────────────────────

  Future<List<LocalAnnouncement>> getAnnouncements(String groupId) =>
      (select(localAnnouncements)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
          .get();

  Future<void> clearAnnouncements(String groupId) => (delete(localAnnouncements)..where((t) => t.groupId.equals(groupId))).go();

  Future<void> upsertAnnouncements(List<LocalAnnouncementsCompanion> items) async {
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localAnnouncements, items);
    });
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<LocalNotification>> getNotifications(String userId) =>
      (select(localNotifications)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
            ..limit(50))
          .get();

  /// COUNT(*) вместо загрузки всех строк в память
  Future<int> getUnreadCount(String userId) async {
    final countExpr = localNotifications.id.count();
    final query = selectOnly(localNotifications)
      ..addColumns([countExpr])
      ..where(localNotifications.userId.equals(userId) & localNotifications.isRead.equals(false));
    final result = await query.getSingle();
    return result.read(countExpr) ?? 0;
  }

  Future<void> clearNotifications(String userId) => (delete(localNotifications)..where((t) => t.userId.equals(userId))).go();

  Future<void> upsertNotifications(List<LocalNotificationsCompanion> items) async {
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localNotifications, items);
    });
  }

  Future<void> markNotificationRead(int id) => (update(localNotifications)..where((t) => t.id.equals(id))).write(const LocalNotificationsCompanion(isRead: Value(true)));

  Future<void> markAllNotificationsRead(String userId) => (update(localNotifications)..where((t) => t.userId.equals(userId) & t.isRead.equals(false))).write(const LocalNotificationsCompanion(isRead: Value(true)));

  Future<void> deleteNotification(int id) => (delete(localNotifications)..where((t) => t.id.equals(id))).go();

  // ── Invitations ───────────────────────────────────────────────────────────

  Future<List<LocalInvitation>> getPendingInvitations(String email) =>
      (select(localInvitations)
            ..where((t) => t.recipientEmail.equals(email) & t.status.equals('pending'))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
          .get();

  Future<void> clearInvitations(String email) => (delete(localInvitations)..where((t) => t.recipientEmail.equals(email))).go();

  Future<void> upsertInvitations(List<LocalInvitationsCompanion> items) async {
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localInvitations, items);
    });
  }

  // ── Полная очистка в одной транзакции ────────────────────────────────────

  Future<void> clearAll() => transaction(() async {
    await delete(localAttendanceRecords).go();
    await delete(localAttendanceLessons).go();
    await delete(localStudents).go();
    await delete(localSchedule).go();
    await delete(localAnnouncements).go();
    await delete(localNotifications).go();
    await delete(localInvitations).go();
    await delete(localGroupMembers).go();
    await delete(localGroups).go();
    await delete(localProfiles).go();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ПОДКЛЮЧЕНИЕ
// ─────────────────────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_local.db'));
    return NativeDatabase.createInBackground(
      file,
      // WAL mode — быстрее для конкурентных read/write
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL');
        db.execute('PRAGMA synchronous=NORMAL');
        db.execute('PRAGMA foreign_keys=ON');
        db.execute('PRAGMA cache_size=-4000'); // 4MB кэш
      },
    );
  });
}
