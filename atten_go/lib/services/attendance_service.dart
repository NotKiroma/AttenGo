// lib/services/attendance_service.dart
//
// Оптимизации vs v1:
//  • loadAll() — один запрос к SQLite для всех записей (нет N+1)
//  • getCurrentLessonStats() — аналогично через getRecordsForLesson
//  • saveLesson() — parallel Future.wait остался, всё пишется в Supabase
//  • _insertStudentRecords — batch insert вместо одиночного

import 'dart:developer' as developer;
import 'db_service.dart';
import 'student_service.dart';
import 'auth_service.dart';
import 'group_service.dart';
import '../local/sync_service.dart';

// ─── Модели ───────────────────────────────────────────────────────────────────

class StudentAttendance {
  final int? recordId;
  final String studentId;
  final String lastName;
  final String firstName;
  final bool isMale;
  final String? avatarUrl;
  String? status;

  StudentAttendance({this.recordId, required this.studentId, required this.lastName, required this.firstName, required this.isMale, this.avatarUrl, this.status});

  factory StudentAttendance.fromStudent(Student s) => StudentAttendance(studentId: s.id, lastName: s.lastName, firstName: s.firstName, isMale: s.isMale, avatarUrl: s.avatarUrl);
}

class LessonAttendance {
  final int? id;
  final String date;
  final String lessonKey;
  final String subject;
  final List<StudentAttendance> students;

  LessonAttendance({this.id, required this.date, required this.lessonKey, required this.subject, required this.students});

  int get presentCount => students.where((s) => s.status == 'present').length;
  int get absentCount => students.where((s) => s.status == 'absent').length;
  int get lateCount => students.where((s) => s.status == 'late').length;
  int get totalCount => students.length;
  int get markedCount => students.where((s) => s.status != null).length;

  String get percentage {
    if (markedCount == 0) return '—';
    return '${((presentCount / totalCount) * 100).round()}%';
  }
}

// ─── Сервис ───────────────────────────────────────────────────────────────────

class AttendanceService {
  static final _supa = DatabaseService.client;
  static final _local = SyncService.db;
  static List<Student>? _studentsCache;

  // ── УТИЛИТЫ ───────────────────────────────────────────────────────────────

  static String lessonKey(String timeStart, String timeEnd) => '$timeStart-$timeEnd';

  static String todayDate() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static bool get isWeekend {
    final wd = DateTime.now().weekday;
    return wd == DateTime.saturday || wd == DateTime.sunday;
  }

  // ── КЭШ ───────────────────────────────────────────────────────────────────

  static Future<List<Student>> _getStudents() async {
    _studentsCache ??= await StudentService.loadAll();
    return _studentsCache!;
  }

  static void invalidateCache() {
    _studentsCache = null;
    GroupService.invalidateCache();
  }

  // ── ЧТЕНИЕ — нет N+1 ──────────────────────────────────────────────────────

  /// Загружает все уроки: один запрос к lessons + один запрос ко всем records.
  static Future<List<LessonAttendance>> loadAll() async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return [];

    final localLessons = await _local.getAttendanceLessons(gid);
    if (localLessons.isEmpty) return [];

    final allStudents = await _getStudents();
    final studentMap = {for (final s in allStudents) s.id: s};

    // Один запрос для всех records сразу — нет цикла с getRecordsForLesson
    final lessonIds = localLessons.map((l) => l.id).toList();
    final recordsMap = await _local.getRecordsForLessons(lessonIds);

