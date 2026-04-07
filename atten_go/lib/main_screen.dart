import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';
import 'services/group_service.dart';
import 'services/realtime_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _canManage = false;
  bool _hasGroup = false;
  bool _roleLoaded = false;
  int _screenKey = 0;

  StreamSubscription? _groupMembersSub;
  StreamSubscription? _groupsSub;

  // Таймер для дебаунса фонового обновления при resume
  Timer? _resumeDebounce;

  late final AnimationController _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))..value = 1.0;
  late Animation<double> _fadeAnimation = _buildFade();
  late Animation<Offset> _slideAnimation = _buildSlide(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Инициализируем Realtime один раз для всего приложения
    RealtimeService.init();

    _loadRole();

    // Слушаем изменения в group_members и groups — они могут реально поменять роль
    _groupMembersSub = RealtimeService.onGroupMembersChanged.listen((_) {
      developer.log('[MainScreen] group_members changed → reload role');
      _loadRole();
    });
    _groupsSub = RealtimeService.onGroupsChanged.listen((_) {
      developer.log('[MainScreen] groups changed → reload role');
      _loadRole();
    });
  }

  // ── Загрузка роли ──────────────────────────────────────
  Future<void> _loadRole() async {
    GroupService.invalidateCache();
    final results = await Future.wait([
      GroupService.canManage(),
      GroupService.getCurrentGroup(),
    ]);
    final can = results[0] as bool;
    final group = results[1] as dynamic;
    if (mounted) {
      final hasGroup = group != null;
      // Перестраиваем экраны только если роль реально изменилась
      final roleChanged = can != _canManage || hasGroup != _hasGroup;
      setState(() {
        _canManage = can;
        _hasGroup = hasGroup;
        _roleLoaded = true;
        if (roleChanged && _roleLoaded) _screenKey++;
      });
    }
  }

  void refreshRole() => _loadRole();

  Animation<double> _buildFade() => Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  Animation<Offset> _buildSlide(bool r) => Tween<Offset>(begin: Offset(r ? 0.04 : -0.04, 0), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _groupMembersSub?.cancel();
    _groupsSub?.cancel();
    _resumeDebounce?.cancel();
    RealtimeService.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Переподключаем realtime — это важно
      RealtimeService.reconnect();

      // Фоновое тихое обновление роли с дебаунсом 1.5с
      // НЕ инвалидируем кэш и НЕ перестраиваем экраны если роль не изменилась
      _resumeDebounce?.cancel();
      _resumeDebounce = Timer(const Duration(milliseconds: 1500), () {
        _silentRoleCheck();
      });
    }
  }

  /// Тихая проверка роли в фоне — не вызывает setState если ничего не изменилось.
  /// Пользователь не видит никаких лоадеров или перестроений.
  Future<void> _silentRoleCheck() async {
    try {
      GroupService.invalidateCache();
      final results = await Future.wait([
        GroupService.canManage(),
        GroupService.getCurrentGroup(),
      ]);
      final can = results[0] as bool;
      final group = results[1] as dynamic;
      if (mounted) {
        final hasGroup = group != null;
        if (can != _canManage || hasGroup != _hasGroup) {
          // Роль реально изменилась — обновляем
          developer.log('[MainScreen] role changed on resume, rebuilding');
          setState(() {
            _canManage = can;
            _hasGroup = hasGroup;
            _screenKey++;
          });
        }
        // Если роль та же — ничего не делаем, пользователь не замечает
      }
    } catch (e) {
      developer.log('[MainScreen] silentRoleCheck error: $e');
    }
  }

  List<Widget> get _screens {
    if (_hasGroup && !_canManage) {
      return [HomeScreen(onNavigateToSchedule: () => _goToTab(1), onNavigateToStats: null, onRoleChanged: refreshRole), ScheduleScreen(canEdit: false, hasGroup: true), ProfileScreen(onRoleChanged: refreshRole)];
    }
    return [HomeScreen(onNavigateToSchedule: () => _goToTab(1), onNavigateToStats: () => _goToTab(3), onRoleChanged: refreshRole), ScheduleScreen(canEdit: _canManage, hasGroup: _hasGroup), const AttendanceScreen(), const StatsScreen(), ProfileScreen(onRoleChanged: refreshRole)];
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
    if (!_roleLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF101C22),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2))),
      );
    }
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
