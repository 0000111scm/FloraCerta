class IdentificationLocation {
  const IdentificationLocation({
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.city,
    required this.state,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final String addressText;
  final String city;
  final String state;
  final DateTime capturedAt;
}
