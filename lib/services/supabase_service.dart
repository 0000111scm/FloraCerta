import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_constants.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;

  bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  bool get isInitialized => _initialized;

  String get supabaseUrl =>
      dotenv.env[AppConstants.supabaseUrlKey]?.trim() ?? '';

  String get supabaseAnonKey =>
      dotenv.env[AppConstants.supabaseAnonKey]?.trim() ?? '';

  Future<void> initializeIfConfigured() async {
    if (_initialized || !isConfigured) {
      return;
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    _initialized = true;
  }

  SupabaseClient? get client {
    if (!_initialized) {
      return null;
    }

    return Supabase.instance.client;
  }

  void logConfigurationStatus() {
    if (isConfigured) {
      debugPrint('Supabase configurado no ambiente.');
      return;
    }

    debugPrint('Supabase nao configurado. O app seguira em modo local.');
  }
}
