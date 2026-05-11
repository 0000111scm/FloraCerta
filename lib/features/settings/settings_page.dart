import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_routes.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../core/utils/app_spacing.dart';
import '../../core/widgets/flora_app_bar.dart';
import '../../services/app_data_repository.dart';
import '../../services/plant_identification_service.dart';
import '../../services/supabase_service.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final AppDataRepository _repository = AppDataRepository.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final PlantIdentificationService _plantIdentificationService =
      const PlantIdentificationService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildFloraAppBar(context, title: 'Configuracoes'),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Text(
            'Ajustes e status do ambiente',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Painel simples para acompanhar o estado atual do app durante a fase de desenvolvimento.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.sectionGap,
          _SettingsSection(
            title: 'Tema',
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeModeController.instance,
                builder: (context, themeMode, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aparencia do aplicativo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_outlined),
                                label: Text('Claro'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_outlined),
                                label: Text('Escuro'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.phone_android_outlined),
                                label: Text('Sistema'),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (selection) {
                              final selectedMode = selection.first;
                              ThemeModeController.instance.setThemeMode(
                                selectedMode,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          AppSpacing.sectionGap,
          _SettingsSection(
            title: 'Infraestrutura',
            children: [
              _StatusTile(
                title: 'Modo de dados local',
                subtitle: _repository.isUsingPersistentLocalStorage
                    ? 'Historico, Minhas plantas, diario e problemas usam armazenamento local persistente.'
                    : 'Historico, Minhas plantas e diario usam armazenamento em memoria nesta etapa.',
                icon: Icons.storage_rounded,
                statusLabel: _repository.isUsingPersistentLocalStorage
                    ? 'Persistente'
                    : 'Ativo',
                statusColor: theme.colorScheme.primary,
              ),
              _StatusTile(
                title: 'Supabase',
                subtitle: _supabaseService.isConfigured
                    ? 'Credenciais detectadas no .env. Integracao pronta para evolucao.'
                    : 'Nao configurado. O app continua funcionando em modo local.',
                icon: Icons.cloud_outlined,
                statusLabel: _supabaseService.isConfigured
                    ? 'Configurado'
                    : 'Pendente',
                statusColor: _supabaseService.isConfigured
                    ? theme.colorScheme.primary
                    : theme.colorScheme.tertiary,
              ),
              _StatusTile(
                title: 'API de identificacao',
                subtitle: _plantIdentificationService.hasApiConfiguration
                    ? 'Configuracao detectada. O app tenta consulta real e usa fallback local apenas em falha.'
                    : 'Sem configuracao. O fluxo atual usa resultado local de exemplo.',
                icon: Icons.eco_outlined,
                statusLabel: _plantIdentificationService.hasApiConfiguration
                    ? 'Ativa'
                    : 'Mock local',
                statusColor: _plantIdentificationService.hasApiConfiguration
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
              ),
            ],
          ),
          AppSpacing.sectionGap,
          _SettingsSection(
            title: 'Resumo do app',
            children: [
              ValueListenableBuilder(
                valueListenable: _repository.identificationsListenable,
                builder: (context, identifications, child) {
                  return _CountTile(
                    title: 'Identificacoes salvas',
                    count: identifications.length,
                    icon: Icons.history_rounded,
                  );
                },
              ),
              ValueListenableBuilder(
                valueListenable: _repository.userPlantsListenable,
                builder: (context, userPlants, child) {
                  return _CountTile(
                    title: 'Plantas pessoais',
                    count: userPlants.length,
                    icon: Icons.local_florist_rounded,
                  );
                },
              ),
              ValueListenableBuilder(
                valueListenable: _repository.plantLogsListenable,
                builder: (context, plantLogs, child) {
                  return _CountTile(
                    title: 'Registros de diario',
                    count: plantLogs.length,
                    icon: Icons.menu_book_rounded,
                  );
                },
              ),
              ValueListenableBuilder(
                valueListenable: _repository.plantProblemsListenable,
                builder: (context, plantProblems, child) {
                  return _CountTile(
                    title: 'Problemas registrados',
                    count: plantProblems.length,
                    icon: Icons.bug_report_outlined,
                  );
                },
              ),
            ],
          ),
          AppSpacing.sectionGap,
          _SettingsSection(
            title: 'Acoes rapidas',
            children: [
              _ActionTile(
                title: 'Abrir historico',
                subtitle: 'Ver as identificacoes registradas localmente.',
                icon: Icons.history_rounded,
                onTap: () => context.push(AppRoutes.history),
              ),
              _ActionTile(
                title: 'Abrir Minhas plantas',
                subtitle: 'Acompanhar plantas pessoais e diario.',
                icon: Icons.local_florist_rounded,
                onTap: () => context.push(AppRoutes.myPlants),
              ),
              _ActionTile(
                title: 'Abrir diagnostico',
                subtitle:
                    'Usar o formulario de sintomas com resposta de exemplo.',
                icon: Icons.health_and_safety_rounded,
                onTap: () => context.push(AppRoutes.diagnosis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...children.expand((child) => [child, const SizedBox(height: 12)]),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.statusLabel,
    required this.statusColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.title,
    required this.count,
    required this.icon,
  });

  final String title;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$count',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
