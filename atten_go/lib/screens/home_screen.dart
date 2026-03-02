import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/attendance_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Lesson> _lessons = [];
  LessonAttendance? _currentLessonStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await ScheduleService.getTodayLessons();
    setState(() => _lessons = lessons);
    await _loadAttendanceStats();
    setState(() => _isLoading = false);
  }

  Future<void> _loadAttendanceStats() async {
    if (AttendanceService.isWeekend || _lessons.isEmpty) return;

    Lesson? activeLesson;
    for (final l in _lessons) {
      if (getLessonStatus(l.timeStart, l.timeEnd) == LessonStatus.active) {
        activeLesson = l;
        break;
      }
    }
    activeLesson ??= _lessons.firstWhere(
      (l) => getLessonStatus(l.timeStart, l.timeEnd) == LessonStatus.upcoming,
      orElse: () => _lessons.first,
    );

    final stats = await AttendanceService.getCurrentLessonStats(
      date:      AttendanceService.todayDate(),
      lessonKey: AttendanceService.lessonKey(activeLesson.timeStart, activeLesson.timeEnd),
    );
    setState(() => _currentLessonStats = stats);
  }

  int get _remainingCount =>
      _lessons.where((l) => getLessonStatus(l.timeStart, l.timeEnd) != LessonStatus.past).length;

  Lesson? get _nextLesson {
    for (final l in _lessons) {
      final s = getLessonStatus(l.timeStart, l.timeEnd);
      if (s == LessonStatus.active || s == LessonStatus.upcoming) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double w = mq.size.width;
    final double h = mq.size.height;

    // Адаптивные размеры — зажаты между min и max чтобы не ломалось на маленьких/больших экранах
    final double fs     = w.clamp(320.0, 430.0); // base для шрифтов
    final double hPad   = w * 0.04;
    final double vPad   = h * 0.015;

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101C22),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            SizedBox(
              height: 44,
              width: 44,
              child: ClipOval(child: Image.asset('assets/images/man_avatar.png', fit: BoxFit.cover)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Привет, Егор!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (fs * 0.058).clamp(18.0, 24.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Староста • 3 курс',
                  style: TextStyle(
                    color: const Color(0xFF7D92B1),
                    fontSize: (fs * 0.033).clamp(11.0, 14.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2)))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 24),
              child: Column(
                children: [
                  _buildLessonsCard(fs, h),
                  SizedBox(height: h * 0.025),
                  _buildScheduleToday(fs, h, w),
                  SizedBox(height: h * 0.025),
                  _buildAttendanceGroup(fs, h),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // ── Карточка «Оставшиеся занятия» ──────────────────────────────────────────
  Widget _buildLessonsCard(double fs, double h) {
    final next = _nextLesson;
    final nextLabel = next != null
        ? 'След.: ${next.subject.split(' ').first} | ${next.timeStart}'
        : 'Занятий больше нет';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D59F2),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x300D59F2), blurRadius: 16, spreadRadius: 2, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Оставшиеся занятия',
                  style: TextStyle(color: Colors.white70, fontSize: (fs * 0.033).clamp(11.0, 14.0)),
                ),
                const SizedBox(height: 4),
                Text(
                  _lessons.isEmpty ? '—' : '$_remainingCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (fs * 0.18).clamp(48.0, 72.0),
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x25FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    nextLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: (fs * 0.031).clamp(10.0, 13.0)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Color(0x15FFFFFF), shape: BoxShape.circle),
            child: Icon(Icons.calendar_today_rounded, color: Colors.white, size: (fs * 0.1).clamp(28.0, 40.0)),
          ),
        ],
      ),
    );
  }

  // ── Расписание на сегодня ───────────────────────────────────────────────────
  Widget _buildScheduleToday(double fs, double h, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Расписание на сегодня',
              style: TextStyle(color: Colors.white, fontSize: (fs * 0.048).clamp(15.0, 20.0)),
            ),
            Text(
              'Все',
              style: TextStyle(color: const Color(0xFF0D59F2), fontSize: (fs * 0.044).clamp(14.0, 18.0)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lessons.isEmpty)
          Text(
            'Сегодня занятий нет',
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: (fs * 0.038).clamp(13.0, 16.0)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _lessons.map((lesson) {
                final status = getLessonStatus(lesson.timeStart, lesson.timeEnd);
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildScheduleCard(fs, h, w, lesson: lesson, status: status),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Карточка занятия ────────────────────────────────────────────────────────
  Widget _buildScheduleCard(double fs, double h, double w, {required Lesson lesson, required LessonStatus status}) {
    final bool isActive = status == LessonStatus.active;
    final bool isPast   = status == LessonStatus.past;

    final Color color = isActive
        ? const Color(0xFF0D59F2)
        : isPast ? const Color(0xFF455664) : const Color(0xFF94A3B8);
    final Color bgColor = isActive
        ? const Color(0x200D59F2)
        : isPast ? const Color(0x20455664) : const Color(0x2094A3B8);
    final Color borderColor = isActive
        ? const Color(0xFF0D59F2)
        : isPast ? const Color(0x40455664) : const Color(0x4094A3B8);
    final String label = isActive ? 'В ПРОЦЕССЕ' : isPast ? 'ПРОШЛО' : 'ОЖИДАЕТСЯ';

    // Ширина карточки — 75% экрана, но не меньше 240 и не больше 320
    final double cardWidth = (w * 0.75).clamp(240.0, 320.0);

    return Container(
      padding: const EdgeInsets.all(16),
      width: cardWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: (fs * 0.03).clamp(10.0, 13.0), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.access_time_filled, color: color, size: (fs * 0.065).clamp(20.0, 28.0)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lesson.subject,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPast ? const Color(0xFF7D92B1) : Colors.white,
              fontSize: (fs * 0.046).clamp(14.0, 19.0),
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${lesson.room} • ${lesson.teacher}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: (fs * 0.032).clamp(10.0, 14.0)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, color: const Color(0xFF7D92B1), size: (fs * 0.037).clamp(12.0, 16.0)),
              const SizedBox(width: 6),
              Text(
                '${lesson.timeStart} – ${lesson.timeEnd}',
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: (fs * 0.032).clamp(10.0, 14.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Посещаемость группы ─────────────────────────────────────────────────────
  Widget _buildAttendanceGroup(double fs, double h) {
    final stats     = _currentLessonStats;
    final isWeekend = AttendanceService.isWeekend;

    int present = 0, absent = 0, late = 0, total = 0;
    String percentage = '—';

    if (stats != null && stats.markedCount > 0) {
      present    = stats.presentCount;
      absent     = stats.absentCount;
      late       = stats.lateCount;
      total      = stats.totalCount;
      percentage = '${((present / total) * 100).round()}%';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Посещаемость группы',
          style: TextStyle(color: Colors.white, fontSize: (fs * 0.048).clamp(15.0, 20.0)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF10232C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x4094A3B8), width: 1.5),
          ),
          child: isWeekend
              ? _buildPlaceholder(fs, icon: Icons.weekend_outlined, text: 'Сегодня выходной')
              : stats == null
                  ? _buildPlaceholder(fs, icon: Icons.people_outline, text: 'Никто ещё не отмечен')
                  : Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D59F2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            stats.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF0D59F2),
                              fontSize: (fs * 0.031).clamp(10.0, 13.0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // Круг с процентом
                            SizedBox(
                              width: 88,
                              height: 88,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF0D59F2), width: 6),
                                      color: const Color(0xFF10232C),
                                    ),
                                  ),
                                  Text(
                                    percentage,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: (fs * 0.055).clamp(16.0, 22.0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStatRow(fs, const Color(0xFF0D59F2), 'Присутствует', '$present'),
                                  const SizedBox(height: 10),
                                  _buildStatRow(fs, const Color(0xFFF87171), 'Отсутствуют', '$absent'),
                                  const SizedBox(height: 10),
                                  _buildStatRow(fs, const Color(0xFFFACC15), 'Причина', '$late'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Отмечено: ${stats.markedCount} из $total',
                          style: TextStyle(
                            color: const Color(0xFF7D92B1),
                            fontSize: (fs * 0.032).clamp(10.0, 14.0),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Подробный отчет',
                          style: TextStyle(
                            color: const Color(0xFF0D59F2),
                            fontSize: (fs * 0.042).clamp(13.0, 17.0),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(double fs, {required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF455664), size: (fs * 0.12).clamp(36.0, 52.0)),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: (fs * 0.036).clamp(12.0, 15.0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(double fs, Color dotColor, String label, String value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: (fs * 0.038).clamp(12.0, 16.0)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: (fs * 0.038).clamp(12.0, 16.0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}