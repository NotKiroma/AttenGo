import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/group_service.dart';
import '../services/realtime_service.dart';
import '../local/sync_service.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  final Widget mainApp;

  const AuthWrapper({super.key, required this.mainApp});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _init();
    _listenAuthChanges();
  }

  /// При старте: проверяем сессию, если залогинены — ждём syncAll перед показом UI.
  Future<void> _init() async {
    final loggedIn = AuthService.isLoggedIn;

    if (loggedIn) {
      RealtimeService.init();

      // 1. Синкаем ТОЛЬКО профиль и группу для быстрого старта
      final uid = AuthService.currentUserId;
      if (uid != null) {
        await Future.wait([SyncService.syncProfile(uid), SyncService.syncGroup(uid)]);
      }

      // 2. Остальное (Студенты, Расписание и т.д.) скачиваем в фоне!
      // Обратите внимание: тут НЕТ слова await перед SyncService.syncAll
      SyncService.syncAll().catchError((e) {
        debugPrint('Background sync error: $e');
      });
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isLoading = false; // Пускаем пользователя на главный экран быстрее!
      });
    }
  }

  void _listenAuthChanges() {
    AuthService.authStateChanges.listen((authState) async {
      final event = authState.event;
      if (!mounted) return;

      if (event == AuthChangeEvent.signedIn) {
        // Показываем лоадер, синкаем, потом показываем главный экран
        setState(() => _isLoading = true);
        RealtimeService.init();
        await SyncService.syncAll();
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
        }
      } else if (event == AuthChangeEvent.signedOut) {
        RealtimeService.dispose();
        AttendanceService.invalidateCache();
        GroupService.fullInvalidate();
        await SyncService.clearAll();
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101C22),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0D59F2)),
              SizedBox(height: 16),
              Text('Загрузка данных...', style: TextStyle(color: Color(0xFF7D92B1), fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? widget.mainApp : const LoginScreen();
  }
}
