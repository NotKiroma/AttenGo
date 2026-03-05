import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';
import '../utils/dark_page_route.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ЭКРАН ПРОФИЛЯ СТУДЕНТА
// ═══════════════════════════════════════════════════════════════════════════════

class StudentProfileScreen extends StatefulWidget {
  final Student student;
  final VoidCallback? onUpdated;

  const StudentProfileScreen({super.key, required this.student, this.onUpdated});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late Student _student;
  bool _isLoading = true;

  int _totalLessons = 0;
  int _attended = 0;
  int _missed = 0;
  int _excused = 0;

  final Map<String, Map<String, dynamic>> _subjectStats = {};
  // Сворачиваемость
  final Set<String> _expandedSubjects = {};

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final all = await AttendanceService.loadAll();

    for (final lesson in all) {
      if (lesson.lessonKey == 'weekend') continue;

      StudentAttendance? sa;
      try {
        sa = lesson.students.firstWhere((s) => s.studentId == _student.id);
      } catch (_) {
        continue;
      }

      if (sa.status == null) continue;

      _totalLessons++;
      if (sa.status == 'present') _attended++;
      if (sa.status == 'absent') _missed++;
      if (sa.status == 'late') _excused++;

      _subjectStats.putIfAbsent(lesson.subject, () => {'present': 0, 'absent': 0, 'late': 0, 'total': 0, 'teacher': ''});
      _subjectStats[lesson.subject]!['total']++;
      _subjectStats[lesson.subject]![sa.status!] = (_subjectStats[lesson.subject]![sa.status!] as int) + 1;
    }

