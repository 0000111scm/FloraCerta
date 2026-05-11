import 'package:flutter/material.dart';

import '../../core/utils/app_spacing.dart';
import '../../core/widgets/flora_app_bar.dart';
import '../../services/app_data_repository.dart';
import '../identification/models/plant_identification.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final AppDataRepository _repository = AppDataRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String? _selectedSpecies;
  _HistoryDateFilter _dateFilter = _HistoryDateFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildFloraAppBar(context, title: 'Historico'),
      body: ValueListenableBuilder<List<PlantIdentification>>(
        valueListenable: _repository.identificationsListenable,
        builder: (context, identifications, child) {
          final speciesOptions =
              identifications
                  .map((item) => item.popularName.trim())
                  .where((name) => name.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final filtered = identifications.where(_matchesFilters).toList();

          if (identifications.isEmpty) {
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
                          Icons.history_rounded,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        AppSpacing.itemGap,
                        Text(
                          'Nenhuma identificacao salva ainda.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'As identificacoes salvas aparecerao aqui para consulta rapida.',
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

          return Column(
            children: [
              Padding(
                padding: AppSpacing.pagePadding,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar no historico',
                    hintText: 'Nome, endereco ou notas',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _query = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedSpecies,
                        decoration: const InputDecoration(labelText: 'Especie'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...speciesOptions.map(
                            (species) => DropdownMenuItem<String?>(
                              value: species,
                              child: Text(species),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecies = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<_HistoryDateFilter>(
                        initialValue: _dateFilter,
                        decoration: const InputDecoration(labelText: 'Periodo'),
                        items: _HistoryDateFilter.values
                            .map(
                              (filter) => DropdownMenuItem(
                                value: filter,
                                child: Text(filter.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _dateFilter = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: AppSpacing.pagePadding,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 52,
                                color: theme.colorScheme.primary,
                              ),
                              AppSpacing.itemGap,
                              Text(
                                'Nenhum resultado encontrado.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => AppSpacing.itemGap,
                    itemBuilder: (context, index) {
                      final identification = filtered[index];
                      return _HistoryCard(
                        identification: identification,
                        onEdit: () =>
                            _showIdentificationEditor(context, identification),
                        onDelete: () => _confirmRemoveIdentification(
                          context,
                          identification,
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _matchesFilters(PlantIdentification identification) {
    if (_selectedSpecies != null &&
        identification.popularName != _selectedSpecies) {
      return false;
    }

    if (!_matchesDateFilter(identification.identifiedAt)) {
      return false;
    }

    if (_query.isEmpty) {
      return true;
    }

    final haystack = [
      identification.popularName,
      identification.scientificName,
      identification.addressText ?? '',
      identification.city ?? '',
      identification.state ?? '',
      identification.notes,
      identification.description,
    ].join(' ').toLowerCase();

    return haystack.contains(_query);
  }

  bool _matchesDateFilter(DateTime identifiedAt) {
    final now = DateTime.now();
    final dateOnly = DateTime(
      identifiedAt.year,
      identifiedAt.month,
      identifiedAt.day,
    );
    switch (_dateFilter) {
      case _HistoryDateFilter.all:
        return true;
      case _HistoryDateFilter.last7Days:
        return dateOnly.isAfter(now.subtract(const Duration(days: 8)));
      case _HistoryDateFilter.last30Days:
        return dateOnly.isAfter(now.subtract(const Duration(days: 31)));
    }
  }

  Future<void> _showIdentificationEditor(
    BuildContext context,
    PlantIdentification identification,
  ) async {
    final descriptionController = TextEditingController(
      text: identification.description,
    );
    final notesController = TextEditingController(text: identification.notes);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar identificacao',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                AppSpacing.itemGap,
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                ),
                AppSpacing.itemGap,
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notas'),
                ),
                AppSpacing.sectionGap,
                ElevatedButton(
                  onPressed: () {
                    _repository.updateIdentification(
                      PlantIdentification(
                        id: identification.id,
                        popularName: identification.popularName,
                        scientificName: identification.scientificName,
                        confidence: identification.confidence,
                        description: descriptionController.text.trim(),
                        photoBytes: identification.photoBytes,
                        identifiedAt: identification.identifiedAt,
                        notes: notesController.text.trim(),
                        saveExactLocation: identification.saveExactLocation,
                        locationPrivacyMode: identification.locationPrivacyMode,
                        latitude: identification.latitude,
                        longitude: identification.longitude,
                        addressText: identification.addressText,
                        city: identification.city,
                        state: identification.state,
                      ),
                    );

                    Navigator.of(context).pop();
                  },
                  child: const Text('Salvar alteracoes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemoveIdentification(
    BuildContext context,
    PlantIdentification identification,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover identificacao'),
          content: Text(
            'Deseja remover a identificacao de ${identification.popularName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    _repository.removeIdentification(identification.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Identificacao removida.')));
  }
}

enum _HistoryDateFilter {
  all('Todo periodo'),
  last7Days('Ultimos 7 dias'),
  last30Days('Ultimos 30 dias');

  const _HistoryDateFilter(this.label);
  final String label;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.identification,
    required this.onEdit,
    required this.onDelete,
  });

  final PlantIdentification identification;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidenceText =
        '${(identification.confidence * 100).toStringAsFixed(0)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 96,
                height: 96,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          identification.popularName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar identificacao',
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remover identificacao',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    identification.scientificName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Confianca: $confidenceText',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Data: ${_formatDateTime(identification.identifiedAt)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Endereco: ${identification.addressText ?? 'Nao informado'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (identification.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notas: ${identification.notes}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
