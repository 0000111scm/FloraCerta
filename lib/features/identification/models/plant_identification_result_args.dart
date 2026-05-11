import 'dart:typed_data';

import 'identification_location.dart';
import 'location_privacy_mode.dart';
import 'plant_identification_result.dart';

class PlantIdentificationResultArgs {
  const PlantIdentificationResultArgs({
    required this.imageBytes,
    required this.imageName,
    required this.result,
    required this.locationPrivacyMode,
    required this.userDescription,
    this.location,
  });

  final Uint8List imageBytes;
  final String imageName;
  final PlantIdentificationResult result;
  final LocationPrivacyMode locationPrivacyMode;
  final String userDescription;
  final IdentificationLocation? location;
}
