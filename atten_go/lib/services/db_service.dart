import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static const _url     = 'https://hiidpfgcsljombikrhvy.supabase.co';
  static const _anonKey = 'sb_publishable_U4kAvFaV9UkOkUiL2qtujw__FIT_DKH';

  static Future<void> init() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
