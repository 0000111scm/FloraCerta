import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/app_spacing.dart';
import '../../core/widgets/flora_app_bar.dart';
import '../../services/app_data_repository.dart';
import '../../services/image_picker_service.dart';
import '../../services/plant_diagnosis_service.dart';
import '../my_plants/models/user_plant.dart';
import 'models/diagnosis_options.dart';
import 'models/diagnosis_result.dart';
import 'models/plant_problem.dart';

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  final AppDataRepository _repository = AppDataRepository.instance;
  final ImagePickerService _imagePickerService = ImagePickerService();
  final PlantDiagnosisService _plantDiagnosisService =
      const PlantDiagnosisService();
  final TextEditingController _symptomsController = TextEditingController();

  UserPlant? _selectedPlant;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoadingImage = false;
  DiagnosisResult? _diagnosisResult;
  bool _hasSavedProblem = false;
  DiagnosisProblemType _selectedProblemType = DiagnosisProblemType.unknown;
  TreatmentStatusOption? _selectedTreatmentStatus;

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(Future<XFile?> Function() pickerAction) async {
    setState(() {
      _isLoadingImage = true;
    });

    try {
      final selectedImage = await pickerAction();
      if (selectedImage == null) {
        return;
      }

      final imageBytes = await selectedImage.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = selectedImage;
        _selectedImageBytes = imageBytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel carregar a foto do diagnostico.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  void _generateDiagnosis() {
    final selectedPlant = _selectedPlant;
    final symptoms = _symptomsController.text.trim();

    if (selectedPlant == null || symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma planta e descreva os sintomas.'),
        ),
      );
      return;
    }
    if (symptoms.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Descreva melhor os sintomas (minimo de 10 caracteres).',
          ),
        ),
      );
      return;
    }

    final result = _plantDiagnosisService.generateMockDiagnosis(
      plantName: selectedPlant.nickname,
      symptoms: symptoms,
      selectedProblemType: _selectedProblemType,
    );

    setState(() {
      _diagnosisResult = result;
      _hasSavedProblem = false;
      _selectedTreatmentStatus = result.treatmentStatusOption;
    });
  }

  void _saveProblem() {
    final selectedPlant = _selectedPlant;
    final result = _diagnosisResult;
    final symptoms = _symptomsController.text.trim();

    if (selectedPlant == null || result == null || symptoms.isEmpty) {
      return;
    }
    final treatmentStatus =
        _selectedTreatmentStatus?.label ?? result.treatmentStatus;

    _repository.savePlantProblem(
      PlantProblem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userPlantId: selectedPlant.id,
        photoPath: _selectedImage?.name,
        photoBytes: _selectedImageBytes,
        problemType: result.problemType,
        symptoms: symptoms,
        diagnosis: result.probableDiagnosis,
        treatment: result.suggestedTreatment,
        status: treatmentStatus,
        createdAt: DateTime.now(),
      ),
    );

    setState(() {
      _hasSavedProblem = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostico salvo no historico da planta.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: buildFloraAppBar(context, title: 'Diagnostico'),
      body: ValueListenableBuilder<List<UserPlant>>(
        valueListenable: _repository.userPlantsListenable,
        builder: (context, plants, child) {
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
                          Icons.health_and_safety_rounded,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        AppSpacing.itemGap,
                        Text(
                          'Cadastre uma planta em Minhas plantas para iniciar um diagnostico.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'O formulario de diagnostico usa a sua lista de plantas pessoais como base.',
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

          _selectedPlant ??= plants.first;

          return ListView(
            padding: AppSpacing.pagePadding,
            children: [
              Text(
                'Registre sintomas e gere um exemplo de diagnostico.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta etapa ainda nao usa IA real. O objetivo aqui e preparar o fluxo e a arquitetura.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.sectionGap,
              DropdownButtonFormField<UserPlant>(
                initialValue: _selectedPlant,
                decoration: const InputDecoration(
                  labelText: 'Planta selecionada',
                ),
                items: plants
                    .map(
                      (plant) => DropdownMenuItem<UserPlant>(
                        value: plant,
                        child: Text('${plant.nickname} - ${plant.popularName}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlant = value;
                    _hasSavedProblem = false;
                    _diagnosisResult = null;
                  });
                },
              ),
              AppSpacing.itemGap,
              TextField(
                controller: _symptomsController,
                minLines: 4,
                maxLines: 6,
                onChanged: (_) {
                  setState(() {
                    _hasSavedProblem = false;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Sintomas',
                  hintText:
                      'Ex.: folhas amareladas, pontas secas, manchas escuras, presenca de insetos.',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Minimo recomendado: 10 caracteres.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.itemGap,
              DropdownButtonFormField<DiagnosisProblemType>(
                initialValue: _selectedProblemType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de problema (opcional)',
                ),
                items: DiagnosisProblemType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedProblemType = value;
                    _hasSavedProblem = false;
                  });
                },
              ),
              AppSpacing.sectionGap,
              Text(
                'Foto opcional',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoadingImage
                    ? null
                    : () => _pickImage(_imagePickerService.pickFromCamera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Tirar foto'),
              ),
              AppSpacing.itemGap,
              OutlinedButton.icon(
                onPressed: _isLoadingImage
                    ? null
                    : () => _pickImage(_imagePickerService.pickFromGallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Escolher da galeria'),
              ),
              AppSpacing.itemGap,
              _buildImagePreview(theme),
              AppSpacing.sectionGap,
              ElevatedButton.icon(
                onPressed: _canGenerateDiagnosis ? _generateDiagnosis : null,
                icon: const Icon(Icons.biotech_outlined),
                label: const Text('Gerar diagnostico de exemplo'),
              ),
              if (_diagnosisResult != null) ...[
                AppSpacing.sectionGap,
                _DiagnosisResultCard(
                  result: _diagnosisResult!,
                  selectedPlant: _selectedPlant!,
                  imageName: _selectedImage?.name,
                ),
                AppSpacing.itemGap,
                DropdownButtonFormField<TreatmentStatusOption>(
                  initialValue:
                      _selectedTreatmentStatus ??
                      _diagnosisResult!.treatmentStatusOption,
                  decoration: const InputDecoration(
                    labelText: 'Status atual do tratamento',
                  ),
                  items: TreatmentStatusOption.values
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
                    setState(() {
                      _selectedTreatmentStatus = value;
                      _hasSavedProblem = false;
                    });
                  },
                ),
                AppSpacing.itemGap,
                OutlinedButton.icon(
                  onPressed: _hasSavedProblem ? null : _saveProblem,
                  icon: Icon(
                    _hasSavedProblem
                        ? Icons.check_circle_outline
                        : Icons.save_outlined,
                  ),
                  label: Text(
                    _hasSavedProblem
                        ? 'Diagnostico salvo'
                        : 'Salvar no historico da planta',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    if (_isLoadingImage) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedImageBytes == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_search_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhuma foto adicionada ao diagnostico.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
      ),
    );
  }

  bool get _canGenerateDiagnosis {
    final symptoms = _symptomsController.text.trim();
    return _selectedPlant != null && symptoms.length >= 10;
  }
}

class _DiagnosisResultCard extends StatelessWidget {
  const _DiagnosisResultCard({
    required this.result,
    required this.selectedPlant,
    this.imageName,
  });

  final DiagnosisResult result;
  final UserPlant selectedPlant;
  final String? imageName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultado do diagnostico',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.disclaimer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.sectionGap,
            _DiagnosisLine(label: 'Planta', value: selectedPlant.nickname),
            _DiagnosisLine(
              label: 'Tipo de problema',
              value: result.problemType,
            ),
            _DiagnosisLine(
              label: 'Diagnostico provavel',
              value: result.probableDiagnosis,
            ),
            _DiagnosisLine(
              label: 'Tratamento sugerido',
              value: result.suggestedTreatment,
            ),
            _DiagnosisLine(
              label: 'Status do tratamento',
              value: result.treatmentStatus,
            ),
            if (imageName != null)
              _DiagnosisLine(label: 'Foto anexada', value: imageName!),
          ],
        ),
      ),
    );
  }
}

class _DiagnosisLine extends StatelessWidget {
  const _DiagnosisLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
