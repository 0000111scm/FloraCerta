import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/config/app_constants.dart';
import 'core/theme/theme_mode_controller.dart';
import 'services/app_data_repository.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnvironment();
  await SupabaseService.instance.initializeIfConfigured();
  await AppDataRepository.instance.initialize();
  await ThemeModeController.instance.initialize();
  SupabaseService.instance.logConfigurationStatus();

  runApp(const FloraCertaApp());
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: AppConstants.envFileName);
  } catch (_) {
    // O arquivo .env e opcional nesta fase inicial.
  }
}
