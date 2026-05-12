import 'dart:convert';

import 'package:http/http.dart' as http;

class PlantInfoData {
  const PlantInfoData({
    required this.summary,
    required this.sourceUrl,
    this.imageUrl,
  });

  final String summary;
  final String sourceUrl;
  final String? imageUrl;
}

class PlantInfoService {
  const PlantInfoService();
  static const _maxSummaryLength = 900;

  Future<PlantInfoData?> fetchSupplementalInfo({
    required String scientificName,
    required String popularName,
  }) async {
    final candidates = <String>[
      scientificName.trim(),
      popularName.trim(),
    ].where((item) => item.isNotEmpty).toList();

    for (final term in candidates) {
      final result = await _fetchFromWikipedia(term, language: 'pt');
      if (result != null) {
        return result;
      }
      final fallback = await _fetchFromWikipedia(term, language: 'en');
      if (fallback != null) {
        return fallback;
      }
    }

    return null;
  }

  Future<PlantInfoData?> _fetchFromWikipedia(
    String rawTerm, {
    required String language,
  }) async {
    final normalized = rawTerm.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return null;
    }

    final encoded = Uri.encodeComponent(normalized.replaceAll(' ', '_'));
    final uri = Uri.parse(
      'https://$language.wikipedia.org/api/rest_v1/page/summary/$encoded',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'FloraCerta/1.0 (plant info enrichment)',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        return null;
      }

      final extract = (json['extract'] as String?)?.trim() ?? '';
      if (extract.isEmpty) {
        return null;
      }

      final contentUrls = json['content_urls'];
      final desktop = contentUrls is Map<String, dynamic>
          ? contentUrls['desktop']
          : null;
      final page = desktop is Map<String, dynamic> ? desktop['page'] : null;
      final sourceUrl = page is String && page.trim().isNotEmpty
          ? page.trim()
          : uri.toString();
      final safeSourceUrl = _sanitizeHttpsUrl(sourceUrl);
      if (safeSourceUrl == null) {
        return null;
      }

      final thumbnail = json['thumbnail'];
      final image = thumbnail is Map<String, dynamic>
          ? thumbnail['source']
          : null;
      final safeImageUrl = image is String ? _sanitizeHttpsUrl(image.trim()) : null;
      final summary = extract.length > _maxSummaryLength
          ? '${extract.substring(0, _maxSummaryLength)}...'
          : extract;

      return PlantInfoData(
        summary: summary,
        sourceUrl: safeSourceUrl,
        imageUrl: safeImageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  String? _sanitizeHttpsUrl(String value) {
    if (value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') {
      return null;
    }
    return uri.toString();
  }
}
