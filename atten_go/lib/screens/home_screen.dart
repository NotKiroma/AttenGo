import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'notification_screen.dart';
import '../utils/dark_page_route.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSchedule;
  final VoidCallback? onNavigateToStats;

  const HomeScreen({super.key, this.onNavigateToSchedule, this.onNavigateToStats});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Lesson> _lessons = [];
  LessonAttendance? _currentLessonStats;
  bool _isLoading = true;
  UserProfile? _profile;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await ScheduleService.getTodayLessons();
    final profile = await AuthService.getProfile();
    final unread = await NotificationService.unreadCount();
    setState(() {
      _lessons = lessons;
      _profile = profile;
      _unreadCount = unread;
    });
    await _loadAttendanceStats();
    setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    final lessons = await ScheduleService.getTodayLessons();
    final profile = await AuthService.getProfile();
    final unread = await NotificationService.unreadCount();
    setState(() {
      _lessons = lessons;
      _profile = profile;
      _unreadCount = unread;
    });
    await _loadAttendanceStats();
    setState(() {});
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
    activeLesson ??= _lessons.firstWhere((l) => getLessonStatus(l.timeStart, l.timeEnd) == LessonStatus.upcoming, orElse: () => _lessons.first);
    final stats = await AttendanceService.getCurrentLessonStats(date: AttendanceService.todayDate(), lessonKey: AttendanceService.lessonKey(activeLesson.timeStart, activeLesson.timeEnd));
    setState(() => _currentLessonStats = stats);
  }

  int get _remainingCount => _lessons.where((l) => getLessonStatus(l.timeStart, l.timeEnd) != LessonStatus.past).length;

  Lesson? get _nextLesson {
    for (final l in _lessons) {
      final s = getLessonStatus(l.timeStart, l.timeEnd);
      if (s == LessonStatus.active || s == LessonStatus.upcoming) return l;
    }
    return null;
  }

  void _openNotifications() async {
    await Navigator.push(context, DarkPageRoute(builder: (_) => const NotificationScreen()));
    // Полностью обновляем — пользователь мог принять приглашение
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double w = mq.size.width;
    final double h = mq.size.height;
    final double fs = w.clamp(320.0, 430.0);
    final double hPad = w * 0.04;
    final double vPad = h * 0.015;

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101C22),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: h * 0.085,
        title: Row(
          children: [
            // Аватарка как в профиле
            _buildAvatar(fs),
            SizedBox(width: fs * 0.03),
            Expanded(
              child: Text(
                'Привет, ${_profile?.firstName ?? ''}!',
                style: TextStyle(color: Colors.white, fontSize: (fs * 0.058).clamp(18.0, 24.0), fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Центр уведомлений
          Padding(
            padding: EdgeInsets.only(right: w * 0.02),
            child: GestureDetector(
              onTap: _openNotifications,
              child: Stack(
                children: [
                  Container(
                    width: fs * 0.11,
                    height: fs * 0.11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10232C),
                      borderRadius: BorderRadius.circular(fs * 0.04),
                      border: Border.all(color: const Color(0xFF455664), width: 1),
                    ),
                    child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: fs * 0.055),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: fs * 0.045,
                        height: fs * 0.045,
                        decoration: const BoxDecoration(color: Color(0xFFF87171), shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: TextStyle(color: Colors.white, fontSize: fs * 0.022, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2)))
          : RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF0D59F2),
              backgroundColor: const Color(0xFF10232C),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, h * 0.03),
                child: Column(
                  children: [
                    _buildLessonsCard(fs, h, w),
                    SizedBox(height: h * 0.025),
                    _buildScheduleToday(fs, h, w),
                    SizedBox(height: h * 0.025),
                    _buildAttendanceGroup(fs, h, w),
                    SizedBox(height: h * 0.02),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar(double fs) {
    final size = fs * 0.13;
    final url = _profile?.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0D59F2), width: 2),
        ),
        child: ClipOval(
          child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initialsAvatar(fs, size)),
        ),
      );
    }
    return _initialsAvatar(fs, size);
  }

  Widget _initialsAvatar(double fs, double size) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(color: Color(0xFF0D59F2), shape: BoxShape.circle),
      child: Center(
        child: Text(
          _profile?.initials ?? '?',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Карточка «Оставшиеся занятия» ──
  Widget _buildLessonsCard(double fs, double h, double w) {
    final next = _nextLesson;
    final nextLabel = next != null ? 'След.: ${next.subject.split(' ').first} | ${next.timeStart}' : 'Занятий больше нет';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fs * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFF0D59F2),
        borderRadius: BorderRadius.circular(fs * 0.04),
        boxShadow: const [BoxShadow(color: Color(0x300D59F2), blurRadius: 16, spreadRadius: 2, offset: Offset(0, 8))],
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
                SizedBox(height: h * 0.005),
                Text(
                  _lessons.isEmpty ? '—' : '$_remainingCount',
                  style: TextStyle(color: Colors.white, fontSize: (fs * 0.16).clamp(44.0, 68.0), fontWeight: FontWeight.bold, height: 1.0),
                ),
                SizedBox(height: h * 0.01),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: fs * 0.03, vertical: fs * 0.015),
                  decoration: BoxDecoration(color: const Color(0x25FFFFFF), borderRadius: BorderRadius.circular(fs * 0.04)),
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
          SizedBox(width: fs * 0.03),
          Container(
            width: fs * 0.18,
            height: fs * 0.18,
            decoration: const BoxDecoration(color: Color(0x15FFFFFF), shape: BoxShape.circle),
            child: Icon(Icons.calendar_today_rounded, color: Colors.white, size: fs * 0.085),
          ),
        ],
      ),
    );
  }

  // ── Расписание на сегодня ──
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
            GestureDetector(
              onTap: widget.onNavigateToSchedule,
              child: Text(
                'Все',
                style: TextStyle(color: const Color(0xFF0D59F2), fontSize: (fs * 0.042).clamp(13.0, 17.0)),
              ),
            ),
          ],
        ),
        SizedBox(height: h * 0.015),
        if (_lessons.isEmpty)
          Text(
            'Сегодня занятий нет',
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: (fs * 0.038).clamp(13.0, 16.0)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _lessons.map((lesson) {
                  final status = getLessonStatus(lesson.timeStart, lesson.timeEnd);
                  return Padding(
                    padding: EdgeInsets.only(right: fs * 0.03),
                    child: _buildScheduleCard(fs, h, w, lesson: lesson, status: status),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleCard(double fs, double h, double w, {required Lesson lesson, required LessonStatus status}) {
    final bool isActive = status == LessonStatus.active;
    final bool isPast = status == LessonStatus.past;
    final Color color = isActive
        ? const Color(0xFF0D59F2)
        : isPast
        ? const Color(0xFF455664)
        : const Color(0xFF94A3B8);
    final Color bgColor = isActive
        ? const Color(0x200D59F2)
        : isPast
        ? const Color(0x20455664)
        : const Color(0x2094A3B8);
    final Color borderColor = isActive
        ? const Color(0xFF0D59F2)
        : isPast
        ? const Color(0x40455664)
        : const Color(0x4094A3B8);
    final String label = isActive
        ? 'В ПРОЦЕССЕ'
        : isPast
        ? 'ПРОШЛО'
        : 'ОЖИДАЕТСЯ';
    final double cardWidth = (w * 0.65).clamp(220.0, 280.0);

    return Container(
      padding: EdgeInsets.all(fs * 0.04),
      width: cardWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: fs * 0.01),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(fs * 0.04)),
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: (fs * 0.028).clamp(9.0, 12.0), fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: fs * 0.02),
              Icon(Icons.access_time_filled, color: color, size: fs * 0.055),
            ],
          ),
          SizedBox(height: h * 0.012),
          Text(
            lesson.subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isPast ? const Color(0xFF7D92B1) : Colors.white, fontSize: (fs * 0.042).clamp(13.0, 18.0), fontWeight: FontWeight.bold, height: 1.25),
          ),
          SizedBox(height: h * 0.006),
          Text(
            '${lesson.room} • ${lesson.teacher}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: (fs * 0.03).clamp(10.0, 13.0)),
          ),
          const Spacer(),
          SizedBox(height: h * 0.012),
          Row(
            children: [
              Icon(Icons.schedule, color: const Color(0xFF7D92B1), size: fs * 0.035),
              SizedBox(width: fs * 0.015),
              Text(
                '${lesson.timeStart} – ${lesson.timeEnd}',
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: (fs * 0.03).clamp(10.0, 13.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Посещаемость группы ──
  Widget _buildAttendanceGroup(double fs, double h, double w) {
    final stats = _currentLessonStats;
    final isWeekend = AttendanceService.isWeekend;
    int present = 0, absent = 0, late_ = 0, total = 0;
    String percentage = '—';
    if (stats != null && stats.markedCount > 0) {
      present = stats.presentCount;
      absent = stats.absentCount;
      late_ = stats.lateCount;
      total = stats.totalCount;
      percentage = '${((present / total) * 100).round()}%';
    }
    final double circleSize = fs * 0.28;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Посещаемость группы',
          style: TextStyle(color: Colors.white, fontSize: (fs * 0.048).clamp(15.0, 20.0)),
        ),
        SizedBox(height: h * 0.015),
        Container(
          padding: EdgeInsets.all(fs * 0.04),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF10232C),
            borderRadius: BorderRadius.circular(fs * 0.04),
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
                      padding: EdgeInsets.symmetric(horizontal: fs * 0.03, vertical: fs * 0.015),
                      margin: EdgeInsets.only(bottom: h * 0.015),
                      decoration: BoxDecoration(color: const Color(0xFF0D59F2).withOpacity(0.1), borderRadius: BorderRadius.circular(fs * 0.04)),
                      child: Text(
                        stats.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: const Color(0xFF0D59F2), fontSize: (fs * 0.031).clamp(10.0, 13.0), fontWeight: FontWeight.w600),
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: circleSize,
                          height: circleSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF0D59F2), width: fs * 0.015),
                                  color: const Color(0xFF10232C),
                                ),
                              ),
                              Text(
                                percentage,
                                style: TextStyle(color: Colors.white, fontSize: (fs * 0.065).clamp(20.0, 28.0), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: fs * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatRow(fs, const Color(0xFF0D59F2), 'Присутствует', '$present'),
                              SizedBox(height: h * 0.012),
                              _buildStatRow(fs, const Color(0xFFF87171), 'Отсутствуют', '$absent'),
                              SizedBox(height: h * 0.012),
                              _buildStatRow(fs, const Color(0xFFFACC15), 'Причина', '$late_'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.015),
                    GestureDetector(
                      onTap: widget.onNavigateToStats,
                      child: Text(
                        'Подробный отчет',
                        style: TextStyle(color: const Color(0xFF0D59F2), fontSize: (fs * 0.042).clamp(13.0, 17.0), fontWeight: FontWeight.w500),
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
      padding: EdgeInsets.symmetric(vertical: fs * 0.05),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF455664), size: fs * 0.12),
            SizedBox(height: fs * 0.02),
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
        Container(
          width: fs * 0.025,
          height: fs * 0.025,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: fs * 0.02),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: (fs * 0.036).clamp(12.0, 15.0)),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: (fs * 0.036).clamp(12.0, 15.0), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
