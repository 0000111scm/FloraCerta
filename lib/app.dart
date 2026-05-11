import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/diagnosis/diagnosis_page.dart';
import 'features/history/history_page.dart';
import 'features/home/home_page.dart';
import 'features/identification/identify_page.dart';
import 'features/identification/models/plant_identification_result_args.dart';
import 'features/identification/result_page.dart';
import 'features/map/map_page.dart';
import 'features/my_plants/plant_detail_page.dart';
import 'features/my_plants/my_plants_page.dart';
import 'features/settings/settings_page.dart';

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.identify,
      builder: (context, state) => const IdentifyPage(),
    ),
    GoRoute(
      path: AppRoutes.identifyResult,
      builder: (context, state) =>
          ResultPage(args: state.extra as PlantIdentificationResultArgs?),
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => HistoryPage(),
    ),
    GoRoute(path: AppRoutes.map, builder: (context, state) => MapPage()),
    GoRoute(
      path: AppRoutes.myPlants,
      builder: (context, state) => MyPlantsPage(),
    ),
    GoRoute(
      path: AppRoutes.myPlantDetail,
      builder: (context, state) =>
          PlantDetailPage(plantId: state.extra! as String),
    ),
    GoRoute(
      path: AppRoutes.diagnosis,
      builder: (context, state) => const DiagnosisPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => SettingsPage(),
    ),
  ],
);

class FloraCertaApp extends StatelessWidget {
  const FloraCertaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController.instance,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          title: 'FloraCerta',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
