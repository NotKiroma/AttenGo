import 'dart:developer' as developer;
import 'db_service.dart';
import 'auth_service.dart';
import 'group_service.dart';

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

  Student({required this.id, required this.lastName, required this.firstName, this.middleName = '', this.birthDay = '', this.birthMonth = '', this.birthYear = '', required this.isMale, this.status = 'active'});

  String get avatarAsset => isMale ? 'assets/images/man_avatar.png' : 'assets/images/women_avatar.png';

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
  );
}

// ─── Сервис студентов ─────────────────────────────────────────────────────────

class StudentService {
  static final _db = DatabaseService.client;

  static Future<List<Student>> loadAll() async {
    final gid = await GroupService.getCurrentGroupId();
    if (gid == null) return [];
    try {
      final rows = await _db.from('students').select().eq('group_id', gid).or('status.neq.inactive,status.is.null').order('last_name', ascending: true);
      return (rows as List).map((r) => Student.fromRow(r)).toList();
    } catch (e) {
      developer.log('[StudentService] loadAll error: $e');
      return [];
    }
  }

  static Future<Student?> addStudent(Student student) async {
    final gid = await GroupService.getCurrentGroupId();
    final uid = AuthService.currentUserId;
    if (gid == null || uid == null) return null;
    try {
      final inserted = await _db
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
      return Student.fromRow(inserted);
    } catch (e) {
      developer.log('[StudentService] addStudent error: $e');
      return null;
    }
  }

  static Future<void> updateStudent(Student student) async {
    try {
      await _db
          .from('students')
          .update({'last_name': student.lastName, 'first_name': student.firstName, 'middle_name': student.middleName, 'birth_day': student.birthDay, 'birth_month': student.birthMonth, 'birth_year': student.birthYear, 'is_male': student.isMale, 'status': student.status})
          .eq('id', student.id);
    } catch (e) {
      developer.log('[StudentService] updateStudent error: $e');
    }
  }

  static Future<void> deleteStudent(String studentId) async {
    try {
      await _db.from('students').delete().eq('id', studentId);
    } catch (e) {
      developer.log('[StudentService] deleteStudent error: $e');
    }
  }
}
