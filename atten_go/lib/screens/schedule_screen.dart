import 'dart:async';
import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/announcement_service.dart';
import '../services/attendance_service.dart';
import '../services/realtime_service.dart';
import '../utils/app_snackbar.dart';

class ScheduleScreen extends StatefulWidget {
  final bool canEdit; // может ли добавлять/редактировать пары
  final bool hasGroup; // состоит ли в группе (своей или чужой)

  const ScheduleScreen({super.key, this.canEdit = true, this.hasGroup = true});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _activeIndex = 0;
  bool _isLoading = true;

  List<DateTime> _dates = [];
  List<List<Lesson>> _schedule = [];

  static const _weekNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ'];

  StreamSubscription? _scheduleSub;

  @override
  void initState() {
    super.initState();
    _activeIndex = _todayIndex;
    _loadSchedule();

    // Авто-обновление при изменении расписания в БД
    _scheduleSub = RealtimeService.onScheduleChanged.listen((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _scheduleSub?.cancel();
    super.dispose();
  }

  int get _todayIndex {
    final wd = DateTime.now().weekday;
    return (wd >= 1 && wd <= 5) ? wd - 1 : 0;
  }

  DateTime get _monday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (now.weekday) {
      case 6:
        return today.add(const Duration(days: 2));
      case 7:
        return today.add(const Duration(days: 1));
      default:
        return today.subtract(Duration(days: now.weekday - 1));
    }
  }

  Future<void> _loadSchedule() async {
    final allDays = await ScheduleService.getAllDays();
    final monday = _monday;
    final dates = List.generate(5, (i) => monday.add(Duration(days: i)));

    setState(() {
      _dates = dates;
      _schedule = allDays;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    final allDays = await ScheduleService.getAllDays();
    final monday = _monday;
    final dates = List.generate(5, (i) => monday.add(Duration(days: i)));

    setState(() {
      _dates = dates;
      _schedule = allDays;
    });
  }

  static const _monthsShort = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  // ── Добавить занятие ──
  void _addLesson() {
    _showLessonEditor(context, dayIndex: _activeIndex);
  }

  // ── Редактировать занятие ──
  void _editLesson(int lessonIndex) {
    if (_activeIndex >= _schedule.length) return;
    final lesson = _schedule[_activeIndex][lessonIndex];
    _showLessonEditor(context, dayIndex: _activeIndex, lesson: lesson, lessonIndex: lessonIndex);
  }

  // ── Удалить занятие ──
  void _deleteLesson(int lessonIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10232C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить занятие?', style: TextStyle(color: Colors.white)),
        content: Text('Вы уверены, что хотите удалить это занятие?', style: TextStyle(color: const Color(0xFF7D92B1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: Color(0xFF7D92B1))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_activeIndex < _schedule.length) {
                final lessons = _schedule[_activeIndex];
                if (lessonIndex < lessons.length) {
                  final lesson = lessons[lessonIndex];
                  await ScheduleService.deleteLesson(dayIndex: _activeIndex, lesson: lesson);
                  await _refresh();
                }
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTimeOfDay(String t) {
    try {
      final p = t.split(':');
      if (p.length >= 2) return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } catch (_) {}
    return TimeOfDay.now();
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showLessonEditor(BuildContext context, {required int dayIndex, Lesson? lesson, int? lessonIndex}) {
    final isEdit = lesson != null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101C22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(MediaQuery.of(context).size.width.clamp(320.0, 430.0) * 0.06))),
      builder: (ctx) => _LessonEditorSheet(
        lesson: lesson,
        dayIndex: dayIndex,
        lessonIndex: lessonIndex,
        isEdit: isEdit,
        parseTimeOfDay: _parseTimeOfDay,
        formatTimeOfDay: _formatTimeOfDay,
        onSave: (newLesson) async {
          if (isEdit && lessonIndex != null) {
            await ScheduleService.updateLesson(dayIndex: dayIndex, lessonIndex: lessonIndex, lesson: newLesson);
          } else {
            await ScheduleService.addLesson(dayIndex: dayIndex, lesson: newLesson);
          }
          await _refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;
    final double fs = w.clamp(320.0, 430.0);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101C22),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Расписание',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.055, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton(
              heroTag: 'fab_schedule',
              onPressed: _addLesson,
              backgroundColor: const Color(0xFF0D59F2),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: !widget.hasGroup
          ? _buildNoGroupPlaceholder(fs, h)
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.03).add(EdgeInsets.only(top: h * 0.02)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _weekRow(fs, h, w),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ЗАНЯТИЯ',
                        style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.031, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      ),
                      if (widget.canEdit)
                        GestureDetector(
                          onTap: _cancelDay,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: fs * 0.032, vertical: fs * 0.018),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF87171).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(fs * 0.035),
                              border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.event_busy_rounded, color: const Color(0xFFF87171), size: fs * 0.04),
                                SizedBox(width: fs * 0.015),
                                Text(
                                  'Отменить день',
                                  style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.029, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: h * 0.015),
                  _lessonsList(fs, h, w),
                ],
              ),
            ),
    );
  }

  Future<void> _showLessonActions(Lesson lesson, int index) async {
    final fs = MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    if (!mounted) return;

    // Показываем шторку СРАЗУ, статус отмены загружаем внутри
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LessonActionsSheet(
        lesson: lesson,
        index: index,
        fs: fs,
        onEdit: () {
          Navigator.pop(ctx);
          _editLesson(index);
        },
        onCancel: () {
          Navigator.pop(ctx);
          _cancelLesson(lesson);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deleteLesson(index);
        },
      ),
    );
  }

  // Widget _lessonActionTile(BuildContext ctx, double fs, {required IconData icon, required String label, String? sub, required Color iconBg, required Color textColor, bool disabled = false, required VoidCallback onTap}) {
  //   return GestureDetector(
  //     onTap: disabled ? null : onTap,
  //     child: Container(
  //       padding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.03),
  //       decoration: BoxDecoration(
  //         color: disabled ? const Color(0xFF0A1A22) : const Color(0xFF10232C),
  //         borderRadius: BorderRadius.circular(fs * 0.04),
  //         border: Border.all(color: disabled ? const Color(0xFF2A3A44) : const Color(0xFF455664)),
  //       ),
  //       child: Row(
  //         children: [
  //           Container(
  //             padding: EdgeInsets.all(fs * 0.022),
  //             decoration: BoxDecoration(color: (disabled ? const Color(0xFF455664) : iconBg).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(fs * 0.03)),
  //             child: Icon(icon, color: disabled ? const Color(0xFF455664) : iconBg, size: fs * 0.045),
  //           ),
  //           SizedBox(width: fs * 0.03),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   label,
  //                   style: TextStyle(color: disabled ? const Color(0xFF455664) : textColor, fontSize: fs * 0.036, fontWeight: FontWeight.w600),
  //                 ),
  //                 if (sub != null) ...[
  //                   SizedBox(height: 2),
  //                   Text(
  //                     sub,
  //                     style: TextStyle(color: disabled ? const Color(0xFF2A3A44) : const Color(0xFF7D92B1), fontSize: fs * 0.028),
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),
  //           if (!disabled) Icon(Icons.chevron_right_rounded, color: const Color(0xFF455664), size: fs * 0.045),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<void> _cancelLesson(Lesson lesson) async {
    final date = AttendanceService.todayDate();
    final lessonKey = AttendanceService.lessonKey(lesson.timeStart, lesson.timeEnd);
    final res = await AnnouncementService.create(title: '«${lesson.subject}» отменена', body: '${lesson.timeStart}–${lesson.timeEnd} пара не состоится', isCancel: true, cancelDate: date, cancelKey: lessonKey);
    if (mounted) {
      if (res.success) {
        AppSnackBar.success(context, 'Пара отменена, участники уведомлены');
      } else {
        AppSnackBar.error(context, res.error ?? 'Ошибка');
      }
    }
  }

  Future<void> _cancelDay() async {
    final fs = MediaQuery.of(context).size.width.clamp(320.0, 430.0);
    final date = AttendanceService.todayDate();

    // Проверяем уже отменён ли день
    final alreadyCancelled = await AnnouncementService.isCancelled(date: date, lessonKey: 'all');
    if (!mounted) return;

    if (alreadyCancelled) {
      AppSnackBar.warning(context, 'День уже отменён');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10232C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.04)),
        title: Text(
          'Отменить весь день?',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.045),
        ),
        content: Text(
          'Все пары сегодня будут отменены и не будут учитываться в посещаемости.',
          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Отмена',
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Отменить день',
              style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.036, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await AnnouncementService.create(title: 'Все пары отменены', body: 'Сегодня занятий нет', isCancel: true, cancelDate: date, cancelKey: 'all');
    if (mounted) {
      if (res.success) {
        AppSnackBar.success(context, 'День отменён, участники уведомлены');
      } else {
        AppSnackBar.error(context, res.error ?? 'Ошибка');
      }
    }
  }

  Widget _buildNoGroupPlaceholder(double fs, double h) {
    return Center(
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
              'Чтобы добавлять занятия, сначала создайте группу в разделе «Профиль»',
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lessonsList(double fs, double h, double w) {
    if (_schedule.isEmpty || _activeIndex >= _schedule.length) {
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
                child: Column(
                  children: [
                    Icon(Icons.event_busy_outlined, color: const Color(0xFF455664), size: fs * 0.12),
                    SizedBox(height: fs * 0.02),
                    Text(
                      'Занятий нет',
                      style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.042),
                    ),
                    if (widget.canEdit) ...[
                      SizedBox(height: fs * 0.03),
                      TextButton.icon(
                        onPressed: _addLesson,
                        icon: Icon(Icons.add_circle_outline, color: const Color(0xFF0D59F2), size: fs * 0.05),
                        label: Text(
                          'Добавить занятие',
                          style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.038),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lessons = _schedule[_activeIndex];
    if (lessons.isEmpty) {
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
                child: Column(
                  children: [
                    Icon(Icons.event_busy_outlined, color: const Color(0xFF455664), size: fs * 0.12),
                    SizedBox(height: fs * 0.02),
                    Text(
                      'Занятий нет',
                      style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.042),
                    ),
                    if (widget.canEdit) ...[
                      SizedBox(height: fs * 0.03),
                      TextButton.icon(
                        onPressed: _addLesson,
                        icon: Icon(Icons.add_circle_outline, color: const Color(0xFF0D59F2), size: fs * 0.05),
                        label: Text(
                          'Добавить занятие',
                          style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.038),
                        ),
                      ),
                    ],
                  ],
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
        child: ListView.builder(physics: const AlwaysScrollableScrollPhysics(), itemCount: lessons.length, itemBuilder: (context, index) => _buildLessonCard(fs, h, w, lessons[index], index)),
      ),
    );
  }

  Widget _buildLessonCard(double fs, double h, double w, Lesson lesson, int index) {
    return GestureDetector(
      onTap: () => widget.canEdit ? _showLessonActions(lesson, index) : null,
      onLongPress: null,
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.015),
        padding: EdgeInsets.all(fs * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFF10232C),
          borderRadius: BorderRadius.circular(fs * 0.065),
          border: Border.all(color: const Color(0xFF455664), width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Время
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    lesson.timeStart,
                    style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: fs * 0.01, horizontal: 2),
                      width: 1.5,
                      color: const Color(0xFF455664).withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    lesson.timeEnd,
                    style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.032),
                  ),
                ],
              ),
              SizedBox(width: fs * 0.04),
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.subject,
                      style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                    SizedBox(height: h * 0.008),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: const Color(0xFF7D92B1), size: fs * 0.036),
                        SizedBox(width: fs * 0.01),
                        Expanded(
                          child: Text(
                            lesson.room,
                            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.031),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.005),
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: const Color(0xFF7D92B1), size: fs * 0.036),
                        SizedBox(width: fs * 0.01),
                        Expanded(
                          child: Text(
                            lesson.teacher,
                            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.031),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Стрелка для входа в шторку (только для canEdit)
              if (widget.canEdit) Icon(Icons.chevron_right_rounded, color: const Color(0xFF455664), size: fs * 0.055),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weekRow(double fs, double h, double w) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.025),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (i) {
          return GestureDetector(
            onTap: () => setState(() => _activeIndex = i),
            child: _buildDayCard(fs, h, w, index: i),
          );
        }),
      ),
    );
  }

  Widget _buildDayCard(double fs, double h, double w, {required int index}) {
    final isActive = _activeIndex == index;
    final isToday = index == _todayIndex;
    final date = _dates.length > index ? _dates[index] : DateTime.now();

    final bgColor = isActive ? const Color(0xFF0D59F2) : const Color(0xFF10232C);
    final borderColor = isActive
        ? Colors.transparent
        : isToday
        ? const Color(0xFF0D59F2)
        : const Color(0xFF455664);
    final dayColor = isActive ? Colors.white : const Color(0xFF7D92B1);

    final cardW = (w - w * 0.06 - fs * 0.04 * 4) / 5;

    return Container(
      width: cardW.clamp(50.0, w * 0.17),
      height: h * 0.105,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: isToday && !isActive ? 1.5 : 1),
        borderRadius: BorderRadius.circular(fs * 0.055),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekNames[index],
            style: TextStyle(color: dayColor, fontSize: fs * 0.03, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          ),
          SizedBox(height: h * 0.006),
          Text(
            date.day.toString(),
            style: TextStyle(color: Colors.white, fontSize: fs * 0.055, fontWeight: FontWeight.bold, height: 1.0),
          ),
          SizedBox(height: h * 0.003),
          Text(
            _monthsShort[date.month],
            style: TextStyle(color: isActive ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF7D92B1), fontSize: fs * 0.026, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ШТОРКА ДЕЙСТВИЙ НАД ПАРОЙ — загружает статус отмены асинхронно
// ═══════════════════════════════════════════════════════════════════════════════

class _LessonActionsSheet extends StatefulWidget {
  final Lesson lesson;
  final int index;
  final double fs;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _LessonActionsSheet({required this.lesson, required this.index, required this.fs, required this.onEdit, required this.onCancel, required this.onDelete});

  @override
  State<_LessonActionsSheet> createState() => _LessonActionsSheetState();
}

class _LessonActionsSheetState extends State<_LessonActionsSheet> {
  bool _loading = true;
  bool _alreadyCancelled = false;
  bool _dayAlreadyCancelled = false;

  @override
  void initState() {
    super.initState();
    _loadCancelStatus();
  }

  Future<void> _loadCancelStatus() async {
    final date = AttendanceService.todayDate();
    final lessonKey = AttendanceService.lessonKey(widget.lesson.timeStart, widget.lesson.timeEnd);
    final cancelledKeys = await AnnouncementService.getCancelledLessonKeys(date: date);
    if (mounted) {
      setState(() {
        _alreadyCancelled = cancelledKeys.contains(lessonKey);
        _dayAlreadyCancelled = cancelledKeys.contains('all');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = widget.fs;
    final lesson = widget.lesson;
    final canCancel = !_loading && !_alreadyCancelled && !_dayAlreadyCancelled;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF152028),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(fs * 0.05, fs * 0.035, fs * 0.05, fs * 0.06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: fs * 0.1,
              height: 4,
              margin: EdgeInsets.only(bottom: fs * 0.035),
              decoration: BoxDecoration(color: const Color(0xFF455664), borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Заголовок пары
          Container(
            padding: EdgeInsets.all(fs * 0.04),
            decoration: BoxDecoration(
              color: const Color(0xFF10232C),
              borderRadius: BorderRadius.circular(fs * 0.04),
              border: Border.all(color: const Color(0xFF455664)),
            ),
            child: Row(
              children: [
                Container(
                  width: fs * 0.11,
                  height: fs * 0.11,
                  decoration: BoxDecoration(color: const Color(0xFF0D59F2).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(fs * 0.035)),
                  child: Icon(Icons.book_outlined, color: const Color(0xFF0D59F2), size: fs * 0.05),
                ),
                SizedBox(width: fs * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.subject,
                        style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: const Color(0xFF7D92B1), size: fs * 0.035),
                          SizedBox(width: 4),
                          Text(
                            '${lesson.timeStart} – ${lesson.timeEnd}',
                            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.031),
                          ),
                          if (lesson.room.isNotEmpty) ...[
                            SizedBox(width: fs * 0.02),
                            Icon(Icons.location_on_outlined, color: const Color(0xFF7D92B1), size: fs * 0.035),
                            SizedBox(width: 2),
                            Text(
                              lesson.room,
                              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.031),
                            ),
                          ],
                        ],
                      ),
                      if (!_loading && (_alreadyCancelled || _dayAlreadyCancelled)) ...[
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFF87171).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(fs * 0.02)),
                          child: Text(
                            _dayAlreadyCancelled ? 'День уже отменён' : 'Пара уже отменена',
                            style: TextStyle(color: const Color(0xFFF87171), fontSize: fs * 0.026, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: fs * 0.03),

          // Редактировать
          _actionTile(fs, icon: Icons.edit_outlined, label: 'Редактировать', iconBg: const Color(0xFF0D59F2), textColor: Colors.white, onTap: widget.onEdit),
          SizedBox(height: fs * 0.015),

          // Отменить пару
          _actionTile(
            fs,
            icon: Icons.do_not_disturb_on_outlined,
            label: 'Отменить пару',
            sub: _loading ? 'Загрузка...' : (canCancel ? 'Участники получат уведомление' : (_dayAlreadyCancelled ? 'День уже отменён' : 'Пара уже отменена')),
            iconBg: const Color(0xFFF87171),
            textColor: canCancel ? Colors.white : const Color(0xFF455664),
            disabled: !canCancel,
            onTap: canCancel ? widget.onCancel : () {},
          ),
          SizedBox(height: fs * 0.015),

          // Удалить
          _actionTile(fs, icon: Icons.delete_outline_rounded, label: 'Удалить из расписания', iconBg: const Color(0xFF455664), textColor: const Color(0xFF7D92B1), onTap: widget.onDelete),
        ],
      ),
    );
  }

  Widget _actionTile(double fs, {required IconData icon, required String label, String? sub, required Color iconBg, required Color textColor, bool disabled = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.03),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFF0A1A22) : const Color(0xFF10232C),
          borderRadius: BorderRadius.circular(fs * 0.04),
          border: Border.all(color: disabled ? const Color(0xFF2A3A44) : const Color(0xFF455664)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(fs * 0.022),
              decoration: BoxDecoration(color: (disabled ? const Color(0xFF455664) : iconBg).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(fs * 0.03)),
              child: Icon(icon, color: disabled ? const Color(0xFF455664) : iconBg, size: fs * 0.045),
            ),
            SizedBox(width: fs * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: disabled ? const Color(0xFF455664) : textColor, fontSize: fs * 0.036, fontWeight: FontWeight.w600),
                  ),
                  if (sub != null) ...[
                    SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(color: disabled ? const Color(0xFF2A3A44) : const Color(0xFF7D92B1), fontSize: fs * 0.028),
                    ),
                  ],
                ],
              ),
            ),
            if (!disabled) Icon(Icons.chevron_right_rounded, color: const Color(0xFF455664), size: fs * 0.045),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// РЕДАКТОР ЗАНЯТИЯ — StatefulWidget с нативным TimePicker
