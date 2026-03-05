import 'package:flutter/material.dart';
import '../services/schedule_service.dart';

class SheduleScreen extends StatefulWidget {
  const SheduleScreen({super.key});

  @override
  State<SheduleScreen> createState() => _SheduleScreenState();
}

class _SheduleScreenState extends State<SheduleScreen> {
  int _activeIndex = 0;
  bool _isLoading = true;

  List<DateTime> _dates = [];
  List<List<Lesson>> _schedule = [];

  static const _weekNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ'];

  @override
  void initState() {
    super.initState();
    _activeIndex = _todayIndex;
    _loadSchedule();
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

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_monthsShort[d.month]}';

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

  void _showLessonEditor(BuildContext context, {required int dayIndex, Lesson? lesson, int? lessonIndex}) {
    final subjectCtrl = TextEditingController(text: lesson?.subject ?? '');
    final roomCtrl = TextEditingController(text: lesson?.room ?? '');
    final teacherCtrl = TextEditingController(text: lesson?.teacher ?? '');
    final timeStartCtrl = TextEditingController(text: lesson?.timeStart ?? '');
    final timeEndCtrl = TextEditingController(text: lesson?.timeEnd ?? '');
    final isEdit = lesson != null;
    final double w = MediaQuery.of(context).size.width;
    final double fs = w.clamp(320.0, 430.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101C22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(fs * 0.06))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(fs * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: fs * 0.1,
                    height: 4,
                    margin: EdgeInsets.only(bottom: fs * 0.04),
                    decoration: BoxDecoration(color: const Color(0xFF455664), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(
                  isEdit ? 'Редактировать занятие' : 'Новое занятие',
                  style: TextStyle(color: Colors.white, fontSize: fs * 0.05, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: fs * 0.04),
                _editorField(fs, subjectCtrl, 'Предмет', Icons.book_outlined),
                SizedBox(height: fs * 0.025),
                _editorField(fs, roomCtrl, 'Аудитория', Icons.location_on_outlined),
                SizedBox(height: fs * 0.025),
                _editorField(fs, teacherCtrl, 'Преподаватель', Icons.person_outline),
                SizedBox(height: fs * 0.025),
                Row(
                  children: [
                    Expanded(child: _editorField(fs, timeStartCtrl, 'Начало (09:00)', Icons.access_time)),
                    SizedBox(width: fs * 0.03),
                    Expanded(child: _editorField(fs, timeEndCtrl, 'Конец (10:30)', Icons.access_time)),
                  ],
                ),
                SizedBox(height: fs * 0.06),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (subjectCtrl.text.trim().isEmpty || timeStartCtrl.text.trim().isEmpty || timeEndCtrl.text.trim().isEmpty) {
                        return;
                      }
                      final newLesson = Lesson(id: lesson?.id, dayIndex: dayIndex, subject: subjectCtrl.text.trim(), room: roomCtrl.text.trim(), teacher: teacherCtrl.text.trim(), timeStart: timeStartCtrl.text.trim(), timeEnd: timeEndCtrl.text.trim());
                      if (isEdit && lessonIndex != null) {
                        await ScheduleService.updateLesson(dayIndex: dayIndex, lessonIndex: lessonIndex, lesson: newLesson);
                      } else {
                        await ScheduleService.addLesson(dayIndex: dayIndex, lesson: newLesson);
                      }
                      Navigator.pop(ctx);
                      await _refresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D59F2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: fs * 0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs * 0.065)),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit ? 'Сохранить' : 'Добавить',
                      style: TextStyle(fontSize: fs * 0.04, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: fs * 0.02),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _editorField(double fs, TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.04),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: TextField(
        controller: ctrl,
        style: TextStyle(color: Colors.white, fontSize: fs * 0.037),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.035),
          prefixIcon: Icon(icon, color: const Color(0xFF7D92B1), size: fs * 0.05),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.035),
        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addLesson,
        backgroundColor: const Color(0xFF0D59F2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.03).add(EdgeInsets.only(top: h * 0.02)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _weekRow(fs, h, w),
            Text(
              'ЗАНЯТИЯ',
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.031, fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
            SizedBox(height: h * 0.015),
            _lessonsList(fs, h, w),
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
      onTap: () => _editLesson(index),
      onLongPress: () => _deleteLesson(index),
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
                      color: const Color(0xFF455664).withOpacity(0.5),
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
              // Кнопка редактирования
              Icon(Icons.edit_outlined, color: const Color(0xFF455664), size: fs * 0.045),
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
            style: TextStyle(color: isActive ? Colors.white.withOpacity(0.75) : const Color(0xFF7D92B1), fontSize: fs * 0.026, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
