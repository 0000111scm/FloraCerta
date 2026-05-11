import 'dart:convert';
import 'dart:typed_data';

import 'location_privacy_mode.dart';

class PlantIdentification {
  const PlantIdentification({
    required this.id,
    required this.popularName,
    required this.scientificName,
    required this.confidence,
    required this.description,
    required this.photoBytes,
    required this.identifiedAt,
    required this.notes,
    required this.saveExactLocation,
    required this.locationPrivacyMode,
    this.latitude,
    this.longitude,
    this.addressText,
    this.city,
    this.state,
  });

  final String id;
  final String popularName;
  final String scientificName;
  final double confidence;
  final String description;
  final Uint8List photoBytes;
  final DateTime identifiedAt;
  final String notes;
  final bool saveExactLocation;
  final LocationPrivacyMode locationPrivacyMode;
  final double? latitude;
  final double? longitude;
  final String? addressText;
  final String? city;
  final String? state;

  Map<String, dynamic> toJson({
    bool includePhotoBytes = true,
    String? photoStoragePath,
  }) {
    return {
      'id': id,
      'popularName': popularName,
      'scientificName': scientificName,
      'confidence': confidence,
      'description': description,
      if (includePhotoBytes) 'photoBytes': base64Encode(photoBytes),
      'photoStoragePath': photoStoragePath,
      'identifiedAt': identifiedAt.toIso8601String(),
      'notes': notes,
      'saveExactLocation': saveExactLocation,
      'locationPrivacyMode': locationPrivacyMode.storageValue,
      'latitude': latitude,
      'longitude': longitude,
      'addressText': addressText,
      'city': city,
      'state': state,
    };
  }

  factory PlantIdentification.fromJson(
    Map<String, dynamic> json, {
    Uint8List? resolvedPhotoBytes,
  }) {
    final inlinePhoto = json['photoBytes'] as String?;
    return PlantIdentification(
      id: json['id'] as String,
      popularName: json['popularName'] as String,
      scientificName: json['scientificName'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'] as String,
      photoBytes:
          resolvedPhotoBytes ??
          (inlinePhoto != null
              ? base64Decode(inlinePhoto)
              : Uint8List.fromList(const <int>[])),
      identifiedAt: DateTime.parse(json['identifiedAt'] as String),
      notes: json['notes'] as String,
      saveExactLocation: (json['saveExactLocation'] as bool?) ?? false,
      locationPrivacyMode: _resolveLocationPrivacyMode(json),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      addressText: json['addressText'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
    );
  }

  static LocationPrivacyMode _resolveLocationPrivacyMode(
    Map<String, dynamic> json,
  ) {
    final rawMode = json['locationPrivacyMode'] as String?;
    if (rawMode != null) {
      return LocationPrivacyMode.fromStorage(rawMode);
    }

    final legacyExactFlag = (json['saveExactLocation'] as bool?) ?? false;
    if (legacyExactFlag) {
      return LocationPrivacyMode.exact;
    }

    if (json['latitude'] != null || json['longitude'] != null) {
      return LocationPrivacyMode.approximate;
    }

    return LocationPrivacyMode.none;
  }
}
