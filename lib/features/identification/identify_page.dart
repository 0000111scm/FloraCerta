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
  static const int _maxPhotos = 5;
  static const int _maxPhotoSizeBytes = 12 * 1024 * 1024;

  final ImagePickerService _imagePickerService = ImagePickerService();
  final LocationService _locationService = const LocationService();
  final PlantIdentificationService _plantIdentificationService =
      const PlantIdentificationService();
  final TextEditingController _descriptionController = TextEditingController();

  LocationPrivacyMode _locationPrivacyMode = LocationPrivacyMode.approximate;
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedImageBytes = [];
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
    if (_selectedImages.length >= _maxPhotos) {
      _showLimitMessage();
      return;
    }

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
        _selectedImages.add(selectedImage);
        _selectedImageBytes.add(imageBytes);
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

  Future<void> _pickMultipleFromGallery() async {
    final remainingSlots = _maxPhotos - _selectedImages.length;
    if (remainingSlots <= 0) {
      _showLimitMessage();
      return;
    }

    setState(() {
      _isLoadingImage = true;
    });

    try {
      final selectedFiles = await _imagePickerService.pickMultipleFromGallery(
        maxImages: remainingSlots,
      );
      if (selectedFiles.isEmpty) {
        return;
      }

      final newBytes = <Uint8List>[];
      final limited = selectedFiles.take(remainingSlots).toList();
      for (final file in limited) {
        newBytes.add(await file.readAsBytes());
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImages.addAll(limited);
        _selectedImageBytes.addAll(newBytes);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel carregar as imagens da galeria.'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
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
    if (_selectedImages.isEmpty || _selectedImageBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos 1 foto para identificar a planta.'),
        ),
      );
      return;
    }

    for (final bytes in _selectedImageBytes) {
      final validationMessage = _validateImageForScan(bytes);
      if (validationMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationMessage)),
        );
        return;
      }
    }

    setState(() {
      _isIdentifying = true;
    });

    try {
      final description = _descriptionController.text.trim();
      final normalizedDescription = description.isEmpty ? null : description;

      var bestIndex = 0;
      var bestResult = await _plantIdentificationService.identifyPlant(
        imageBytes: _selectedImageBytes[0],
        imageName: _selectedImages[0].name,
        description: normalizedDescription,
      );

      for (var i = 1; i < _selectedImages.length; i++) {
        final currentResult = await _plantIdentificationService.identifyPlant(
          imageBytes: _selectedImageBytes[i],
          imageName: _selectedImages[i].name,
          description: normalizedDescription,
        );
        if (currentResult.confidence > bestResult.confidence) {
          bestResult = currentResult;
          bestIndex = i;
        }
      }

      if (!mounted) {
        return;
      }

      context.push(
        AppRoutes.identifyResult,
        extra: PlantIdentificationResultArgs(
          imageBytes: _selectedImageBytes[bestIndex],
          imageName: _selectedImages[bestIndex].name,
          result: bestResult,
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
    if (imageBytes.length < 30 * 1024) {
      return 'Uma das fotos esta muito pequena para identificar com confianca. Tente uma foto mais nitida.';
    }
    if (imageBytes.length > _maxPhotoSizeBytes) {
      return 'Uma das fotos esta muito grande. Use imagens de ate 12 MB.';
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

  void _removeImageAt(int index) {
    if (index < 0 || index >= _selectedImages.length) {
      return;
    }
    setState(() {
      _selectedImages.removeAt(index);
      _selectedImageBytes.removeAt(index);
    });
  }

  void _showLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voce pode adicionar no maximo 5 fotos por identificacao.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _selectedImageBytes.isNotEmpty;

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
            'Use camera ou galeria para identificar a planta e salvar o resultado localmente.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Fotos selecionadas: ${_selectedImages.length}/$_maxPhotos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
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
                    'Dica rapida: use de 2 a 5 fotos por angulos diferentes para melhorar a precisao.',
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
                : _pickMultipleFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Escolher da galeria (multiplas)'),
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
            height: 280,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: _buildPreview(theme),
          ),
          const SizedBox(height: 12),
          if (!hasImage) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingImage || _isIdentifying
                        ? null
                        : () => _pickImage(_imagePickerService.pickFromCamera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Tirar foto aqui'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingImage || _isIdentifying
                        ? null
                        : _pickMultipleFromGallery,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Adicionar fotos'),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 140),
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
          'Estado: ${location.state}\n'
          'Precisao estimada: ${location.accuracyMeters.toStringAsFixed(0)} m';
    }

    final latitude = location.latitude.toStringAsFixed(6);
    final longitude = location.longitude.toStringAsFixed(6);
    return 'Latitude: $latitude\n'
        'Longitude: $longitude\n'
        'Precisao estimada: ${location.accuracyMeters.toStringAsFixed(0)} m\n'
        'Endereco: ${location.addressText}\n'
        'Cidade: ${location.city}\n'
        'Estado: ${location.state}';
  }

  Widget _buildPreview(ThemeData theme) {
    if (_isLoadingImage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedImageBytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_selectedImageBytes.first, fit: BoxFit.cover),
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
                    '${_selectedImages.length} foto(s) adicionada(s)',
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
              left: 12,
              right: 12,
              top: 12,
              child: SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImageBytes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: index == 0
                                  ? theme.colorScheme.primary
                                  : Colors.white54,
                              width: index == 0 ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.memory(
                              _selectedImageBytes[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isIdentifying
                                ? null
                                : () => _removeImageAt(index),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
          const SizedBox(height: 10),
          Text(
            'Use os botoes abaixo para capturar ou adicionar imagens.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
