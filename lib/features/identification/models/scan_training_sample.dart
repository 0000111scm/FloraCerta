import 'dart:convert';
import 'dart:typed_data';

class ScanTrainingSample {
  const ScanTrainingSample({
    required this.id,
    required this.imageBytes,
    required this.capturedAt,
    required this.predictedPopularName,
    required this.predictedScientificName,
    required this.confidence,
    required this.isPrimarySelection,
    this.sourceLabel,
    this.userDescription,
    this.city,
    this.state,
  });

  final String id;
  final Uint8List imageBytes;
  final DateTime capturedAt;
  final String predictedPopularName;
  final String predictedScientificName;
  final double confidence;
  final bool isPrimarySelection;
  final String? sourceLabel;
  final String? userDescription;
  final String? city;
  final String? state;

  Map<String, dynamic> toJson({
    bool includePhotoBytes = true,
    String? photoStoragePath,
  }) {
    return {
      'id': id,
      if (includePhotoBytes) 'photoBytes': base64Encode(imageBytes),
      'photoStoragePath': photoStoragePath,
      'capturedAt': capturedAt.toIso8601String(),
      'predictedPopularName': predictedPopularName,
      'predictedScientificName': predictedScientificName,
      'confidence': confidence,
      'isPrimarySelection': isPrimarySelection,
      'sourceLabel': sourceLabel,
      'userDescription': userDescription,
      'city': city,
      'state': state,
    };
  }

  factory ScanTrainingSample.fromJson(
    Map<String, dynamic> json, {
    Uint8List? resolvedPhotoBytes,
  }) {
    final inlinePhoto = json['photoBytes'] as String?;
    return ScanTrainingSample(
      id: json['id'] as String,
      imageBytes:
          resolvedPhotoBytes ??
          (inlinePhoto != null
              ? base64Decode(inlinePhoto)
              : Uint8List.fromList(const <int>[])),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      predictedPopularName: json['predictedPopularName'] as String? ?? '',
      predictedScientificName: json['predictedScientificName'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isPrimarySelection: (json['isPrimarySelection'] as bool?) ?? false,
      sourceLabel: json['sourceLabel'] as String?,
      userDescription: json['userDescription'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
    );
  }
}