    // По умолчанию все свёрнуты
    setState(() => _isLoading = false);
  }

  void _openEdit() async {
    final updated = await Navigator.push<Student>(
      context,
      DarkPageRoute(builder: (_) => StudentEditScreen(student: _student)),
    );
    if (updated != null) {
      setState(() => _student = updated);
      widget.onUpdated?.call();
    }
  }

  double _percent(Map<String, dynamic> s) {
    final total = s['total'] as int;
    if (total == 0) return 0;
    return (s['present'] as int) / total;
  }

  String _grade(double p) {
    if (p >= 0.9) return 'ХОРОШО';
    if (p >= 0.7) return 'СРЕДНЕ';
    return 'ПЛОХО';
  }

  Color _gradeColor(double p) {
    if (p >= 0.9) return const Color(0xFF34D399);
    if (p >= 0.7) return const Color(0xFFFACC15);
    return const Color(0xFFF87171);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final fs = w.clamp(320.0, 430.0);

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Профиль студента', style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF455664), height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2)))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04).add(EdgeInsets.only(top: h * 0.03, bottom: h * 0.04)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(fs, h),
                  SizedBox(height: h * 0.03),
                  _statsGrid(fs, h),
                  SizedBox(height: h * 0.025),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openEdit,
                      icon: Icon(Icons.edit_outlined, size: fs * 0.042),
                      label: Text('Изменить', style: TextStyle(fontSize: fs * 0.037, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D59F2),
                        side: const BorderSide(color: Color(0xFF0D59F2), width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: h * 0.016),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.03),
                  if (_subjectStats.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Посещаемость по предметам', style: TextStyle(color: Colors.white, fontSize: fs * 0.044, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_expandedSubjects.length == _subjectStats.length) {
                                _expandedSubjects.clear();
                              } else {
                                _expandedSubjects.addAll(_subjectStats.keys);
                              }
                            });
                          },
                          child: Text(
                            _expandedSubjects.length == _subjectStats.length ? 'Свернуть все' : 'Развернуть все',
                            style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.033),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.015),
                    ..._subjectStats.entries.map((e) => _subjectCard(fs, h, e.key, e.value)),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(fs * 0.05),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10232C),
                        borderRadius: BorderRadius.circular(fs * 0.04),
                        border: Border.all(color: const Color(0xFF455664)),
                      ),
                      child: Text('Посещаемость ещё не отмечалась', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036)),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _header(double fs, double h) {
    final avatarSize = fs * 0.3;
    return Center(
      child: Column(children: [
        Container(
          width: avatarSize, height: avatarSize,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0D59F2), width: 3)),
          child: ClipOval(child: Image.asset(_student.avatarAsset, fit: BoxFit.cover)),
        ),
        SizedBox(height: h * 0.018),
        Text('${_student.lastName} ${_student.firstName}', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: fs * 0.06, fontWeight: FontWeight.bold)),
        if (_student.middleName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(_student.middleName, style: TextStyle(color: Colors.white, fontSize: fs * 0.04)),
        ],
        SizedBox(height: h * 0.006),
        Text('ID: ${_student.id}', style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035)),
      ]),
    );
  }

  Widget _statsGrid(double fs, double h) {
    final attendPct = _totalLessons > 0 ? ((_attended / _totalLessons) * 100).toStringAsFixed(1) : '0';
    final missedPct = _totalLessons > 0 ? ((_missed / _totalLessons) * 100).toStringAsFixed(1) : '0';
    final excusedPct = _totalLessons > 0 ? ((_excused / _totalLessons) * 100).toStringAsFixed(1) : '0';

    return Column(children: [
      Row(children: [
        Expanded(child: _statCard(fs, h, label: 'Всего занятий', value: '$_totalLessons', badge: '100%', badgeColor: const Color(0xFF34D399))),
        SizedBox(width: fs * 0.03),
        Expanded(child: _statCard(fs, h, label: 'Посещено', value: '$_attended', badge: '$attendPct%', badgeColor: const Color(0xFF34D399))),
      ]),
      SizedBox(height: fs * 0.03),
      Row(children: [
        Expanded(child: _statCard(fs, h, label: 'Пропущено', value: '$_missed', badge: '$missedPct%', badgeColor: const Color(0xFFF87171))),
        SizedBox(width: fs * 0.03),
        Expanded(child: _statCard(fs, h, label: 'Уважительных', value: '$_excused', badge: '$excusedPct%', badgeColor: const Color(0xFFFACC15))),
      ]),
    ]);
  }

  Widget _statCard(double fs, double h, {required String label, required String value, required String badge, required Color badgeColor}) {
    return Container(
      padding: EdgeInsets.all(fs * 0.04),
      decoration: BoxDecoration(color: const Color(0xFF10232C), borderRadius: BorderRadius.circular(fs * 0.04), border: Border.all(color: const Color(0xFF455664), width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.033)),
        SizedBox(height: h * 0.006),
        Text(value, style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.09, fontWeight: FontWeight.bold, height: 1.0)),
        SizedBox(height: h * 0.008),
        Container(
          padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 3),
          decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(fs * 0.04)),
          child: Text(badge, style: TextStyle(color: badgeColor, fontSize: fs * 0.028, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _subjectCard(double fs, double h, String subject, Map<String, dynamic> stats) {
    final p = _percent(stats);
    final pInt = (p * 100).round();
    final color = _gradeColor(p);
    final grade = _grade(p);
    final isExpanded = _expandedSubjects.contains(subject);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedSubjects.remove(subject);
          } else {
            _expandedSubjects.add(subject);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: h * 0.012),
        padding: EdgeInsets.all(fs * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFF10232C),
          borderRadius: BorderRadius.circular(fs * 0.04),
          border: Border.all(color: const Color(0xFF455664), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок — всегда видим
            Row(
              children: [
                Expanded(
                  child: Text(subject, style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.bold, height: 1.3)),
                ),
                SizedBox(width: fs * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(fs * 0.04), border: Border.all(color: color.withOpacity(0.5))),
                  child: Text(grade, style: TextStyle(color: color, fontSize: fs * 0.027, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: fs * 0.02),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF7D92B1), size: fs * 0.06),
                ),
              ],
            ),
            // Краткий текст процента — всегда видим
            SizedBox(height: h * 0.006),
            Text('$pInt% посещаемости', style: TextStyle(color: color, fontSize: fs * 0.032, fontWeight: FontWeight.w600)),

            // Развернутая часть
            if (isExpanded) ...[
              SizedBox(height: h * 0.012),
              Container(height: 1, color: const Color(0xFF455664).withOpacity(0.5)),
              SizedBox(height: h * 0.012),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Посещаемость', style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.033)),
                  Text('$pInt%', style: TextStyle(color: color, fontSize: fs * 0.036, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: h * 0.008),
              LayoutBuilder(
                builder: (_, constraints) {
                  return Stack(children: [
                    Container(height: fs * 0.015, width: constraints.maxWidth, decoration: BoxDecoration(color: const Color(0xFF455664), borderRadius: BorderRadius.circular(fs * 0.04))),
                    Container(height: fs * 0.015, width: constraints.maxWidth * p.clamp(0.0, 1.0), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(fs * 0.04))),
                  ]);
                },
              ),
              SizedBox(height: h * 0.012),
              Row(children: [
                _detailChip(fs, 'Присутствие', '${stats['present']}', const Color(0xFF34D399)),
                SizedBox(width: fs * 0.02),
                _detailChip(fs, 'Пропуски', '${stats['absent']}', const Color(0xFFF87171)),
                SizedBox(width: fs * 0.02),
                _detailChip(fs, 'Причина', '${stats['late']}', const Color(0xFFFACC15)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailChip(double fs, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: fs * 0.02),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(fs * 0.04)),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: fs * 0.038, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: fs * 0.025)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ЭКРАН РЕДАКТИРОВАНИЯ СТУДЕНТА
// ═══════════════════════════════════════════════════════════════════════════════

class StudentEditScreen extends StatefulWidget {
  final Student student;
  const StudentEditScreen({super.key, required this.student});

  @override
  State<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends State<StudentEditScreen> {
  late TextEditingController _lastNameCtrl;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _middleNameCtrl;
  late TextEditingController _dayCtrl;
  late TextEditingController _monthCtrl;
  late TextEditingController _yearCtrl;
  late bool _isMale;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _lastNameCtrl = TextEditingController(text: s.lastName);
    _firstNameCtrl = TextEditingController(text: s.firstName);
    _middleNameCtrl = TextEditingController(text: s.middleName);
    _dayCtrl = TextEditingController(text: s.birthDay);
    _monthCtrl = TextEditingController(text: s.birthMonth);
    _yearCtrl = TextEditingController(text: s.birthYear);
    _isMale = s.isMale;
  }

  @override
  void dispose() {
    for (final c in [_lastNameCtrl, _firstNameCtrl, _middleNameCtrl, _dayCtrl, _monthCtrl, _yearCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final updated = Student(
      id: widget.student.id, lastName: _lastNameCtrl.text.trim(), firstName: _firstNameCtrl.text.trim(),
      middleName: _middleNameCtrl.text.trim(), birthDay: _dayCtrl.text.trim(), birthMonth: _monthCtrl.text.trim(),
      birthYear: _yearCtrl.text.trim(), isMale: _isMale, status: widget.student.status,
    );
    await StudentService.updateStudent(updated);
    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final fs = w.clamp(320.0, 430.0);
    final avatar = _isMale ? 'assets/images/man_avatar.png' : 'assets/images/women_avatar.png';

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0, scrolledUnderElevation: 0,
        title: Text('Изменить студента', style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold)),
        centerTitle: true, backgroundColor: const Color(0xFF101C22),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF455664), height: 1)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04).add(EdgeInsets.only(top: h * 0.03, bottom: h * 0.04)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Column(children: [
            Container(width: fs * 0.28, height: fs * 0.28, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0D59F2), width: 3)), child: ClipOval(child: Image.asset(avatar, fit: BoxFit.cover))),
            SizedBox(height: h * 0.01),
            Text('ID: ${widget.student.id}', style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.033)),
          ])),
          SizedBox(height: h * 0.03),
          _label(fs, 'ФИО'),
          SizedBox(height: h * 0.01),
          _field(fs, _lastNameCtrl, 'Фамилия', Icons.person_outline),
          SizedBox(height: h * 0.012),
          _field(fs, _firstNameCtrl, 'Имя', Icons.person_outline),
          SizedBox(height: h * 0.012),
          _field(fs, _middleNameCtrl, 'Отчество (необязательно)', Icons.person_outline),
          SizedBox(height: h * 0.025),
          _label(fs, 'Дата рождения'),
          SizedBox(height: h * 0.01),
          Row(children: [
            Expanded(flex: 2, child: _field(fs, _dayCtrl, 'ДД', Icons.calendar_today, maxLen: 2, numeric: true)),
            SizedBox(width: fs * 0.02),
            Expanded(flex: 2, child: _field(fs, _monthCtrl, 'ММ', Icons.calendar_today, maxLen: 2, numeric: true)),
            SizedBox(width: fs * 0.02),
            Expanded(flex: 3, child: _field(fs, _yearCtrl, 'ГГГГ', Icons.calendar_today, maxLen: 4, numeric: true)),
          ]),
          SizedBox(height: h * 0.025),
          _label(fs, 'Пол'),
          SizedBox(height: h * 0.01),
          Row(children: [
            Expanded(child: _genderBtn(fs, label: 'Мужской', icon: Icons.male, selected: _isMale, onTap: () => setState(() => _isMale = true))),
            SizedBox(width: fs * 0.03),
            Expanded(child: _genderBtn(fs, label: 'Женский', icon: Icons.female, selected: !_isMale, onTap: () => setState(() => _isMale = false))),
          ]),
          SizedBox(height: h * 0.04),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D59F2), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF455664), padding: EdgeInsets.symmetric(vertical: h * 0.018), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04))),
            child: _isSaving ? SizedBox(width: fs * 0.055, height: fs * 0.055, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Сохранить', style: TextStyle(fontSize: fs * 0.04, fontWeight: FontWeight.w600)),
          )),
        ]),
      ),
    );
  }

  Widget _label(double fs, String text) => Text(text, style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.w600));

  Widget _field(double fs, TextEditingController ctrl, String hint, IconData icon, {int? maxLen, bool numeric = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF10232C), borderRadius: BorderRadius.circular(fs * 0.04), border: Border.all(color: const Color(0xFF455664), width: 1)),
      child: TextField(
        controller: ctrl, style: TextStyle(color: Colors.white, fontSize: fs * 0.037), maxLength: maxLen,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035), prefixIcon: Icon(icon, color: const Color(0xFF7D92B1), size: fs * 0.048), border: InputBorder.none, counterText: '', contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.035)),
      ),
    );
  }

  Widget _genderBtn(double fs, {required String label, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: fs * 0.035),
        decoration: BoxDecoration(color: selected ? const Color(0xFF0D59F2) : const Color(0xFF10232C), borderRadius: BorderRadius.circular(fs * 0.04), border: Border.all(color: selected ? const Color(0xFF0D59F2) : const Color(0xFF455664), width: 1.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? Colors.white : const Color(0xFF7D92B1), size: fs * 0.05),
          SizedBox(width: fs * 0.02),
          Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF7D92B1), fontSize: fs * 0.036, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
