// lib/services/auth_service.dart
//
// Исправления vs предыдущей версии:
//  • getProfile() — сначала читает из локальной БД, Supabase только fallback
//  • updateProfile() — после обновления синкает профиль в локальную БД
//  • uploadAvatar() — после загрузки синкает профиль в локальную БД

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_service.dart';
import '../local/sync_service.dart';

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
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'] as String)
            : null,
      );

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class AuthService {
  static final _db = DatabaseService.client;
  static final _local = SyncService.db;

  static UserProfile? _cachedProfile;

  static String? get currentUserId => _db.auth.currentUser?.id;
  static bool get isLoggedIn => _db.auth.currentUser != null;

  static void invalidateProfileCache() => _cachedProfile = null;

  static Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

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
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
        },
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
  // Вход / Выход
  // ══════════════════════════════════════════════════════════════════════════

  static Future<({bool success, String? error})> login({
    required String email,
    required String password,
  }) async {
    try {
      await _db.auth.signInWithPassword(email: email.trim(), password: password);
      return (success: true, error: null);
    } catch (e) {
      developer.log('[AuthService] login error: $e');
      final msg = e.toString();
      if (msg.contains('Invalid login credentials')) {
        return (success: false, error: 'Неверный email или пароль');
      }
      if (msg.contains('Email not confirmed')) {
        return (success: false, error: 'Подтвердите email перед входом');
      }
      return (success: false, error: 'Ошибка входа: $e');
    }
  }

  static Future<void> logout() async {
    _cachedProfile = null;
    await _db.auth.signOut();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Профиль
  // ══════════════════════════════════════════════════════════════════════════

  /// Получить профиль:
  ///   1. In-memory кэш (мгновенно)
  ///   2. LocalDatabase (SQLite, без сети)
  ///   3. Supabase (только если нет в локальной БД)
  static Future<UserProfile?> getProfile({bool forceRefresh = false}) async {
    final uid = currentUserId;
    if (uid == null) return null;

    // 1. In-memory кэш
    if (!forceRefresh && _cachedProfile != null && _cachedProfile!.id == uid) {
      return _cachedProfile;
    }

    // 2. Локальная БД
    if (!forceRefresh) {
      try {
        final local = await _local.getProfile(uid);
        if (local != null && local.email.isNotEmpty) {
          _cachedProfile = UserProfile(
            id: local.id,
            email: local.email,
            firstName: local.firstName,
            lastName: local.lastName,
            avatarUrl: local.avatarUrl,
            createdAt: local.createdAt != null
                ? DateTime.tryParse(local.createdAt!)
                : null,
          );
          return _cachedProfile;
        }
      } catch (e) {
        developer.log('[AuthService] getProfile local error: $e');
      }
    }

    // 3. Supabase (fallback / forceRefresh)
    try {
      final row = await _db
          .from('profiles')
          .select('id, email, first_name, last_name, avatar_url, created_at')
          .eq('id', uid)
          .single();
      _cachedProfile = UserProfile.fromRow(row);
      return _cachedProfile;
    } catch (e) {
      developer.log('[AuthService] getProfile remote error: $e');
      final user = _db.auth.currentUser;
      if (user != null) {
        _cachedProfile = UserProfile(
          id: user.id,
          email: user.email ?? '',
          firstName: user.userMetadata?['first_name'] as String? ?? '',
          lastName: user.userMetadata?['last_name'] as String? ?? '',
        );
        return _cachedProfile;
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
      await _db.auth.updateUser(UserAttributes(
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
        },
      ));
      // Синкаем профиль в локальную БД
      _cachedProfile = null;
      await SyncService.syncProfile(uid);
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: 'Ошибка: $e');
    }
  }

  static Future<({bool success, String? error})> changePassword(
      String newPassword) async {
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

  static Future<({bool success, String? error, String? url})> uploadAvatar(
      Uint8List bytes) async {
    final uid = currentUserId;
    if (uid == null) return (success: false, error: 'Не авторизован', url: null);
    try {
      const path = 'avatar.png';
      final storagePath = '$uid/$path';
      const contentType = 'image/png';

      try {
        await _db.storage.from('avatars').remove([
          '$uid/avatar.png',
          '$uid/avatar.jpg',
          '$uid/avatar.jpeg',
          '$uid/avatar.webp',
        ]);
      } catch (_) {}

      await _db.storage.from('avatars').uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final url = _db.storage.from('avatars').getPublicUrl(storagePath);
      final urlWithCache = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      await _db.from('profiles').update({'avatar_url': urlWithCache}).eq('id', uid);

      // Синкаем профиль в локальную БД
      _cachedProfile = null;
      await SyncService.syncProfile(uid);

      return (success: true, error: null, url: urlWithCache);
    } catch (e) {
      developer.log('[AuthService] uploadAvatar error: $e');
      return (success: false, error: 'Ошибка загрузки: $e', url: null);
    }
  }
}
