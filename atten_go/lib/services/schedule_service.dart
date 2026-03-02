import 'db_service.dart';

// ─── Модель занятия ───────────────────────────────────────────────────────────

class Lesson {
  final int? id;
  final int dayIndex;
  final String timeStart;
  final String timeEnd;
  final String subject;
  final String room;
  final String teacher;

  const Lesson({this.id, required this.dayIndex, required this.timeStart, required this.timeEnd, required this.subject, required this.room, required this.teacher});

  factory Lesson.fromRow(Map<String, dynamic> row) => Lesson(id: row['id'] as int?, dayIndex: row['day_index'] as int, timeStart: row['time_start'] as String, timeEnd: row['time_end'] as String, subject: row['subject'] as String, room: row['room'] as String, teacher: row['teacher'] as String);
}

// ─── Сервис расписания ────────────────────────────────────────────────────────

class ScheduleService {
  static final _db = DatabaseService.client;

  /// Занятия на сегодня (пн=0 ... пт=4; выходные → [])
  static Future<List<Lesson>> getTodayLessons() async {
    return getLessonsForDay(DateTime.now().weekday - 1);
  }

  /// Занятия для конкретного дня (0–4)
  static Future<List<Lesson>> getLessonsForDay(int dayIndex) async {
    if (dayIndex < 0 || dayIndex > 4) return [];
    final rows = await _db.from('schedule').select().eq('day_index', dayIndex).order('time_start', ascending: true);
    return (rows as List).map((r) => Lesson.fromRow(r)).toList();
  }

  /// Всё расписание: список из 5 дней [пн, вт, ср, чт, пт]
  static Future<List<List<Lesson>>> getAllDays() async {
    final rows = await _db.from('schedule').select().order('day_index', ascending: true).order('time_start', ascending: true);

    final result = List.generate(5, (_) => <Lesson>[]);
    for (final r in rows as List) {
      final lesson = Lesson.fromRow(r);
      if (lesson.dayIndex >= 0 && lesson.dayIndex < 5) {
        result[lesson.dayIndex].add(lesson);
      }
    }
    return result;
  }
}

// ─── Статус занятия ───────────────────────────────────────────────────────────

enum LessonStatus { active, upcoming, past }

LessonStatus getLessonStatus(String timeStart, String timeEnd) {
  final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
  final startMin = _parseTimeToMin(timeStart);
  final endMin = _parseTimeToMin(timeEnd);

  if (nowMin >= startMin && nowMin <= endMin) return LessonStatus.active;
  if (nowMin < startMin) return LessonStatus.upcoming;
  return LessonStatus.past;
}

int _parseTimeToMin(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}
