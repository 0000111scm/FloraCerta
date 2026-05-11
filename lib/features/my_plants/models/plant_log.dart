import 'dart:convert';
import 'dart:typed_data';

import 'plant_status.dart';

class PlantLog {
  const PlantLog({
    required this.id,
    required this.userPlantId,
    required this.note,
    required this.healthStatus,
    required this.createdAt,
    this.photoPath,
    this.photoBytes,
    this.heightCm,
    this.treatment,
  });

  final String id;
  final String userPlantId;
  final String? photoPath;
  final Uint8List? photoBytes;
  final String note;
  final PlantStatus healthStatus;
  final double? heightCm;
  final String? treatment;
  final DateTime createdAt;

  Map<String, dynamic> toJson({
    bool includePhotoBytes = true,
    String? photoStoragePath,
  }) {
    return {
      'id': id,
      'userPlantId': userPlantId,
      'photoPath': photoPath,
      if (includePhotoBytes && photoBytes != null)
        'photoBytes': base64Encode(photoBytes!),
      'photoStoragePath': photoStoragePath,
      'note': note,
      'healthStatus': healthStatus.name,
      'heightCm': heightCm,
      'treatment': treatment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlantLog.fromJson(
    Map<String, dynamic> json, {
    Uint8List? resolvedPhotoBytes,
  }) {
    final inlinePhoto = json['photoBytes'] as String?;
    return PlantLog(
      id: json['id'] as String,
      userPlantId: json['userPlantId'] as String,
      photoPath: json['photoPath'] as String?,
      photoBytes:
          resolvedPhotoBytes ??
          (inlinePhoto != null ? base64Decode(inlinePhoto) : null),
      note: json['note'] as String,
      healthStatus: PlantStatus.fromName(json['healthStatus'] as String),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      treatment: json['treatment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
