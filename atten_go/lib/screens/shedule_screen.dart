import 'package:flutter/material.dart';
import '../services/schedule_service.dart';

class SheduleScreen extends StatefulWidget {
  const SheduleScreen({super.key});

  @override
  State<SheduleScreen> createState() => _SheduleScreenState();
}

class _SheduleScreenState extends State<SheduleScreen> {
  int _activeIndex = 0;
  bool _isLoading  = true;

  List<DateTime> _dates    = [];
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
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (now.weekday) {
      case 6:  return today.add(const Duration(days: 2));
      case 7:  return today.add(const Duration(days: 1));
      default: return today.subtract(Duration(days: now.weekday - 1));
    }
  }

  Future<void> _loadSchedule() async {
    final allDays = await ScheduleService.getAllDays();
    final monday  = _monday;
    final dates   = List.generate(5, (i) => monday.add(Duration(days: i)));

    setState(() {
      _dates    = dates;
      _schedule = allDays;
      _isLoading = false;
    });
  }

  static const _monthsShort = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_monthsShort[d.month]}';

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

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
          style: TextStyle(color: Colors.white, fontSize: w * 0.06, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.03).add(EdgeInsets.only(top: h * 0.02)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _weekRow(w, h),
            Text(
              'ЗАНЯТИЯ',
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.033, fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
            SizedBox(height: h * 0.015),
            _lessonsList(w, h),
          ],
        ),
      ),
    );
  }

  Widget _lessonsList(double w, double h) {
    if (_schedule.isEmpty || _activeIndex >= _schedule.length) {
      return const Expanded(child: SizedBox.shrink());
    }
    final lessons = _schedule[_activeIndex];
    if (lessons.isEmpty) {
      return Expanded(
        child: Center(
          child: Text('Занятий нет', style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.045)),
        ),
      );
    }
    return Expanded(
      child: SingleChildScrollView(
        child: Column(children: lessons.map((l) => _buildLessonCard(w, h, l)).toList()),
      ),
    );
  }

  Widget _buildLessonCard(double w, double h, Lesson lesson) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Время
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(lesson.timeStart, style: TextStyle(color: Colors.white, fontSize: w * 0.04, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    width: 1.5,
                    color: const Color(0xFF455664).withOpacity(0.5),
                  ),
                ),
                Text(lesson.timeEnd, style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.034)),
              ],
            ),
            SizedBox(width: w * 0.04),
            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.subject,
                    style: TextStyle(color: Colors.white, fontSize: w * 0.042, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  SizedBox(height: h * 0.008),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: const Color(0xFF7D92B1), size: w * 0.038),
                      SizedBox(width: w * 0.01),
                      Text(lesson.room, style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.033)),
                    ],
                  ),
                  SizedBox(height: h * 0.005),
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: const Color(0xFF7D92B1), size: w * 0.038),
                      SizedBox(width: w * 0.01),
                      Text(lesson.teacher, style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.033)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekRow(double w, double h) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.025),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (i) {
          return GestureDetector(
            onTap: () => setState(() => _activeIndex = i),
            child: _buildDayCard(w, h, index: i),
          );
        }),
      ),
    );
  }

  Widget _buildDayCard(double w, double h, {required int index}) {
    final isActive = _activeIndex == index;
    final isToday  = index == _todayIndex;
    final date     = _dates[index];

    final bgColor     = isActive ? const Color(0xFF0D59F2) : const Color(0xFF10232C);
    final borderColor = isActive
        ? Colors.transparent
        : isToday
            ? const Color(0xFF0D59F2)
            : const Color(0xFF455664);
    final dayColor = isActive ? Colors.white : const Color(0xFF7D92B1);

    return Container(
      width: w * 0.17,
      height: h * 0.105,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: isToday && !isActive ? 1.5 : 1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekNames[index],
            style: TextStyle(color: dayColor, fontSize: w * 0.032, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          ),
          SizedBox(height: h * 0.006),
          Text(
            date.day.toString(),
            style: TextStyle(color: Colors.white, fontSize: w * 0.058, fontWeight: FontWeight.bold, height: 1.0),
          ),
          SizedBox(height: h * 0.003),
          Text(
            _monthsShort[date.month],
            style: TextStyle(
              color: isActive ? Colors.white.withOpacity(0.75) : const Color(0xFF7D92B1),
              fontSize: w * 0.028,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
