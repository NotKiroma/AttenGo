// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/db_service.dart'; // <-- через сервис
import 'screens/auth_wrapper.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Color(0xFF101C22), statusBarIconBrightness: Brightness.light, systemNavigationBarColor: Color(0xFF101C22), systemNavigationBarIconBrightness: Brightness.light));

  // Единая точка инициализации — секреты внутри
  await DatabaseService.init();

  runApp(const MyApp());
}

// ... остальной код MyApp без изменений

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AttenGo',
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],

      // ═══ ЭТО УБИРАЕТ БЕЛЫЕ ВСПЫШКИ ═══
      theme: ThemeData(
        // Фон всех Scaffold
        scaffoldBackgroundColor: const Color(0xFF101C22),
        // Фон канваса (между страницами при анимации)
        canvasColor: const Color(0xFF101C22),
        // Фон карточек и диалогов
        cardColor: const Color(0xFF10232C),
        // Фон AppBar
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101C22), surfaceTintColor: Colors.transparent),
        // Тёмная цветовая схема
        colorScheme: const ColorScheme.dark(surface: Color(0xFF101C22), primary: Color(0xFF0D59F2)),
        // Фон страницы при анимации переходов
        pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: _DarkFadeTransitionBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()}),
        useMaterial3: true,
      ),

      // ═══════════════════════════════════
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
      color: const Color(0xFF101C22), // тёмный фон под анимацией
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}
