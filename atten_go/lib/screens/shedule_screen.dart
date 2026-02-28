import 'package:flutter/material.dart';

class SheduleScreen extends StatefulWidget {
  const SheduleScreen({super.key});

  @override
  State<SheduleScreen> createState() => _SheduleScreenState();
}

class _SheduleScreenState extends State<SheduleScreen> {
  int _activeIndex = 0; // ВТ активен по умолчанию

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
      {'timeStart': '08:00', 'timeEnd': '09:20', 'subject': 'Программирование цифровых устройств', 'room': 'Ауд. 313, Этаж 3', 'teacher': 'Зиаятдинов В.Р.'},
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Основы предпринимательской деятельности', 'room': 'Ауд. 105, Этаж 1', 'teacher': 'Шамова Ш.Н.'},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Нейронные сети и искусственный интеллект', 'room': 'Ауд. 406, Этаж 4', 'teacher': 'Абайұлы Т.'},
    ],
    // ВТ
    [
      {'timeStart': '08:00', 'timeEnd': '09:20', 'subject': 'Физическая культура', 'room': 'Спортивный зал', 'teacher': 'Зеленин В.А.'},
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Объектно-ориентированное программирование', 'room': 'Ауд. 310, Этаж 3', 'teacher': 'Нехорошев В.Д.'},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Разработка прикладных решений', 'room': 'Ауд. 211, Этаж 2', 'teacher': 'Мырзабекова Д.Е.'},
      {'timeStart': '12:50', 'timeEnd': '14:10', 'subject': 'Основы социологии и политологии', 'room': 'Ауд. 106, Этаж 1', 'teacher': 'Нуржумаев М.Т.'},
    ],
    // СР
    [
      {'timeStart': '08:00', 'timeEnd': '09:20', 'subject': 'Программирование цифровых устройств', 'room': 'Ауд. 313, Этаж 3', 'teacher': 'Зиаятдинов В.Р.'},
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Объектно-ориентированное программирование', 'room': 'Ауд. 310, Этаж 3', 'teacher': 'Нехорошев В.Д.'},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Разработка прикладных решений', 'room': 'Ауд. 211, Этаж 2', 'teacher': 'Мырзабекова Д.Е.'},
      {'timeStart': '12:50', 'timeEnd': '14:10', 'subject': 'Основы предпринимательской деятельности', 'room': 'Ауд. 105, Этаж 1', 'teacher': 'Шамова Ш.Н.'},
      {'timeStart': '14:20', 'timeEnd': '15:40', 'subject': 'Культурология', 'room': 'Ауд. 106, Этаж 1', 'teacher': 'Нуржумаев М.Т.'},
    ],
    // ЧТ
    [
      {'timeStart': '08:00', 'timeEnd': '09:20', 'subject': 'Физическая культура', 'room': 'Спортивный зал', 'teacher': 'Зеленин В.А.'},
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Объектно-ориентированное программирование', 'room': 'Ауд. 310, Этаж 3', 'teacher': 'Нехорошев В.Д.'},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Нейронные сети и искусственный интеллект', 'room': 'Ауд. 406, Этаж 4', 'teacher': 'Абайұлы Т.'},
    ],
    // ПТ
    [
      {'timeStart': '09:30', 'timeEnd': '10:50', 'subject': 'Разработка прикладных решений', 'room': 'Ауд. 211, Этаж 2', 'teacher': 'Мырзабекова Д.Е.'},
      {'timeStart': '11:00', 'timeEnd': '12:20', 'subject': 'Нейронные сети и искусственный интеллект', 'room': 'Ауд. 406, Этаж 4', 'teacher': 'Абайұлы Т.'},
      {'timeStart': '12:50', 'timeEnd': '14:10', 'subject': 'Основы социологии и политологии', 'room': 'Ауд. 106, Этаж 1', 'teacher': 'Нуржумаев М.Т.'},
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
        padding: EdgeInsets.symmetric(horizontal: w * 0.03).add(EdgeInsets.only(top: h * 0.02)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _weekCardes(w, h),
            Text(
              'ЗАНЯТИЯ СЕГОДНЯ',
              style: TextStyle(
                color: const Color(0xFF7D92B1), //
                fontSize: w * 0.033,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: h * 0.015),
            _lessonsList(w, h),
          ],
        ),
      ),
    );
  }

  // Список занятий для выбранного дня
  Widget _lessonsList(double w, double h) {
    final lessons = _schedule[_activeIndex];
    return Expanded(
      child: SingleChildScrollView(
        child: Column(children: lessons.map((lesson) => _buildLessonCard(w, h, lesson)).toList()), //
      ),
    );
  }

  // Конструктор карточек занятий
  Widget _buildLessonCard(double w, double h, Map<String, String> lesson) {
    const Color accentColor = Color(0xFF455664);
    const Color cardColor = Color(0xFF10232C);
    const Color borderColor = Color(0xFF455664);
    const Color subjectColor = Colors.white;
    const Color timeStartColor = Colors.white;
    const Color timeEndColor = Color(0xFF7D92B1);
    const Color secondaryColor = Color(0xFF7D92B1);

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Время
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  lesson['timeStart']!,
                  style: TextStyle(color: timeStartColor, fontSize: w * 0.04, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), width: 1.5, height: 28, color: accentColor.withOpacity(0.5)),
                ),
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
                  Text(
                    lesson['subject']!,
                    style: TextStyle(color: subjectColor, fontSize: w * 0.042, fontWeight: FontWeight.bold, height: 1.3),
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

  // Карточки дней недели
  Widget _weekCardes(double w, double h) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.03),
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

  // Конструктор карточки дня недели
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
