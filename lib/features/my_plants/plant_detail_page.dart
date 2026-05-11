import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/app_spacing.dart';
import '../../core/widgets/flora_app_bar.dart';
import '../../services/app_data_repository.dart';
import '../../services/image_picker_service.dart';
import '../diagnosis/models/plant_problem.dart';
import 'models/plant_log.dart';
import 'models/plant_status.dart';
import 'models/user_plant.dart';

class PlantDetailPage extends StatelessWidget {
  PlantDetailPage({required this.plantId, super.key});

  final String plantId;
  final AppDataRepository _repository = AppDataRepository.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<UserPlant>>(
      valueListenable: _repository.userPlantsListenable,
      builder: (context, plants, child) {
        final plant = _repository.findUserPlantById(plantId);

        if (plant == null) {
          return Scaffold(
            appBar: buildFloraAppBar(context, title: 'Detalhes da planta'),
            body: const Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Text(
                  'A planta selecionada nao foi encontrada.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return _PlantDetailView(plant: plant, repository: _repository);
      },
    );
  }
}

class _PlantDetailView extends StatelessWidget {
  const _PlantDetailView({required this.plant, required this.repository});

  final UserPlant plant;
  final AppDataRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildFloraAppBar(
        context,
        title: plant.nickname,
        actions: [
          IconButton(
            tooltip: 'Editar planta',
            onPressed: () => _showPlantEditor(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Remover planta',
            onPressed: () => _confirmRemovePlant(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogEditor(context),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Novo registro'),
      ),
      body: ValueListenableBuilder<List<PlantLog>>(
        valueListenable: repository.plantLogsListenable,
        builder: (context, logs, child) {
          return ValueListenableBuilder<List<PlantProblem>>(
            valueListenable: repository.plantProblemsListenable,
            builder: (context, problems, child) {
              final plantLogs = repository.logsForPlant(plant.id);
              final plantProblems = repository.problemsForPlant(plant.id);

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
                            plant.popularName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            plant.scientificName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.itemGap,
                          _InfoLine(label: 'Apelido', value: plant.nickname),
                          _InfoLine(label: 'Local', value: plant.locationName),
                          _InfoLine(
                            label: 'Status atual',
                            value: plant.status.label,
                          ),
                          _InfoLine(
                            label: 'Cadastrada em',
                            value: _formatDateTime(plant.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.sectionGap,
                  Text(
                    'Diario da planta',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acompanhe observacoes, estado de saude e tratamentos aplicados.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.itemGap,
                  if (plantLogs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Nenhum registro foi adicionado ainda para esta planta.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...plantLogs.map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlantLogCard(
                          log: log,
                          onEdit: () => _showLogEditor(context, existing: log),
                          onDelete: () => _confirmRemoveLog(context, log),
                        ),
                      ),
                    ),
                  AppSpacing.sectionGap,
                  Text(
                    'Historico de problemas',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diagnosticos e observacoes de doencas ou pragas registrados para esta planta.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.itemGap,
                  if (plantProblems.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Nenhum problema foi registrado ainda para esta planta.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...plantProblems.map(
                      (problem) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlantProblemCard(
                          problem: problem,
                          onEdit: () =>
                              _showProblemEditor(context, existing: problem),
                          onDelete: () =>
                              _confirmRemoveProblem(context, problem),
                        ),
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

  Future<void> _confirmRemovePlant(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover planta'),
          content: const Text(
            'Isso remove a planta pessoal e tambem todos os registros do diario e problemas associados.',
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

    repository.removeUserPlant(plant.id);
    if (context.canPop()) {
      context.pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Planta removida com seus dados associados.'),
      ),
    );
  }

  Future<void> _showPlantEditor(BuildContext context) async {
    final nicknameController = TextEditingController(text: plant.nickname);
    final locationController = TextEditingController(text: plant.locationName);
    var selectedStatus = plant.status;

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
                      'Editar planta',
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
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Local onde fica',
                      ),
                    ),
                    AppSpacing.itemGap,
                    DropdownButtonFormField<PlantStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status da planta',
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
                        final location = locationController.text.trim();

                        if (nickname.isEmpty || location.isEmpty) {
                          return;
                        }

                        repository.updateUserPlant(
                          UserPlant(
                            id: plant.id,
                            identificationId: plant.identificationId,
                            popularName: plant.popularName,
                            scientificName: plant.scientificName,
                            nickname: nickname,
                            locationName: location,
                            status: selectedStatus,
                            createdAt: plant.createdAt,
                          ),
                        );

                        Navigator.of(context).pop();
                      },
                      child: const Text('Salvar alteracoes'),
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

  Future<void> _confirmRemoveLog(BuildContext context, PlantLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover registro'),
          content: const Text('Deseja remover este registro do diario?'),
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

    repository.removePlantLog(log.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Registro removido.')));
  }

  Future<void> _confirmRemoveProblem(
    BuildContext context,
    PlantProblem problem,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover problema'),
          content: const Text('Deseja remover este problema registrado?'),
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

    repository.removePlantProblem(problem.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Problema removido.')));
  }

  Future<void> _showLogEditor(
    BuildContext context, {
    PlantLog? existing,
  }) async {
    final imagePickerService = ImagePickerService();
    final noteController = TextEditingController(text: existing?.note ?? '');
    final treatmentController = TextEditingController(
      text: existing?.treatment ?? '',
    );
    final heightController = TextEditingController(
      text: existing?.heightCm?.toString() ?? '',
    );
    var selectedStatus = existing?.healthStatus ?? plant.status;
    XFile? selectedImage;
    Uint8List? selectedImageBytes = existing?.photoBytes;
    String? selectedImageName = existing?.photoPath;
    var isLoadingImage = false;

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
                      existing == null ? 'Novo registro' : 'Editar registro',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.itemGap,
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observacao',
                        hintText: 'Ex.: folhas novas, solo seco, recebeu poda.',
                      ),
                    ),
                    AppSpacing.itemGap,
                    DropdownButtonFormField<PlantStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Saude atual',
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
                    AppSpacing.itemGap,
                    TextField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Altura em cm (opcional)',
                      ),
                    ),
                    AppSpacing.itemGap,
                    TextField(
                      controller: treatmentController,
                      decoration: const InputDecoration(
                        labelText: 'Tratamento aplicado (opcional)',
                      ),
                    ),
                    AppSpacing.itemGap,
                    ElevatedButton.icon(
                      onPressed: isLoadingImage
                          ? null
                          : () async {
                              setModalState(() {
                                isLoadingImage = true;
                              });

                              final image = await imagePickerService
                                  .pickFromGallery();
                              if (image != null) {
                                selectedImage = image;
                                selectedImageBytes = await image.readAsBytes();
                                selectedImageName = image.name;
                              }

                              setModalState(() {
                                isLoadingImage = false;
                              });
                            },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        selectedImageName == null
                            ? 'Adicionar foto ao registro'
                            : 'Trocar foto do registro',
                      ),
                    ),
                    if (selectedImageName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        selectedImageName!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    AppSpacing.sectionGap,
                    ElevatedButton(
                      onPressed: () {
                        if (noteController.text.trim().isEmpty) {
                          return;
                        }

                        final parsedHeight = double.tryParse(
                          heightController.text.trim().replaceAll(',', '.'),
                        );

                        final updated = PlantLog(
                          id:
                              existing?.id ??
                              DateTime.now().microsecondsSinceEpoch.toString(),
                          userPlantId: plant.id,
                          photoPath: selectedImage?.name ?? existing?.photoPath,
                          photoBytes: selectedImageBytes,
                          note: noteController.text.trim(),
                          healthStatus: selectedStatus,
                          createdAt: existing?.createdAt ?? DateTime.now(),
                          heightCm: parsedHeight,
                          treatment: treatmentController.text.trim().isEmpty
                              ? null
                              : treatmentController.text.trim(),
                        );

                        if (existing == null) {
                          repository.savePlantLog(updated);
                        } else {
                          repository.updatePlantLog(updated);
                        }

                        Navigator.of(context).pop();
                      },
                      child: Text(
                        existing == null ? 'Salvar registro' : 'Salvar edicao',
                      ),
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

  Future<void> _showProblemEditor(
    BuildContext context, {
    required PlantProblem existing,
  }) async {
    final symptomsController = TextEditingController(text: existing.symptoms);
    final diagnosisController = TextEditingController(text: existing.diagnosis);
    final treatmentController = TextEditingController(text: existing.treatment);
    final statusController = TextEditingController(text: existing.status);

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
                  'Editar problema',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                AppSpacing.itemGap,
                TextField(
                  controller: symptomsController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Sintomas'),
                ),
                AppSpacing.itemGap,
                TextField(
                  controller: diagnosisController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Diagnostico'),
                ),
                AppSpacing.itemGap,
                TextField(
                  controller: treatmentController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Tratamento'),
                ),
                AppSpacing.itemGap,
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                AppSpacing.sectionGap,
                ElevatedButton(
                  onPressed: () {
                    if (symptomsController.text.trim().isEmpty ||
                        diagnosisController.text.trim().isEmpty) {
                      return;
                    }

                    repository.updatePlantProblem(
                      PlantProblem(
                        id: existing.id,
                        userPlantId: existing.userPlantId,
                        photoPath: existing.photoPath,
                        photoBytes: existing.photoBytes,
                        problemType: existing.problemType,
                        symptoms: symptomsController.text.trim(),
                        diagnosis: diagnosisController.text.trim(),
                        treatment: treatmentController.text.trim(),
                        status: statusController.text.trim().isEmpty
                            ? existing.status
                            : statusController.text.trim(),
                        createdAt: existing.createdAt,
                      ),
                    );

                    Navigator.of(context).pop();
                  },
                  child: const Text('Salvar edicao'),
                ),
              ],
            ),
          ),
        );
      },
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

class _PlantLogCard extends StatelessWidget {
  const _PlantLogCard({
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  final PlantLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (log.photoBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.memory(log.photoBytes!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(log.createdAt),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar registro',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remover registro',
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoLine(label: 'Status', value: log.healthStatus.label),
            _InfoLine(label: 'Observacao', value: log.note),
            if (log.heightCm != null)
              _InfoLine(
                label: 'Altura',
                value: '${log.heightCm!.toStringAsFixed(1)} cm',
              ),
            if (log.treatment != null)
              _InfoLine(label: 'Tratamento', value: log.treatment!),
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

class _PlantProblemCard extends StatelessWidget {
  const _PlantProblemCard({
    required this.problem,
    required this.onEdit,
    required this.onDelete,
  });

  final PlantProblem problem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (problem.photoBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.memory(problem.photoBytes!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(problem.createdAt),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar problema',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remover problema',
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoLine(label: 'Tipo de problema', value: problem.problemType),
            _InfoLine(label: 'Sintomas', value: problem.symptoms),
            _InfoLine(label: 'Diagnostico', value: problem.diagnosis),
            _InfoLine(label: 'Tratamento', value: problem.treatment),
            _InfoLine(label: 'Status', value: problem.status),
            if (problem.photoPath != null)
              _InfoLine(label: 'Foto anexada', value: problem.photoPath!),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
