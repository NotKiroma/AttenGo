import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/db_service.dart';
import 'screens/auth_wrapper.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Тёмный статус-бар
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Color(0xFF101C22), statusBarIconBrightness: Brightness.light, systemNavigationBarColor: Color(0xFF101C22), systemNavigationBarIconBrightness: Brightness.light));

  // Единственная точка инициализации Supabase
  await DatabaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AttenGo',

      // ═══ Тёмная тема — убирает белые вспышки ═══
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF101C22),
        canvasColor: const Color(0xFF101C22),
        cardColor: const Color(0xFF10232C),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101C22), surfaceTintColor: Colors.transparent),
        colorScheme: const ColorScheme.dark(surface: Color(0xFF101C22), primary: Color(0xFF0D59F2)),
        // SnackBar — контрастный на тёмном фоне
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1E3A4A),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: _DarkFadeTransitionBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()}),
        useMaterial3: true,
      ),

      home: AuthWrapper(mainApp: const MainScreen()),
    );
  }
}

/// Тёмный fade-переход вместо стандартного (который показывает белый фон)
class _DarkFadeTransitionBuilder extends PageTransitionsBuilder {
  const _DarkFadeTransitionBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return Container(
      color: const Color(0xFF101C22),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}
