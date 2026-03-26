import 'dart:async';
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/student_service.dart';
import '../services/group_service.dart';
import '../services/announcement_service.dart';
import '../services/schedule_service.dart';
import '../services/realtime_service.dart';
import 'student_profile_screen.dart';
import '../utils/dark_page_route.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  LessonAttendance? _currentLesson;
  String? _currentLessonKey;
  bool _isLoading = true;
  bool _isWeekend = false;
  bool _hasGroup = false;
  bool _isCancelledLesson = false;

  List<Student> _fullStudents = [];
  List<Lesson> _todaySchedule = [];

  // Ручной выбор пары (null = автоматический режим)
  int? _manualLessonIndex;

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();

    // Авто-обновление при изменениях в БД
    _subs.add(
      RealtimeService.onAttendanceRecordsChanged.listen((_) {
        if (mounted) _refresh();
      }),
    );
    _subs.add(
      RealtimeService.onStudentsChanged.listen((_) {
        if (mounted) _refresh();
      }),
    );
    _subs.add(
      RealtimeService.onAttendanceLessonsChanged.listen((_) {
        if (mounted) _refresh();
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkLessonChange();
  }

  Future<void> _init() async {
    GroupService.invalidateCache();
    final group = await GroupService.getCurrentGroup();
    _hasGroup = group != null;
    if (!_hasGroup) {
      setState(() => _isLoading = false);
      return;
    }
    _isWeekend = AttendanceService.isWeekend;
    _fullStudents = await StudentService.loadAll();
    _todaySchedule = await ScheduleService.getTodayLessons();

    if (_isWeekend) {
      final freshStudents = await StudentService.loadAll();
      _fullStudents = freshStudents;
      _currentLesson = LessonAttendance(date: AttendanceService.todayDate(), lessonKey: 'weekend', subject: 'Выходной', students: freshStudents.map((s) => StudentAttendance.fromStudent(s)).toList());
    } else {
      await _loadCurrentLesson();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    GroupService.invalidateCache();
    AttendanceService.invalidateCache();
    final group = await GroupService.getCurrentGroup();
    _hasGroup = group != null;
    if (!_hasGroup) {
      setState(() {});
      return;
    }
    _fullStudents = await StudentService.loadAll();
    _todaySchedule = await ScheduleService.getTodayLessons();

    if (_isWeekend) {
      final freshStudents = await StudentService.loadAll();
      _fullStudents = freshStudents;
      _currentLesson = LessonAttendance(date: AttendanceService.todayDate(), lessonKey: 'weekend', subject: 'Выходной', students: freshStudents.map((s) => StudentAttendance.fromStudent(s)).toList());
    } else {
      await _loadCurrentLesson();
    }
    setState(() {});
  }

  // Пара которая ИДЁТ ПРЯМО СЕЙЧАС (начало <= now <= конец)
  Lesson? get _activeLesson {
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final lesson in _todaySchedule) {
      final start = _parseTime(lesson.timeStart);
      final end = _parseTime(lesson.timeEnd);
      if (nowMin >= start && nowMin <= end) return lesson;
    }
    return null;
  }

  // Следующая пара (ещё не началась)
  Lesson? get _upcomingLesson {
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final lesson in _todaySchedule) {
      if (nowMin < _parseTime(lesson.timeStart)) return lesson;
    }
    return null;
  }

  int _parseTime(String t) {
    try {
      final p = t.split(':');
      if (p.length >= 2) {
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      }
      // Формат без двоеточия: "0900" -> 09*60+00
      if (t.length == 4) {
        return int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(2, 4));
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _loadCurrentLesson() async {
    final date = AttendanceService.todayDate();

    // Ручной выбор пары
    Lesson? lesson;
    if (_manualLessonIndex != null && _manualLessonIndex! < _todaySchedule.length) {
      lesson = _todaySchedule[_manualLessonIndex!];
    } else {
      // Автоматический режим: активная или следующая
      _manualLessonIndex = null;
      final active = _activeLesson;
      final upcoming = _upcomingLesson;
      lesson = active ?? upcoming;
    }

    if (lesson == null) {
      final students = await StudentService.loadAll();
      _currentLesson = LessonAttendance(date: date, lessonKey: 'no_lesson', subject: '', students: students.map((s) => StudentAttendance.fromStudent(s)).toList());
      _fullStudents = students;
      _currentLessonKey = null;
      return;
    }

    final key = AttendanceService.lessonKey(lesson.timeStart, lesson.timeEnd);

    // Проверяем отменена ли пара или весь день
    final isCancelled = await AnnouncementService.isCancelled(date: date, lessonKey: key);
    final isDayCancelled = await AnnouncementService.isCancelled(date: date, lessonKey: 'all');

    if (isCancelled || isDayCancelled) {
      // Пара отменена — показываем студентов без возможности отмечать
      final students = await StudentService.loadAll();
      _currentLesson = LessonAttendance(date: date, lessonKey: 'cancelled', subject: lesson.subject, students: students.map((s) => StudentAttendance.fromStudent(s)).toList());
      _fullStudents = students;
      _currentLessonKey = null;
      _isCancelledLesson = true;
      return;
    }

    _isCancelledLesson = false;

    // В ручном режиме — всегда разрешаем отмечать
    // В авто-режиме — только если пара идёт прямо сейчас
    if (_manualLessonIndex != null) {
      _currentLessonKey = key;
    } else {
      _currentLessonKey = _activeLesson != null ? key : null;
    }

    _currentLesson = await AttendanceService.getOrCreateLesson(date: date, lessonKey: key, subject: lesson.subject);
  }

  /// Выбрать пару вручную (по индексу в _todaySchedule)
  void _selectLesson(int index) async {
    setState(() {
      _manualLessonIndex = index;
      _isLoading = true;
    });
    await _loadCurrentLesson();
    setState(() => _isLoading = false);
  }

  /// Вернуться в автоматический режим
  void _resetToAuto() async {
    setState(() {
      _manualLessonIndex = null;
      _isLoading = true;
    });
    await _loadCurrentLesson();
    setState(() => _isLoading = false);
  }

  /// Найти предыдущую НЕотменённую пару и скопировать статусы
  Future<void> _copyFromPrevious() async {
    if (_currentLesson == null || _todaySchedule.isEmpty) return;

    final date = AttendanceService.todayDate();

    // Определяем индекс текущей пары
    int currentIdx = -1;
    if (_manualLessonIndex != null) {
      currentIdx = _manualLessonIndex!;
    } else {
      final active = _activeLesson;
      final upcoming = _upcomingLesson;
      final target = active ?? upcoming;
      if (target != null) {
        currentIdx = _todaySchedule.indexOf(target);
      }
    }

    if (currentIdx <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет предыдущей пары')));
      }
      return;
    }

    // Ищем предыдущую НЕотменённую пару (идём назад от currentIdx - 1)
    LessonAttendance? prevLesson;
    for (int i = currentIdx - 1; i >= 0; i--) {
      final l = _todaySchedule[i];
      final key = AttendanceService.lessonKey(l.timeStart, l.timeEnd);
      final cancelled = await AnnouncementService.isCancelled(date: date, lessonKey: key);
      final dayOff = await AnnouncementService.isCancelled(date: date, lessonKey: 'all');
      if (!cancelled && !dayOff) {
        prevLesson = await AttendanceService.getCurrentLessonStats(date: date, lessonKey: key);
        break;
      }
    }

    if (prevLesson == null || prevLesson.markedCount == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Предыдущая пара не отмечена')));
      }
      return;
    }

    // Копируем статусы
    final current = _currentLesson!;
    for (final student in current.students) {
      try {
        final prevStudent = prevLesson.students.firstWhere((s) => s.studentId == student.studentId);
        if (prevStudent.status != null) {
          student.status = prevStudent.status;
        }
      } catch (_) {
        // Студент не найден в предыдущей паре — пропускаем
      }
    }

    await AttendanceService.saveLesson(current);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скопировано с пары «${prevLesson.subject}»'), backgroundColor: const Color(0xFF10232C)));
    }
  }

  /// Показать шторку выбора пары
  void _showLessonPicker() {
    if (_todaySchedule.isEmpty) return;
    final w = MediaQuery.of(context).size.width;
    final fs = w.clamp(320.0, 430.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          decoration: const BoxDecoration(
            color: Color(0xFF152028),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: fs * 0.1,
                  height: 4,
                  margin: EdgeInsets.only(top: fs * 0.04, bottom: fs * 0.03),
                  decoration: BoxDecoration(color: const Color(0xFF455664), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: fs * 0.05),
                child: Row(
                  children: [
                    Text(
                      'Выбрать пару',
                      style: TextStyle(color: Colors.white, fontSize: fs * 0.048, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_manualLessonIndex != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _resetToAuto();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: fs * 0.03, vertical: fs * 0.015),
                          decoration: BoxDecoration(color: const Color(0xFF0D59F2).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(fs * 0.03)),
                          child: Text(
                            'Авто',
                            style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.03, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: fs * 0.02),
              Container(height: 1, color: const Color(0xFF455664).withValues(alpha: 0.5)),
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(fs * 0.04, fs * 0.02, fs * 0.04, fs * 0.06),
                  shrinkWrap: true,
                  itemCount: _todaySchedule.length,
                  itemBuilder: (_, i) {
                    final l = _todaySchedule[i];
                    final isSelected = _manualLessonIndex == i;
                    final status = getLessonStatus(l.timeStart, l.timeEnd);
                    final isActive = status == LessonStatus.active;
                    final isPast = status == LessonStatus.past;
                    final statusLabel = isActive ? 'СЕЙЧАС' : (isPast ? 'ПРОШЛА' : 'ВПЕРЕДИ');
                    final statusColor = isActive ? const Color(0xFF0D59F2) : (isPast ? const Color(0xFF455664) : const Color(0xFF94A3B8));

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _selectLesson(i);
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: fs * 0.02),
                        padding: EdgeInsets.all(fs * 0.04),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0D59F2).withValues(alpha: 0.1) : const Color(0xFF10232C),
                          borderRadius: BorderRadius.circular(fs * 0.04),
                          border: Border.all(color: isSelected ? const Color(0xFF0D59F2) : const Color(0xFF455664), width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            // Время
                            Column(
                              children: [
                                Text(
                                  l.timeStart,
                                  style: TextStyle(color: Colors.white, fontSize: fs * 0.035, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  l.timeEnd,
                                  style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.028),
                                ),
                              ],
                            ),
                            SizedBox(width: fs * 0.04),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.subject,
                                    style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (l.room.isNotEmpty || l.teacher.isNotEmpty)
                                    Text(
                                      [l.room, l.teacher].where((s) => s.isNotEmpty).join(' • '),
                                      style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.028),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            // Статус
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: fs * 0.02, vertical: 3),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(fs * 0.02)),
                              child: Text(
                                statusLabel,
                                style: TextStyle(color: statusColor, fontSize: fs * 0.024, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isSelected) ...[SizedBox(width: fs * 0.02), Icon(Icons.check_circle, color: const Color(0xFF0D59F2), size: fs * 0.05)],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkLessonChange() async {
    // В ручном режиме не переключаем пару автоматически
    if (_manualLessonIndex != null) return;

    final active = _activeLesson;
    final newKey = active != null ? AttendanceService.lessonKey(active.timeStart, active.timeEnd) : null;
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

  bool get _hasActiveLesson => !_isWeekend && _currentLessonKey != null;

  Student? _findFullStudent(StudentAttendance sa) {
    try {
      return _fullStudents.firstWhere((s) => s.id == sa.studentId);
    } catch (_) {
      return null;
    }
  }

  List<int> get _sortedIndexes {
    if (_currentLesson == null) return [];
    final students = _currentLesson!.students;
    final indexes = List<int>.generate(students.length, (i) => i);

    final filtered = _searchQuery.isEmpty
        ? indexes
        : indexes.where((i) {
            final last = students[i].lastName.toLowerCase();
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
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.transparent;
    }
  }

  void _openProfile(StudentAttendance sa) {
    final full = _findFullStudent(sa);
    if (full == null) return;
    Navigator.push(
      context,
      DarkPageRoute(
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              label: 'УВАЖ. ПРИЧИНА',
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

  /// Открыть диалог со списком студентов с нужным статусом
  void _showStudentsByStatus(String status, Color color, String title) {
    if (_currentLesson == null) return;
    final filtered = _currentLesson!.students.where((s) => s.status == status).toList()
      ..sort((a, b) {
        final c = a.lastName.compareTo(b.lastName);
        return c != 0 ? c : a.firstName.compareTo(b.firstName);
      });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final double mh = MediaQuery.of(context).size.height * 0.65;
        return Container(
          constraints: BoxConstraints(maxHeight: mh),
          decoration: const BoxDecoration(
            color: Color(0xFF152028),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${filtered.length} чел.', style: const TextStyle(color: Color(0xFF7D92B1), fontSize: 14)),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFF455664)),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Никого нет', style: TextStyle(color: Color(0xFF7D92B1), fontSize: 15)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final s = filtered[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10232C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF455664), width: 1),
                        ),
                        child: Row(
                          children: [
                            _studentAvatar(s, 18),
                            const SizedBox(width: 12),
                            Text(
                              '${s.lastName} ${s.firstName}',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Добавить студента ──
  void _addStudent() {
    final lastCtrl = TextEditingController();
    final firstCtrl = TextEditingController();
    final middleCtrl = TextEditingController();
    bool isMale = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width;
        final fs = w.clamp(320.0, 430.0);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF152028),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: EdgeInsets.fromLTRB(w * 0.05, 24, w * 0.05, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добавить студента',
                      style: TextStyle(color: Colors.white, fontSize: fs * 0.048, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: fs * 0.04),
                    _sheetField(fs, lastCtrl, 'Фамилия'),
                    SizedBox(height: fs * 0.025),
                    _sheetField(fs, firstCtrl, 'Имя'),
                    SizedBox(height: fs * 0.025),
                    _sheetField(fs, middleCtrl, 'Отчество (необязательно)'),
                    SizedBox(height: fs * 0.03),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => isMale = true),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: fs * 0.03),
                              decoration: BoxDecoration(
                                color: isMale ? const Color(0xFF0D59F2) : const Color(0xFF10232C),
                                borderRadius: BorderRadius.circular(fs * 0.04),
                                border: Border.all(color: isMale ? const Color(0xFF0D59F2) : const Color(0xFF455664)),
                              ),
                              child: Center(
                                child: Text(
                                  'Мужской',
                                  style: TextStyle(color: isMale ? Colors.white : const Color(0xFF7D92B1), fontSize: fs * 0.035, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: fs * 0.03),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => isMale = false),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: fs * 0.03),
                              decoration: BoxDecoration(
                                color: !isMale ? const Color(0xFF0D59F2) : const Color(0xFF10232C),
                                borderRadius: BorderRadius.circular(fs * 0.04),
                                border: Border.all(color: !isMale ? const Color(0xFF0D59F2) : const Color(0xFF455664)),
                              ),
                              child: Center(
                                child: Text(
                                  'Женский',
                                  style: TextStyle(color: !isMale ? Colors.white : const Color(0xFF7D92B1), fontSize: fs * 0.035, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fs * 0.04),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (lastCtrl.text.trim().isEmpty || firstCtrl.text.trim().isEmpty) return;
                          final student = Student(id: '', lastName: lastCtrl.text.trim(), firstName: firstCtrl.text.trim(), middleName: middleCtrl.text.trim(), isMale: isMale);
                          await StudentService.addStudent(student);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          AttendanceService.invalidateCache();
                          await _refresh();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D59F2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: fs * 0.04),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
                        ),
                        child: Text(
                          'Добавить',
                          style: TextStyle(fontSize: fs * 0.04, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField(double fs, TextEditingController ctrl, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: TextField(
        controller: ctrl,
        style: TextStyle(color: Colors.white, fontSize: fs * 0.038),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.035),
        ),
      ),
    );
  }

  // ── Удалить студента ──
  void _confirmDelete(StudentAttendance student) {
    showDialog(
      context: context,
      builder: (ctx) {
        final fs = MediaQuery.of(ctx).size.width.clamp(320.0, 430.0);
        return AlertDialog(
          backgroundColor: const Color(0xFF10232C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
          title: Text(
            'Удалить студента?',
            style: TextStyle(color: Colors.white, fontSize: fs * 0.045),
          ),
          content: Text(
            '${student.lastName} ${student.firstName} будет удалён из списка.',
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Отмена',
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await StudentService.deleteStudent(student.studentId);
                AttendanceService.invalidateCache();
                await _refresh();
              },
              child: Text(
                'Удалить',
                style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.036, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoGroupScaffold(double w, double h) {
    final fs = w.clamp(320.0, 430.0);
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
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(fs * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(fs * 0.06),
                decoration: BoxDecoration(color: const Color(0xFF0D59F2).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.group_add_outlined, color: const Color(0xFF0D59F2), size: fs * 0.14),
              ),
              SizedBox(height: fs * 0.04),
              Text(
                'Создайте группу',
                style: TextStyle(color: Colors.white, fontSize: fs * 0.052, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: fs * 0.02),
              Text(
                'Чтобы отмечать посещаемость, сначала создайте группу в разделе «Профиль»',
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;
    final sortedIndexes = _sortedIndexes;

    // Если нет группы — показываем заглушку
    if (!_isLoading && !_hasGroup) {
      return _buildNoGroupScaffold(w, h);
    }

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
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_attendance',
        onPressed: _addStudent,
        backgroundColor: const Color(0xFF0D59F2),
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2)))
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.03).add(EdgeInsets.only(top: h * 0.02)),
              child: Column(
                children: [
                  // Плашка отменённой пары
                  if (_isCancelledLesson && _currentLesson != null) ...[_buildCancelledBanner(w, h), SizedBox(height: h * 0.015)],
                  // Плашка занятия — только если есть активное занятие
                  if (_hasActiveLesson) ...[_buildCurrentLessonBanner(w, h), SizedBox(height: h * 0.01)],
                  // Кнопки действий: выбор пары + скопировать с прошлой
                  if (!_isWeekend && _todaySchedule.isNotEmpty) ...[_buildActionButtons(w, h), SizedBox(height: h * 0.012)],
                  _buildSearchField(w),
                  SizedBox(height: h * 0.018),
                  // Фильтры — только если есть активное занятие
                  if (_hasActiveLesson) ...[_buildFilterRow(w), SizedBox(height: h * 0.018)],
                  _buildStudentList(w, h, sortedIndexes),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons(double w, double h) {
    final isManual = _manualLessonIndex != null;
    return Row(
      children: [
        // Кнопка выбора пары
        Expanded(
          child: GestureDetector(
            onTap: _showLessonPicker,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: h * 0.012),
              decoration: BoxDecoration(
                color: isManual ? const Color(0xFF0D59F2).withValues(alpha: 0.12) : const Color(0xFF10232C),
                borderRadius: BorderRadius.circular(w * 0.035),
                border: Border.all(color: isManual ? const Color(0xFF0D59F2) : const Color(0xFF455664)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isManual ? Icons.swap_horiz_rounded : Icons.list_alt_rounded, color: isManual ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), size: w * 0.045),
                  SizedBox(width: w * 0.015),
                  Text(
                    isManual ? 'Пара выбрана' : 'Выбрать пару',
                    style: TextStyle(color: isManual ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), fontSize: w * 0.032, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: w * 0.025),
        // Кнопка «Как на прошлой паре»
        Expanded(
          child: GestureDetector(
            onTap: _hasActiveLesson ? _copyFromPrevious : null,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: h * 0.012),
              decoration: BoxDecoration(
                color: _hasActiveLesson ? const Color(0xFF34D399).withValues(alpha: 0.1) : const Color(0xFF10232C).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(w * 0.035),
                border: Border.all(color: _hasActiveLesson ? const Color(0xFF34D399).withValues(alpha: 0.5) : const Color(0xFF455664).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.content_copy_rounded, color: _hasActiveLesson ? const Color(0xFF34D399) : const Color(0xFF455664), size: w * 0.04),
                  SizedBox(width: w * 0.015),
                  Flexible(
                    child: Text(
                      'Как на прошлой',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _hasActiveLesson ? const Color(0xFF34D399) : const Color(0xFF455664), fontSize: w * 0.03, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledBanner(double w, double h) {
    final subject = _currentLesson?.subject ?? '';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.014),
      decoration: BoxDecoration(
        color: const Color(0xFFF87171).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFF87171).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(w * 0.03)),
            child: Text(
              'ОТМЕНЕНА',
              style: TextStyle(color: const Color(0xFFF87171), fontSize: w * 0.028, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              subject.isNotEmpty ? subject : 'Пара отменена',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: const Color(0xFFF87171), fontSize: w * 0.036, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.cancel_outlined, color: const Color(0xFFF87171).withValues(alpha: 0.7), size: w * 0.05),
        ],
      ),
    );
  }

  Widget _buildCurrentLessonBanner(double w, double h) {
    if (_currentLesson == null || !_hasActiveLesson) return const SizedBox.shrink();
    final lesson = _currentLesson!;
    final active = _activeLesson;
    final isNow = active != null && AttendanceService.lessonKey(active.timeStart, active.timeEnd) == lesson.lessonKey;
    final isManual = _manualLessonIndex != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: isNow ? const Color(0xFF0D59F2) : (isManual ? const Color(0xFFFACC15) : const Color(0xFF455664)), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: 3),
                decoration: BoxDecoration(color: isManual ? const Color(0xFFFACC15).withValues(alpha: 0.15) : (isNow ? const Color(0x200D59F2) : const Color(0x20455664)), borderRadius: BorderRadius.circular(w * 0.03)),
                child: Text(
                  isManual ? 'РУЧНОЙ ВЫБОР' : (isNow ? 'ИДЁТ СЕЙЧАС' : 'СЛЕДУЮЩАЯ'),
                  style: TextStyle(color: isManual ? const Color(0xFFFACC15) : (isNow ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1)), fontSize: w * 0.028, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: w * 0.02),
              Text(
                lesson.lessonKey.replaceAll('-', ' – '),
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.032),
              ),
            ],
          ),
          SizedBox(height: h * 0.005),
          Row(
            children: [
              Expanded(
                child: Text(
                  lesson.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: w * 0.04, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: w * 0.02),
              _miniStat(w, Colors.green, '${lesson.presentCount}'),
              SizedBox(width: w * 0.025),
              _miniStat(w, Colors.red, '${lesson.absentCount}'),
              SizedBox(width: w * 0.025),
              _miniStat(w, Colors.orange, '${lesson.lateCount}'),
              SizedBox(width: w * 0.025),
              Text(
                '${lesson.markedCount}/${lesson.totalCount}',
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.03),
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: w * 0.01),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: w * 0.032, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSearchField(double w) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E2D36), borderRadius: BorderRadius.circular(w * 0.04)),
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
        Expanded(
          child: _buildFilterChip(label: 'ПРИСУТСТВУЕТ', color: Colors.green, w: w, onTap: () => _showStudentsByStatus('present', Colors.green, 'Присутствуют')),
        ),
        SizedBox(width: w * 0.02),
        Expanded(
          child: _buildFilterChip(label: 'ОТСУТСТВУЕТ', color: Colors.red, w: w, onTap: () => _showStudentsByStatus('absent', Colors.red, 'Отсутствуют')),
        ),
        SizedBox(width: w * 0.02),
        Expanded(
          child: _buildFilterChip(label: 'УВАЖ. ПРИЧИНА', color: Colors.orange, w: w, onTap: () => _showStudentsByStatus('late', Colors.orange, 'Уваж. причина')),
        ),
      ],
    );
  }

  Widget _buildFilterChip({required String label, required Color color, required double w, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
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
      ),
    );
  }

  Widget _buildStudentList(double w, double h, List<int> sortedIndexes) {
    // Список всегда показывается
    final students = _currentLesson?.students ?? [];
    final indexes = sortedIndexes;

    if (students.isEmpty) {
      return Expanded(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF0D59F2),
          backgroundColor: const Color(0xFF10232C),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: h * 0.25),
              Center(
                child: Text(
                  'Нет данных о студентах',
                  style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.045),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF0D59F2),
        backgroundColor: const Color(0xFF10232C),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: indexes.length,
          separatorBuilder: (_, _) => SizedBox(height: h * 0.01),
          itemBuilder: (context, i) {
            final idx = indexes[i];
            final student = students[idx];
            final hasStatus = student.status != null;

            return GestureDetector(
              onTap: () => _openProfile(student),
              onLongPress: () => _confirmDelete(student),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: _hasActiveLesson ? h * 0.013 : h * 0.015),
                decoration: BoxDecoration(
                  color: const Color(0xFF10232C),
                  borderRadius: BorderRadius.circular(w * 0.04),
                  border: Border.all(color: const Color(0xFF455664), width: 1),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        _studentAvatar(student, _hasActiveLesson ? w * 0.065 : w * 0.055),
                        if (hasStatus && _hasActiveLesson)
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
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: _hasActiveLesson
                          // Два ряда — обычный режим с занятием
                          ? Text(
                              '${student.lastName}\n${student.firstName}',
                              style: TextStyle(color: Colors.white, fontSize: w * 0.04, fontWeight: FontWeight.w600, height: 1.3),
                            )
                          // Один ряд — режим без занятия / выходной
                          : Text(
                              '${student.lastName} ${student.firstName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white, fontSize: w * 0.038, fontWeight: FontWeight.w500),
                            ),
                    ),
                    // Кнопка только если есть активное занятие
                    if (_hasActiveLesson)
                      ElevatedButton(
                        onPressed: () => _showStatusSheet(context, idx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasStatus ? _statusColor(student.status).withValues(alpha: 0.15) : const Color(0xFF0D59F2),
                          foregroundColor: hasStatus ? _statusColor(student.status) : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.04)),
                          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.011),
                          side: hasStatus ? BorderSide(color: _statusColor(student.status), width: 1) : BorderSide.none,
                        ),
                        child: Text(
                          hasStatus ? 'Изменить' : 'Отметить',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: w * 0.034),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _studentAvatar(StudentAttendance sa, double radius) {
    final full = _findFullStudent(sa);
    final avatarUrl = full?.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundColor: const Color(0xFF3A5FCD), backgroundImage: NetworkImage(avatarUrl));
    }
    final asset = (full?.isMale ?? true) ? 'assets/images/man_avatar.png' : 'assets/images/women_avatar.png';
    return CircleAvatar(radius: radius, backgroundImage: AssetImage(asset), backgroundColor: const Color(0xFF3A5FCD));
  }

  Widget _buildStatusOption({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
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
