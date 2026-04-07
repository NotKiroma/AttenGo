import 'package:flutter/material.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import '../services/attendance_service.dart';
import '../services/announcement_service.dart';
import '../services/group_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // 0=День, 1=Неделя, 2=Месяц, 3=Период
  int _selectedPeriod = 1;
  bool _isLoading = true;
  bool _hasGroup = false;
  bool _showChart = true;

  List<LessonAttendance> _allLessons = [];

  // ── Навигация ──
  DateTime _navDay = DateTime.now();
  late DateTime _navWeekStart;
  late DateTime _navMonth;
  DateTime? _periodStart;
  DateTime? _periodEnd;

  // ── Рассчитанные данные ──
  double _overallPercent = 0;
  double _percentChange = 0;
  List<_DayData> _chartData = [];
  int _statTotalLessons = 0;
  int _statPresent = 0;
  int _statAbsent = 0;
  int _statExcused = 0;
  int _statMarkedTotal = 0;

  // ── Предметы ──
  List<String> _subjects = [];
  String? _selectedSubject;
  Map<String, dynamic> _subjectStats = {};

  // ── День: уроки ──
  List<LessonAttendance> _dayLessons = [];
  int? _expandedDayLesson;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _navDay = today;
    _navWeekStart = today.subtract(Duration(days: today.weekday - 1));
    _navMonth = DateTime(today.year, today.month);
    _periodStart = today.subtract(const Duration(days: 7));
    _periodEnd = today;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    GroupService.invalidateCache();
    final group = await GroupService.getCurrentGroup();
    _hasGroup = group != null;
    if (!_hasGroup) {
      setState(() => _isLoading = false);
      return;
    }

    // Параллельно загружаем уроки и объявления
    final results = await Future.wait([AttendanceService.loadAll(), AnnouncementService.loadAll()]);

    final all = results[0] as List<LessonAttendance>;
    final announcements = results[1] as List<Announcement>;

    // Строим Set отменённых пар: "date|lessonKey" или "date|all"
    final cancelledKeys = <String>{};
    final cancelledDays = <String>{};
    for (final a in announcements) {
      if (!a.isCancel) continue;
      // Проверяем не истёк ли срок действия
      if (a.expiresAt != null && DateTime.now().isAfter(a.expiresAt!)) continue;
      if (a.cancelDate == null) continue;
      if (a.cancelKey == 'all') {
        cancelledDays.add(a.cancelDate!);
      } else if (a.cancelKey != null) {
        cancelledKeys.add('${a.cancelDate}|${a.cancelKey}');
      }
    }

    _allLessons = all.where((l) {
      if (l.lessonKey == 'weekend') return false;
      if (l.markedCount == 0) return false;
      // Фильтруем отменённые дни
      if (cancelledDays.contains(l.date)) return false;
      // Фильтруем отменённые пары
      if (cancelledKeys.contains('${l.date}|${l.lessonKey}')) return false;
      return true;
    }).toList();

    _extractSubjects();
    _recalculate();
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

  List<LessonAttendance> _getFilteredLessons() {
    switch (_selectedPeriod) {
      case 0:
        final dateStr = _formatDate(_navDay);
        return _allLessons.where((l) => l.date == dateStr).toList();
      case 1:
        final weekEnd = _navWeekStart.add(const Duration(days: 5));
        return _allLessons.where((l) {
          final d = _parseDate(l.date);
          return d != null && !d.isBefore(_navWeekStart) && !d.isAfter(weekEnd);
        }).toList();
      case 2:
        final monthStart = DateTime(_navMonth.year, _navMonth.month, 1);
        final monthEnd = DateTime(_navMonth.year, _navMonth.month + 1, 0);
        return _allLessons.where((l) {
          final d = _parseDate(l.date);
          return d != null && !d.isBefore(monthStart) && !d.isAfter(monthEnd);
        }).toList();
      case 3:
        if (_periodStart == null || _periodEnd == null) return [];
        return _allLessons.where((l) {
          final d = _parseDate(l.date);
          return d != null && !d.isBefore(_periodStart!) && !d.isAfter(_periodEnd!);
        }).toList();
      default:
        return [];
    }
  }

  List<LessonAttendance> _getPreviousPeriodLessons() {
    switch (_selectedPeriod) {
      case 0:
        final prevDay = _navDay.subtract(const Duration(days: 1));
        final dateStr = _formatDate(prevDay);
        return _allLessons.where((l) => l.date == dateStr).toList();
      case 1:
        final prevWeekStart = _navWeekStart.subtract(const Duration(days: 7));
        final prevWeekEnd = prevWeekStart.add(const Duration(days: 5));
        return _allLessons.where((l) {
          final d = _parseDate(l.date);
          return d != null && !d.isBefore(prevWeekStart) && !d.isAfter(prevWeekEnd);
        }).toList();
      case 2:
        final prevMonthStart = DateTime(_navMonth.year, _navMonth.month - 1, 1);
        final prevMonthEnd = DateTime(_navMonth.year, _navMonth.month, 0);
        return _allLessons.where((l) {
          final d = _parseDate(l.date);
          return d != null && !d.isBefore(prevMonthStart) && !d.isAfter(prevMonthEnd);
        }).toList();
      default:
        return [];
    }
  }

  void _recalculate() {
    final filtered = _getFilteredLessons();
    final previousFiltered = _getPreviousPeriodLessons();

    int totalPresent = 0, totalAbsent = 0, totalExcused = 0, totalMarked = 0;
    for (final l in filtered) {
      for (final s in l.students) {
        if (s.status == null) continue;
        totalMarked++;
        if (s.status == 'present') totalPresent++;
        if (s.status == 'absent') totalAbsent++;
        if (s.status == 'late') totalExcused++;
      }
    }

    _statTotalLessons = filtered.length;
    _statPresent = totalPresent;
    _statAbsent = totalAbsent;
    _statExcused = totalExcused;
    _statMarkedTotal = totalMarked;
    _overallPercent = totalMarked > 0 ? (totalPresent / totalMarked) * 100 : 0;

    if (previousFiltered.isNotEmpty && _selectedPeriod != 3) {
      int prevPresent = 0, prevMarked = 0;
      for (final l in previousFiltered) {
        prevPresent += l.presentCount;
        prevMarked += l.markedCount;
      }
      final prevPercent = prevMarked > 0 ? (prevPresent / prevMarked) * 100 : 0;
      _percentChange = _overallPercent - prevPercent;
    } else {
      _percentChange = 0;
    }

    _buildChartData(filtered);

    if (_selectedPeriod == 0) {
      // Сортируем по времени начала пары (lessonKey вида "08:00-09:30")
      _dayLessons = List.of(filtered)..sort((a, b) => a.lessonKey.compareTo(b.lessonKey));
      _expandedDayLesson = null;
    }
  }

  void _buildChartData(List<LessonAttendance> filtered) {
    _chartData = [];

    if (_selectedPeriod == 0) return;

    final Map<String, List<LessonAttendance>> byDate = {};
    for (final l in filtered) {
      byDate.putIfAbsent(l.date, () => []).add(l);
    }

    if (_selectedPeriod == 1) {
      final dayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ'];
      for (int i = 0; i < 6; i++) {
        final day = _navWeekStart.add(Duration(days: i));
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
      final Map<int, DateTime> weekStartDates = {};
      for (final entry in byDate.entries) {
        final d = _parseDate(entry.key);
        if (d == null) continue;
        final weekMonday = d.subtract(Duration(days: d.weekday - 1));
        final weekKey = weekMonday.difference(DateTime(weekMonday.year, 1, 1)).inDays ~/ 7;
        byWeek.putIfAbsent(weekKey, () => []).addAll(entry.value);
        weekStartDates.putIfAbsent(weekKey, () => weekMonday);
      }
      final sortedWeeks = byWeek.keys.toList()..sort();
      for (int i = 0; i < sortedWeeks.length; i++) {
        final weekLessons = byWeek[sortedWeeks[i]]!;
        final monday = weekStartDates[sortedWeeks[i]]!;
        final friday = monday.add(const Duration(days: 4));
        int p = 0, m = 0;
        for (final l in weekLessons) {
          p += l.presentCount;
          m += l.markedCount;
        }
        final String label;
        if (monday.month == friday.month) {
          label = '${monday.day}–${friday.day}';
        } else {
          label = '${monday.day}.${monday.month}–${friday.day}.${friday.month}';
        }
        _chartData.add(_DayData(label: label, percent: m > 0 ? (p / m) * 100 : -1));
      }
    }
  }

  void _onPeriodChanged(int index) {
    if (index == _selectedPeriod) return;
    setState(() {
      _selectedPeriod = index;
      if (index == 0) _showChart = false;
      if (index != 0) _showChart = true;
      _recalculate();
    });
  }

  void _prevDay() {
    setState(() {
      _navDay = _navDay.subtract(const Duration(days: 1));
      _recalculate();
    });
  }

  void _nextDay() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (!_navDay.isBefore(todayDate)) return;
    setState(() {
      _navDay = _navDay.add(const Duration(days: 1));
      _recalculate();
    });
  }

  void _prevWeek() {
    setState(() {
      _navWeekStart = _navWeekStart.subtract(const Duration(days: 7));
      _recalculate();
    });
  }

  void _nextWeek() {
    final today = DateTime.now();
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final currentWeekDate = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    if (!_navWeekStart.isBefore(currentWeekDate)) return;
    setState(() {
      _navWeekStart = _navWeekStart.add(const Duration(days: 7));
      _recalculate();
    });
  }

  void _prevMonth() {
    setState(() {
      _navMonth = DateTime(_navMonth.year, _navMonth.month - 1);
      _recalculate();
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (!_navMonth.isBefore(currentMonth)) return;
    setState(() {
      _navMonth = DateTime(_navMonth.year, _navMonth.month + 1);
      _recalculate();
    });
  }

  BoxDecoration get _selectedCellDeco => BoxDecoration(color: const Color(0xFF0D59F2), shape: BoxShape.circle);
  BoxDecoration get _todayCellDeco => BoxDecoration(
    border: Border.all(color: const Color(0xFF0D59F2)),
    shape: BoxShape.circle,
  );

  Future<void> _pickNavigatorDate(BuildContext context) async {
    switch (_selectedPeriod) {
      case 0:
        final picked = await showDatePickerDialog(
          context: context,
          minDate: DateTime(2024),
          maxDate: DateTime.now(),
          initialDate: _navDay,
          currentDate: DateTime.now(),
          selectedDate: _navDay,
          daysOfTheWeekTextStyle: const TextStyle(color: Color(0xFF7D92B1), fontWeight: FontWeight.w600),
          enabledCellsTextStyle: const TextStyle(color: Colors.white),
          disabledCellsTextStyle: const TextStyle(color: Color(0xFF455664)),
          selectedCellTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          selectedCellDecoration: _selectedCellDeco,
          currentDateDecoration: _todayCellDeco,
          currentDateTextStyle: const TextStyle(color: Color(0xFF0D59F2), fontWeight: FontWeight.bold),
          leadingDateTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          slidersColor: const Color(0xFF0D59F2),
          highlightColor: const Color(0xFF0D59F2),
          splashColor: const Color(0xFF0D59F2),
        );
        if (picked != null) {
          setState(() {
            _navDay = picked;
            _recalculate();
          });
        }
        break;
      case 1:
        final picked = await showDatePickerDialog(
          context: context,
          minDate: DateTime(2024),
          maxDate: DateTime.now(),
          initialDate: _navWeekStart.add(const Duration(days: 2)),
          currentDate: DateTime.now(),
          daysOfTheWeekTextStyle: const TextStyle(color: Color(0xFF7D92B1), fontWeight: FontWeight.w600),
          enabledCellsTextStyle: const TextStyle(color: Colors.white),
          disabledCellsTextStyle: const TextStyle(color: Color(0xFF455664)),
          selectedCellTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          selectedCellDecoration: _selectedCellDeco,
          currentDateDecoration: _todayCellDeco,
          currentDateTextStyle: const TextStyle(color: Color(0xFF0D59F2), fontWeight: FontWeight.bold),
          leadingDateTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          slidersColor: const Color(0xFF0D59F2),
          highlightColor: const Color(0xFF0D59F2),
          splashColor: const Color(0xFF0D59F2),
        );
        if (picked != null) {
          setState(() {
            _navWeekStart = picked.subtract(Duration(days: picked.weekday - 1));
            _recalculate();
          });
        }
        break;
      case 2:
        final picked = await showDatePickerDialog(
          context: context,
          minDate: DateTime(2024),
          maxDate: DateTime.now(),
          initialDate: DateTime(_navMonth.year, _navMonth.month, 15),
          currentDate: DateTime.now(),
          initialPickerType: PickerType.months,
          daysOfTheWeekTextStyle: const TextStyle(color: Color(0xFF7D92B1), fontWeight: FontWeight.w600),
          enabledCellsTextStyle: const TextStyle(color: Colors.white),
          disabledCellsTextStyle: const TextStyle(color: Color(0xFF455664)),
          selectedCellTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          selectedCellDecoration: _selectedCellDeco,
          currentDateDecoration: _todayCellDeco,
          currentDateTextStyle: const TextStyle(color: Color(0xFF0D59F2), fontWeight: FontWeight.bold),
          leadingDateTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          slidersColor: const Color(0xFF0D59F2),
          highlightColor: const Color(0xFF0D59F2),
          splashColor: const Color(0xFF0D59F2),
        );
        if (picked != null) {
          setState(() {
            _navMonth = DateTime(picked.year, picked.month);
            _recalculate();
          });
        }
        break;
    }
  }

  Future<void> _pickPeriodRange(BuildContext context) async {
    final picked = await showRangePickerDialog(
      context: context,
      minDate: DateTime(2024),
      maxDate: DateTime.now(),
      selectedRange: _periodStart != null && _periodEnd != null ? DateTimeRange(start: _periodStart!, end: _periodEnd!) : null,
      daysOfTheWeekTextStyle: const TextStyle(color: Color(0xFF7D92B1), fontWeight: FontWeight.w600),
      enabledCellsTextStyle: const TextStyle(color: Colors.white),
      selectedCellsTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      selectedCellsDecoration: _selectedCellDeco,
      currentDateDecoration: _todayCellDeco,
      currentDateTextStyle: const TextStyle(color: Color(0xFF0D59F2), fontWeight: FontWeight.bold),
      leadingDateTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      slidersColor: const Color(0xFF0D59F2),
      highlightColor: const Color(0xFF0D59F2),
      splashColor: const Color(0xFF0D59F2),
    );
    if (picked != null) {
      setState(() {
        _periodStart = picked.start;
        _periodEnd = picked.end;
        _recalculate();
      });
    }
  }

  void _showSubjectPicker(BuildContext context, double fs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          decoration: BoxDecoration(
            color: const Color(0xFF10232C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(fs * 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: fs * 0.025),
                width: fs * 0.1,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFF455664), borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: EdgeInsets.all(fs * 0.04),
                child: Text(
                  'Выберите предмет',
                  style: TextStyle(color: Colors.white, fontSize: fs * 0.045, fontWeight: FontWeight.bold),
                ),
              ),
              Container(height: 1, color: const Color(0xFF455664)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: fs * 0.02),
                  itemCount: _subjects.length,
                  itemBuilder: (ctx, i) {
                    final subject = _subjects[i];
                    final isSelected = subject == _selectedSubject;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSubject = subject;
                          _calcSubjectStats();
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: fs * 0.035, vertical: fs * 0.008),
                        padding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.035),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0D59F2).withValues(alpha: 0.15) : const Color(0xFF1A2E38),
                          borderRadius: BorderRadius.circular(fs * 0.04),
                          border: isSelected ? Border.all(color: const Color(0xFF0D59F2)) : Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                subject,
                                style: TextStyle(color: isSelected ? const Color(0xFF0D59F2) : Colors.white, fontSize: fs * 0.038, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                              ),
                            ),
                            if (isSelected) Icon(Icons.check_rounded, color: const Color(0xFF0D59F2), size: fs * 0.05),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + fs * 0.02),
            ],
          ),
        );
      },
    );
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

  static const _monthNamesGen = ['', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
  static const _monthNamesNom = ['', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
  static const _monthNamesShort = ['', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  String _formatDateHuman(DateTime d) => '${d.day} ${_monthNamesGen[d.month]}';

  Color _pctColor(double pct) {
    if (pct >= 80) return const Color(0xFF34D399);
    if (pct >= 60) return const Color(0xFFFACC15);
    return const Color(0xFFF87171);
  }

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
          : !_hasGroup
          ? _buildNoGroupBody(fs, h)
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
                    SizedBox(height: h * 0.015),
                    SizedBox(height: h * 0.067, child: _buildNavigator(fs, h)),
                    SizedBox(height: h * 0.018),
                    _buildAttendanceSection(fs, h, w),
                    SizedBox(height: h * 0.025),
                    _buildSubjectSection(fs, h, w),
                    if (_selectedPeriod == 0) ...[SizedBox(height: h * 0.025), _buildDayLessonsSection(fs, h, w)],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoGroupBody(double fs, double h) {
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
              'Чтобы просматривать отчёты, сначала создайте группу в разделе «Профиль»',
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.036, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTabs(double fs) {
    final labels = ['День', 'Неделя', 'Месяц', 'Период'];
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
                    style: TextStyle(color: isActive ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), fontSize: fs * 0.034, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigator(double fs, double h) {
    if (_selectedPeriod == 3) return _buildPeriodPickers(fs, h);

    String label;
    VoidCallback onPrev;
    VoidCallback onNext;
    bool canNext;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    switch (_selectedPeriod) {
      case 0:
        label = _formatDateHuman(_navDay);
        onPrev = _prevDay;
        onNext = _nextDay;
        canNext = _navDay.isBefore(todayDate);
        break;
      case 1:
        final weekEnd = _navWeekStart.add(const Duration(days: 5));
        if (_navWeekStart.month == weekEnd.month) {
          label = '${_navWeekStart.day} – ${weekEnd.day} ${_monthNamesGen[weekEnd.month]}';
        } else {
          label = '${_navWeekStart.day} ${_monthNamesShort[_navWeekStart.month]} – ${weekEnd.day} ${_monthNamesShort[weekEnd.month]}';
        }
        onPrev = _prevWeek;
        onNext = _nextWeek;
        final currentWeekStart = todayDate.subtract(Duration(days: todayDate.weekday - 1));
        canNext = _navWeekStart.isBefore(currentWeekStart);
        break;
      case 2:
        label = '${_monthNamesNom[_navMonth.month]} ${_navMonth.year}';
        onPrev = _prevMonth;
        onNext = _nextMonth;
        final currentMonth = DateTime(today.year, today.month);
        canNext = _navMonth.isBefore(currentMonth);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: fs * 0.02, vertical: fs * 0.025),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.05),
        border: Border.all(color: const Color(0xFF455664)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onPrev,
            child: Container(
              padding: EdgeInsets.all(fs * 0.02),
              decoration: BoxDecoration(color: const Color(0xFF1A2E38), borderRadius: BorderRadius.circular(fs * 0.03)),
              child: Icon(Icons.chevron_left_rounded, color: const Color(0xFF0D59F2), size: fs * 0.06),
            ),
          ),
          GestureDetector(
            onTap: () => _pickNavigatorDate(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: fs * 0.035, vertical: fs * 0.015),
              decoration: BoxDecoration(color: const Color(0xFF1A2E38), borderRadius: BorderRadius.circular(fs * 0.03)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, color: const Color(0xFF0D59F2), size: fs * 0.035),
                  SizedBox(width: fs * 0.02),
                  Text(
                    label,
                    style: TextStyle(color: Colors.white, fontSize: fs * 0.038, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: canNext ? onNext : null,
            child: Container(
              padding: EdgeInsets.all(fs * 0.02),
              decoration: BoxDecoration(color: const Color(0xFF1A2E38), borderRadius: BorderRadius.circular(fs * 0.03)),
              child: Icon(Icons.chevron_right_rounded, color: canNext ? const Color(0xFF0D59F2) : const Color(0xFF455664), size: fs * 0.06),
            ),
          ),
        ],
      ),
    );
  }

  // ── ПЕРИОД: такой же стиль как навигатор, но центральная кнопка показывает диапазон ──
  Widget _buildPeriodPickers(double fs, double h) {
    final hasRange = _periodStart != null && _periodEnd != null;
    final String centerLabel = hasRange ? '${_periodStart!.day} ${_monthNamesShort[_periodStart!.month]} – ${_periodEnd!.day} ${_monthNamesShort[_periodEnd!.month]}' : 'Выбрать период';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: fs * 0.02, vertical: fs * 0.025),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.05),
        border: Border.all(color: const Color(0xFF455664)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Левая кнопка — сдвиг периода назад
          GestureDetector(
            onTap: hasRange
                ? () {
                    final diff = _periodEnd!.difference(_periodStart!);
                    setState(() {
                      _periodStart = _periodStart!.subtract(diff + const Duration(days: 1));
                      _periodEnd = _periodEnd!.subtract(diff + const Duration(days: 1));
                      _recalculate();
                    });
                  }
                : null,
            child: Container(
              padding: EdgeInsets.all(fs * 0.02),
              decoration: BoxDecoration(color: const Color(0xFF1A2E38), borderRadius: BorderRadius.circular(fs * 0.03)),
              child: Icon(Icons.chevron_left_rounded, color: hasRange ? const Color(0xFF0D59F2) : const Color(0xFF455664), size: fs * 0.06),
            ),
          ),
          // Центральная кнопка — открывает range picker
          GestureDetector(
            onTap: () => _pickPeriodRange(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: fs * 0.035, vertical: fs * 0.015),
              decoration: BoxDecoration(color: const Color(0xFF1A2E38), borderRadius: BorderRadius.circular(fs * 0.03)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range_rounded, color: const Color(0xFF0D59F2), size: fs * 0.035),
                  SizedBox(width: fs * 0.02),
                  Text(
                    centerLabel,
                    style: TextStyle(color: hasRange ? Colors.white : const Color(0xFF7D92B1), fontSize: fs * 0.036, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          // Правая кнопка — сдвиг периода вперёд
          GestureDetector(
            onTap: hasRange
                ? () {
                    final diff = _periodEnd!.difference(_periodStart!);
                    final newEnd = _periodEnd!.add(diff + const Duration(days: 1));
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    if (newEnd.isAfter(today)) return;
                    setState(() {
                      _periodStart = _periodStart!.add(diff + const Duration(days: 1));
                      _periodEnd = newEnd;
                      _recalculate();
                    });
                  }
                : null,
            child: Container(
              padding: EdgeInsets.all(fs * 0.02),
              decoration: BoxDecoration(color: const Color(0xFF1A2E38), borderRadius: BorderRadius.circular(fs * 0.03)),
              child: Icon(Icons.chevron_right_rounded, color: _canShiftPeriodForward() ? const Color(0xFF0D59F2) : const Color(0xFF455664), size: fs * 0.06),
            ),
          ),
        ],
      ),
    );
  }

  bool _canShiftPeriodForward() {
    if (_periodEnd == null || _periodStart == null) return false;
    final diff = _periodEnd!.difference(_periodStart!);
    final newEnd = _periodEnd!.add(diff + const Duration(days: 1));
    final now = DateTime.now();
    return !newEnd.isAfter(DateTime(now.year, now.month, now.day));
  }

  Widget _buildAttendanceSection(double fs, double h, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: fs * 0.08,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Посещаемость',
                style: TextStyle(color: Colors.white, fontSize: fs * 0.048, fontWeight: FontWeight.bold),
              ),
              if (_selectedPeriod != 0 && _selectedPeriod != 3) _buildViewToggle(fs),
            ],
          ),
        ),
        SizedBox(height: h * 0.012),
        Container(
          padding: EdgeInsets.all(fs * 0.04),
          decoration: BoxDecoration(
            color: const Color(0xFF10232C),
            borderRadius: BorderRadius.circular(fs * 0.05),
            border: Border.all(color: const Color(0xFF455664)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Общая посещаемость',
                      style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.033),
                    ),
                    SizedBox(height: h * 0.006),
                    Text(
                      '${_overallPercent.toStringAsFixed(1)}%',
                      style: TextStyle(color: const Color(0xFF0D59F2), fontSize: fs * 0.09, fontWeight: FontWeight.bold, height: 1.0),
                    ),
                  ],
                ),
              ),
              if (_percentChange != 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: fs * 0.015),
                  decoration: BoxDecoration(color: (_percentChange >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171)).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(fs * 0.03)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_percentChange >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: _percentChange >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171), size: fs * 0.04),
                      SizedBox(width: fs * 0.01),
                      Text(
                        '${_percentChange >= 0 ? '+' : ''}${_percentChange.toStringAsFixed(1)}%',
                        style: TextStyle(color: _percentChange >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171), fontSize: fs * 0.03, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: h * 0.015),
        SizedBox(height: h * 0.28, child: (_selectedPeriod == 0 || _selectedPeriod == 3 || !_showChart) ? _buildCardsContent(fs, h) : _buildChartContent(fs, h)),
      ],
    );
  }

  Widget _buildViewToggle(double fs) {
    return Container(
      padding: EdgeInsets.all(fs * 0.008),
      decoration: BoxDecoration(color: const Color(0xFF1A2E38), borderRadius: BorderRadius.circular(fs * 0.03)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showChart = true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: fs * 0.015),
              decoration: BoxDecoration(color: _showChart ? const Color(0xFF10232C) : Colors.transparent, borderRadius: BorderRadius.circular(fs * 0.025)),
              child: Icon(Icons.show_chart_rounded, color: _showChart ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), size: fs * 0.045),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showChart = false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: fs * 0.015),
              decoration: BoxDecoration(color: !_showChart ? const Color(0xFF10232C) : Colors.transparent, borderRadius: BorderRadius.circular(fs * 0.025)),
              child: Icon(Icons.grid_view_rounded, color: !_showChart ? const Color(0xFF0D59F2) : const Color(0xFF7D92B1), size: fs * 0.045),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent(double fs, double h) {
    if (_chartData.isEmpty) return _emptyCard(fs, 'Нет данных за период');

    return Container(
      padding: EdgeInsets.fromLTRB(fs * 0.01, fs * 0.04, fs * 0.04, fs * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.05),
        border: Border.all(color: const Color(0xFF455664)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: fs * 0.1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const topPad = 24.0;
                      const bottomPad = 12.0;
                      final chartHeight = constraints.maxHeight - topPad - bottomPad;
                      return Stack(
                        children: [100.0, 75.0, 50.0, 25.0, 0.0].map((pct) {
                          final y = topPad + chartHeight - (pct / 100) * chartHeight;
                          return Positioned(
                            top: y - 7,
                            right: 0,
                            child: Text(
                              '${pct.toInt()}%',
                              style: TextStyle(color: const Color(0xFF455664), fontSize: fs * 0.023),
                              textAlign: TextAlign.right,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                SizedBox(width: fs * 0.02),
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _ChartPainter(data: _chartData, fs: fs),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: h * 0.008),
          Padding(
            padding: EdgeInsets.only(left: fs * 0.1 + fs * 0.02),
            child: Row(
              children: _chartData
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d.label,
                          style: TextStyle(color: const Color(0xFF7D92B1), fontSize: fs * 0.024, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsContent(double fs, double h) {
    final presentPct = _statMarkedTotal > 0 ? (_statPresent / _statMarkedTotal * 100).toStringAsFixed(1) : '0.0';
    final absentPct = _statMarkedTotal > 0 ? (_statAbsent / _statMarkedTotal * 100).toStringAsFixed(1) : '0.0';
    final excusedPct = _statMarkedTotal > 0 ? (_statExcused / _statMarkedTotal * 100).toStringAsFixed(1) : '0.0';

    if (_statTotalLessons == 0) return _emptyCard(fs, 'Нет данных за период');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statCard(fs, h, label: 'Всего занятий', value: '$_statTotalLessons', badge: '100%', badgeColor: const Color(0xFF34D399)),
              ),
              SizedBox(width: fs * 0.03),
              Expanded(
                child: _statCard(fs, h, label: 'Присутствуют', value: '$_statPresent', badge: '$presentPct%', badgeColor: const Color(0xFF34D399)),
              ),
            ],
          ),
        ),
        SizedBox(height: fs * 0.03),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statCard(fs, h, label: 'Отсутствуют', value: '$_statAbsent', badge: '$absentPct%', badgeColor: const Color(0xFFF87171)),
              ),
              SizedBox(width: fs * 0.03),
              Expanded(
                child: _statCard(fs, h, label: 'Уважительная', value: '$_statExcused', badge: '$excusedPct%', badgeColor: const Color(0xFFFACC15)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSection(double fs, double h, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'По предметам',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.048, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: h * 0.012),
        GestureDetector(
          onTap: () => _showSubjectPicker(context, fs),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: fs * 0.04, vertical: fs * 0.035),
            decoration: BoxDecoration(
              color: const Color(0xFF10232C),
              borderRadius: BorderRadius.circular(fs * 0.05),
              border: Border.all(color: const Color(0xFF455664)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSubject ?? 'Выберите предмет',
                    style: TextStyle(color: _selectedSubject != null ? Colors.white : const Color(0xFF7D92B1), fontSize: fs * 0.038, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF0D59F2), size: fs * 0.06),
              ],
            ),
          ),
        ),
        SizedBox(height: h * 0.015),
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
        border: Border.all(color: const Color(0xFF455664)),
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
            decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(
              badge,
              style: TextStyle(color: badgeColor, fontSize: fs * 0.028, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLessonsSection(double fs, double h, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Занятия за день',
          style: TextStyle(color: Colors.white, fontSize: fs * 0.048, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: h * 0.012),
        if (_dayLessons.isEmpty) _emptyCard(fs, 'Нет данных за ${_formatDateHuman(_navDay)}') else ...List.generate(_dayLessons.length, (i) => _buildDayLessonCard(fs, h, w, i)),
      ],
    );
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
        border: Border.all(color: const Color(0xFF455664)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _expandedDayLesson = isExpanded ? null : index;
            }),
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: fs * 0.025, vertical: 4),
                    decoration: BoxDecoration(color: _pctColor(pct.toDouble()).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
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
          if (isExpanded) ...[
            Container(height: 1, color: const Color(0xFF455664)),
            Padding(
              padding: EdgeInsets.all(fs * 0.035),
              child: Column(
                children: [
                  Row(
                    children: [
                      _miniStat(fs, const Color(0xFF34D399), 'Присутствуют', '$present'),
                      SizedBox(width: fs * 0.02),
                      _miniStat(fs, const Color(0xFFF87171), 'Отсутствуют', '$absent'),
                      SizedBox(width: fs * 0.02),
                      _miniStat(fs, const Color(0xFFFACC15), 'Уважительная', '$late_'),
                    ],
                  ),
                  SizedBox(height: h * 0.012),
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
                          _buildStudentAvatar(s, fs * 0.04),
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
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
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
        padding: EdgeInsets.symmetric(vertical: fs * 0.02, horizontal: fs * 0.01),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(fs * 0.03)),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: fs * 0.04, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: fs * 0.022),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAvatar(StudentAttendance s, double radius) {
    if (s.avatarUrl != null && s.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF3A5FCD),
        backgroundImage: NetworkImage(s.avatarUrl!),
      );
    }
    final asset = s.isMale
        ? 'assets/images/man_avatar.png'
        : 'assets/images/women_avatar.png';
    return CircleAvatar(
      radius: radius,
      backgroundImage: AssetImage(asset),
      backgroundColor: const Color(0xFF3A5FCD),
    );
  }

  Widget _emptyCard(double fs, String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fs * 0.06),
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(fs * 0.05),
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

class _DayData {
  final String label;
  final double percent;
  _DayData({required this.label, required this.percent});
}

class _ChartPainter extends CustomPainter {
  final List<_DayData> data;
  final double fs;
  _ChartPainter({required this.data, required this.fs});

  Color _pctColor(double pct) {
    if (pct >= 80) return const Color(0xFF34D399);
    if (pct >= 60) return const Color(0xFFFACC15);
    return const Color(0xFFF87171);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final validPoints = <int, double>{};
    for (int i = 0; i < data.length; i++) {
      if (data[i].percent >= 0) validPoints[i] = data[i].percent;
    }
    if (validPoints.isEmpty) return;

    const double topPad = 24.0;
    const double bottomPad = 12.0;
    final double chartTop = topPad;
    final double chartHeight = size.height - topPad - bottomPad;
    final double colWidth = size.width / data.length;

    double pctToY(double percent) => chartTop + chartHeight - (percent / 100) * chartHeight;

    Offset getPoint(int index, double percent) {
      final x = colWidth * index + colWidth / 2;
      return Offset(x, pctToY(percent));
    }

    final gridPaint = Paint()
      ..color = const Color(0xFF455664).withAlpha(60)
      ..strokeWidth = 1;
    for (final pct in [0.0, 25.0, 50.0, 75.0, 100.0]) {
      final y = pctToY(pct);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
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

      canvas.drawPath(fillPath, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF0D59F2).withAlpha(70), const Color(0xFF0D59F2).withAlpha(0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF0D59F2)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (final idx in sortedIndices) {
      final pt = getPoint(idx, validPoints[idx]!);
      final pct = validPoints[idx]!;
      final dotColor = _pctColor(pct);

      canvas.drawCircle(pt, 6, Paint()..color = dotColor);
      canvas.drawCircle(pt, 3.5, Paint()..color = const Color(0xFF10232C));
      canvas.drawCircle(pt, 2, Paint()..color = dotColor);

      final label = '${pct.toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: dotColor, fontSize: fs * 0.027, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      double tx = pt.dx - tp.width / 2;
      tx = tx.clamp(0.0, size.width - tp.width);
      final ty = (pt.dy - tp.height - 7).clamp(0.0, pt.dy - 2);
      tp.paint(canvas, Offset(tx, ty));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
