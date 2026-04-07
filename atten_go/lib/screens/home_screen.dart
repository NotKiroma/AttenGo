import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/group_service.dart';
import '../services/announcement_service.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/realtime_service.dart';
import 'notification_screen.dart';
import '../utils/dark_page_route.dart';
import '../utils/plural_utils.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSchedule;
  final VoidCallback? onNavigateToStats;
  final VoidCallback? onRoleChanged;

  const HomeScreen({super.key, this.onNavigateToSchedule, this.onNavigateToStats, this.onRoleChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Lesson> _lessons = [];
  LessonAttendance? _currentLessonStats;
  bool _isLoading = true;
  UserProfile? _profile;
  int _unreadCount = 0;
  List<GroupInvitation> _pendingInvitations = [];
  List<Announcement> _announcements = [];
  bool _canManage = false;
  Set<String> _cancelledLessons = {}; // lessonKey отменённых пар + 'all'

  // Подписки на Realtime-стримы
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _load();

    // Слушаем изменения через центральный RealtimeService
    _subs.add(
      RealtimeService.onAnnouncementsChanged.listen((_) {
        developer.log('[HomeScreen] announcements changed');
        if (mounted) _refresh();
      }),
    );
    _subs.add(
      RealtimeService.onNotificationsChanged.listen((_) {
        developer.log('[HomeScreen] notifications changed');
        if (mounted) _refresh();
      }),
    );
    _subs.add(
      RealtimeService.onScheduleChanged.listen((_) {
        developer.log('[HomeScreen] schedule changed');
        if (mounted) _refresh();
      }),
    );
    _subs.add(
      RealtimeService.onAttendanceRecordsChanged.listen((_) {
        developer.log('[HomeScreen] attendance changed');
        if (mounted) _refresh();
      }),
    );
    _subs.add(
      RealtimeService.onStudentsChanged.listen((_) {
        developer.log('[HomeScreen] students changed');
        if (mounted) _refresh();
      }),
    );
    _subs.add(
      RealtimeService.onInvitationsChanged.listen((_) {
        developer.log('[HomeScreen] invitations changed');
        if (mounted) _refresh();
      }),
    );
  }

  @override
  void dispose() {
    // Закрываем все подписки Realtime
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();

    super.dispose();
  }

  Future<void> _load() async {
    await _fetchData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refresh() => _fetchData();

  Future<void> _fetchData() async {
    // Все независимые запросы — параллельно
    final results = await Future.wait([
      ScheduleService.getTodayLessons(), // [0]
      AuthService.getProfile(), // [1]
      NotificationService.unreadCount(), // [2]
      GroupService.getMyInvitations(), // [3]
      AnnouncementService.loadAll(), // [4]
      GroupService.canManage(), // [5]
    ]);

    final lessons = results[0] as List<Lesson>;
    final profile = results[1] as UserProfile?;
    final unread = results[2] as int;
    final invitations = results[3] as List<GroupInvitation>;
    final announcements = results[4] as List<Announcement>;
    final canManage = results[5] as bool;

    // Проверяем отмены параллельно — после того как получили уроки
    final cancelled = await _loadCancelledLessons(lessons);

    if (mounted) {
      setState(() {
        _lessons = lessons;
        _profile = profile;
        _unreadCount = unread;
        _pendingInvitations = invitations;
        _announcements = announcements;
        _canManage = canManage;
        _cancelledLessons = cancelled;
      });
    }

    // Статистика посещаемости — загружаем после основных данных
    await _loadAttendanceStats(lessons, cancelled);
  }

  Future<Set<String>> _loadCancelledLessons(List<Lesson> lessons) async {
    final date = AttendanceService.todayDate();
    // Один запрос к локальной БД вместо N вызовов isCancelled
    return AnnouncementService.getCancelledLessonKeys(date: date);
  }

  Future<void> _loadAttendanceStats(List<Lesson> lessons, Set<String> cancelled) async {
    if (AttendanceService.isWeekend || lessons.isEmpty) return;
    if (cancelled.contains('all')) {
      if (mounted) setState(() => _currentLessonStats = null);
      return;
    }
    final date = AttendanceService.todayDate();

    // Проверяем все пары прошли
    final allPast = lessons.every((l) => getLessonStatus(l.timeStart, l.timeEnd) == LessonStatus.past);

    if (allPast) {
      // Показываем суммарную посещаемость за день — берём все уроки и суммируем
      final allLessons = await AttendanceService.loadAll();
      final todayLessons = allLessons.where((la) => la.date == date && la.lessonKey != 'weekend').toList();
      if (todayLessons.isEmpty || todayLessons.every((la) => la.markedCount == 0)) {
        if (mounted) setState(() => _currentLessonStats = null);
        return;
      }
      // Собираем агрегированную статистику — создаём синтетический LessonAttendance
      final allStudents = todayLessons.expand((la) => la.students).toList();
      // Уникальные студенты с лучшим статусом (present > late > absent)
      final Map<String, String?> bestStatus = {};
      for (final s in allStudents) {
        if (s.status == null) continue;
        final cur = bestStatus[s.studentId];
        if (cur == null || (s.status == 'present') || (cur == 'absent' && s.status == 'late')) {
          bestStatus[s.studentId] = s.status;
        }
      }
      final summaryStudents = bestStatus.entries.map((e) {
        final orig = allStudents.firstWhere((s) => s.studentId == e.key);
        return StudentAttendance(studentId: e.key, lastName: orig.lastName, firstName: orig.firstName, isMale: orig.isMale, status: e.value);
      }).toList();
      final summary = LessonAttendance(date: date, lessonKey: 'day_summary', subject: 'Итог за день', students: summaryStudents);
      if (mounted) setState(() => _currentLessonStats = summary);
      return;
    }

    Lesson? activeLesson;
    for (final l in lessons) {
      if (getLessonStatus(l.timeStart, l.timeEnd) == LessonStatus.active) {
        activeLesson = l;
        break;
      }
    }
    activeLesson ??= lessons.firstWhere((l) => getLessonStatus(l.timeStart, l.timeEnd) == LessonStatus.upcoming, orElse: () => lessons.first);

    final key = AttendanceService.lessonKey(activeLesson.timeStart, activeLesson.timeEnd);
    if (cancelled.contains(key)) {
      if (mounted) setState(() => _currentLessonStats = null);
      return;
    }

    final stats = await AttendanceService.getCurrentLessonStats(date: date, lessonKey: key);
    if (mounted) setState(() => _currentLessonStats = stats);
  }

  int get _remainingCount => _lessons.where((l) => getLessonStatus(l.timeStart, l.timeEnd) != LessonStatus.past).length;

  /// Активная пара прямо сейчас (для счётчика и статистики)
  Lesson? get _activeLesson {
    for (final l in _lessons) {
      if (getLessonStatus(l.timeStart, l.timeEnd) == LessonStatus.active) return l;
    }
    return null;
  }

  /// Следующая пара (только upcoming, для надписи "След.:")
  Lesson? get _nextLesson {
    for (final l in _lessons) {
      if (getLessonStatus(l.timeStart, l.timeEnd) == LessonStatus.upcoming) return l;
    }
    return null;
  }

  void _openNotifications() async {
    final roleChanged = await Navigator.push<bool>(context, DarkPageRoute(builder: (_) => const NotificationScreen()));
    _refresh();
    if (roleChanged == true && mounted) {
      widget.onRoleChanged?.call();
    }
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
                    if (_pendingInvitations.isNotEmpty) ...[_buildInvitationBanner(fs, h), SizedBox(height: h * 0.02)],
                    _buildLessonsCard(fs, h, w),
                    SizedBox(height: h * 0.025),
                    _buildScheduleToday(fs, h, w),
                    if (_canManage) ...[SizedBox(height: h * 0.025), _buildAttendanceGroup(fs, h, w)],
                    if (_announcements.isNotEmpty || _canManage) ...[SizedBox(height: h * 0.025), _buildAnnouncements(fs, h)],
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
          child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => _initialsAvatar(fs, size)),
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

  // ── Баннер приглашений ──
  Widget _buildInvitationBanner(double fs, double h) {
    final count = _pendingInvitations.length;
    return GestureDetector(
      onTap: _openNotifications,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: fs * 0.045, vertical: fs * 0.035),
        decoration: BoxDecoration(
          color: const Color(0xFF0D59F2).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(fs * 0.04),
          border: Border.all(color: const Color(0xFF0D59F2).withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(fs * 0.02),
              decoration: BoxDecoration(color: const Color(0xFF0D59F2).withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.group_add_rounded, color: const Color(0xFF0D59F2), size: fs * 0.05),
            ),
            SizedBox(width: fs * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1 ? 'Приглашение в группу' : '$count ${pluralize(count, 'приглашение', 'приглашения', 'приглашений')} в группу',
                    style: TextStyle(color: Colors.white, fontSize: fs * 0.037, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Нажмите чтобы посмотреть',
                    style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.029),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: fs * 0.03, vertical: fs * 0.015),
              decoration: BoxDecoration(color: const Color(0xFF0D59F2), borderRadius: BorderRadius.circular(fs * 0.04)),
              child: Text(
                'Открыть',
                style: TextStyle(color: Colors.white, fontSize: fs * 0.031, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Объявления ──
  Widget _buildAnnouncements(double fs, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Объявления',
              style: TextStyle(color: Colors.white, fontSize: (fs * 0.048).clamp(15.0, 20.0)),
            ),
            if (_canManage)
              GestureDetector(
                onTap: _createAnnouncement,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: fs * 0.03, vertical: fs * 0.015),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D59F2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(fs * 0.04),
                    border: Border.all(color: const Color(0xFF0D59F2).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: const Color(0xFF0D59F2), size: fs * 0.04),
                      SizedBox(width: fs * 0.01),
                      Text(
                        'Создать',
                        style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.03, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: h * 0.012),
        if (_announcements.isEmpty && _canManage)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: h * 0.025),
            decoration: BoxDecoration(
              color: const Color(0xFF10232C),
              borderRadius: BorderRadius.circular(fs * 0.04),
              border: Border.all(color: const Color(0xFF455664).withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Icon(Icons.campaign_outlined, color: const Color(0xFF455664), size: fs * 0.1),
                SizedBox(height: fs * 0.02),
                Text(
                  'Объявлений пока нет',
                  style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.034),
                ),
                SizedBox(height: fs * 0.01),
                Text(
                  'Нажмите «Создать» чтобы добавить',
                  style: TextStyle(color: const Color(0xFF455664), fontSize: fs * 0.028),
                ),
              ],
            ),
          ),
        ..._announcements.map((a) => _announcementCard(fs, h, a)),
      ],
    );
  }

  Widget _announcementCard(double fs, double h, Announcement a) {
    final isCancel = a.isCancel;
    final color = isCancel ? const Color(0xFFF87171) : const Color(0xFF34D399);
    final icon = isCancel ? Icons.cancel_outlined : Icons.campaign_outlined;
    final radius = fs * 0.04;

    String timeLabel(DateTime? dt) {
      if (dt == null) return '';
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'только что';
      if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
      if (diff.inHours < 24) return '${diff.inHours} ч. назад';
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: h * 0.012),
      child: ClipRect(
        child: Stack(
          children: [
            // Красный фон — заходит левее чтобы перекрыть скругления карточки
            Positioned.fill(
              left: radius * 0.6,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF87171).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(radius), bottomRight: Radius.circular(radius), topLeft: Radius.circular(radius), bottomLeft: Radius.circular(radius)),
                ),
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: fs * 0.05),
                child: Icon(Icons.delete_outline, color: const Color(0xFFF87171), size: fs * 0.06),
              ),
            ),
            // Карточка поверх
            Dismissible(
              key: Key('ann_${a.id}'),
              direction: _canManage ? DismissDirection.endToStart : DismissDirection.none,
              onDismissed: (_) async {
                await AnnouncementService.delete(a.id);
                setState(() => _announcements.removeWhere((x) => x.id == a.id));
              },
              background: const SizedBox.shrink(),
              secondaryBackground: const SizedBox.shrink(),
              child: Container(
                padding: EdgeInsets.all(fs * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFF10232C),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(fs * 0.02),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(fs * 0.03)),
                      child: Icon(icon, color: color, size: fs * 0.048),
                    ),
                    SizedBox(width: fs * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a.title,
                                  style: TextStyle(color: Colors.white, fontSize: fs * 0.037, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (a.createdAt != null)
                                Text(
                                  timeLabel(a.createdAt),
                                  style: TextStyle(color: const Color(0xFF455664), fontSize: fs * 0.027),
                                ),
                            ],
                          ),
                          if (a.body.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              a.body,
                              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.031),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (a.authorName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              a.authorName!,
                              style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: fs * 0.027),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createAnnouncement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnnouncementSheet(
        onCreated: () {
          Navigator.pop(ctx);
          _refresh();
        },
      ),
    );
  }

  // ── Карточка «Оставшиеся занятия» ──
  Widget _buildLessonsCard(double fs, double h, double w) {
    final active = _activeLesson;
    final next = _nextLesson;
    final nextLabel = active != null
        ? 'Сейчас: ${active.subject.split(' ').first} | ${active.timeStart}'
        : next != null
        ? 'След.: ${next.subject.split(' ').first} | ${next.timeStart}'
        : 'Занятий больше нет';

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
                  final lessonKey = AttendanceService.lessonKey(lesson.timeStart, lesson.timeEnd);
                  final isCancelled = _cancelledLessons.contains('all') || _cancelledLessons.contains(lessonKey);
                  return Padding(
                    padding: EdgeInsets.only(right: fs * 0.03),
                    child: _buildScheduleCard(fs, h, w, lesson: lesson, status: status, isCancelled: isCancelled),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleCard(double fs, double h, double w, {required Lesson lesson, required LessonStatus status, bool isCancelled = false}) {
    final bool isActive = status == LessonStatus.active && !isCancelled;
    final bool isPast = status == LessonStatus.past;
    final Color color = isCancelled
        ? const Color(0xFFF87171)
        : isActive
        ? const Color(0xFF0D59F2)
        : isPast
        ? const Color(0xFF455664)
        : const Color(0xFF94A3B8);
    final Color bgColor = isCancelled
        ? const Color(0xFFF87171).withValues(alpha: 0.12)
        : isActive
        ? const Color(0x200D59F2)
        : isPast
        ? const Color(0x20455664)
        : const Color(0x2094A3B8);
    final Color borderColor = isCancelled
        ? const Color(0xFFF87171).withValues(alpha: 0.5)
        : isActive
        ? const Color(0xFF0D59F2)
        : isPast
        ? const Color(0x40455664)
        : const Color(0x4094A3B8);
    final String label = isCancelled
        ? 'ОТМЕНЕНА'
        : isActive
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
                      decoration: BoxDecoration(color: const Color(0xFF0D59F2).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(fs * 0.04)),
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
                              _buildStatRow(fs, const Color(0xFFFACC15), 'Уваж. причина', '$late_'),
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

// ═══════════════════════════════════════════════════════════════════════════════
// ШТОРКА СОЗДАНИЯ ОБЪЯВЛЕНИЯ
// ═══════════════════════════════════════════════════════════════════════════════

class _AnnouncementSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _AnnouncementSheet({required this.onCreated});

  @override
  State<_AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends State<_AnnouncementSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  bool _isSaving = false;
  String? _error;
  String _durationType = 'days'; // 'hours', 'days', 'forever'
  int _durationHours = 6;
  int _durationDays = 3;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Введите заголовок');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });

    DateTime? expiresAt;
    if (_durationType == 'hours') {
      expiresAt = DateTime.now().add(Duration(hours: _durationHours));
    } else if (_durationType == 'days') {
      expiresAt = DateTime.now().add(Duration(days: _durationDays));
    }

    final res = await AnnouncementService.create(title: title, body: _bodyCtrl.text.trim(), expiresAt: expiresAt);
    if (mounted) {
      if (res.success) {
        widget.onCreated();
      } else {
        setState(() {
          _isSaving = false;
          _error = res.error ?? 'Ошибка';
        });
      }
    }
  }

  Widget _typeBtn(double fs, String type, String label) {
    final selected = _durationType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _durationType = type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: fs * 0.022),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0D59F2).withValues(alpha: 0.15) : const Color(0xFF10232C),
            borderRadius: BorderRadius.circular(fs * 0.03),
            border: Border.all(color: selected ? const Color(0xFF0D59F2) : const Color(0xFF455664)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: selected ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), fontSize: fs * 0.03, fontWeight: selected ? FontWeight.w700 : FontWeight.normal),
            ),
          ),
        ),
      ),
    );
  }

  Widget _valueBtn(double fs, int val, List<int> allVals) {
    final selected = _durationType == 'hours' ? _durationHours == val : _durationDays == val;
    final isLast = allVals.last == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          if (_durationType == 'hours') {
            _durationHours = val;
          } else {
            _durationDays = val;
          }
        }),
        child: Container(
          margin: EdgeInsets.only(right: isLast ? 0 : fs * 0.02),
          padding: EdgeInsets.symmetric(vertical: fs * 0.022),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0D59F2).withValues(alpha: 0.15) : const Color(0xFF10232C),
            borderRadius: BorderRadius.circular(fs * 0.03),
            border: Border.all(color: selected ? const Color(0xFF0D59F2) : const Color(0xFF455664)),
          ),
          child: Center(
            child: Text(
              '$val',
              style: TextStyle(color: selected ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), fontSize: fs * 0.032, fontWeight: selected ? FontWeight.w700 : FontWeight.normal),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final fs = w.clamp(320.0, 430.0);
    final hourVals = [1, 2, 3, 6, 12];
    final dayVals = [1, 3, 7, 14];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF152028),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(fs * 0.05, fs * 0.04, fs * 0.05, fs * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: fs * 0.1,
                height: 4,
                margin: EdgeInsets.only(bottom: fs * 0.04),
                decoration: BoxDecoration(color: const Color(0xFF455664), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              'Новое объявление',
              style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: fs * 0.04),

            // Заголовок
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10232C),
                borderRadius: BorderRadius.circular(fs * 0.04),
                border: Border.all(color: const Color(0xFF455664)),
              ),
              child: TextField(
                controller: _titleCtrl,
                autofocus: true,
                style: TextStyle(color: Colors.white, fontSize: fs * 0.038),
                decoration: InputDecoration(
                  hintText: 'Заголовок',
                  hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
                  prefixIcon: Icon(Icons.campaign_outlined, color: const Color(0xFF7D92B1), size: fs * 0.05),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.038),
                ),
              ),
            ),
            SizedBox(height: fs * 0.025),

            // Текст
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10232C),
                borderRadius: BorderRadius.circular(fs * 0.04),
                border: Border.all(color: const Color(0xFF455664)),
              ),
              child: TextField(
                controller: _bodyCtrl,
                maxLines: 4,
                style: TextStyle(color: Colors.white, fontSize: fs * 0.036),
                decoration: InputDecoration(
                  hintText: 'Текст объявления (необязательно)',
                  hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.034),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(fs * 0.04),
                ),
              ),
            ),
            SizedBox(height: fs * 0.03),

            // Срок действия — заголовок
            Text(
              'Срок действия',
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.032, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: fs * 0.015),

            // Ряд 1 — тип
            Row(
              children: [
                _typeBtn(fs, 'hours', 'Часы'),
                SizedBox(width: fs * 0.02),
                _typeBtn(fs, 'days', 'Дни'),
                SizedBox(width: fs * 0.02),
                _typeBtn(fs, 'forever', 'Бессрочно'),
              ],
            ),

            // Ряд 2 — значения (анимированно появляются)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _durationType == 'forever'
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(top: fs * 0.015),
                      child: Row(children: (_durationType == 'hours' ? hourVals : dayVals).map((val) => _valueBtn(fs, val, _durationType == 'hours' ? hourVals : dayVals)).toList()),
                    ),
            ),

            // Ошибка
            if (_error != null) ...[
              SizedBox(height: fs * 0.025),
              Container(
                padding: EdgeInsets.all(fs * 0.03),
                decoration: BoxDecoration(
                  color: const Color(0xFFF87171).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(fs * 0.03),
                  border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: const Color(0xFFF87171), size: fs * 0.042),
                    SizedBox(width: fs * 0.02),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.033),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: fs * 0.05),

            // Кнопка
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D59F2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF455664),
                  padding: EdgeInsets.symmetric(vertical: fs * 0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.065)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: fs * 0.05,
                        height: fs * 0.05,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Опубликовать',
                        style: TextStyle(fontSize: fs * 0.04, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
