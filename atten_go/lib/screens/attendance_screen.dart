import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/student_service.dart';
import '../services/schedule_service.dart';
import 'student_profile_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  LessonAttendance? _currentLesson;
  String? _currentLessonKey;
  bool _isLoading = true;
  bool _isWeekend = false;

  List<Student> _fullStudents = [];
  List<Lesson> _todaySchedule = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkLessonChange();
  }

  Future<void> _init() async {
    _isWeekend    = AttendanceService.isWeekend;
    _fullStudents = await StudentService.loadAll();
    _todaySchedule = await ScheduleService.getTodayLessons();

    if (_isWeekend) {
      final students = await AttendanceService.loadStudentsOnly();
      _currentLesson = LessonAttendance(
        date:      AttendanceService.todayDate(),
        lessonKey: 'weekend',
        subject:   'Выходной',
        students:  students,
      );
    } else {
      await _loadCurrentLesson();
    }
    setState(() => _isLoading = false);
  }

  Lesson? get _activeLesson {
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final lesson in _todaySchedule) {
      final start = _parseTime(lesson.timeStart);
      final end   = _parseTime(lesson.timeEnd);
      if (nowMin >= start && nowMin <= end) return lesson;
    }
    for (final lesson in _todaySchedule) {
      if (nowMin < _parseTime(lesson.timeStart)) return lesson;
    }
    return null;
  }

  int _parseTime(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  Future<void> _loadCurrentLesson() async {
    final active = _activeLesson;
    if (active == null) {
      _currentLesson    = null;
      _currentLessonKey = null;
      return;
    }
    final key = AttendanceService.lessonKey(active.timeStart, active.timeEnd);
    _currentLessonKey = key;
    _currentLesson    = await AttendanceService.getOrCreateLesson(
      date:      AttendanceService.todayDate(),
      lessonKey: key,
      subject:   active.subject,
    );
  }

  Future<void> _checkLessonChange() async {
    final active = _activeLesson;
    final newKey = active != null
        ? AttendanceService.lessonKey(active.timeStart, active.timeEnd)
        : null;
    if (newKey != _currentLessonKey) {
      setState(() => _isLoading = true);
      await _loadCurrentLesson();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_currentLesson != null) {
      await AttendanceService.saveLesson(_currentLesson!);
    }
  }

  Student? _findFullStudent(StudentAttendance sa) {
    try {
      return _fullStudents.firstWhere(
          (s) => s.lastName == sa.lastName && s.firstName == sa.firstName);
    } catch (_) {
      return null;
    }
  }

  List<int> get _sortedIndexes {
    if (_currentLesson == null) return [];
    final students = _currentLesson!.students;
    final indexes  = List<int>.generate(students.length, (i) => i);

    final filtered = _searchQuery.isEmpty
        ? indexes
        : indexes.where((i) {
            final last  = students[i].lastName.toLowerCase();
            final first = students[i].firstName.toLowerCase();
            return last.contains(_searchQuery) || first.contains(_searchQuery);
          }).toList();

    filtered.sort((a, b) {
      final cmp = students[a].lastName.compareTo(students[b].lastName);
      if (cmp != 0) return cmp;
      return students[a].firstName.compareTo(students[b].firstName);
    });
    return filtered;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'absent':  return Colors.red;
      case 'late':    return Colors.orange;
      default:        return Colors.transparent;
    }
  }

  void _openProfile(StudentAttendance sa) {
    final full = _findFullStudent(sa);
    if (full == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentProfileScreen(
          student: full,
          onUpdated: () async {
            _fullStudents = await StudentService.loadAll();
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, int originalIndex) {
    if (_currentLesson == null) return;
    final student = _currentLesson!.students[originalIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF152028),
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '${student.lastName} ${student.firstName}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildStatusOption(
              label: 'ПРИСУТСТВУЕТ',
              color: Colors.green,
              onTap: () {
                setState(() => _currentLesson!.students[originalIndex].status = 'present');
                _save();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              label: 'ОТСУТСТВУЕТ',
              color: Colors.red,
              onTap: () {
                setState(() => _currentLesson!.students[originalIndex].status = 'absent');
                _save();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              label: 'ПРИЧИНА',
              color: Colors.orange,
              onTap: () {
                setState(() => _currentLesson!.students[originalIndex].status = 'late');
                _save();
                Navigator.pop(context);
              },
            ),
            if (student.status != null) ...[
              const SizedBox(height: 12),
              _buildStatusOption(
                label: 'СБРОСИТЬ',
                color: const Color(0xFF7D92B1),
                onTap: () {
                  setState(() => _currentLesson!.students[originalIndex].status = null);
                  _save();
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w          = MediaQuery.of(context).size.width;
    final double h          = MediaQuery.of(context).size.height;
    final sortedIndexes = _sortedIndexes;

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Посещаемость',
          style: TextStyle(color: Colors.white, fontSize: w * 0.06, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2)))
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.03)
                  .add(EdgeInsets.only(top: h * 0.02)),
              child: Column(
                children: [
                  _buildCurrentLessonBanner(w, h),
                  SizedBox(height: h * 0.015),
                  _buildSearchField(w),
                  SizedBox(height: h * 0.018),
                  _buildFilterRow(w),
                  SizedBox(height: h * 0.018),
                  if (_currentLesson == null)
                    Expanded(
                      child: Center(
                        child: Text(
                          'Сегодня занятий нет',
                          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.045),
                        ),
                      ),
                    )
                  else
                    _buildStudentList(w, h, sortedIndexes),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentLessonBanner(double w, double h) {
    if (_currentLesson == null || _isWeekend) return const SizedBox.shrink();
    final lesson = _currentLesson!;
    final active = _activeLesson;
    final isNow  = active != null &&
        AttendanceService.lessonKey(active.timeStart, active.timeEnd) == lesson.lessonKey;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.015),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNow ? const Color(0xFF0D59F2) : const Color(0xFF455664),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: 4),
                decoration: BoxDecoration(
                  color: isNow ? const Color(0x200D59F2) : const Color(0x20455664),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isNow ? 'ИДЁТ СЕЙЧАС' : 'СЛЕДУЮЩАЯ',
                  style: TextStyle(
                    color: isNow ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1),
                    fontSize: w * 0.028,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: w * 0.02),
              Text(
                lesson.lessonKey.replaceAll('-', ' – '),
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.032),
              ),
            ],
          ),
          SizedBox(height: h * 0.008),
          Text(
            lesson.subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: w * 0.042, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: h * 0.008),
          Row(
            children: [
              _miniStat(w, Colors.green, '${lesson.presentCount}'),
              SizedBox(width: w * 0.03),
              _miniStat(w, Colors.red, '${lesson.absentCount}'),
              SizedBox(width: w * 0.03),
              _miniStat(w, Colors.orange, '${lesson.lateCount}'),
              const Spacer(),
              Text(
                'Отмечено: ${lesson.markedCount}/${lesson.totalCount}',
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.032),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(double w, Color color, String value) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: w * 0.01),
        Text(value, style: TextStyle(color: Colors.white, fontSize: w * 0.035, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSearchField(double w) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E2D36), borderRadius: BorderRadius.circular(27)),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        decoration: const InputDecoration(
          hintText: 'Поиск',
          hintStyle: TextStyle(color: Color(0xFF7A9BAF)),
          suffixIcon: Icon(Icons.search, color: Color(0xFF7A9BAF)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterRow(double w) {
    return Row(
      children: [
        Expanded(child: _buildFilterChip(label: 'ПРИСУТСТВУЕТ', color: Colors.green, w: w)),
        SizedBox(width: w * 0.02),
        Expanded(child: _buildFilterChip(label: 'ОТСУТСТВУЕТ', color: Colors.red, w: w)),
        SizedBox(width: w * 0.02),
        Expanded(child: _buildFilterChip(label: 'ПРИЧИНА', color: Colors.orange, w: w)),
      ],
    );
  }

  Widget _buildFilterChip({required String label, required Color color, required double w}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: w * 0.015),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: w * 0.028, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(double w, double h, List<int> sortedIndexes) {
    if (_currentLesson == null) return const SizedBox.shrink();
    final students = _currentLesson!.students;

    return Expanded(
      child: ListView.separated(
        itemCount: sortedIndexes.length,
        separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
        itemBuilder: (context, i) {
          final idx     = sortedIndexes[i];
          final student = students[idx];
          final hasStatus = student.status != null;
          final full      = _findFullStudent(student);
          final isMale    = full?.isMale ?? student.isMale;

          return GestureDetector(
            onTap: () => _openProfile(student),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.015),
              decoration: BoxDecoration(
                color: const Color(0xFF10232C),
                borderRadius: BorderRadius.circular(27),
                border: Border.all(color: const Color(0xFF455664), width: 1),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: w * 0.07,
                        backgroundImage: AssetImage(
                          isMale ? 'assets/images/man_avatar.png' : 'assets/images/women_avatar.png',
                        ),
                        backgroundColor: const Color(0xFF3A5FCD),
                      ),
                      if (hasStatus)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _statusColor(student.status),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF10232C), width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: w * 0.04),
                  Expanded(
                    child: Text(
                      '${student.lastName}\n${student.firstName}',
                      style: TextStyle(color: Colors.white, fontSize: w * 0.042, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                  ),
                  if (!_isWeekend)
                    ElevatedButton(
                      onPressed: () => _showStatusSheet(context, idx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D59F2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.013),
                      ),
                      child: Text(
                        hasStatus ? 'Изменить' : 'Отметить',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: w * 0.038),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusOption({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
