import 'plant_status.dart';

class UserPlant {
  const UserPlant({
    required this.id,
    this.identificationId,
    required this.popularName,
    required this.scientificName,
    required this.nickname,
    required this.locationName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String? identificationId;
  final String popularName;
  final String scientificName;
  final String nickname;
  final String locationName;
  final PlantStatus status;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identificationId': identificationId,
      'popularName': popularName,
      'scientificName': scientificName,
      'nickname': nickname,
      'locationName': locationName,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserPlant.fromJson(Map<String, dynamic> json) {
    return UserPlant(
      id: json['id'] as String,
      identificationId: json['identificationId'] as String?,
      popularName: json['popularName'] as String,
      scientificName: json['scientificName'] as String,
      nickname: json['nickname'] as String,
      locationName: json['locationName'] as String,
      status: PlantStatus.fromName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
