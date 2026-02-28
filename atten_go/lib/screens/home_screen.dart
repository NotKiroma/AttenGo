import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101C22),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: h * 0.095,
        title: Row(
          children: [
            Container(height: h * 0.07, child: Image.asset('assets/images/man_avatar.png')),
            SizedBox(width: w * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Привет, Егор!',
                  style: TextStyle(color: Colors.white, fontSize: w * 0.06, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Староста • 3 курс',
                  style: TextStyle(color: Color(0xFF7D92B1), fontSize: w * 0.035),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.03),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: h * 0.025),
              _buildLessonsCard(w, h),
              _sheduleToDay(w, h),
              _attandanceGroup(w, h),
              SizedBox(height: h * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  // Карточка с оставшимися занятиями
  Widget _buildLessonsCard(double w, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.06),
      decoration: BoxDecoration(
        color: const Color(0xFF0D59F2),
        borderRadius: BorderRadius.circular(w * 0.06),
        boxShadow: [BoxShadow(color: const Color(0x200D59F2), blurRadius: 15, spreadRadius: 3, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Оставшиеся занятия',
                style: TextStyle(color: Colors.white70, fontSize: w * 0.035),
              ),
              SizedBox(height: h * 0.006),
              Text(
                '4',
                style: TextStyle(color: Colors.white, fontSize: w * 0.13, fontWeight: FontWeight.bold, height: 1.0),
              ),
              SizedBox(height: h * 0.006),
              Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: h * 0.008),
                decoration: BoxDecoration(color: Color(0x20FFFFFF), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'След.: Математика | 10:30',
                  style: TextStyle(color: Colors.white, fontSize: w * 0.032),
                ),
              ),
            ],
          ),
          Container(
            width: w * 0.22,
            height: w * 0.22,
            decoration: const BoxDecoration(color: Color(0x10FFFFFF), shape: BoxShape.circle),
            child: Icon(Icons.calendar_today_rounded, color: Colors.white, size: w * 0.1),
          ),
        ],
      ),
    );
  }

  // Карточки с расписанием на сегодня
  Widget _sheduleToDay(double w, double h) {
    return Container(
      margin: EdgeInsets.only(top: h * 0.03),
      width: double.infinity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Расписание на сегодня",
                style: TextStyle(color: Colors.white, fontSize: w * 0.052),
              ),
              Text(
                "Все",
                style: TextStyle(color: Color(0xFF0D59F2), fontSize: w * 0.048),
              ),
            ],
          ),
          SizedBox(height: h * 0.015),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildScheduleCard(
                  w, //
                  h,
                  isActive: true,
                  subject: "Цифровые устройства",
                  room: "Ауд. 313 • Зиаятдинов",
                  time: "08:00 - 09:20 AM",
                ),
                SizedBox(width: w * 0.04),
                _buildScheduleCard(
                  w, //
                  h,
                  isActive: false,
                  subject: "Объектно-ориентированное программирование",
                  room: "Ауд. 310 • Нехорошев",
                  time: "09:30 - 10:50 AM",
                ),
                SizedBox(width: w * 0.04),
                _buildScheduleCard(
                  w, //
                  h,
                  isActive: false,
                  subject: "Физическая культура",
                  room: "Спортивный зал • Зеленин",
                  time: "11:00 - 12:20 AM",
                ),
                SizedBox(width: w * 0.04),
                _buildScheduleCard(
                  w, //
                  h,
                  isActive: false,
                  subject: "Разработка прикладных решений",
                  room: "Ауд. 211 • Мырзабекова",
                  time: "12:50 - 14:10 AM",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Карточка с информацией о занятии
  Widget _buildScheduleCard(double w, double h, {required bool isActive, required String subject, required String room, required String time}) {
    final color = isActive ? Color(0xFF0D59F2) : Color(0xFF94A3B8);
    final bgColor = isActive ? Color(0x200D59F2) : Color(0x2094A3B8);
    final borderColor = isActive ? Color(0xFF0D59F2) : Color(0x4094A3B8);
    final label = isActive ? "В ПРОЦЕССЕ" : "ОЖИДАЕТСЯ";

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      width: w * 0.72,
      decoration: BoxDecoration(
        color: const Color(0xFF10232C),
        borderRadius: BorderRadius.circular(w * 0.06),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: h * 0.005),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15)),
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: w * 0.035, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: w * 0.02),
              Icon(Icons.access_time_filled, color: color, size: w * 0.07),
            ],
          ),
          SizedBox(height: h * 0.018),
          Text(
            subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false, // режет прямо посреди слова
            style: TextStyle(color: Colors.white, fontSize: w * 0.05, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: h * 0.01),
          Text(
            room,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Color(0xFF7D92B1), fontSize: w * 0.035),
          ),
          SizedBox(height: h * 0.018),
          Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF7D92B1), size: w * 0.04),
              SizedBox(width: w * 0.015),
              Text(
                time,
                style: TextStyle(color: Color(0xFF7D92B1), fontSize: w * 0.035),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Карточка с посещаемостью группы
  Widget _attandanceGroup(double w, double h) {
    return Container(
      margin: EdgeInsets.only(top: h * 0.03),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Посещаемость группы",
            style: TextStyle(color: Colors.white, fontSize: w * 0.052),
          ),
          SizedBox(height: h * 0.015),
          Container(
            padding: EdgeInsets.all(w * 0.04),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF10232C),
              borderRadius: BorderRadius.circular(w * 0.06),
              border: Border.all(color: Color(0x4094A3B8), width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: w * 0.28,
                      height: w * 0.28,
                      decoration: BoxDecoration(
                        color: Color(0xFF10232C),
                        border: Border.all(color: Color(0xFF0D59F2), width: w * 0.025),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "88%",
                          style: TextStyle(color: Colors.white, fontSize: w * 0.07, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.05),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow(w, Color(0xFF0D59F2), "Посещаемость", "24"),
                          SizedBox(height: h * 0.015),
                          _buildStatRow(w, Color(0xFFF87171), "Отсутствуют", "2"),
                          SizedBox(height: h * 0.015),
                          _buildStatRow(w, Color(0xFFFACC15), "Опоздали", "1"),
                        ],
                      ),
                    ), // ← и закрой
                  ],
                ),
                SizedBox(height: h * 0.025),
                Text(
                  "Подробный отчет",
                  style: TextStyle(color: Color(0xFF0D59F2), fontSize: w * 0.045),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Строка с показателем посещаемости, количеством присутствующих, отсутствующих и опоздавших
  Widget _buildStatRow(double w, Color dotColor, String label, String value) {
    return Row(
      children: [
        Container(
          width: w * 0.03,
          height: w * 0.03,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: w * 0.02),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: w * 0.042),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: w * 0.042, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
