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

    final position = await _resolveBestPosition();

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final placemark = placemarks.isNotEmpty ? placemarks.first : null;

    return IdentificationLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
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

  Future<Position> _resolveBestPosition() async {
    Position? best = await Geolocator.getLastKnownPosition();

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 20),
        ),
      );
      best = _pickBestAccuracy(best, current);
    } catch (_) {
      // Continua para tentativa por stream.
    }

    try {
      final streamBest = await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).where((item) => item.accuracy > 0).take(3).reduce(_pickBestPair);
      best = _pickBestAccuracy(best, streamBest);
    } catch (_) {
      // Fallback para melhor dado ja obtido.
    }

    if (best == null) {
      throw const LocationServiceException(
        'Nao foi possivel obter localizacao no momento. Ative o GPS e tente novamente.',
      );
    }
    return best;
  }

  Position _pickBestPair(Position a, Position b) {
    return a.accuracy <= b.accuracy ? a : b;
  }

  Position _pickBestAccuracy(Position? current, Position next) {
    if (current == null) {
      return next;
    }
    return current.accuracy <= next.accuracy ? current : next;
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
