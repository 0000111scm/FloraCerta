import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../features/identification/models/identification_location.dart';

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  const LocationService();

  Future<IdentificationLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Ative o servico de localizacao do dispositivo para continuar.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException('Permissao de localizacao negada.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Permissao de localizacao negada permanentemente. Ajuste nas configuracoes do dispositivo.',
      );
    }

    final position = await Geolocator.getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final placemark = placemarks.isNotEmpty ? placemarks.first : null;

    return IdentificationLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      addressText: _buildAddressText(placemark),
      city: placemark?.subAdministrativeArea?.trim().isNotEmpty == true
          ? placemark!.subAdministrativeArea!.trim()
          : placemark?.locality?.trim() ?? 'Cidade nao identificada',
      state: placemark?.administrativeArea?.trim().isNotEmpty == true
          ? placemark!.administrativeArea!.trim()
          : 'Estado nao identificado',
      capturedAt: DateTime.now(),
    );
  }

  String _buildAddressText(Placemark? placemark) {
    if (placemark == null) {
      return 'Endereco aproximado indisponivel';
    }

    final parts =
        [
              placemark.street,
              placemark.subLocality,
              placemark.locality,
              placemark.administrativeArea,
            ]
            .map((part) => part?.trim() ?? '')
            .where((part) => part.isNotEmpty)
            .toList();

    if (parts.isEmpty) {
      return 'Endereco aproximado indisponivel';
    }

    return parts.join(', ');
  }
}
