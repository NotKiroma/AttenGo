import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'screens/home_screen.dart';
import 'screens/shedule_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(), // Главный экран
    SheduleScreen(), // Экран расписания
    AttendanceScreen(), // Экран посещаемости
    StatsScreen(), // Экран статистики
    ProfileScreen(), // Экран профиля
  ];

  @override
  Widget build(BuildContext context) {
    // Адаптивный размер иконок — 6% от ширины экрана
    double iconSize = MediaQuery.of(context).size.width * 0.09;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Color(0xFF101C22)),
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF455664), width: 1)),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            selectedFontSize: 0, // убирает место под текст
            unselectedFontSize: 0, // убирает место под текст
            iconSize: 0, // убираем встроенные иконки (у нас SVG)
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Color(0xFF101C22),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            items: [
              _buildNavItem('assets/icons/house-03-svgrepo-com.svg', iconSize),
              _buildNavItem('assets/icons/book-open-svgrepo-com.svg', iconSize),
              _buildNavItem('assets/icons/list-checklist-svgrepo-com.svg', iconSize),
              _buildNavItem('assets/icons/chart-bar-vertical-01-svgrepo-com.svg', iconSize),
              _buildNavItem('assets/icons/user-01-svgrepo-com.svg', iconSize),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(String path, double size) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        path, //
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          Color(0xFF94A3B8), //
          BlendMode.srcIn,
        ),
      ),
      activeIcon: SvgPicture.asset(
        path, //
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          Color(0xFF0D59F2), //
          BlendMode.srcIn,
        ),
      ),
      label: '',
    );
  }
}
