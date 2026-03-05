import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_service.dart';

// ─── Модель профиля ───────────────────────────────────────────────────────────

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserProfile.fromRow(Map<String, dynamic> row) => UserProfile(
        id: row['id'] as String,
        email: row['email'] as String? ?? '',
        firstName: row['first_name'] as String? ?? '',
        lastName: row['last_name'] as String? ?? '',
        avatarUrl: row['avatar_url'] as String?,
        createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      );

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─── Сервис авторизации ───────────────────────────────────────────────────────

class AuthService {
  static final _db = DatabaseService.client;

  static String? get currentUserId => _db.auth.currentUser?.id;
  static bool get isLoggedIn => _db.auth.currentUser != null;
  static Stream get authStateChanges => _db.auth.onAuthStateChange;

  // ══════════════════════════════════════════════════════════════════════════
  // Регистрация
  // ══════════════════════════════════════════════════════════════════════════

  static Future<({bool success, String? error})> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _db.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'first_name': firstName.trim(), 'last_name': lastName.trim()},
      );
      if (response.user == null) {
        return (success: false, error: 'Не удалось создать аккаунт');
      }
      return (success: true, error: null);
    } catch (e) {
      developer.log('[AuthService] register error: $e');
      final msg = e.toString();
      if (msg.contains('already registered') || msg.contains('already been registered')) {
        return (success: false, error: 'Этот email уже зарегистрирован');
      }
      if (msg.contains('valid email')) return (success: false, error: 'Некорректный email');
      if (msg.contains('at least 6')) return (success: false, error: 'Пароль должен содержать минимум 6 символов');
      return (success: false, error: 'Ошибка регистрации: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Вход
  // ══════════════════════════════════════════════════════════════════════════

  static Future<({bool success, String? error})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _db.auth.signInWithPassword(email: email.trim(), password: password);
      if (response.user == null) return (success: false, error: 'Неверный email или пароль');
      return (success: true, error: null);
    } catch (e) {
      developer.log('[AuthService] login error: $e');
      final msg = e.toString();
      if (msg.contains('Invalid login') || msg.contains('invalid_grant')) {
        return (success: false, error: 'Неверный email или пароль');
      }
      return (success: false, error: 'Ошибка входа: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Выход
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> logout() async {
    try {
      await _db.auth.signOut();
    } catch (e) {
      developer.log('[AuthService] logout error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Профиль
  // ══════════════════════════════════════════════════════════════════════════

  static Future<UserProfile?> getProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final row = await _db.from('profiles').select().eq('id', uid).single();
      return UserProfile.fromRow(row);
    } catch (e) {
      developer.log('[AuthService] getProfile error: $e');
      final user = _db.auth.currentUser;
      if (user != null) {
        return UserProfile(
          id: user.id,
          email: user.email ?? '',
          firstName: user.userMetadata?['first_name'] as String? ?? '',
          lastName: user.userMetadata?['last_name'] as String? ?? '',
        );
      }
      return null;
    }
  }

  static Future<({bool success, String? error})> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, error: 'Не авторизован');
    try {
      await _db.from('profiles').update({
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
      }).eq('id', uid);
      await _db.auth.updateUser(
        UserAttributes(data: {'first_name': firstName.trim(), 'last_name': lastName.trim()}),
      );
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: 'Ошибка: $e');
    }
  }

  static Future<({bool success, String? error})> changePassword(String newPassword) async {
    try {
      await _db.auth.updateUser(UserAttributes(password: newPassword));
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: 'Ошибка: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Аватарка
  // ══════════════════════════════════════════════════════════════════════════

  static Future<({bool success, String? error, String? url})> uploadAvatar(Uint8List bytes, String ext) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, error: 'Не авторизован', url: null);
    try {
      final path = '$uid/avatar.$ext';
      await _db.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
          );
      final url = _db.storage.from('avatars').getPublicUrl(path);
      // Добавляем timestamp чтобы сбросить кеш
      final urlWithCache = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      await _db.from('profiles').update({'avatar_url': urlWithCache}).eq('id', uid);
      return (success: true, error: null, url: urlWithCache);
    } catch (e) {
      developer.log('[AuthService] uploadAvatar error: $e');
      return (success: false, error: 'Ошибка загрузки: $e', url: null);
    }
  }
}
