import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';
import 'group_service.dart';

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

  static Future<List<Lesson>> getTodayLessons() async {
    return getLessonsForDay(DateTime.now().weekday - 1);
  }

  static Future<List<Lesson>> getLessonsForDay(int dayIndex) async {
    if (dayIndex < 0 || dayIndex > 4) return [];
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return [];
    try {
      final rows = await _db.from('schedule').select().eq('group_id', gid).eq('day_index', dayIndex).order('time_start', ascending: true);
      return (rows as List).map((r) => Lesson.fromRow(r)).toList();
    } catch (e) {
      developer.log('[ScheduleService] getLessonsForDay error: $e');
      return [];
    }
  }

  static Future<List<List<Lesson>>> getAllDays() async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return List.generate(5, (_) => <Lesson>[]);
    try {
      final rows = await _db.from('schedule').select().eq('group_id', gid).order('day_index', ascending: true).order('time_start', ascending: true);
      final result = List.generate(5, (_) => <Lesson>[]);
      for (final r in rows as List) {
        final lesson = Lesson.fromRow(r);
        if (lesson.dayIndex >= 0 && lesson.dayIndex < 5) result[lesson.dayIndex].add(lesson);
      }
      return result;
    } catch (e) {
      developer.log('[ScheduleService] getAllDays error: $e');
      return List.generate(5, (_) => <Lesson>[]);
    }
  }

  static Future<void> addLesson({required int dayIndex, required Lesson lesson}) async {
    final gid = await GroupService.getCurrentGroupId();
    final uid = AuthService.currentUserId;
    if (gid == null || uid == null) return;
    try {
      await _db.from('schedule').insert({'user_id': uid, 'group_id': gid, 'day_index': dayIndex, 'time_start': lesson.timeStart, 'time_end': lesson.timeEnd, 'subject': lesson.subject, 'room': lesson.room, 'teacher': lesson.teacher});
    } catch (e) {
      developer.log('[ScheduleService] addLesson error: $e');
    }
  }

  static Future<void> updateLesson({required int dayIndex, required int lessonIndex, required Lesson lesson}) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return;
    try {
      if (lesson.id != null) {
        await _db.from('schedule').update({'time_start': lesson.timeStart, 'time_end': lesson.timeEnd, 'subject': lesson.subject, 'room': lesson.room, 'teacher': lesson.teacher}).eq('id', lesson.id!);
      } else {
        final rows = await _db.from('schedule').select().eq('group_id', gid).eq('day_index', dayIndex).order('time_start', ascending: true);
        final list = rows as List;
        if (lessonIndex < list.length) {
          final targetId = list[lessonIndex]['id'] as int;
          await _db.from('schedule').update({'time_start': lesson.timeStart, 'time_end': lesson.timeEnd, 'subject': lesson.subject, 'room': lesson.room, 'teacher': lesson.teacher}).eq('id', targetId);
        }
      }
    } catch (e) {
      developer.log('[ScheduleService] updateLesson error: $e');
    }
  }

  static Future<void> deleteLesson({required int dayIndex, required Lesson lesson}) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return;
    try {
      if (lesson.id != null) {
        await _db.from('schedule').delete().eq('id', lesson.id!);
      } else {
        await _db.from('schedule').delete().eq('group_id', gid).eq('day_index', dayIndex).eq('time_start', lesson.timeStart).eq('time_end', lesson.timeEnd).eq('subject', lesson.subject);
      }
    } catch (e) {
      developer.log('[ScheduleService] deleteLesson error: $e');
    }
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
