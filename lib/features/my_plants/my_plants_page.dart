import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_routes.dart';
import '../../core/utils/app_spacing.dart';
import '../../core/widgets/flora_app_bar.dart';
import '../../services/app_data_repository.dart';
import '../identification/models/plant_identification.dart';
import 'models/plant_status.dart';
import 'models/user_plant.dart';

class MyPlantsPage extends StatefulWidget {
  const MyPlantsPage({super.key});

  @override
  State<MyPlantsPage> createState() => _MyPlantsPageState();
}

class _MyPlantsPageState extends State<MyPlantsPage> {
  final AppDataRepository _repository = AppDataRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  PlantStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildFloraAppBar(context, title: 'Minhas plantas'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManualPlantForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova planta'),
      ),
      body: ValueListenableBuilder<List<UserPlant>>(
        valueListenable: _repository.userPlantsListenable,
        builder: (context, plants, child) {
          return ValueListenableBuilder<List<PlantIdentification>>(
            valueListenable: _repository.identificationsListenable,
            builder: (context, identifications, _) {
              final filtered = plants.where(_matchesFilters).toList();
              final identificationById = <String, PlantIdentification>{
                for (final item in identifications) item.id: item,
              };

              if (plants.isEmpty) {
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
                              Icons.local_florist_rounded,
                              size: 56,
                              color: theme.colorScheme.primary,
                            ),
                            AppSpacing.itemGap,
                            Text(
                              'Nenhuma planta pessoal cadastrada ainda.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Adicione uma identificacao em Minhas plantas para acompanhar o desenvolvimento.',
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
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Buscar plantas',
                            hintText: 'Apelido, especie ou local',
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
                        AppSpacing.itemGap,
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _StatusFilterChip(
                                label: 'Todos',
                                selected: _selectedStatus == null,
                                onTap: () {
                                  setState(() {
                                    _selectedStatus = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ...PlantStatus.values.map(
                                (status) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _StatusFilterChip(
                                    label: status.label,
                                    selected: _selectedStatus == status,
                                    onTap: () {
                                      setState(() {
                                        _selectedStatus = status;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
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
                                    Icons.filter_alt_off_rounded,
                                    size: 52,
                                    color: theme.colorScheme.primary,
                                  ),
                                  AppSpacing.itemGap,
                                  Text(
                                    'Nenhuma planta corresponde aos filtros.',
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
                          final plant = filtered[index];
                          final photoBytes = plant.identificationId == null
                              ? null
                              : identificationById[plant.identificationId]
                                    ?.photoBytes;
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => context.push(
                                AppRoutes.myPlantDetail,
                                extra: plant.id,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    _PlantThumb(photoBytes: photoBytes),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plant.nickname,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${plant.popularName} - ${plant.status.label}',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            plant.locationName,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _matchesFilters(UserPlant plant) {
    final matchesStatus =
        _selectedStatus == null || plant.status == _selectedStatus;
    if (!matchesStatus) {
      return false;
    }

    if (_query.isEmpty) {
      return true;
    }

    final haystack = [
      plant.nickname,
      plant.popularName,
      plant.scientificName,
      plant.locationName,
      plant.status.label,
    ].join(' ').toLowerCase();

    return haystack.contains(_query);
  }

  Future<void> _showManualPlantForm(BuildContext context) async {
    final nicknameController = TextEditingController();
    final popularNameController = TextEditingController();
    final scientificNameController = TextEditingController();
    final locationController = TextEditingController();
    var selectedStatus = PlantStatus.unknown;

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
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cadastro manual',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.itemGap,
                    TextField(
                      controller: nicknameController,
                      decoration: const InputDecoration(labelText: 'Apelido'),
                    ),
                    AppSpacing.itemGap,
                    TextField(
                      controller: popularNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome popular',
                      ),
                    ),
                    AppSpacing.itemGap,
                    TextField(
                      controller: scientificNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome cientifico',
                      ),
                    ),
                    AppSpacing.itemGap,
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Local onde fica',
                      ),
                    ),
                    AppSpacing.itemGap,
                    DropdownButtonFormField<PlantStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status inicial',
                      ),
                      items: PlantStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    AppSpacing.sectionGap,
                    ElevatedButton(
                      onPressed: () {
                        final nickname = nicknameController.text.trim();
                        final popularName = popularNameController.text.trim();
                        final scientificName = scientificNameController.text
                            .trim();
                        final location = locationController.text.trim();

                        if (nickname.isEmpty ||
                            popularName.isEmpty ||
                            scientificName.isEmpty ||
                            location.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Preencha apelido, nome popular, nome cientifico e local.',
                              ),
                            ),
                          );
                          return;
                        }

                        _repository.saveUserPlant(
                          UserPlant(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            popularName: popularName,
                            scientificName: scientificName,
                            nickname: nickname,
                            locationName: location,
                            status: selectedStatus,
                            createdAt: DateTime.now(),
                          ),
                        );

                        Navigator.of(context).pop();
                      },
                      child: const Text('Salvar planta'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PlantThumb extends StatelessWidget {
  const _PlantThumb({required this.photoBytes});

  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (photoBytes != null && photoBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 54,
          height: 54,
          child: Image.memory(
            photoBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      );
    }
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.local_florist_rounded,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
