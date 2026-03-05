import 'dart:developer' as developer;
import 'db_service.dart';
import 'student_service.dart';
import 'auth_service.dart';
import 'group_service.dart';

// ─── Модели ───────────────────────────────────────────────────────────────────

class StudentAttendance {
  final int? recordId;
  final String studentId;
  final String lastName;
  final String firstName;
  final bool isMale;
  String? status;

  StudentAttendance({this.recordId, required this.studentId, required this.lastName, required this.firstName, required this.isMale, this.status});

  factory StudentAttendance.fromFlatRow(Map<String, dynamic> row, List<Student> allStudents) {
    final studentId = row['student_id'] as String;
    Student? full;
    try { full = allStudents.firstWhere((s) => s.id == studentId); } catch (_) {}
    return StudentAttendance(
      recordId: row['id'] as int?,
      studentId: studentId,
      lastName: full?.lastName ?? '',
      firstName: full?.firstName ?? '',
      isMale: full?.isMale ?? true,
      status: row['status'] as String?,
    );
  }

  factory StudentAttendance.fromStudent(Student s) => StudentAttendance(
        studentId: s.id, lastName: s.lastName, firstName: s.firstName, isMale: s.isMale,
      );
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
  static final _db = DatabaseService.client;
  static List<Student>? _studentsCache;

  static Future<List<Student>> _getStudents() async {
    _studentsCache ??= await StudentService.loadAll();
    return _studentsCache!;
  }

  static void invalidateCache() {
    _studentsCache = null;
    GroupService.invalidateCache();
  }

  static Future<List<LessonAttendance>> loadAll() async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return [];
    try {
      final lessons = await _db
          .from('attendance_lessons')
          .select()
          .eq('group_id', gid)
          .order('date', ascending: false);

      final allStudents = await _getStudents();
      final result = <LessonAttendance>[];

      for (final lesson in lessons as List) {
        final lessonId = lesson['id'] as int;
        final records = await _db.from('attendance_records').select().eq('lesson_id', lessonId);
        result.add(LessonAttendance(
          id: lessonId,
          date: lesson['date'] as String,
          lessonKey: lesson['lesson_key'] as String,
          subject: lesson['subject'] as String,
          students: (records as List).map((r) => StudentAttendance.fromFlatRow(r, allStudents)).toList(),
        ));
      }
      return result;
    } catch (e) {
      developer.log('[AttendanceService] loadAll error: $e');
      return [];
    }
  }

  static Future<List<StudentAttendance>> loadStudentsOnly() async {
    final students = await StudentService.loadAll();
    return students.map((s) => StudentAttendance.fromStudent(s)).toList();
  }

  static Future<LessonAttendance> getOrCreateLesson({
    required String date,
    required String lessonKey,
    required String subject,
  }) async {
    final allStudents = await _getStudents();
    final gid = await GroupService.getCurrentGroupId();
    final uid = AuthService.currentUserId;

    if (gid == null || uid == null) {
      return LessonAttendance(date: date, lessonKey: lessonKey, subject: subject, students: allStudents.map((s) => StudentAttendance.fromStudent(s)).toList());
    }

    try {
      final existing = await _db
          .from('attendance_lessons')
          .select()
          .eq('group_id', gid)
          .eq('date', date)
          .eq('lesson_key', lessonKey)
          .limit(1);

      if ((existing as List).isNotEmpty) {
        final lessonId = existing.first['id'] as int;
        final records = await _db.from('attendance_records').select().eq('lesson_id', lessonId);
        final recordList = records as List;

        if (recordList.isEmpty && allStudents.isNotEmpty) {
          await _insertStudentRecords(lessonId, allStudents);
          return LessonAttendance(id: lessonId, date: date, lessonKey: lessonKey, subject: existing.first['subject'] as String,
            students: allStudents.map((s) => StudentAttendance.fromStudent(s)).toList());
        }

        return LessonAttendance(id: lessonId, date: date, lessonKey: lessonKey, subject: existing.first['subject'] as String,
          students: recordList.map((r) => StudentAttendance.fromFlatRow(r, allStudents)).toList());
      }
    } catch (e) {
      developer.log('[AttendanceService] getOrCreateLesson lookup error: $e');
    }

    try {
      final inserted = await _db.from('attendance_lessons').insert({
        'user_id': uid,
        'group_id': gid,
        'date': date,
        'lesson_key': lessonKey,
        'subject': subject,
      }).select().single();

      final lessonId = inserted['id'] as int;
      await _insertStudentRecords(lessonId, allStudents);

      return LessonAttendance(id: lessonId, date: date, lessonKey: lessonKey, subject: subject,
        students: allStudents.map((s) => StudentAttendance.fromStudent(s)).toList());
    } catch (e) {
      developer.log('[AttendanceService] getOrCreateLesson create error: $e');
      return LessonAttendance(date: date, lessonKey: lessonKey, subject: subject,
        students: allStudents.map((s) => StudentAttendance.fromStudent(s)).toList());
    }
  }

  static Future<void> _insertStudentRecords(int lessonId, List<Student> students) async {
    if (students.isEmpty) return;
    try {
      final records = students.map((s) => {'lesson_id': lessonId, 'student_id': s.id, 'status': null}).toList();
      await _db.from('attendance_records').insert(records);
    } catch (e) {
      developer.log('[AttendanceService] _insertStudentRecords error: $e');
    }
  }

  static Future<void> saveLesson(LessonAttendance lesson) async {
    if (lesson.id == null) return;
    for (final student in lesson.students) {
      try {
        if (student.recordId != null) {
          await _db.from('attendance_records').update({'status': student.status}).eq('id', student.recordId!);
        } else {
          await _db.from('attendance_records').update({'status': student.status}).eq('lesson_id', lesson.id!).eq('student_id', student.studentId);
        }
      } catch (e) {
        developer.log('[AttendanceService] saveLesson error for ${student.studentId}: $e');
      }
    }
  }

  static Future<LessonAttendance?> getCurrentLessonStats({required String date, required String lessonKey}) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return null;
    try {
      final rows = await _db.from('attendance_lessons').select().eq('group_id', gid).eq('date', date).eq('lesson_key', lessonKey).limit(1);
      if ((rows as List).isEmpty) return null;

      final lessonId = rows.first['id'] as int;
      final records = await _db.from('attendance_records').select().eq('lesson_id', lessonId);
      final allStudents = await _getStudents();
      final students = (records as List).map((r) => StudentAttendance.fromFlatRow(r, allStudents)).toList();

      if (students.every((s) => s.status == null)) return null;

      return LessonAttendance(id: lessonId, date: rows.first['date'] as String, lessonKey: lessonKey, subject: rows.first['subject'] as String, students: students);
    } catch (e) {
      developer.log('[AttendanceService] getCurrentLessonStats error: $e');
      return null;
    }
  }

  static String lessonKey(String timeStart, String timeEnd) => '$timeStart-$timeEnd';

  static String todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static bool get isWeekend {
    final wd = DateTime.now().weekday;
    return wd == DateTime.saturday || wd == DateTime.sunday;
  }
}
