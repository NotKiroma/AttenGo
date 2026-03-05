import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedPeriod = 0;
  bool _isLoading = true;

  List<LessonAttendance> _allLessons = [];

  double _overallPercent = 0;
  double _percentChange = 0;
  List<_DayData> _chartData = [];

  // ── Предметы ──
  List<String> _subjects = [];
  String? _selectedSubject;
  Map<String, dynamic> _subjectStats = {};

  // ── Календарь ──
  DateTime _selectedDate = DateTime.now();
  List<LessonAttendance> _dayLessons = [];
  int? _expandedDayLesson;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final all = await AttendanceService.loadAll();
    _allLessons = all.where((l) => l.lessonKey != 'weekend' && l.markedCount > 0).toList();
    _recalculate();
    _extractSubjects();
    _loadDayData();
    setState(() => _isLoading = false);
  }

  void _extractSubjects() {
    final set = <String>{};
    for (final l in _allLessons) {
      set.add(l.subject);
    }
    _subjects = set.toList()..sort();
    if (_subjects.isNotEmpty && _selectedSubject == null) {
      _selectedSubject = _subjects.first;
    }
    _calcSubjectStats();
  }

  void _calcSubjectStats() {
    if (_selectedSubject == null) {
      _subjectStats = {};
      return;
    }
    final filtered = _allLessons.where((l) => l.subject == _selectedSubject).toList();
    int total = 0, present = 0, absent = 0, excused = 0;
    for (final l in filtered) {
      for (final s in l.students) {
        if (s.status == null) continue;
        total++;
        if (s.status == 'present') present++;
        if (s.status == 'absent') absent++;
        if (s.status == 'late') excused++;
      }
    }
    final presentPct = total > 0 ? (present / total * 100) : 0.0;
    final absentPct = total > 0 ? (absent / total * 100) : 0.0;
    final excusedPct = total > 0 ? (excused / total * 100) : 0.0;
    _subjectStats = {'total': filtered.length, 'present': present, 'absent': absent, 'excused': excused, 'markTotal': total, 'presentPct': presentPct, 'absentPct': absentPct, 'excusedPct': excusedPct};
  }

  void _loadDayData() {
    final dateStr = _formatDate(_selectedDate);
    _dayLessons = _allLessons.where((l) => l.date == dateStr).toList();
    _expandedDayLesson = null;
  }

  void _recalculate() {
    if (_allLessons.isEmpty) {
      _overallPercent = 0;
      _percentChange = 0;
      _chartData = [];
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<LessonAttendance> filtered;
    List<LessonAttendance> previousPeriod;

    switch (_selectedPeriod) {
      case 0:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final prevMonday = monday.subtract(const Duration(days: 7));
        filtered = _allLessons.where((l) {
          final d = _parseDate(l.date);
          return d != null && !d.isBefore(monday) && !d.isAfter(today);
        }).toList();
        previousPeriod = _allLessons.where((l) {
          final d = _parseDate(l.date);
          return d != null && !d.isBefore(prevMonday) && d.isBefore(monday);
        }).toList();
        break;
      case 1:
        final monthStart = DateTime(now.year, now.month, 1);
        final prevMonthStart = DateTime(now.year, now.month - 1, 1);
        filtered = _allLessons.where((l) {
          final d = _parseDate(l.date);
          return d != null && !d.isBefore(monthStart) && !d.isAfter(today);
        }).toList();
        previousPeriod = _allLessons.where((l) {
          final d = _parseDate(l.date);
          return d != null && !d.isBefore(prevMonthStart) && d.isBefore(monthStart);
        }).toList();
        break;
      default:
        filtered = _allLessons;
        previousPeriod = [];
    }

    int totalPresent = 0, totalMarked = 0;
    for (final l in filtered) {
      totalPresent += l.presentCount;
      totalMarked += l.markedCount;
    }
    _overallPercent = totalMarked > 0 ? (totalPresent / totalMarked) * 100 : 0;

    if (previousPeriod.isNotEmpty) {
      int prevPresent = 0, prevMarked = 0;
      for (final l in previousPeriod) {
        prevPresent += l.presentCount;
        prevMarked += l.markedCount;
      }
      final prevPercent = prevMarked > 0 ? (prevPresent / prevMarked) * 100 : 0;
      _percentChange = _overallPercent - prevPercent;
    } else {
      _percentChange = 0;
    }

    final Map<String, List<LessonAttendance>> byDate = {};
    for (final l in filtered) {
      byDate.putIfAbsent(l.date, () => []).add(l);
    }

    final dayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ'];
    _chartData = [];

    if (_selectedPeriod == 0) {
      final monday = today.subtract(Duration(days: today.weekday - 1));
      for (int i = 0; i < 6; i++) {
        final day = monday.add(Duration(days: i));
        final dateStr = _formatDate(day);
        final dayLessons = byDate[dateStr] ?? [];
        int p = 0, m = 0;
        for (final l in dayLessons) {
          p += l.presentCount;
          m += l.markedCount;
        }
        _chartData.add(_DayData(label: dayNames[i], percent: m > 0 ? (p / m) * 100 : -1));
      }
    } else {
      final Map<int, List<LessonAttendance>> byWeek = {};
      for (final entry in byDate.entries) {
        final d = _parseDate(entry.key);
        if (d == null) continue;
        final weekNum = d.difference(DateTime(d.year, 1, 1)).inDays ~/ 7;
        byWeek.putIfAbsent(weekNum, () => []).addAll(entry.value);
      }
      final sortedWeeks = byWeek.keys.toList()..sort();
      for (final week in sortedWeeks) {
        final weekLessons = byWeek[week]!;
        int p = 0, m = 0;
        for (final l in weekLessons) {
          p += l.presentCount;
          m += l.markedCount;
        }
        _chartData.add(_DayData(label: 'Н${sortedWeeks.indexOf(week) + 1}', percent: m > 0 ? (p / m) * 100 : -1));
      }
    }
  }

  DateTime? _parseDate(String date) {
    try {
      final parts = date.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _onPeriodChanged(int index) {
    if (index == _selectedPeriod) return;
    setState(() {
      _selectedPeriod = index;
      _recalculate();
    });
  }

  static const _monthNames = ['', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];

  String _formatDateHuman(DateTime d) => '${d.day} ${_monthNames[d.month]}';

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;
    final double fs = w.clamp(320.0, 430.0);

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Отчет',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.055, fontWeight: FontWeight.bold),
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
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: const Color(0xFF0D59F2),
              backgroundColor: const Color(0xFF10232C),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: w * 0.04).add(EdgeInsets.only(top: h * 0.02, bottom: h * 0.04)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodTabs(fs),
                    SizedBox(height: h * 0.02),
                    _buildAttendanceCard(fs, h, w),
                    SizedBox(height: h * 0.025),
                    _buildSubjectSection(fs, h, w),
                    SizedBox(height: h * 0.025),
                    _buildCalendarSection(fs, h, w),
                  ],
                ),
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ТАБЫ ПЕРИОДА
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildPeriodTabs(double fs) {
    final labels = ['Неделя', 'Месяц', 'Семестр'];
    return Container(
      height: fs * 0.13,
      padding: EdgeInsets.all(fs * 0.012),
      decoration: BoxDecoration(color: const Color(0xFF1A2E38), borderRadius: BorderRadius.circular(fs * 0.065)),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = _selectedPeriod == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onPeriodChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(color: isActive ? const Color(0xFF10232C) : Colors.transparent, borderRadius: BorderRadius.circular(fs * 0.055)),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(color: isActive ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), fontSize: fs * 0.038, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // КАРТОЧКА ПОСЕЩАЕМОСТИ + ГРАФИК
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildAttendanceCard(double fs, double h, double w) {
    final changeSign = _percentChange >= 0 ? '+' : '';
    final changeText = '~$changeSign${_percentChange.toStringAsFixed(1)}%';
    final changeColor = _percentChange >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171);

    return Container(
      padding: EdgeInsets.all(fs * 0.045),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.065),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Посещаемость группы',
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
              ),
              Icon(Icons.show_chart_rounded, color: const Color(0xFF0D59F2), size: fs * 0.055),
            ],
          ),
          SizedBox(height: h * 0.01),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_overallPercent.toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.white, fontSize: fs * 0.09, fontWeight: FontWeight.bold, height: 1.0),
              ),
              SizedBox(width: fs * 0.03),
              if (_percentChange != 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(color: changeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    changeText,
                    style: TextStyle(color: changeColor, fontSize: fs * 0.03, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          SizedBox(height: h * 0.025),
          _chartData.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'Нет данных за период',
                      style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
                    ),
                  ),
                )
              : SizedBox(
                  height: h * 0.2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: fs * 0.02),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _ChartPainter(data: _chartData),
                    ),
                  ),
                ),
          if (_chartData.isNotEmpty) ...[
            SizedBox(height: h * 0.01),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: fs * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _chartData
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d.label,
                            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.028, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // СЕКЦИЯ ПРЕДМЕТОВ
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildSubjectSection(double fs, double h, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'По предметам',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.048, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: h * 0.012),
        // Выпадающий список
        Container(
          padding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.005),
          decoration: BoxDecoration(
            color: const Color(0xFF10232C),
            borderRadius: BorderRadius.circular(fs * 0.04),
            border: Border.all(color: const Color(0xFF455664), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject,
              isExpanded: true,
              dropdownColor: const Color(0xFF10232C),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF0D59F2), size: fs * 0.06),
              style: TextStyle(color: Colors.white, fontSize: fs * 0.038),
              hint: Text(
                'Выберите предмет',
                style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.038),
              ),
              items: _subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSubject = val;
                  _calcSubjectStats();
                });
              },
            ),
          ),
        ),
        SizedBox(height: h * 0.015),
        // Сетка статистики 2x2 — как на скриншоте
        if (_selectedSubject != null && _subjectStats.isNotEmpty) _buildSubjectGrid(fs, h, w),
        if (_selectedSubject != null && _subjectStats.isEmpty) _emptyCard(fs, 'Нет данных по предмету'),
      ],
    );
  }

  Widget _buildSubjectGrid(double fs, double h, double w) {
    final total = _subjectStats['total'] as int? ?? 0;
    final present = _subjectStats['present'] as int? ?? 0;
    final absent = _subjectStats['absent'] as int? ?? 0;
    final excused = _subjectStats['excused'] as int? ?? 0;
    final presentPct = (_subjectStats['presentPct'] as double? ?? 0).toStringAsFixed(1);
    final absentPct = (_subjectStats['absentPct'] as double? ?? 0).toStringAsFixed(1);
    final excusedPct = (_subjectStats['excusedPct'] as double? ?? 0).toStringAsFixed(1);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(fs, h, label: 'Всего занятий', value: '$total', badge: '100%', badgeColor: const Color(0xFF34D399)),
            ),
            SizedBox(width: fs * 0.03),
            Expanded(
              child: _statCard(fs, h, label: 'Посещено', value: '$present', badge: '$presentPct%', badgeColor: const Color(0xFF34D399)),
            ),
          ],
        ),
        SizedBox(height: fs * 0.03),
        Row(
          children: [
            Expanded(
              child: _statCard(fs, h, label: 'Пропущено', value: '$absent', badge: '$absentPct%', badgeColor: const Color(0xFFF87171)),
            ),
            SizedBox(width: fs * 0.03),
            Expanded(
              child: _statCard(fs, h, label: 'Уважительных', value: '$excused', badge: '$excusedPct%', badgeColor: const Color(0xFFFACC15)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(double fs, double h, {required String label, required String value, required String badge, required Color badgeColor}) {
    return Container(
      padding: EdgeInsets.all(fs * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.05),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.033),
          ),
          SizedBox(height: h * 0.006),
          Text(
            value,
            style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.09, fontWeight: FontWeight.bold, height: 1.0),
          ),
          SizedBox(height: h * 0.008),
          Container(
            padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 3),
            decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(
              badge,
              style: TextStyle(color: badgeColor, fontSize: fs * 0.028, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // СЕКЦИЯ КАЛЕНДАРЯ
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildCalendarSection(double fs, double h, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'По дням',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.048, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: h * 0.012),
        // Выбор даты
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.035),
            decoration: BoxDecoration(
              color: const Color(0xFF10232C),
              borderRadius: BorderRadius.circular(fs * 0.04),
              border: Border.all(color: const Color(0xFF455664), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: const Color(0xFF0D59F2), size: fs * 0.05),
                SizedBox(width: fs * 0.03),
                Expanded(
                  child: Text(
                    _formatDateHuman(_selectedDate),
                    style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF0D59F2), size: fs * 0.06),
              ],
            ),
          ),
        ),
        SizedBox(height: h * 0.015),
        // Список занятий за день
        if (_dayLessons.isEmpty) _emptyCard(fs, 'Нет данных за ${_formatDateHuman(_selectedDate)}') else ...List.generate(_dayLessons.length, (i) => _buildDayLessonCard(fs, h, w, i)),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF0D59F2), onPrimary: Colors.white, surface: Color(0xFF10232C), onSurface: Colors.white),
            dialogBackgroundColor: const Color(0xFF101C22),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadDayData();
      });
    }
  }

  Widget _buildDayLessonCard(double fs, double h, double w, int index) {
    final lesson = _dayLessons[index];
    final isExpanded = _expandedDayLesson == index;
    final present = lesson.presentCount;
    final absent = lesson.absentCount;
    final late_ = lesson.lateCount;
    final total = lesson.markedCount;
    final pct = total > 0 ? (present / total * 100).round() : 0;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.012),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.05),
        border: Border.all(color: const Color(0xFF455664), width: 1),
      ),
      child: Column(
        children: [
          // Заголовок — нажимаемый
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedDayLesson = isExpanded ? null : index;
              });
            },
            child: Container(
              padding: EdgeInsets.all(fs * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.subject,
                          style: TextStyle(color: Colors.white, fontSize: fs * 0.04, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                        SizedBox(height: h * 0.004),
                        Text(
                          lesson.lessonKey,
                          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.03),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: fs * 0.02),
                  // Процент
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 4),
                    decoration: BoxDecoration(color: _pctColor(pct.toDouble()).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '$pct%',
                      style: TextStyle(color: _pctColor(pct.toDouble()), fontSize: fs * 0.035, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: fs * 0.02),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF7D92B1), size: fs * 0.055),
                  ),
                ],
              ),
            ),
          ),
          // Раскрытый контент — список студентов
          if (isExpanded) ...[
            Container(height: 1, color: const Color(0xFF455664)),
            Padding(
              padding: EdgeInsets.all(fs * 0.035),
              child: Column(
                children: [
                  // Мини-статистика
                  Row(
                    children: [
                      _miniStat(fs, const Color(0xFF0D59F2), 'Здесь', '$present'),
                      SizedBox(width: fs * 0.03),
                      _miniStat(fs, const Color(0xFFF87171), 'Нет', '$absent'),
                      SizedBox(width: fs * 0.03),
                      _miniStat(fs, const Color(0xFFFACC15), 'Ув.', '$late_'),
                    ],
                  ),
                  SizedBox(height: h * 0.012),
                  // Студенты
                  ...lesson.students.where((s) => s.status != null).map((s) {
                    final statusColor = s.status == 'present'
                        ? const Color(0xFF34D399)
                        : s.status == 'absent'
                        ? const Color(0xFFF87171)
                        : const Color(0xFFFACC15);
                    final statusText = s.status == 'present'
                        ? 'Присутствует'
                        : s.status == 'absent'
                        ? 'Отсутствует'
                        : 'Уважительная';

                    return Padding(
                      padding: EdgeInsets.only(bottom: h * 0.008),
                      child: Row(
                        children: [
                          CircleAvatar(radius: fs * 0.04, backgroundImage: AssetImage(s.isMale ? 'assets/images/man_avatar.png' : 'assets/images/women_avatar.png'), backgroundColor: const Color(0xFF3A5FCD)),
                          SizedBox(width: fs * 0.025),
                          Expanded(
                            child: Text(
                              '${s.lastName} ${s.firstName}',
                              style: TextStyle(color: Colors.white, fontSize: fs * 0.034),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: fs * 0.02, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              statusText,
                              style: TextStyle(color: statusColor, fontSize: fs * 0.026, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(double fs, Color color, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: fs * 0.02),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(fs * 0.03)),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: fs * 0.04, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: fs * 0.026),
            ),
          ],
        ),
      ),
    );
  }

  Color _pctColor(double pct) {
    if (pct >= 80) return const Color(0xFF34D399);
    if (pct >= 60) return const Color(0xFFFACC15);
    return const Color(0xFFF87171);
  }

  Widget _emptyCard(double fs, String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fs * 0.06),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.065),
        border: Border.all(color: const Color(0xFF455664)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// МОДЕЛИ
// ══════════════════════════════════════════════════════════════════════════════

class _DayData {
  final String label;
  final double percent;
  _DayData({required this.label, required this.percent});
}

// ══════════════════════════════════════════════════════════════════════════════
// КАСТОМНЫЙ ГРАФИК — исправлено выравнивание
// ══════════════════════════════════════════════════════════════════════════════

class _ChartPainter extends CustomPainter {
  final List<_DayData> data;
  _ChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final validPoints = <int, double>{};
    for (int i = 0; i < data.length; i++) {
      if (data[i].percent >= 0) validPoints[i] = data[i].percent;
    }
    if (validPoints.isEmpty) return;

    const double chartTop = 10;
    final double chartHeight = size.height - 20;
    final double paddingH = 0;

    final double usableWidth = size.width - paddingH * 2;
    final double stepX = data.length > 1 ? usableWidth / (data.length - 1) : usableWidth / 2;

    Offset getPoint(int index, double percent) {
      final x = paddingH + (data.length > 1 ? index * stepX : usableWidth / 2);
      final y = chartTop + chartHeight - (percent / 100) * chartHeight;
      return Offset(x, y);
    }

    final sortedIndices = validPoints.keys.toList()..sort();

    if (sortedIndices.length >= 2) {
      final path = Path();
      final firstPt = getPoint(sortedIndices.first, validPoints[sortedIndices.first]!);
      path.moveTo(firstPt.dx, firstPt.dy);

      for (int i = 1; i < sortedIndices.length; i++) {
        final prev = getPoint(sortedIndices[i - 1], validPoints[sortedIndices[i - 1]]!);
        final curr = getPoint(sortedIndices[i], validPoints[sortedIndices[i]]!);
        final midX = (prev.dx + curr.dx) / 2;
        path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
      }

      final fillPath = Path.from(path);
      final lastPt = getPoint(sortedIndices.last, validPoints[sortedIndices.last]!);
      fillPath.lineTo(lastPt.dx, size.height);
      fillPath.lineTo(firstPt.dx, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x500D59F2), Color(0x000D59F2)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF0D59F2)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (final idx in sortedIndices) {
      final pt = getPoint(idx, validPoints[idx]!);
      canvas.drawCircle(pt, 6, Paint()..color = const Color(0xFF0D59F2));
      canvas.drawCircle(pt, 3, Paint()..color = const Color(0xFF10232C));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
