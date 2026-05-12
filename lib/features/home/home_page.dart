import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/config/app_constants.dart';
import '../../core/config/app_routes.dart';
import '../../core/utils/app_spacing.dart';
import '../../core/widgets/feature_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _requestedStartupPermissions = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedStartupPermissions) {
      return;
    }
    _requestedStartupPermissions = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStartupPermissions();
    });
  }

  Future<void> _requestStartupPermissions() async {
    final permissions = <Permission>[
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.notification,
    ];

    await permissions.request();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Text(
            'Painel',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF2D9C3B)
                      : theme.colorScheme.primaryContainer,
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF58BD5C)
                      : theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identifique, registre e acompanhe suas plantas.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fluxo completo para foto, historico, mapa e acompanhamento da sua colecao.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.sectionGap,
          Text(
            'Acoes rapidas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fluxos principais do FloraCerta',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.itemGap,
          FeatureCard(
            title: 'Identificar planta',
            subtitle: 'Capture uma foto ou use uma imagem da galeria.',
            icon: Icons.camera_alt_rounded,
            onTap: () => context.push(AppRoutes.identify),
          ),
          AppSpacing.itemGap,
          FeatureCard(
            title: 'Historico',
            subtitle: 'Consulte registros anteriores de identificacao.',
            icon: Icons.history_rounded,
            onTap: () => context.push(AppRoutes.history),
          ),
          AppSpacing.itemGap,
          FeatureCard(
            title: 'Mapa',
            subtitle: 'Visualize plantas registradas por localizacao.',
            icon: Icons.map_rounded,
            onTap: () => context.push(AppRoutes.map),
          ),
          AppSpacing.itemGap,
          FeatureCard(
            title: 'Minhas plantas',
            subtitle: 'Acompanhe o desenvolvimento da sua colecao.',
            icon: Icons.local_florist_rounded,
            onTap: () => context.push(AppRoutes.myPlants),
          ),
          AppSpacing.itemGap,
          FeatureCard(
            title: 'Diagnostico',
            subtitle: 'Organize registros de doencas e pragas.',
            icon: Icons.health_and_safety_rounded,
            onTap: () => context.push(AppRoutes.diagnosis),
          ),
          AppSpacing.itemGap,
          FeatureCard(
            title: 'Configuracoes',
            subtitle: 'Veja status do ambiente e atalhos do app.',
            icon: Icons.settings_outlined,
            onTap: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}
