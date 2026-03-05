import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/group_service.dart';
import 'login_screen.dart';

/// Оборачивает приложение: если пользователь не авторизован — показываем LoginScreen,
/// иначе — основное приложение (mainApp).
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
    _checkSession();
    _listenAuthChanges();
  }

  void _checkSession() {
    setState(() {
      _isLoggedIn = AuthService.isLoggedIn;
      _isLoading = false;
    });
  }

  void _listenAuthChanges() {
    AuthService.authStateChanges.listen((data) {
      final event = (data as AuthState).event;
      if (mounted) {
        setState(() {
          _isLoggedIn = AuthService.isLoggedIn;
        });

        if (event == AuthChangeEvent.signedOut) {
          AttendanceService.invalidateCache();
          GroupService.invalidateCache();
        }

        // При входе — проверяем приглашения и создаём группу если нет
        if (event == AuthChangeEvent.signedIn) {
          _onSignIn();
        }
      }
    });
  }

  Future<void> _onSignIn() async {
    // Убеждаемся что у пользователя есть группа
    final group = await GroupService.getCurrentGroup();
    if (group == null) {
      // Группа не создалась автоматически — возможно старый аккаунт
      // Проверяем есть ли приглашения
      final invitations = await GroupService.getMyInvitations();
      if (invitations.isEmpty) {
        // Нет приглашений и нет группы — это проблема, но не блокируем
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101C22),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2))),
      );
    }

    return _isLoggedIn ? widget.mainApp : const LoginScreen();
  }
}
