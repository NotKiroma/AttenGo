import 'package:flutter/material.dart';

class SheduleScreen extends StatefulWidget {
  const SheduleScreen({super.key});

  @override
  State<SheduleScreen> createState() => _SheduleScreenState();
}

class _SheduleScreenState extends State<SheduleScreen> {
  int _activeIndex = 1; // ВТ активен по умолчанию

  // Дни недели и даты для отображения в карточках
  final List<Map<String, String>> _days = [
    {'week': 'ПН', 'day': '24'},
    {'week': 'ВТ', 'day': '25'},
    {'week': 'СР', 'day': '26'},
    {'week': 'ЧТ', 'day': '27'},
    {'week': 'ПТ', 'day': '28'},
  ];

  // Расписание по дням (индекс 0 = ПН, 1 = ВТ, и т.д.)
  final List<List<Map<String, String>>> _schedule = [
    // ПН
    [
      {'timeStart': '08:00', 'timeEnd': '09:20', 'subject': 'Программирование цифровых устройств', 'room': 'Ауд. 313, Этаж 3', 'teacher': 'Зиаятдинов В.Р.', 'status': 'прошла'},
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Основы предпринимательской деятельности', 'room': 'Ауд. 105, Этаж 1', 'teacher': 'Шамова Ш.Н.', 'status': ''},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Нейронные сети и искусственный интеллект', 'room': 'Ауд. 406, Этаж 4', 'teacher': 'Абайұлы Т.', 'status': ''},
    ],
    // ВТ
    [
      {'timeStart': '08:00', 'timeEnd': '09:20', 'subject': 'Физическая культура', 'room': 'Спортивный зал', 'teacher': 'Зеленин В.А.', 'status': ''},
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Объектно-ориентированное программирование', 'room': 'Ауд. 310, Этаж 3', 'teacher': 'Нехорошев В.Д.', 'status': 'сейчас'},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Разработка прикладных решений', 'room': 'Ауд. 211, Этаж 2', 'teacher': 'Мырзабекова Д.Е.', 'status': ''},
      {'timeStart': '12:50', 'timeEnd': '14:10', 'subject': 'Основы социологии и политологии', 'room': 'Ауд. 106, Этаж 1', 'teacher': 'Нуржумаев М.Т.', 'status': ''},
    ],
    // СР
    [
      {'timeStart': '08:00', 'timeEnd': '09:20', 'subject': 'Программирование цифровых устройств', 'room': 'Ауд. 313, Этаж 3', 'teacher': 'Зиаятдинов В.Р.', 'status': ''},
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Объектно-ориентированное программирование', 'room': 'Ауд. 310, Этаж 3', 'teacher': 'Нехорошев В.Д.', 'status': ''},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Разработка прикладных решений', 'room': 'Ауд. 211, Этаж 2', 'teacher': 'Мырзабекова Д.Е.', 'status': ''},
      {'timeStart': '12:50', 'timeEnd': '14:10', 'subject': 'Основы предпринимательской деятельности', 'room': 'Ауд. 105, Этаж 1', 'teacher': 'Шамова Ш.Н.', 'status': ''},
      {'timeStart': '14:20', 'timeEnd': '15:40', 'subject': 'Культурология', 'room': 'Ауд. 106, Этаж 1', 'teacher': 'Нуржумаев М.Т.', 'status': ''},
    ],
    // ЧТ
    [
      {'timeStart': '08:00', 'timeEnd': '09:20', 'subject': 'Физическая культура', 'room': 'Спортивный зал', 'teacher': 'Зеленин В.А.', 'status': ''},
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Объектно-ориентированное программирование', 'room': 'Ауд. 310, Этаж 3', 'teacher': 'Нехорошев В.Д.', 'status': ''},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Нейронные сети и искусственный интеллект', 'room': 'Ауд. 406, Этаж 4', 'teacher': 'Абайұлы Т.', 'status': ''},
    ],
    // ПТ
    [
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Разработка прикладных решений', 'room': 'Ауд. 211, Этаж 2', 'teacher': 'Мырзабекова Д.Е.', 'status': ''},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Нейронные сети и искусственный интеллект', 'room': 'Ауд. 406, Этаж 4', 'teacher': 'Абайұлы Т.', 'status': ''},
      {'timeStart': '12:50', 'timeEnd': '14:10', 'subject': 'Основы социологии и политологии', 'room': 'Ауд. 106, Этаж 1', 'teacher': 'Нуржумаев М.Т.', 'status': ''},
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Расписание',
          style: TextStyle(color: const Color(0xFFFFFFFF), fontSize: w * 0.06, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.03),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.025),
              _weekCardes(w, h),
              SizedBox(height: h * 0.03),
              _sectionTitle(w),
              SizedBox(height: h * 0.015),
              _lessonsList(w, h),
              SizedBox(height: h * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  // Заголовок секции "ЗАНЯТИЯ СЕГОДНЯ"
  Widget _sectionTitle(double w) {
    return Text(
      'ЗАНЯТИЯ СЕГОДНЯ',
      style: TextStyle(
        color: const Color(0xFF7D92B1), //
        fontSize: w * 0.033,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  // Список занятий для выбранного дня
  Widget _lessonsList(double w, double h) {
    final lessons = _schedule[_activeIndex];

    if (lessons.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: h * 0.1),
          child: Text(
            'Занятий нет',
            style: TextStyle(color: const Color(0xFF7D92B1), fontSize: w * 0.045),
          ),
        ),
      );
    }

    return Column(children: lessons.map((lesson) => _buildLessonCard(w, h, lesson)).toList());
  }

  // Конструктор карточек занятий
  Widget _buildLessonCard(double w, double h, Map<String, String> lesson) {
    final status = lesson['status'] ?? '';
    final isNow = status == 'сейчас';
    final isPast = status == 'прошла';

    final Color accentColor;
    if (isNow)
      accentColor = const Color(0xFF0D59F2);
    else if (isPast)
      accentColor = const Color(0xFF2A3A45);
    else
      accentColor = const Color(0xFF455664);

    final Color cardColor;
    if (isNow)
      cardColor = const Color(0x100D59F2);
    else if (isPast)
      cardColor = const Color(0xFF0D171D);
    else
      cardColor = const Color(0xFF10232C);

    final Color borderColor;
    if (isNow)
      borderColor = const Color(0x500D59F2);
    else if (isPast)
      borderColor = const Color(0xFF1A2830);
    else
      borderColor = const Color(0xFF455664);

    final Color subjectColor = isPast ? const Color(0xFF3D5060) : Colors.white;
    final Color timeStartColor = isPast ? const Color(0xFF3D5060) : Colors.white;
    final Color timeEndColor = isPast ? const Color(0xFF2A3A45) : const Color(0xFF7D92B1);
    final Color secondaryColor = isPast ? const Color(0xFF2A3A45) : const Color(0xFF7D92B1);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(w * 0.04),
        child: Row(
          children: [
            // Время
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson['timeStart']!,
                  style: TextStyle(color: timeStartColor, fontSize: w * 0.04, fontWeight: FontWeight.bold),
                ),
                Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), width: 1.5, height: 28, color: accentColor.withOpacity(0.5)),
                Text(
                  lesson['timeEnd']!,
                  style: TextStyle(color: timeEndColor, fontSize: w * 0.034),
                ),
              ],
            ),
            SizedBox(width: w * 0.04),
            // Правая часть
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          lesson['subject']!,
                          style: TextStyle(color: subjectColor, fontSize: w * 0.042, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                      ),
                      if (status.isNotEmpty) ...[SizedBox(width: w * 0.02), _statusBadge(w, status)],
                    ],
                  ),
                  SizedBox(height: h * 0.008),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: secondaryColor, size: w * 0.038),
                      SizedBox(width: w * 0.01),
                      Text(
                        lesson['room']!,
                        style: TextStyle(color: secondaryColor, fontSize: w * 0.033),
                      ),
                    ],
                  ),
                  SizedBox(height: h * 0.005),
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: secondaryColor, size: w * 0.038),
                      SizedBox(width: w * 0.01),
                      Text(
                        lesson['teacher']!,
                        style: TextStyle(color: secondaryColor, fontSize: w * 0.033),
                      ),
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

  // Бейдж "ПРОШЛА" / "СЕЙЧАС"
  Widget _statusBadge(double w, String status) {
    final isNow = status == 'сейчас';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: 4),
      decoration: BoxDecoration(color: isNow ? const Color(0x7022C55E) : const Color(0x25455664), borderRadius: BorderRadius.circular(9.5)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: isNow ? Colors.white : const Color(0xFF7D92B1), fontSize: w * 0.028, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _weekCardes(double w, double h) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_days.length, (index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeIndex = index;
              });
            },
            child: _buildWeekCard(w, h, isActive: _activeIndex == index, week: _days[index]['week']!, day: _days[index]['day']!),
          );
        }),
      ),
    );
  }

  Widget _buildWeekCard(double w, double h, {required bool isActive, required String week, required String day}) {
    final color = isActive ? const Color(0xFFFFFFFF) : const Color(0xFF7D92B1);
    final bgColor = isActive ? const Color(0xFF0D59F2) : const Color(0xFF10232C);
    final borderColor = isActive ? const Color(0x00FFFFFF) : const Color(0xFF455664);

    return Container(
      width: w * 0.16,
      height: h * 0.11,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            week,
            style: TextStyle(color: color, fontSize: w * 0.038, fontWeight: FontWeight.normal),
          ),
          SizedBox(height: h * 0.01),
          Text(
            day,
            style: TextStyle(color: const Color(0xFFFFFFFF), fontSize: w * 0.055, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
