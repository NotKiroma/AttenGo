import 'db_service.dart';
import 'student_service.dart';

// ─── Модели ───────────────────────────────────────────────────────────────────

class StudentAttendance {
  final String lastName;
  final String firstName;
  final bool isMale;
  String? status; // 'present' | 'absent' | 'late' | null

  StudentAttendance({
    required this.lastName,
    required this.firstName,
    required this.isMale,
    this.status,
  });

  factory StudentAttendance.fromRow(Map<String, dynamic> row) =>
      StudentAttendance(
        lastName:  row['last_name'] as String,
        firstName: row['first_name'] as String,
        isMale:    row['is_male'] as bool,
        status:    row['status'] as String?,
      );
}

class LessonAttendance {
  final int? id;
  final String date;
  final String lessonKey;
  final String subject;
  final List<StudentAttendance> students;

  LessonAttendance({
    this.id,
    required this.date,
    required this.lessonKey,
    required this.subject,
    required this.students,
  });

  int get presentCount => students.where((s) => s.status == 'present').length;
  int get absentCount  => students.where((s) => s.status == 'absent').length;
  int get lateCount    => students.where((s) => s.status == 'late').length;
  int get totalCount   => students.length;
  int get markedCount  => students.where((s) => s.status != null).length;

  String get percentage {
    if (markedCount == 0) return '—';
    return '${((presentCount / totalCount) * 100).round()}%';
  }
}

// ─── Сервис ───────────────────────────────────────────────────────────────────

class AttendanceService {
  static final _db = DatabaseService.client;

  // ── Загрузить все записи посещаемости ──────────────────────────────────────

  static Future<List<LessonAttendance>> loadAll() async {
    final lessons = await _db
        .from('attendance_lessons')
        .select()
        .order('date', ascending: false);

    final result = <LessonAttendance>[];
    for (final lesson in lessons as List) {
      final lessonId = lesson['id'] as int;
      final records  = await _db
          .from('attendance_records')
          .select()
          .eq('lesson_id', lessonId);

      result.add(LessonAttendance(
        id:        lessonId,
        date:      lesson['date'] as String,
        lessonKey: lesson['lesson_key'] as String,
        subject:   lesson['subject'] as String,
        students:  (records as List).map((r) => StudentAttendance.fromRow(r)).toList(),
      ));
    }
    return result;
  }

  /// Загрузить только список студентов (без статусов) — для выходного дня
  static Future<List<StudentAttendance>> loadStudentsOnly() async {
    final students = await StudentService.loadAll();
    return students
        .map((s) => StudentAttendance(
              lastName:  s.lastName,
              firstName: s.firstName,
              isMale:    s.isMale,
            ))
        .toList();
  }

  // ── Получить или создать занятие ───────────────────────────────────────────

  static Future<LessonAttendance> getOrCreateLesson({
    required String date,
    required String lessonKey,
    required String subject,
  }) async {
    // Проверяем существующую запись
    final existing = await _db
        .from('attendance_lessons')
        .select()
        .eq('date', date)
        .eq('lesson_key', lessonKey)
        .limit(1);

    if ((existing as List).isNotEmpty) {
      final lessonId = existing.first['id'] as int;
      final records  = await _db
          .from('attendance_records')
          .select()
          .eq('lesson_id', lessonId);

      return LessonAttendance(
        id:        lessonId,
        date:      date,
        lessonKey: lessonKey,
        subject:   subject,
        students:  (records as List).map((r) => StudentAttendance.fromRow(r)).toList(),
      );
    }

    // Создаём новое занятие
    final inserted = await _db
        .from('attendance_lessons')
        .insert({'date': date, 'lesson_key': lessonKey, 'subject': subject})
        .select()
        .single();

    final lessonId = inserted['id'] as int;

    // Создаём записи для всех студентов
    final students = await StudentService.loadAll();
    final records  = students.map((s) => {
      'lesson_id':  lessonId,
      'last_name':  s.lastName,
      'first_name': s.firstName,
      'is_male':    s.isMale,
      'status':     null,
    }).toList();

    await _db.from('attendance_records').insert(records);

    final savedRecords = await _db
        .from('attendance_records')
        .select()
        .eq('lesson_id', lessonId);

    return LessonAttendance(
      id:        lessonId,
      date:      date,
      lessonKey: lessonKey,
      subject:   subject,
      students:  (savedRecords as List).map((r) => StudentAttendance.fromRow(r)).toList(),
    );
  }

  // ── Сохранить статус одного студента ───────────────────────────────────────

  static Future<void> saveLesson(LessonAttendance lesson) async {
    if (lesson.id == null) return;

    for (final student in lesson.students) {
      await _db
          .from('attendance_records')
          .update({'status': student.status})
          .eq('lesson_id', lesson.id!)
          .eq('last_name', student.lastName)
          .eq('first_name', student.firstName);
    }
  }

  // ── Статистика текущей пары (для HomeScreen) ────────────────────────────────

  static Future<LessonAttendance?> getCurrentLessonStats({
    required String date,
    required String lessonKey,
  }) async {
    final rows = await _db
        .from('attendance_lessons')
        .select()
        .eq('date', date)
        .eq('lesson_key', lessonKey)
        .limit(1);

    if ((rows as List).isEmpty) return null;

    final lessonId = rows.first['id'] as int;
    final records  = await _db
        .from('attendance_records')
        .select()
        .eq('lesson_id', lessonId);

    final students = (records as List).map((r) => StudentAttendance.fromRow(r)).toList();
    if (students.every((s) => s.status == null)) return null;

    return LessonAttendance(
      id:        lessonId,
      date:      rows.first['date'] as String,
      lessonKey: lessonKey,
      subject:   rows.first['subject'] as String,
      students:  students,
    );
  }

  // ── Вспомогательные методы ─────────────────────────────────────────────────

  static String lessonKey(String timeStart, String timeEnd) =>
      '$timeStart-$timeEnd';

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
}
