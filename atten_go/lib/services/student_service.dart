import 'db_service.dart';

// ─── Модель студента ──────────────────────────────────────────────────────────

class Student {
  final String id;
  String lastName;
  String firstName;
  String middleName;
  String birthDay;
  String birthMonth;
  String birthYear;
  bool isMale;
  String? status;

  Student({
    required this.id,
    required this.lastName,
    required this.firstName,
    this.middleName = '',
    this.birthDay = '',
    this.birthMonth = '',
    this.birthYear = '',
    required this.isMale,
    this.status,
  });

  factory Student.fromRow(Map<String, dynamic> row) => Student(
    id:          row['id'] as String,
    lastName:    row['last_name'] as String,
    firstName:   row['first_name'] as String,
    middleName:  row['middle_name'] as String? ?? '',
    birthDay:    row['birth_day'] as String? ?? '',
    birthMonth:  row['birth_month'] as String? ?? '',
    birthYear:   row['birth_year'] as String? ?? '',
    isMale:      row['is_male'] as bool,
    status:      row['status'] as String?,
  );

  Map<String, dynamic> toRow() => {
    'id':          id,
    'last_name':   lastName,
    'first_name':  firstName,
    'middle_name': middleName,
    'birth_day':   birthDay,
    'birth_month': birthMonth,
    'birth_year':  birthYear,
    'is_male':     isMale,
    'status':      status,
  };

  String get fullName =>
      '$lastName $firstName'
      '${middleName.isNotEmpty ? ' $middleName' : ''}';

  String get birthDate {
    if (birthDay.isEmpty && birthMonth.isEmpty && birthYear.isEmpty) return '';
    return '${birthDay.padLeft(2, '0')}.${birthMonth.padLeft(2, '0')}.$birthYear';
  }

  String get avatarAsset =>
      isMale ? 'assets/images/man_avatar.png' : 'assets/images/women_avatar.png';
}

// ─── Сервис ───────────────────────────────────────────────────────────────────

class StudentService {
  static final _db = DatabaseService.client;

  // Загрузить всех студентов
  static Future<List<Student>> loadAll() async {
    final rows = await _db
        .from('students')
        .select()
        .order('last_name')
        .order('first_name');
    return (rows as List).map((r) => Student.fromRow(r)).toList();
  }

  // Обновить одного студента
  static Future<void> updateStudent(Student updated) async {
    await _db
        .from('students')
        .update(updated.toRow())
        .eq('id', updated.id);
  }

  // Получить студента по id
  static Future<Student?> getById(String id) async {
    final rows = await _db
        .from('students')
        .select()
        .eq('id', id)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return Student.fromRow(rows.first);
  }
}
