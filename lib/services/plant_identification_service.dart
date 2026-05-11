import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_constants.dart';
import '../features/identification/models/plant_identification_result.dart';

class PlantIdentificationService {
  const PlantIdentificationService();

  bool get hasApiConfiguration => apiKey.isNotEmpty;

  String get apiUrl =>
      dotenv.env[AppConstants.plantIdentificationApiUrlKey]
              ?.trim()
              .isNotEmpty ==
          true
      ? dotenv.env[AppConstants.plantIdentificationApiUrlKey]!.trim()
      : 'https://my-api.plantnet.org/v2/identify/all';

  String get apiKey =>
      dotenv.env[AppConstants.plantIdentificationApiKey]?.trim() ?? '';

  Future<PlantIdentificationResult> identifyPlant({
    required Uint8List imageBytes,
    required String imageName,
    String? description,
  }) async {
    if (!hasApiConfiguration) {
      return _buildMockResult(
        description: description,
        reason:
            'API de identificacao ainda nao configurada. Exibindo exemplo local.',
      );
    }

    try {
      return await _identifyWithApi(
        imageBytes: imageBytes,
        imageName: imageName,
        description: description,
      );
    } catch (_) {
      return _buildMockResult(
        description: description,
        reason:
            'Falha ao consultar a API de identificacao. Exibindo exemplo local.',
      );
    }
  }

  Future<PlantIdentificationResult> _identifyWithApi({
    required Uint8List imageBytes,
    required String imageName,
    String? description,
  }) async {
    if (imageBytes.isEmpty || imageName.trim().isEmpty) {
      throw ArgumentError('Imagem invalida para identificacao.');
    }

    final uri = Uri.parse('$apiUrl?api-key=$apiKey&lang=pt-BR&nb-results=4');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes('images', imageBytes, filename: imageName),
      )
      ..fields['organs'] = 'auto';

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 25),
    );
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw Exception('API retornou status ${streamedResponse.statusCode}');
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Formato de resposta invalido.');
    }

    return _mapApiResponseToResult(decoded, description);
  }

  PlantIdentificationResult _buildMockResult({
    String? description,
    required String reason,
  }) {
    return PlantIdentificationResult.mock(
      userDescription: description,
      reason: reason,
    );
  }

  PlantIdentificationResult _mapApiResponseToResult(
    Map<String, dynamic> payload,
    String? userDescription,
  ) {
    final resultsDynamic = payload['results'];
    if (resultsDynamic is! List || resultsDynamic.isEmpty) {
      return _buildMockResult(
        description: userDescription,
        reason:
            'A API nao retornou resultados suficientes para identificacao. Exibindo exemplo local.',
      );
    }

    final first = resultsDynamic.first;
    if (first is! Map<String, dynamic>) {
      return _buildMockResult(
        description: userDescription,
        reason:
            'Resposta da API em formato inesperado. Exibindo exemplo local.',
      );
    }

    final species = first['species'] as Map<String, dynamic>?;
    final popularName =
        _extractPopularName(species) ?? 'Nome popular indisponivel';
    final scientificName =
        _extractScientificName(species) ?? 'Nome cientifico indisponivel';
    final confidence = (first['score'] as num?)?.toDouble() ?? 0.0;

    final similarSpecies = resultsDynamic
        .skip(1)
        .take(3)
        .map((entry) {
          if (entry is! Map<String, dynamic>) {
            return null;
          }
          final speciesEntry = entry['species'] as Map<String, dynamic>?;
          return _extractScientificName(speciesEntry);
        })
        .whereType<String>()
        .toList();

    final genus = _extractNestedScientificName(species, 'genus');
    final family = _extractNestedScientificName(species, 'family');
    final description =
        'Identificacao retornada pela API com base na imagem enviada.'
        '${userDescription?.trim().isNotEmpty == true ? ' Descricao informada: ${userDescription!.trim()}.' : ''}'
        '${genus != null ? ' Genero sugerido: $genus.' : ''}'
        '${family != null ? ' Familia sugerida: $family.' : ''}';

    return PlantIdentificationResult(
      popularName: popularName,
      scientificName: scientificName,
      confidence: confidence,
      description: description,
      similarSpecies: similarSpecies.isEmpty
          ? ['Nenhuma especie semelhante retornada pela API.']
          : similarSpecies,
      light: 'Recomendacao geral: validar necessidade de luz por especie.',
      water:
          'Recomendacao geral: monitorar umidade do substrato antes de cada rega.',
      soil: 'Recomendacao geral: utilizar substrato drenante e organico.',
      pruning:
          'Recomendacao geral: realizar poda apenas para limpeza e controle.',
      fertilization:
          'Recomendacao geral: adubacao moderada conforme fase de crescimento.',
      toxicity:
          'Toxicidade depende da especie exata. Confirmar em fonte botanica confiavel.',
      sourceLabel: 'Pl@ntNet API',
      disclaimer:
          'Resultado retornado por API externa. Sempre valide a identificacao antes de qualquer manejo.',
    );
  }

  String? _extractPopularName(Map<String, dynamic>? species) {
    if (species == null) {
      return null;
    }
    final commonNames = species['commonNames'];
    if (commonNames is List && commonNames.isNotEmpty) {
      final first = commonNames.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }
    return null;
  }

  String? _extractScientificName(Map<String, dynamic>? species) {
    if (species == null) {
      return null;
    }
    final fullName = species['scientificName'];
    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final withoutAuthor = species['scientificNameWithoutAuthor'];
    if (withoutAuthor is String && withoutAuthor.trim().isNotEmpty) {
      return withoutAuthor.trim();
    }
    return null;
  }

  String? _extractNestedScientificName(
    Map<String, dynamic>? species,
    String field,
  ) {
    if (species == null) {
      return null;
    }
    final nested = species[field];
    if (nested is! Map<String, dynamic>) {
      return null;
    }
    final scientificName = nested['scientificName'];
    if (scientificName is String && scientificName.trim().isNotEmpty) {
      return scientificName.trim();
    }
    final noAuthor = nested['scientificNameWithoutAuthor'];
    if (noAuthor is String && noAuthor.trim().isNotEmpty) {
      return noAuthor.trim();
    }
    return null;
  }
}
