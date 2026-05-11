import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_routes.dart';
import '../../core/utils/app_spacing.dart';
import '../../core/widgets/flora_app_bar.dart';
import '../../services/image_picker_service.dart';
import '../../services/location_service.dart';
import '../../services/plant_identification_service.dart';
import 'models/identification_location.dart';
import 'models/location_privacy_mode.dart';
import 'models/plant_identification_result_args.dart';

class IdentifyPage extends StatefulWidget {
  const IdentifyPage({super.key});

  @override
  State<IdentifyPage> createState() => _IdentifyPageState();
}

class _IdentifyPageState extends State<IdentifyPage> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final LocationService _locationService = const LocationService();
  final PlantIdentificationService _plantIdentificationService =
      const PlantIdentificationService();
  final TextEditingController _descriptionController = TextEditingController();

  LocationPrivacyMode _locationPrivacyMode = LocationPrivacyMode.approximate;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoadingImage = false;
  bool _isLoadingLocation = false;
  bool _isIdentifying = false;
  IdentificationLocation? _currentLocation;
  String? _locationStatusMessage;
  bool _locationStatusIsError = false;

  @override
  void dispose() {
    _descriptionController.dispose();
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
          content: Text('Nao foi possivel carregar a imagem. Tente novamente.'),
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

  Future<void> _captureLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final location = await _locationService.getCurrentLocation();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentLocation = location;
        _locationStatusMessage =
            'Localizacao capturada com sucesso. Revise os dados abaixo.';
        _locationStatusIsError = false;
      });
    } on LocationServiceException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      setState(() {
        _locationStatusMessage = error.message;
        _locationStatusIsError = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel obter a localizacao agora.'),
        ),
      );
      setState(() {
        _locationStatusMessage =
            'Falha ao obter localizacao. Verifique GPS/permissao e tente novamente.';
        _locationStatusIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _identifyPlant() async {
    final imageBytes = _selectedImageBytes;
    final selectedImage = _selectedImage;

    if (imageBytes == null || selectedImage == null) {
      return;
    }
    final validationMessage = _validateImageForScan(imageBytes);
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    setState(() {
      _isIdentifying = true;
    });

    try {
      final description = _descriptionController.text.trim();
      final result = await _plantIdentificationService.identifyPlant(
        imageBytes: imageBytes,
        imageName: selectedImage.name,
        description: description.isEmpty ? null : description,
      );

      if (!mounted) {
        return;
      }

      context.push(
        AppRoutes.identifyResult,
        extra: PlantIdentificationResultArgs(
          imageBytes: imageBytes,
          imageName: selectedImage.name,
          result: result,
          locationPrivacyMode: _locationPrivacyMode,
          userDescription: description,
          location: _locationPrivacyMode == LocationPrivacyMode.none
              ? null
              : _currentLocation,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel processar a identificacao agora. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isIdentifying = false;
        });
      }
    }
  }

  String? _validateImageForScan(Uint8List imageBytes) {
    // Evita envio de imagem muito pequena/comprimida demais, que tende a falhar no reconhecimento.
    if (imageBytes.length < 30 * 1024) {
      return 'Imagem muito pequena para identificar com confianca. Tente uma foto mais nitida e aproximada da planta.';
    }
    return null;
  }

  void _setLocationPrivacyMode(LocationPrivacyMode mode) {
    setState(() {
      _locationPrivacyMode = mode;
      if (mode == LocationPrivacyMode.none) {
        _currentLocation = null;
        _locationStatusMessage = null;
        _locationStatusIsError = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _selectedImageBytes != null;

    return Scaffold(
      appBar: buildFloraAppBar(context, title: 'Identificar planta'),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ElevatedButton.icon(
          onPressed: hasImage && !_isIdentifying ? _identifyPlant : null,
          icon: _isIdentifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search_rounded),
          label: Text(_isIdentifying ? 'Processando...' : 'Identificar planta'),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Text(
            'Selecione uma imagem para iniciar a identificacao.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use camera ou galeria para identificar a planta pela API e salvar o resultado localmente.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dica rapida: foque na folha ou flor, boa luz, sem objetos no fundo e aproxime a camera.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.sectionGap,
          ElevatedButton.icon(
            onPressed: _isLoadingImage || _isIdentifying
                ? null
                : () => _pickImage(_imagePickerService.pickFromCamera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Tirar foto'),
          ),
          AppSpacing.itemGap,
          OutlinedButton.icon(
            onPressed: _isLoadingImage || _isIdentifying
                ? null
                : () => _pickImage(_imagePickerService.pickFromGallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Escolher da galeria'),
          ),
          AppSpacing.sectionGap,
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Descricao opcional da planta',
              hintText:
                  'Ex.: folhas grandes, verde-escuras, fica na sombra, parece jiboia.',
            ),
          ),
          AppSpacing.sectionGap,
          Text(
            'Privacidade da localizacao',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha como a localizacao sera salva nesta identificacao.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.itemGap,
          SegmentedButton<LocationPrivacyMode>(
            segments: LocationPrivacyMode.values
                .map(
                  (mode) => ButtonSegment<LocationPrivacyMode>(
                    value: mode,
                    label: Text(mode.label),
                  ),
                )
                .toList(),
            selected: {_locationPrivacyMode},
            onSelectionChanged: (selection) {
              _setLocationPrivacyMode(selection.first);
            },
          ),
          const SizedBox(height: 8),
          Text(
            _locationPrivacyMode.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_locationPrivacyMode != LocationPrivacyMode.none) ...[
            AppSpacing.itemGap,
            _buildLocationCard(theme),
          ],
          AppSpacing.sectionGap,
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: _buildPreview(theme),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Localizacao da identificacao',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _currentLocation == null
                  ? 'Nenhuma localizacao capturada ainda.'
                  : _buildLocationSummary(_locationPrivacyMode),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_locationStatusMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _locationStatusIsError
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _locationStatusMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _locationStatusIsError
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            AppSpacing.itemGap,
            ElevatedButton.icon(
              onPressed: _isLoadingLocation || _isIdentifying
                  ? null
                  : _captureLocation,
              icon: _isLoadingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _currentLocation == null
                    ? 'Capturar localizacao'
                    : 'Atualizar localizacao',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildLocationSummary(LocationPrivacyMode mode) {
    final location = _currentLocation;
    if (location == null) {
      return '';
    }

    if (mode == LocationPrivacyMode.approximate) {
      return 'Endereco aproximado: ${location.addressText}\n'
          'Cidade: ${location.city}\n'
          'Estado: ${location.state}';
    }

    final latitude = location.latitude.toStringAsFixed(6);
    final longitude = location.longitude.toStringAsFixed(6);

    return 'Latitude: $latitude\n'
        'Longitude: $longitude\n'
        'Endereco: ${location.addressText}\n'
        'Cidade: ${location.city}\n'
        'Estado: ${location.state}';
  }

  Widget _buildPreview(ThemeData theme) {
    if (_isLoadingImage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _selectedImage?.name ?? 'Imagem selecionada',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filled(
                tooltip: 'Remover foto',
                onPressed: _isIdentifying
                    ? null
                    : () {
                        setState(() {
                          _selectedImage = null;
                          _selectedImageBytes = null;
                        });
                      },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('Preview da imagem', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Nenhuma foto selecionada ainda.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
