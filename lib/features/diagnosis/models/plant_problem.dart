import 'dart:convert';
import 'dart:typed_data';

class PlantProblem {
  const PlantProblem({
    required this.id,
    required this.userPlantId,
    required this.problemType,
    required this.symptoms,
    required this.diagnosis,
    required this.treatment,
    required this.status,
    required this.createdAt,
    this.photoPath,
    this.photoBytes,
  });

  final String id;
  final String userPlantId;
  final String? photoPath;
  final Uint8List? photoBytes;
  final String problemType;
  final String symptoms;
  final String diagnosis;
  final String treatment;
  final String status;
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
      'problemType': problemType,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlantProblem.fromJson(
    Map<String, dynamic> json, {
    Uint8List? resolvedPhotoBytes,
  }) {
    final inlinePhoto = json['photoBytes'] as String?;
    return PlantProblem(
      id: json['id'] as String,
      userPlantId: json['userPlantId'] as String,
      photoPath: json['photoPath'] as String?,
      photoBytes:
          resolvedPhotoBytes ??
          (inlinePhoto != null ? base64Decode(inlinePhoto) : null),
      problemType: json['problemType'] as String,
      symptoms: json['symptoms'] as String,
      diagnosis: json['diagnosis'] as String,
      treatment: json['treatment'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
