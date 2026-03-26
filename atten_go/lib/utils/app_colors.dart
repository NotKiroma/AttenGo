import 'package:flutter/material.dart';

/// Централизованные цвета приложения.
/// Используйте вместо хардкод-значений по всему проекту.
class AppColors {
  AppColors._();

  // ── Основные фоны ──
  static const Color background = Color(0xFF101C22);
  static const Color surface = Color(0xFF10232C);
  static const Color surfaceDark = Color(0xFF152028);

  // ── Акцент / primary ──
  static const Color primary = Color(0xFF0D59F2);

  // ── Текст ──
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF7D92B1);

  // ── Границы / разделители ──
  static const Color border = Color(0xFF455664);

  // ── Статусы ──
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFACC15);

  // ── Неактивные элементы ──
  static const Color inactive = Color(0xFF94A3B8);
}