// ═══════════════════════════════════════════════════════════════════════════════

class _LessonEditorSheet extends StatefulWidget {
  final Lesson? lesson;
  final int dayIndex;
  final int? lessonIndex;
  final bool isEdit;
  final TimeOfDay Function(String) parseTimeOfDay;
  final String Function(TimeOfDay) formatTimeOfDay;
  final Future<void> Function(Lesson) onSave;

  const _LessonEditorSheet({required this.lesson, required this.dayIndex, required this.lessonIndex, required this.isEdit, required this.parseTimeOfDay, required this.formatTimeOfDay, required this.onSave});

  @override
  State<_LessonEditorSheet> createState() => _LessonEditorSheetState();
}

class _LessonEditorSheetState extends State<_LessonEditorSheet> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _teacherCtrl;
  late TimeOfDay _timeStart;
  late TimeOfDay _timeEnd;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _subjectCtrl = TextEditingController(text: l?.subject ?? '');
    _roomCtrl = TextEditingController(text: l?.room ?? '');
    _teacherCtrl = TextEditingController(text: l?.teacher ?? '');
    _timeStart = l != null ? widget.parseTimeOfDay(l.timeStart) : const TimeOfDay(hour: 9, minute: 0);
    _timeEnd = l != null ? widget.parseTimeOfDay(l.timeEnd) : const TimeOfDay(hour: 10, minute: 30);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _roomCtrl.dispose();
    _teacherCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _timeStart : _timeEnd,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF0D59F2), onPrimary: Colors.white, surface: Color(0xFF10232C), onSurface: Colors.white),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: Color(0xFF152028),
            hourMinuteColor: Color(0xFF10232C),
            hourMinuteTextColor: Colors.white,
            dayPeriodColor: Color(0xFF10232C),
            dayPeriodTextColor: Color(0xFF0D59F2),
            dialBackgroundColor: Color(0xFF10232C),
            dialHandColor: Color(0xFF0D59F2),
            dialTextColor: Colors.white,
            entryModeIconColor: Color(0xFF7D92B1),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _timeStart = picked;
        } else {
          _timeEnd = picked;
        }
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    if (_subjectCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Введите название предмета');
      return;
    }
    // Проверяем что конец после начала
    final startMin = _timeStart.hour * 60 + _timeStart.minute;
    final endMin = _timeEnd.hour * 60 + _timeEnd.minute;
    if (endMin <= startMin) {
      setState(() => _error = 'Конец должен быть позже начала');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final newLesson = Lesson(id: widget.lesson?.id, dayIndex: widget.dayIndex, subject: _subjectCtrl.text.trim(), room: _roomCtrl.text.trim(), teacher: _teacherCtrl.text.trim(), timeStart: widget.formatTimeOfDay(_timeStart), timeEnd: widget.formatTimeOfDay(_timeEnd));
    await widget.onSave(newLesson);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final fs = w.clamp(320.0, 430.0);
    final startLabel = widget.formatTimeOfDay(_timeStart);
    final endLabel = widget.formatTimeOfDay(_timeEnd);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(fs * 0.05),
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
              widget.isEdit ? 'Редактировать занятие' : 'Новое занятие',
              style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: fs * 0.04),

            // Предмет
            _field(fs, _subjectCtrl, 'Предмет', Icons.book_outlined),
            SizedBox(height: fs * 0.025),
            _field(fs, _roomCtrl, 'Аудитория', Icons.location_on_outlined),
            SizedBox(height: fs * 0.025),
            _field(fs, _teacherCtrl, 'Преподаватель', Icons.person_outline),
            SizedBox(height: fs * 0.03),

            // Время — два тапабельных блока
            Row(
              children: [
                Expanded(child: _timeTile(fs, 'Начало', startLabel, () => _pickTime(true))),
                SizedBox(width: fs * 0.03),
                Expanded(child: _timeTile(fs, 'Конец', endLabel, () => _pickTime(false))),
              ],
            ),

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

            SizedBox(height: fs * 0.055),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
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
                        widget.isEdit ? 'Сохранить' : 'Добавить',
                        style: TextStyle(fontSize: fs * 0.04, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            SizedBox(height: fs * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(double fs, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.035),
        decoration: BoxDecoration(
          color: const Color(0xFF10232C),
          borderRadius: BorderRadius.circular(fs * 0.04),
          border: Border.all(color: const Color(0xFF455664)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, color: const Color(0xFF0D59F2), size: fs * 0.05),
            SizedBox(width: fs * 0.025),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.028),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(color: Colors.white, fontSize: fs * 0.042, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFF455664), size: fs * 0.045),
          ],
        ),
      ),
    );
  }

  Widget _field(double fs, TextEditingController ctrl, String hint, IconData icon) {
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
          prefixIcon: Icon(icon, color: const Color(0xFF7D92B1), size: fs * 0.05),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.038),
        ),
      ),
    );
  }
}
