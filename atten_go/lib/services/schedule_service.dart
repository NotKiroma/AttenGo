// lib/services/schedule_service.dart
//
// Читает из LocalDatabase, пишет в Supabase → синхронизирует локально.

import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';
import 'group_service.dart';
import '../local/sync_service.dart';

// ─── Модель занятия ───────────────────────────────────────────────────────────

class Lesson {
  final int? id;
  final int dayIndex;
  final String timeStart;
  final String timeEnd;
  final String subject;
  final String room;
  final String teacher;

  const Lesson({
    this.id,
    required this.dayIndex,
    required this.timeStart,
    required this.timeEnd,
    required this.subject,
    required this.room,
    required this.teacher,
  });

  factory Lesson.fromRow(Map<String, dynamic> row) => Lesson(
        id: row['id'] as int?,
        dayIndex: row['day_index'] as int,
        timeStart: row['time_start'] as String,
        timeEnd: row['time_end'] as String,
        subject: row['subject'] as String,
        room: row['room'] as String,
        teacher: row['teacher'] as String,
      );
}

// ─── Сервис расписания ────────────────────────────────────────────────────────

class ScheduleService {
  static final _supa = DatabaseService.client;
  static final _local = SyncService.db;

  // ── ЧТЕНИЕ ИЗ ЛОКАЛЬНОЙ БД ────────────────────────────────────────────────

  static Future<List<Lesson>> getTodayLessons() =>
      getLessonsForDay(DateTime.now().weekday - 1);

  static Future<List<Lesson>> getLessonsForDay(int dayIndex) async {
    if (dayIndex < 0 || dayIndex > 4) return [];
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return [];
    final rows = await _local.getLessonsForDay(gid, dayIndex);
    return rows
        .map((r) => Lesson(
              id: r.id,
              dayIndex: r.dayIndex,
              timeStart: r.timeStart,
              timeEnd: r.timeEnd,
              subject: r.subject,
              room: r.room,
              teacher: r.teacher,
            ))
        .toList();
  }

  static Future<List<List<Lesson>>> getAllDays() async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return List.generate(5, (_) => <Lesson>[]);
    final rows = await _local.getAllLessons(gid);
    final result = List.generate(5, (_) => <Lesson>[]);
    for (final r in rows) {
      if (r.dayIndex >= 0 && r.dayIndex < 5) {
        result[r.dayIndex].add(Lesson(
          id: r.id,
          dayIndex: r.dayIndex,
          timeStart: r.timeStart,
          timeEnd: r.timeEnd,
          subject: r.subject,
          room: r.room,
          teacher: r.teacher,
        ));
      }
    }
    return result;
  }

  // ── ЗАПИСЬ В SUPABASE + СИНХРОНИЗАЦИЯ ─────────────────────────────────────

  static Future<void> addLesson({
    required int dayIndex,
    required Lesson lesson,
  }) async {
    final gid = await GroupService.getCurrentGroupId();
    final uid = AuthService.currentUserId;
    if (gid == null || uid == null) return;
    try {
      await _supa.from('schedule').insert({
        'user_id': uid,
        'group_id': gid,
        'day_index': dayIndex,
        'time_start': lesson.timeStart,
        'time_end': lesson.timeEnd,
        'subject': lesson.subject,
        'room': lesson.room,
        'teacher': lesson.teacher,
      });
      await SyncService.syncSchedule(gid);
    } catch (e) {
      developer.log('[ScheduleService] addLesson error: $e');
    }
  }

  static Future<void> updateLesson({
    required int dayIndex,
    required int lessonIndex,
    required Lesson lesson,
  }) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return;
    try {
      if (lesson.id != null) {
        await _supa.from('schedule').update({
          'time_start': lesson.timeStart,
          'time_end': lesson.timeEnd,
          'subject': lesson.subject,
          'room': lesson.room,
          'teacher': lesson.teacher,
        }).eq('id', lesson.id!);
      } else {
        final rows = await _local.getLessonsForDay(gid, dayIndex);
        if (lessonIndex < rows.length) {
          final targetId = rows[lessonIndex].id;
          await _supa.from('schedule').update({
            'time_start': lesson.timeStart,
            'time_end': lesson.timeEnd,
            'subject': lesson.subject,
            'room': lesson.room,
            'teacher': lesson.teacher,
          }).eq('id', targetId);
        }
      }
      await SyncService.syncSchedule(gid);
    } catch (e) {
      developer.log('[ScheduleService] updateLesson error: $e');
    }
  }

  static Future<void> deleteLesson({
    required int dayIndex,
    required Lesson lesson,
  }) async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return;
    try {
      if (lesson.id != null) {
        await _supa.from('schedule').delete().eq('id', lesson.id!);
        await _local.deleteLesson(lesson.id!);
      } else {
        await _supa
            .from('schedule')
            .delete()
            .eq('group_id', gid)
            .eq('day_index', dayIndex)
            .eq('time_start', lesson.timeStart)
            .eq('time_end', lesson.timeEnd)
            .eq('subject', lesson.subject);
        await SyncService.syncSchedule(gid);
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
