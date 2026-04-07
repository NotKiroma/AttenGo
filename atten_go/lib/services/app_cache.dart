import 'auth_service.dart';
import 'group_service.dart';

/// Единый кэш приложения.
/// Хранит последние загруженные данные — используется для мгновенного
/// отображения без лоадера при повторных открытиях экранов.
class AppCache {
  AppCache._();

  // ── Профиль ──────────────────────────────────────────────────────────────
  static UserProfile? profile;

  // ── Группа / членство ─────────────────────────────────────────────────────
  static Group? group;
  static GroupMember? membership;
  static bool? canManage;

  // ── Инвалидация ───────────────────────────────────────────────────────────
  static void clear() {
    profile = null;
    group = null;
    membership = null;
    canManage = null;
  }

  static void clearGroup() {
    group = null;
    membership = null;
    canManage = null;
  }
}
