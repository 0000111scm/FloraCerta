import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_constants.dart';
import '../features/identification/models/plant_identification_result.dart';

class PlantIdentificationService {
  const PlantIdentificationService();
  static const List<String> _organsPriority = [
    'auto',
    'leaf',
    'flower',
    'fruit',
    'bark',
  ];
  static const List<String> _languagesPriority = ['pt', 'en'];

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
      return _buildApiFailureResult(
        description: description,
        reason:
            'API de identificacao ainda nao configurada. Configure a chave para usar reconhecimento real.',
      );
    }

    try {
      return await _identifyWithApi(
        imageBytes: imageBytes,
        imageName: imageName,
        description: description,
      );
    } on _PlantIdentificationApiException catch (error) {
      return _buildApiFailureResult(
        description: description,
        reason: error.message,
      );
    } catch (_) {
      return _buildApiFailureResult(
        description: description,
        reason: 'Falha ao consultar a API de identificacao.',
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

    ({int statusCode, String body, String language, String organ})? bestSuccess;
    var bestScore = -1.0;
    final failedStatuses = <int>[];

    for (final language in _languagesPriority) {
      for (final organ in _organsPriority) {
        final response = await _sendIdentificationRequest(
          imageBytes: imageBytes,
          imageName: imageName,
          language: language,
          organ: organ,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final score = _extractTopScore(response.body);
          if (score > bestScore) {
            bestScore = score;
            bestSuccess = response;
          }
          if (score >= 0.65) {
            break;
          }
          continue;
        }

        if (response.statusCode == 404 &&
            response.body.toLowerCase().contains('species not found')) {
          continue;
        }

        if (response.statusCode == 404 &&
            response.body.contains('No localization available')) {
          continue;
        }

        failedStatuses.add(response.statusCode);
        debugPrint(
          'Plant API erro HTTP ${response.statusCode} [lang=$language organ=$organ]: ${response.body}',
        );
      }
    }

    if (bestSuccess == null) {
      if (failedStatuses.isNotEmpty) {
        throw _PlantIdentificationApiException(
          'Falha na API (${failedStatuses.first}).',
        );
      }
      return _buildNoMatchResult(description);
    }

    final decoded = jsonDecode(bestSuccess.body);
    if (decoded is! Map<String, dynamic>) {
      throw const _PlantIdentificationApiException('Resposta invalida da API.');
    }

    return _mapApiResponseToResult(
      decoded,
      description,
      usedLanguage: bestSuccess.language,
      usedOrgan: bestSuccess.organ,
    );
  }

  Future<({int statusCode, String body, String language, String organ})>
  _sendIdentificationRequest({
    required Uint8List imageBytes,
    required String imageName,
    required String language,
    required String organ,
  }) async {
    final uri = Uri.parse(
      '$apiUrl?api-key=$apiKey&lang=$language&nb-results=4',
    );
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes('images', imageBytes, filename: imageName),
      )
      ..fields['organs'] = organ;

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 25),
    );
    final responseBody = await streamedResponse.stream.bytesToString();
    return (
      statusCode: streamedResponse.statusCode,
      body: responseBody,
      language: language,
      organ: organ,
    );
  }

  PlantIdentificationResult _mapApiResponseToResult(
    Map<String, dynamic> payload,
    String? userDescription, {
    required String usedLanguage,
    required String usedOrgan,
  }) {
    final resultsDynamic = payload['results'];
    if (resultsDynamic is! List || resultsDynamic.isEmpty) {
      return _buildNoMatchResult(userDescription);
    }

    final first = resultsDynamic.first;
    if (first is! Map<String, dynamic>) {
      return _buildApiFailureResult(
        description: userDescription,
        reason: 'Resposta da API em formato inesperado.',
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
      sourceLabel: 'Pl@ntNet API • orgao: $usedOrgan • idioma: $usedLanguage',
      disclaimer:
          'Resultado retornado por API externa. Sempre valide a identificacao antes de qualquer manejo.',
    );
  }

  double _extractTopScore(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return -1;
      }
      final results = decoded['results'];
      if (results is! List || results.isEmpty) {
        return -1;
      }
      final first = results.first;
      if (first is! Map<String, dynamic>) {
        return -1;
      }
      return (first['score'] as num?)?.toDouble() ?? -1;
    } catch (_) {
      return -1;
    }
  }

  PlantIdentificationResult _buildNoMatchResult(String? userDescription) {
    final descriptionSuffix =
        userDescription != null && userDescription.trim().isNotEmpty
        ? ' Descricao informada: ${userDescription.trim()}.'
        : '';

    return PlantIdentificationResult(
      popularName: 'Nao identificada',
      scientificName: 'Sem correspondencia confiavel',
      confidence: 0.0,
      description:
          'A API recebeu a imagem, mas nao encontrou especie com confianca adequada.$descriptionSuffix',
      similarSpecies: const [
        'Tente uma foto mais nitida, com foco em folhas ou flor.',
      ],
      light: 'Nao disponivel sem identificacao da especie.',
      water: 'Nao disponivel sem identificacao da especie.',
      soil: 'Nao disponivel sem identificacao da especie.',
      pruning: 'Nao disponivel sem identificacao da especie.',
      fertilization: 'Nao disponivel sem identificacao da especie.',
      toxicity: 'Nao disponivel sem identificacao da especie.',
      sourceLabel: 'Pl@ntNet API',
      disclaimer:
          'Nenhuma especie encontrada para esta imagem. Ajuste enquadramento e tente novamente.',
    );
  }

  PlantIdentificationResult _buildApiFailureResult({
    required String reason,
    String? description,
  }) {
    final descriptionSuffix =
        description != null && description.trim().isNotEmpty
        ? ' Descricao informada: ${description.trim()}.'
        : '';

    return PlantIdentificationResult(
      popularName: 'Falha na identificacao',
      scientificName: 'Consulta indisponivel',
      confidence: 0.0,
      description:
          'Nao foi possivel concluir a identificacao via API.$descriptionSuffix',
      similarSpecies: const [
        'Verifique conexao com internet e status da chave da API.',
      ],
      light: 'Indisponivel enquanto a identificacao nao for concluida.',
      water: 'Indisponivel enquanto a identificacao nao for concluida.',
      soil: 'Indisponivel enquanto a identificacao nao for concluida.',
      pruning: 'Indisponivel enquanto a identificacao nao for concluida.',
      fertilization: 'Indisponivel enquanto a identificacao nao for concluida.',
      toxicity: 'Indisponivel enquanto a identificacao nao for concluida.',
      sourceLabel: 'Pl@ntNet API',
      disclaimer: reason,
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

class _PlantIdentificationApiException implements Exception {
  const _PlantIdentificationApiException(this.message);

  final String message;
}