    return localLessons.map((lesson) {
      final records = recordsMap[lesson.id] ?? [];
      return LessonAttendance(
        id: lesson.id,
        date: lesson.date,
        lessonKey: lesson.lessonKey,
        subject: lesson.subject,
        students: records.where((r) => studentMap.containsKey(r.studentId)).map((r) {
          final s = studentMap[r.studentId]!;
          return StudentAttendance(recordId: r.id, studentId: r.studentId, lastName: s.lastName, firstName: s.firstName, isMale: s.isMale, avatarUrl: s.avatarUrl, status: r.status);
        }).toList(),
      );
    }).toList();
  }

  static Future<List<StudentAttendance>> loadStudentsOnly() async {
    final students = await StudentService.loadAll();
    return students.map((s) => StudentAttendance.fromStudent(s)).toList();
  }

  /// Статистика конкретного урока без создания.
  static Future<LessonAttendance?> getCurrentLessonStats({required String date, required String lessonKey}) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return null;

    final lesson = await _local.getAttendanceLesson(gid, date, lessonKey);
    if (lesson == null) return null;

    final allStudents = await _getStudents();
    final studentMap = {for (final s in allStudents) s.id: s};
    final records = await _local.getRecordsForLesson(lesson.id);

    final students = records.where((r) => studentMap.containsKey(r.studentId)).map((r) {
      final s = studentMap[r.studentId]!;
      return StudentAttendance(recordId: r.id, studentId: r.studentId, lastName: s.lastName, firstName: s.firstName, isMale: s.isMale, avatarUrl: s.avatarUrl, status: r.status);
    }).toList();

    if (students.every((s) => s.status == null)) return null;

    return LessonAttendance(id: lesson.id, date: lesson.date, lessonKey: lesson.lessonKey, subject: lesson.subject, students: students);
  }

  // ── СОЗДАНИЕ / ЗАПИСЬ ─────────────────────────────────────────────────────

  static Future<LessonAttendance> getOrCreateLesson({required String date, required String lessonKey, required String subject}) async {
    final allStudents = await _getStudents();
    final studentMap = {for (final s in allStudents) s.id: s};
    final gid = await GroupService.getCurrentGroupId();
    final uid = AuthService.currentUserId;

    if (gid == null || uid == null) {
      return _emptyLesson(date, lessonKey, subject, allStudents);
    }

    // Пробуем из локальной БД
    final existing = await _local.getAttendanceLesson(gid, date, lessonKey);
    if (existing != null) {
      final records = await _local.getRecordsForLesson(existing.id);

      // Проверяем недостающих студентов
      final existingIds = records.map((r) => r.studentId).toSet();
      final missing = allStudents.where((s) => !existingIds.contains(s.id)).toList();
      if (missing.isNotEmpty) {
        await _insertStudentRecords(existing.id, missing);
        await SyncService.syncAttendance(gid);
        return getOrCreateLesson(date: date, lessonKey: lessonKey, subject: subject);
      }

      return LessonAttendance(
        id: existing.id,
        date: existing.date,
        lessonKey: existing.lessonKey,
        subject: existing.subject,
        students: records.where((r) => studentMap.containsKey(r.studentId)).map((r) {
          final s = studentMap[r.studentId]!;
          return StudentAttendance(recordId: r.id, studentId: r.studentId, lastName: s.lastName, firstName: s.firstName, isMale: s.isMale, avatarUrl: s.avatarUrl, status: r.status);
        }).toList(),
      );
    }

    // Создаём в Supabase → синкаем
    try {
      final inserted = await _supa.from('attendance_lessons').insert({'user_id': uid, 'group_id': gid, 'date': date, 'lesson_key': lessonKey, 'subject': subject}).select('id').single();

      final lessonId = inserted['id'] as int;
      await _insertStudentRecords(lessonId, allStudents);
      await SyncService.syncAttendance(gid);

      return LessonAttendance(id: lessonId, date: date, lessonKey: lessonKey, subject: subject, students: allStudents.map((s) => StudentAttendance.fromStudent(s)).toList());
    } catch (e) {
      developer.log('[AttendanceService] getOrCreateLesson error: $e');
      return _emptyLesson(date, lessonKey, subject, allStudents);
    }
  }

  /// Сохраняет все статусы урока параллельными update'ами.
  // Находим метод saveLesson и заменяем его:

  static Future<void> saveLesson(LessonAttendance lesson) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return;

    try {
      // 1. Оптимистичное обновление локальной БД (чтобы UI не дергался)
      // Мы вызываем метод синка или напрямую пишем в Drift через SyncService.db
      // В данном случае проще всего вызвать syncAttendance СРАЗУ после сетевого запроса,
      // но заблокировать повторный вызов из Realtime.

      final client = DatabaseService.client;

      // 2. Отправка в Supabase
      if (lesson.id == null) {
        final inserted = await client.from('attendance_lessons').insert({'group_id': gid, 'date': lesson.date, 'lesson_key': lesson.lessonKey, 'subject': lesson.subject}).select().single();

        final newId = inserted['id'] as int;
        await _insertStudentRecords(newId, lesson.students.map((s) => Student(id: s.studentId, lastName: s.lastName, firstName: s.firstName, isMale: s.isMale)).toList());
      }

      // Обновляем статусы студентов
      final futures = lesson.students.where((s) => s.recordId != null).map((s) => client.from('attendance_records').update({'status': s.status}).eq('id', s.recordId!));

      await Future.wait(futures);

      // 3. Принудительный синк локальной БД сразу после сохранения
      await SyncService.syncAttendance(gid);
    } catch (e) {
      developer.log('[AttendanceService] saveLesson error: $e');
      // ЕСЛИ ОШИБКА: принудительно затираем ошибочные локальные данные
      // правдой из облака, чтобы UI вернулся в реальное состояние
      await SyncService.syncAttendance(gid);
      // Пробрасываем ошибку дальше, чтобы экран мог показать SnackBar
      throw Exception('Не удалось сохранить данные: $e');
    }
  }

  static Future<void> saveRecord({required int lessonId, required String studentId, required String? status, int? recordId}) async {
    final gid = await GroupService.getCurrentGroupId();
    try {
      if (recordId != null) {
        if (status != null) {
          await _supa.from('attendance_records').update({'status': status}).eq('id', recordId);
        } else {
          await _supa.from('attendance_records').delete().eq('id', recordId);
        }
      } else if (status != null) {
        await _supa.from('attendance_records').insert({'lesson_id': lessonId, 'student_id': studentId, 'status': status});
      }
      if (gid != null) await SyncService.syncAttendance(gid);
    } catch (e) {
      developer.log('[AttendanceService] saveRecord error: $e');
    }
  }

  static Future<void> copyFromPreviousLesson({required int targetLessonId, required String date, required String lessonKey}) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return;
    try {
      await _supa.rpc('copy_previous_lesson_attendance', params: {'p_lesson_id': targetLessonId, 'p_group_id': gid, 'p_date': date, 'p_lesson_key': lessonKey});
      await SyncService.syncAttendance(gid);
    } catch (e) {
      developer.log('[AttendanceService] copyFromPreviousLesson error: $e');
    }
  }

  // ── ВСПОМОГАТЕЛЬНЫЕ ───────────────────────────────────────────────────────

  static LessonAttendance _emptyLesson(String date, String lessonKey, String subject, List<Student> students) => LessonAttendance(date: date, lessonKey: lessonKey, subject: subject, students: students.map((s) => StudentAttendance.fromStudent(s)).toList());

  /// Batch insert записей посещаемости
  static Future<void> _insertStudentRecords(int lessonId, List<Student> students) async {
    if (students.isEmpty) return;
    try {
      await _supa.from('attendance_records').insert(students.map((s) => {'lesson_id': lessonId, 'student_id': s.id, 'status': null}).toList());
    } catch (e) {
      developer.log('[AttendanceService] _insertStudentRecords error: $e');
    }
  }
}
