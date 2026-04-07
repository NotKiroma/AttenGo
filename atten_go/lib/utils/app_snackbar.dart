import 'package:flutter/material.dart';

/// Стилизованные уведомления в стиле приложения
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isWarning = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final Color accentColor;
    final IconData icon;
    if (isError) {
      accentColor = const Color(0xFFF87171);
      icon = Icons.error_outline_rounded;
    } else if (isWarning) {
      accentColor = const Color(0xFFFACC15);
      icon = Icons.warning_amber_rounded;
    } else {
      accentColor = const Color(0xFF34D399);
      icon = Icons.check_circle_outline_rounded;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF152028),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        elevation: 8,
      ),
    );
  }

  static void success(BuildContext context, String message) => show(context, message);
  static void error(BuildContext context, String message) => show(context, message, isError: true);
  static void warning(BuildContext context, String message) => show(context, message, isWarning: true);
}
