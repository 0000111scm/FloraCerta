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

  String get relayUrl =>
      dotenv.env[AppConstants.plantIdentificationRelayUrlKey]?.trim() ?? '';

  String get apiUrl =>
      dotenv.env[AppConstants.plantIdentificationApiUrlKey]
              ?.trim()
              .isNotEmpty ==
          true
      ? dotenv.env[AppConstants.plantIdentificationApiUrlKey]!.trim()
      : 'https://my-api.plantnet.org/v2/identify/all';

  String get apiKey =>
      dotenv.env[AppConstants.plantIdentificationApiKey]?.trim() ?? '';

  bool get allowClientSideKey {
    final raw = dotenv.env[AppConstants.allowClientSidePlantKey]?.trim();
    if (raw == null || raw.isEmpty) {
      return false;
    }
    return raw == '1' || raw.toLowerCase() == 'true';
  }

  bool get hasRelayConfiguration => relayUrl.isNotEmpty;

  bool get hasDirectConfiguration => apiKey.isNotEmpty && apiKey.length >= 20;

  bool get hasApiConfiguration =>
      hasRelayConfiguration || (allowClientSideKey && hasDirectConfiguration);

  Future<PlantIdentificationResult> identifyPlant({
    required Uint8List imageBytes,
    required String imageName,
    String? description,
  }) async {
    if (!hasApiConfiguration) {
      return _buildFailureResult(
        description: description,
        reason:
            'Servico de identificacao indisponivel no momento. Tente novamente mais tarde.',
      );
    }

    try {
      return await _identify(
        imageBytes: imageBytes,
        imageName: imageName,
        description: description,
      );
    } on _PlantIdentificationException catch (error) {
      return _buildFailureResult(description: description, reason: error.message);
    } catch (_) {
      return _buildFailureResult(
        description: description,
        reason: 'Falha ao consultar o servico de identificacao.',
      );
    }
  }

  Future<PlantIdentificationResult> _identify({
    required Uint8List imageBytes,
    required String imageName,
    String? description,
  }) async {
    if (imageBytes.isEmpty || imageName.trim().isEmpty) {
      throw const _PlantIdentificationException(
        'Imagem invalida para identificacao.',
      );
    }

    if (hasRelayConfiguration) {
      return _identifyWithRelay(
        imageBytes: imageBytes,
        imageName: imageName,
        description: description,
      );
    }

    if (!allowClientSideKey) {
      throw const _PlantIdentificationException(
        'Servico de identificacao indisponivel no momento.',
      );
    }

    return _identifyWithDirectProvider(
      imageBytes: imageBytes,
      imageName: imageName,
      description: description,
    );
  }

  Future<PlantIdentificationResult> _identifyWithRelay({
    required Uint8List imageBytes,
    required String imageName,
    String? description,
  }) async {
    final uri = Uri.tryParse(relayUrl);
    if (uri == null) {
      throw const _PlantIdentificationException(
        'Servico de identificacao indisponivel no momento.',
      );
    }

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: imageName),
      );
    if (description != null && description.trim().isNotEmpty) {
      request.fields['description'] = description.trim();
    }

    final response = await request.send().timeout(const Duration(seconds: 25));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _PlantIdentificationException(_toUserSafeError(response.statusCode));
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const _PlantIdentificationException(
        'Resposta invalida do servico de identificacao.',
      );
    }

    return _mapApiResponseToResult(
      decoded,
      description,
      usedLanguage: 'pt',
      usedOrgan: 'auto',
      source: 'Servico protegido',
    );
  }

  Future<PlantIdentificationResult> _identifyWithDirectProvider({
    required Uint8List imageBytes,
    required String imageName,
    String? description,
  }) async {
    ({int statusCode, String body, String language, String organ})? bestSuccess;
    var bestScore = -1.0;
    final failedStatuses = <int>[];

    for (final language in _languagesPriority) {
      for (final organ in _organsPriority) {
        final response = await _sendDirectRequest(
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

        failedStatuses.add(response.statusCode);
        if (kDebugMode) {
          debugPrint(
            'Falha identificacao status=${response.statusCode} [lang=$language orgao=$organ]',
          );
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const _PlantIdentificationException(
            'Servico de identificacao indisponivel no momento.',
          );
        }
        if (response.statusCode == 429) {
          throw const _PlantIdentificationException(
            'Muitas consultas em sequencia. Tente novamente em instantes.',
          );
        }
      }
    }

    if (bestSuccess == null) {
      if (failedStatuses.isNotEmpty) {
        throw _PlantIdentificationException(
          _toUserSafeError(failedStatuses.first),
        );
      }
      return _buildNoMatchResult(description);
    }

    final decoded = jsonDecode(bestSuccess.body);
    if (decoded is! Map<String, dynamic>) {
      throw const _PlantIdentificationException(
        'Resposta invalida do servico de identificacao.',
      );
    }

    return _mapApiResponseToResult(
      decoded,
      description,
      usedLanguage: bestSuccess.language,
      usedOrgan: bestSuccess.organ,
      source: 'Pl@ntNet',
    );
  }

  Future<({int statusCode, String body, String language, String organ})>
  _sendDirectRequest({
    required Uint8List imageBytes,
    required String imageName,
    required String language,
    required String organ,
  }) async {
    final uri = Uri.parse('$apiUrl?api-key=$apiKey&lang=$language&nb-results=4');
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
    required String source,
  }) {
    final resultsDynamic = payload['results'];
    if (resultsDynamic is! List || resultsDynamic.isEmpty) {
      return _buildNoMatchResult(userDescription);
    }

    final first = resultsDynamic.first;
    if (first is! Map<String, dynamic>) {
      return _buildFailureResult(
        description: userDescription,
        reason: 'Formato de resposta inesperado.',
      );
    }

    final species = first['species'] as Map<String, dynamic>?;
    final popularName = _extractPopularName(species) ?? 'Nome popular indisponivel';
    final scientificName =
        _extractScientificName(species) ?? 'Nome cientifico indisponivel';
    final confidence = _normalizeConfidence((first['score'] as num?)?.toDouble() ?? 0.0);

    final similarSpecies = resultsDynamic
        .skip(1)
        .take(4)
        .map((entry) {
          if (entry is! Map<String, dynamic>) {
            return null;
          }
          final speciesEntry = entry['species'] as Map<String, dynamic>?;
          final name = _extractScientificName(speciesEntry);
          final score = (entry['score'] as num?)?.toDouble();
          if (name == null) {
            return null;
          }
          if (score == null) {
            return name;
          }
          return '$name (${(score * 100).toStringAsFixed(0)}%)';
        })
        .whereType<String>()
        .toList();

    final genus = _extractNestedScientificName(species, 'genus');
    final family = _extractNestedScientificName(species, 'family');
    final description =
        'Identificacao baseada na imagem enviada.'
        '${userDescription?.trim().isNotEmpty == true ? ' Descricao informada: ${userDescription!.trim()}.' : ''}'
        '${genus != null ? ' Genero sugerido: $genus.' : ''}'
        '${family != null ? ' Familia sugerida: $family.' : ''}';

    return PlantIdentificationResult(
      popularName: popularName,
      scientificName: scientificName,
      confidence: confidence,
      description: description,
      similarSpecies: similarSpecies.isEmpty
          ? const ['Sem especies semelhantes retornadas.']
          : similarSpecies,
      light: 'Prefira consultar exigencia de luz da especie identificada.',
      water: 'Regue com base na umidade do substrato, evitando encharcamento.',
      soil: 'Use substrato drenante e rico em materia organica.',
      pruning: 'Realize poda de limpeza e controle conforme crescimento.',
      fertilization: 'Adube de forma moderada nas fases de crescimento.',
      toxicity: 'Confirme a toxicidade da especie em fonte botanica confiavel.',
      sourceLabel: '$source | orgao: $usedOrgan | idioma: $usedLanguage',
      disclaimer: _buildConfidenceDisclaimer(confidence),
    );
  }

  double _normalizeConfidence(double raw) {
    if (raw.isNaN || raw.isInfinite) {
      return 0.0;
    }
    final clamped = raw.clamp(0.0, 1.0);
    // Ajuste conservador para evitar superconfianca em um unico match.
    final calibrated = clamped * 0.92;
    return calibrated.clamp(0.0, 1.0);
  }

  String _buildConfidenceDisclaimer(double confidence) {
    if (confidence >= 0.8) {
      return 'Resultado automatico com boa confianca. Ainda valide visualmente antes de qualquer manejo.';
    }
    if (confidence >= 0.55) {
      return 'Resultado automatico com confianca moderada. Recomendado repetir com outra foto para confirmar.';
    }
    return 'Resultado automatico com baixa confianca. Recomendado tirar novas fotos e comparar.';
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
          'A imagem foi recebida, mas nao houve especie com confianca adequada.$descriptionSuffix',
      similarSpecies: const [
        'Tente uma foto mais nitida, com foco em folhas ou flor.',
      ],
      light: 'Nao disponivel sem identificacao confiavel.',
      water: 'Nao disponivel sem identificacao confiavel.',
      soil: 'Nao disponivel sem identificacao confiavel.',
      pruning: 'Nao disponivel sem identificacao confiavel.',
      fertilization: 'Nao disponivel sem identificacao confiavel.',
      toxicity: 'Nao disponivel sem identificacao confiavel.',
      sourceLabel: 'Identificacao automatica',
      disclaimer:
          'Nenhuma especie encontrada para esta imagem. Ajuste enquadramento e tente novamente.',
    );
  }

  PlantIdentificationResult _buildFailureResult({
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
          'Nao foi possivel concluir a identificacao.$descriptionSuffix',
      similarSpecies: const [
        'Confira sua conexao e tente novamente.',
      ],
      light: 'Indisponivel enquanto a identificacao nao for concluida.',
      water: 'Indisponivel enquanto a identificacao nao for concluida.',
      soil: 'Indisponivel enquanto a identificacao nao for concluida.',
      pruning: 'Indisponivel enquanto a identificacao nao for concluida.',
      fertilization: 'Indisponivel enquanto a identificacao nao for concluida.',
      toxicity: 'Indisponivel enquanto a identificacao nao for concluida.',
      sourceLabel: 'Identificacao automatica',
      disclaimer: reason,
    );
  }

  String _toUserSafeError(int statusCode) {
    if (statusCode == 429) {
      return 'Muitas consultas em sequencia. Tente novamente em instantes.';
    }
    if (statusCode >= 500) {
      return 'Servico de identificacao indisponivel no momento.';
    }
    return 'Nao foi possivel concluir a identificacao agora.';
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

class _PlantIdentificationException implements Exception {
  const _PlantIdentificationException(this.message);

  final String message;
}
