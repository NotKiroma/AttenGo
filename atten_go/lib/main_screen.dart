import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens/home_screen.dart';
import 'screens/shedule_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';
import 'services/group_service.dart';

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
  bool _canManage = false;
  bool _hasGroup = false;
  bool _roleLoaded = false;
  int _screenKey = 0; // инкрементируется при смене роли — пересоздаёт все экраны

  late final AnimationController _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))..value = 1.0;
  late Animation<double> _fadeAnimation = _buildFade();
  late Animation<Offset> _slideAnimation = _buildSlide(true);

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    GroupService.invalidateCache();
    final can = await GroupService.canManage();
    final group = await GroupService.getCurrentGroup();
    if (mounted)
      setState(() {
        _canManage = can;
        _hasGroup = group != null;
        _roleLoaded = true;
        _screenKey++; // пересоздаём экраны при каждой смене роли
      });
  }

  void refreshRole() => _loadRole();

  Animation<double> _buildFade() => Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  Animation<Offset> _buildSlide(bool r) => Tween<Offset>(begin: Offset(r ? 0.04 : -0.04, 0), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Три состояния:
  // 1. !hasGroup (нет группы) → все 5 вкладок, посещаемость/отчёты показывают заглушку
  // 2. hasGroup && !canManage (member в чужой группе) → 3 вкладки (без посещаемости и отчётов)
  // 3. canManage (owner/admin) → все 5 вкладок, всё разрешено
  List<Widget> get _screens {
    // member в чужой группе — скрываем посещаемость и отчёты
    if (_hasGroup && !_canManage) {
      return [HomeScreen(onNavigateToSchedule: () => _goToTab(1), onNavigateToStats: null, onRoleChanged: refreshRole), SheduleScreen(canEdit: false, hasGroup: true), ProfileScreen(onRoleChanged: refreshRole)];
    }
    // owner/admin или нет группы — все 5 вкладок
    return [HomeScreen(onNavigateToSchedule: () => _goToTab(1), onNavigateToStats: () => _goToTab(3), onRoleChanged: refreshRole), SheduleScreen(canEdit: _canManage, hasGroup: _hasGroup), const AttendanceScreen(), const StatsScreen(), ProfileScreen(onRoleChanged: refreshRole)];
  }

  List<String> get _icons => (_hasGroup && !_canManage)
      ? ['assets/icons/house-03-svgrepo-com.svg', 'assets/icons/book-open-svgrepo-com.svg', 'assets/icons/user-01-svgrepo-com.svg']
      : ['assets/icons/house-03-svgrepo-com.svg', 'assets/icons/book-open-svgrepo-com.svg', 'assets/icons/list-checklist-svgrepo-com.svg', 'assets/icons/chart-bar-vertical-01-svgrepo-com.svg', 'assets/icons/user-01-svgrepo-com.svg'];

  void _goToTab(int index) {
    if (index == _currentIndex) return;
    _fadeAnimation = _buildFade();
    _slideAnimation = _buildSlide(index > _currentIndex);
    setState(() => _currentIndex = index.clamp(0, _screens.length - 1));
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleLoaded)
      return const Scaffold(
        backgroundColor: Color(0xFF101C22),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2))),
      );
    final safe = _currentIndex.clamp(0, _screens.length - 1);
    final double iconSize = MediaQuery.of(context).size.width * 0.09;
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: IndexedStack(key: ValueKey(_screenKey), index: safe, children: _screens),
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
            currentIndex: safe,
            onTap: _goToTab,
            backgroundColor: const Color(0xFF101C22),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            items: _icons
                .map(
                  (p) => BottomNavigationBarItem(
                    icon: SvgPicture.asset(p, width: iconSize, height: iconSize, colorFilter: const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn)),
                    activeIcon: SvgPicture.asset(p, width: iconSize, height: iconSize, colorFilter: const ColorFilter.mode(Color(0xFF0D59F2), BlendMode.srcIn)),
                    label: '',
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
