import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_routes.dart';
import '../../core/utils/app_spacing.dart';
import '../../core/widgets/flora_app_bar.dart';
import '../../services/app_data_repository.dart';
import '../../services/plant_info_service.dart';
import '../my_plants/models/plant_log.dart';
import '../my_plants/models/plant_status.dart';
import '../my_plants/models/user_plant.dart';
import 'models/location_privacy_mode.dart';
import 'models/plant_identification.dart';
import 'models/plant_identification_result_args.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({required this.args, super.key});

  final PlantIdentificationResultArgs? args;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final AppDataRepository _repository = AppDataRepository.instance;
  final PlantInfoService _plantInfoService = const PlantInfoService();

  bool _hasSaved = false;
  bool _addedToMyPlants = false;
  PlantInfoData? _supplementalInfo;
  bool _isLoadingSupplemental = false;

  @override
  void initState() {
    super.initState();
    _loadSupplementalInfo();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    if (args == null) {
      return Scaffold(
        appBar: buildFloraAppBar(context, title: 'Resultado da identificacao'),
        body: const Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Text(
              'Nenhum resultado disponivel para exibir.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final result = args.result;
    final confidenceText = '${(result.confidence * 100).toStringAsFixed(0)}%';
    final confidenceProgress = result.confidence.clamp(0, 1);
    final isValidIdentification = result.confidence > 0.01;
    final confidenceLevel = _confidenceLevel(result.confidence);

    return Scaffold(
      appBar: buildFloraAppBar(context, title: 'Resultado da identificacao'),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.memory(args.imageBytes, fit: BoxFit.cover),
            ),
          ),
          AppSpacing.sectionGap,
          Text(
            result.popularName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.scientificName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: _confidenceColor(context, result.confidence),
                ),
                label: Text('Confianca $confidenceLevel'),
              ),
              Chip(
                avatar: const Icon(Icons.eco_outlined, size: 18),
                label: Text(
                  result.sourceLabel ?? 'Identificacao automatica',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (result.sourceLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              'Fonte: ${result.sourceLabel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          AppSpacing.itemGap,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Confianca estimada: $confidenceText',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: confidenceProgress.toDouble(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.itemGap,
          if (result.disclaimer != null)
            Text(
              result.disclaimer!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          AppSpacing.sectionGap,
          if (args.userDescription.isNotEmpty) ...[
            _SectionCard(
              title: 'Descricao informada',
              child: Text(args.userDescription),
            ),
            AppSpacing.itemGap,
          ],
          _SectionCard(title: 'Descricao', child: Text(result.description)),
          if (_supplementalInfo != null) ...[
            AppSpacing.itemGap,
            _SectionCard(
              title: 'Resumo ampliado',
              child: Text(_supplementalInfo!.summary),
            ),
          ] else if (_isLoadingSupplemental) ...[
            AppSpacing.itemGap,
            const _SectionCard(
              title: 'Resumo ampliado',
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Text('Buscando mais detalhes da planta...')),
                ],
              ),
            ),
          ],
          AppSpacing.itemGap,
          _SectionCard(
            title: 'Especies parecidas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.similarSpecies
                  .map(
                    (species) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('- $species'),
                    ),
                  )
                  .toList(),
            ),
          ),
          AppSpacing.itemGap,
          _SectionCard(
            title: 'Cuidados basicos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CareLine(label: 'Luz', value: result.light),
                _CareLine(label: 'Agua', value: result.water),
                _CareLine(label: 'Solo', value: result.soil),
                _CareLine(label: 'Poda', value: result.pruning),
                _CareLine(label: 'Adubacao', value: result.fertilization),
              ],
            ),
          ),
          AppSpacing.itemGap,
          _SectionCard(title: 'Toxicidade', child: Text(result.toxicity)),
          AppSpacing.itemGap,
          OutlinedButton.icon(
            onPressed: () => _showMoreInformation(context, args),
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('Mais informacoes da planta'),
          ),
          if (args.locationPrivacyMode != LocationPrivacyMode.none) ...[
            AppSpacing.itemGap,
            _SectionCard(
              title: 'Localizacao associada',
              child: Text(_buildLocationText(args.locationPrivacyMode)),
            ),
          ],
          AppSpacing.sectionGap,
          ElevatedButton.icon(
            onPressed: _hasSaved || !isValidIdentification
                ? null
                : () => _saveIdentification(args),
            icon: Icon(
              _hasSaved ? Icons.check_circle_outline : Icons.save_outlined,
            ),
            label: Text(
              _hasSaved
                  ? 'Identificacao salva'
                  : isValidIdentification
                  ? 'Salvar identificacao'
                  : 'Salvar desativado',
            ),
          ),
          AppSpacing.itemGap,
          OutlinedButton.icon(
            onPressed: _addedToMyPlants || !isValidIdentification
                ? null
                : () => _addToMyPlants(args),
            icon: Icon(
              _addedToMyPlants
                  ? Icons.check_circle_outline
                  : Icons.local_florist_outlined,
            ),
            label: Text(
              _addedToMyPlants
                  ? 'Adicionada em Minhas plantas'
                  : isValidIdentification
                  ? 'Adicionar as minhas plantas'
                  : 'Adicionar desativado',
            ),
          ),
        ],
      ),
    );
  }

  String _confidenceLevel(double value) {
    if (value >= 0.8) {
      return 'alta';
    }
    if (value >= 0.55) {
      return 'media';
    }
    return 'baixa';
  }

  Color _confidenceColor(BuildContext context, double value) {
    final colorScheme = Theme.of(context).colorScheme;
    if (value >= 0.8) {
      return Colors.green.shade600;
    }
    if (value >= 0.55) {
      return colorScheme.tertiary;
    }
    return colorScheme.error;
  }

  Future<void> _loadSupplementalInfo() async {
    final args = widget.args;
    if (args == null) {
      return;
    }
    setState(() {
      _isLoadingSupplemental = true;
    });
    final info = await _plantInfoService.fetchSupplementalInfo(
      scientificName: args.result.scientificName,
      popularName: args.result.popularName,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _supplementalInfo = info;
      _isLoadingSupplemental = false;
    });
  }

  void _showMoreInformation(
    BuildContext context,
    PlantIdentificationResultArgs args,
  ) {
    final result = args.result;
    final confidence = (result.confidence * 100).toStringAsFixed(0);
    final confidenceLevel = result.confidence >= 0.8
        ? 'Alta'
        : result.confidence >= 0.55
        ? 'Media'
        : 'Baixa';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ficha detalhada',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${result.popularName} (${result.scientificName})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.sectionGap,
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.verified_rounded,
                          label: 'Confianca',
                          value: '$confidence%',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.analytics_outlined,
                          label: 'Nivel',
                          value: confidenceLevel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Origem dos dados',
                    child: Text(result.sourceLabel ?? 'Nao informado'),
                  ),
                  if (args.userDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _SectionCard(
                        title: 'Descricao enviada por voce',
                        child: Text(args.userDescription),
                      ),
                    ),
                  AppSpacing.sectionGap,
                  _SectionCard(
                    title: 'Leitura de confiabilidade',
                    child: Text(_buildConfidenceGuide(result.confidence)),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Como aumentar a precisao',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _BulletLine(
                          text:
                              'Fotografe folha ou flor ocupando boa parte da imagem.',
                        ),
                        _BulletLine(text: 'Evite fundo poluido e baixa luz.'),
                        _BulletLine(
                          text:
                              'Tire 2 ou 3 fotos por angulos diferentes e compare.',
                        ),
                        _BulletLine(
                          text: 'Foque em detalhes (nervuras, bordas, textura).',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Cuidados resumidos',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CareLine(label: 'Luz', value: result.light),
                        _CareLine(label: 'Agua', value: result.water),
                        _CareLine(label: 'Solo', value: result.soil),
                        _CareLine(label: 'Poda', value: result.pruning),
                        _CareLine(label: 'Adubacao', value: result.fertilization),
                        _CareLine(label: 'Toxicidade', value: result.toxicity),
                      ],
                    ),
                  ),
                  if (_supplementalInfo != null) ...[
                    const SizedBox(height: 10),
                    _SectionCard(
                      title: 'Conteudo complementar',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_supplementalInfo!.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _supplementalInfo!.imageUrl!,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (_supplementalInfo!.imageUrl != null)
                            const SizedBox(height: 10),
                          Text(_supplementalInfo!.summary),
                          const SizedBox(height: 10),
                          Text(
                            'Fonte: ${_supplementalInfo!.sourceUrl}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildConfidenceGuide(double confidence) {
    if (confidence >= 0.8) {
      return 'Confianca alta. Ainda assim, valide visualmente antes de qualquer manejo.';
    }
    if (confidence >= 0.55) {
      return 'Confianca media. Recomendado repetir o scan com foto mais focada para confirmar.';
    }
    return 'Confianca baixa. Trate como indicacao inicial e refaca a captura em melhores condicoes.';
  }

  void _saveIdentification(PlantIdentificationResultArgs args) {
    final identification = _buildIdentification(args);
    _repository.saveIdentification(identification);

    setState(() {
      _hasSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Identificacao salva no historico local.')),
    );
  }

  void _addToMyPlants(PlantIdentificationResultArgs args) {
    final identification = _buildIdentification(args);
    final locationName =
        args.location?.addressText ??
        args.location?.city ??
        'Local nao informado';
    final plantId = DateTime.now().microsecondsSinceEpoch.toString();

    if (!_hasSaved) {
      _repository.saveIdentification(identification);
    }

    _repository.saveUserPlant(
      UserPlant(
        id: plantId,
        identificationId: identification.id,
        popularName: identification.popularName,
        scientificName: identification.scientificName,
        nickname: identification.popularName,
        locationName: locationName,
        status: PlantStatus.healthy,
        createdAt: DateTime.now(),
      ),
    );

    _repository.savePlantLog(
      PlantLog(
        id: '${plantId}_log',
        userPlantId: plantId,
        note: 'Planta adicionada a partir de uma identificacao.',
        healthStatus: PlantStatus.healthy,
        createdAt: DateTime.now(),
        treatment: 'Nenhum tratamento registrado ainda.',
      ),
    );

    setState(() {
      _hasSaved = true;
      _addedToMyPlants = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Planta adicionada em Minhas plantas.'),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () {
            context.push(AppRoutes.myPlantDetail, extra: plantId);
          },
        ),
      ),
    );
  }

  PlantIdentification _buildIdentification(PlantIdentificationResultArgs args) {
    final result = args.result;
    final location = args.location;

    return PlantIdentification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      popularName: result.popularName,
      scientificName: result.scientificName,
      confidence: result.confidence,
      description: result.description,
      photoBytes: args.imageBytes,
      identifiedAt: location?.capturedAt ?? DateTime.now(),
      notes: 'Resultado de identificacao salvo localmente.',
      saveExactLocation: args.locationPrivacyMode == LocationPrivacyMode.exact,
      locationPrivacyMode: args.locationPrivacyMode,
      latitude: args.locationPrivacyMode == LocationPrivacyMode.exact
          ? location?.latitude
          : null,
      longitude: args.locationPrivacyMode == LocationPrivacyMode.exact
          ? location?.longitude
          : null,
      addressText: location?.addressText,
      city: location?.city,
      state: location?.state,
    );
  }

  String _buildLocationText(LocationPrivacyMode mode) {
    final location = widget.args!.location;
    if (location == null) {
      return 'A opcao de salvar localizacao estava ativa, mas nenhuma localizacao foi capturada.';
    }

    if (mode == LocationPrivacyMode.approximate) {
      return 'Modo: aproximada\n'
          'Endereco: ${location.addressText}\n'
          'Cidade: ${location.city}\n'
          'Estado: ${location.state}\n'
          'Precisao estimada: ${location.accuracyMeters.toStringAsFixed(0)} m';
    }

    return 'Modo: exata\n'
        'Latitude: ${location.latitude.toStringAsFixed(6)}\n'
        'Longitude: ${location.longitude.toStringAsFixed(6)}\n'
        'Precisao estimada: ${location.accuracyMeters.toStringAsFixed(0)} m\n'
        'Endereco: ${location.addressText}\n'
        'Cidade: ${location.city}\n'
        'Estado: ${location.state}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CareLine extends StatelessWidget {
  const _CareLine({required this.label, required this.value});

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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
