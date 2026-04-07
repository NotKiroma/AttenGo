// lib/services/student_service.dart
//
// Читает из LocalDatabase, пишет в Supabase → синхронизирует локально.

import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';
import 'group_service.dart';
import '../local/sync_service.dart';

// ─── Модель студента ──────────────────────────────────────────────────────────

class Student {
  final String id;
  final String lastName;
  final String firstName;
  final String middleName;
  final String birthDay;
  final String birthMonth;
  final String birthYear;
  final bool isMale;
  final String status;
  final String? linkedUserId;
  final String? avatarUrl;

  Student({
    required this.id,
    required this.lastName,
    required this.firstName,
    this.middleName = '',
    this.birthDay = '',
    this.birthMonth = '',
    this.birthYear = '',
    required this.isMale,
    this.status = 'active',
    this.linkedUserId,
    this.avatarUrl,
  });

  String get avatarAsset =>
      isMale ? 'assets/images/man_avatar.png' : 'assets/images/women_avatar.png';

  factory Student.fromRow(Map<String, dynamic> row) => Student(
        id: row['id'] as String,
        lastName: row['last_name'] as String? ?? '',
        firstName: row['first_name'] as String? ?? '',
        middleName: row['middle_name'] as String? ?? '',
        birthDay: row['birth_day'] as String? ?? '',
        birthMonth: row['birth_month'] as String? ?? '',
        birthYear: row['birth_year'] as String? ?? '',
        isMale: row['is_male'] as bool? ?? true,
        status: row['status'] as String? ?? 'active',
        linkedUserId: row['linked_user_id'] as String?,
        avatarUrl: row['avatar_url'] as String?,
      );
}

// ─── Сервис студентов ─────────────────────────────────────────────────────────

class StudentService {
  static final _supa = DatabaseService.client;
  static final _local = SyncService.db;

  // ── ЧТЕНИЕ ИЗ ЛОКАЛЬНОЙ БД ────────────────────────────────────────────────

  static Future<List<Student>> loadAll() async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return [];
    final rows = await _local.getStudentsForGroup(gid);
    return rows
        .map((r) => Student(
              id: r.id,
              lastName: r.lastName,
              firstName: r.firstName,
              middleName: r.middleName,
              birthDay: r.birthDay,
              birthMonth: r.birthMonth,
              birthYear: r.birthYear,
              isMale: r.isMale,
              status: r.status,
              linkedUserId: r.linkedUserId,
              avatarUrl: r.avatarUrl,
            ))
        .toList();
  }

  // ── ЗАПИСЬ В SUPABASE + СИНХРОНИЗАЦИЯ ─────────────────────────────────────

  static Future<Student?> addStudent(Student student) async {
    final gid = await GroupService.getCurrentGroupId();
    final uid = AuthService.currentUserId;
    if (gid == null || uid == null) return null;
    try {
      final inserted = await _supa
          .from('students')
          .insert({
            'user_id': uid,
            'group_id': gid,
            'last_name': student.lastName,
            'first_name': student.firstName,
            'middle_name': student.middleName,
            'birth_day': student.birthDay,
            'birth_month': student.birthMonth,
            'birth_year': student.birthYear,
            'is_male': student.isMale,
            'status': student.status,
          })
          .select()
          .single();
      await SyncService.syncStudents(gid);
      return Student.fromRow(inserted);
    } catch (e) {
      developer.log('[StudentService] addStudent error: $e');
      return null;
    }
  }

  static Future<void> updateStudent(Student student) async {
    final gid = await GroupService.getCurrentGroupId();
    try {
      await _supa.from('students').update({
        'last_name': student.lastName,
        'first_name': student.firstName,
        'middle_name': student.middleName,
        'birth_day': student.birthDay,
        'birth_month': student.birthMonth,
        'birth_year': student.birthYear,
        'is_male': student.isMale,
        'status': student.status,
      }).eq('id', student.id);
      if (gid != null) await SyncService.syncStudents(gid);
    } catch (e) {
      developer.log('[StudentService] updateStudent error: $e');
    }
  }

  static Future<void> deleteStudent(String studentId) async {
    try {
      await _supa.from('students').delete().eq('id', studentId);
      await _local.deleteStudent(studentId);
    } catch (e) {
      developer.log('[StudentService] deleteStudent error: $e');
    }
  }
}
