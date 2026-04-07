// lib/services/db_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/env.dart';

class DatabaseService {
  DatabaseService._();

  /// Инициализация Supabase. Вызывается один раз в main().
  /// URL и ключ берутся из обфусцированного .env (envied).
  static Future<void> init() async {
    await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
