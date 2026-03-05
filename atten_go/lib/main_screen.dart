import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens/home_screen.dart';
import 'screens/shedule_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';

/// Тёмная тема для MaterialApp — убирает белую вспышку при переходах
ThemeData appDarkTheme() {
  return ThemeData(
    scaffoldBackgroundColor: const Color(0xFF101C22),
    canvasColor: const Color(0xFF101C22),
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D59F2), brightness: Brightness.dark),
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()}),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))..value = 1.0;

  late Animation<double> _fadeAnimation = _buildFade();
  late Animation<Offset> _slideAnimation = _buildSlide(true);

  late final List<Widget> _screens = [HomeScreen(onNavigateToSchedule: () => _goToTab(1), onNavigateToStats: () => _goToTab(3)), const SheduleScreen(), const AttendanceScreen(), const StatsScreen(), const ProfileScreen()];

  Animation<double> _buildFade() {
    return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  Animation<Offset> _buildSlide(bool goingRight) {
    return Tween<Offset>(begin: Offset(goingRight ? 0.04 : -0.04, 0), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    if (index == _currentIndex) return;
    final goingRight = index > _currentIndex;
    _fadeAnimation = _buildFade();
    _slideAnimation = _buildSlide(goingRight);
    setState(() => _currentIndex = index);
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    double iconSize = MediaQuery.of(context).size.width * 0.09;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: IndexedStack(index: _currentIndex, children: _screens),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF101C22)),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF455664), width: 1)),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            selectedFontSize: 0,
            unselectedFontSize: 0,
            iconSize: 0,
            currentIndex: _currentIndex,
            onTap: _goToTab,
            backgroundColor: const Color(0xFF101C22),
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
      icon: SvgPicture.asset(path, width: size, height: size, colorFilter: const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn)),
      activeIcon: SvgPicture.asset(path, width: size, height: size, colorFilter: const ColorFilter.mode(Color(0xFF0D59F2), BlendMode.srcIn)),
      label: '',
    );
  }
}
