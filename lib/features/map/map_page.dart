import 'package:flutter/material.dart';

import '../../core/utils/app_spacing.dart';
import '../../core/widgets/flora_app_bar.dart';
import '../../services/app_data_repository.dart';
import '../identification/models/plant_identification.dart';

class MapPage extends StatelessWidget {
  MapPage({super.key});

  final AppDataRepository _repository = AppDataRepository.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildFloraAppBar(context, title: 'Mapa'),
      body: ValueListenableBuilder<List<PlantIdentification>>(
        valueListenable: _repository.identificationsListenable,
        builder: (context, identifications, child) {
          final localizedItems = identifications
              .where(
                (item) =>
                    item.latitude != null &&
                    item.longitude != null &&
                    (item.addressText?.isNotEmpty ?? false),
              )
              .toList();

          if (localizedItems.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        AppSpacing.itemGap,
                        Text(
                          'Nenhum registro com localizacao disponivel ainda.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Salve identificacoes com localizacao para preparar a futura visualizacao em mapa.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: AppSpacing.pagePadding,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapa em preparacao',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ainda nao ha um SDK de mapas configurado. Esta tela organiza os registros georreferenciados que depois serao exibidos como marcadores.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.itemGap,
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _SummaryChip(
                            icon: Icons.location_on_outlined,
                            label: '${localizedItems.length} registros',
                          ),
                          _SummaryChip(
                            icon: Icons.public_outlined,
                            label: '${_countCities(localizedItems)} cidades',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.sectionGap,
              ...localizedItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LocationRecordCard(identification: item),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _countCities(List<PlantIdentification> items) {
    final cities = items
        .map((item) => item.city?.trim() ?? '')
        .where((city) => city.isNotEmpty)
        .toSet();
    return cities.length;
  }
}

class _LocationRecordCard extends StatelessWidget {
  const _LocationRecordCard({required this.identification});

  final PlantIdentification identification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: Image.memory(
                      identification.photoBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        identification.popularName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        identification.scientificName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _PinLine(
                        icon: Icons.place_outlined,
                        text:
                            identification.addressText ??
                            'Endereco indisponivel',
                      ),
                      const SizedBox(height: 6),
                      _PinLine(
                        icon: Icons.schedule_outlined,
                        text: _formatDateTime(identification.identifiedAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marcador preparado',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latitude: ${identification.latitude!.toStringAsFixed(5)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Longitude: ${identification.longitude!.toStringAsFixed(5)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if ((identification.city?.isNotEmpty ?? false) ||
                      (identification.state?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Regiao: ${_buildRegionText()}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildRegionText() {
    final parts = [
      identification.city?.trim() ?? '',
      identification.state?.trim() ?? '',
    ].where((part) => part.isNotEmpty).toList();

    return parts.isEmpty ? 'Nao informada' : parts.join(' - ');
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _PinLine extends StatelessWidget {
  const _PinLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
