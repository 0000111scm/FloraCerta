import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/diagnosis/models/plant_problem.dart';
import '../features/identification/models/plant_identification.dart';
import '../features/my_plants/models/plant_log.dart';
import '../features/my_plants/models/user_plant.dart';
import 'image_asset_store.dart';

class LocalPersistenceSnapshot {
  const LocalPersistenceSnapshot({
    required this.identifications,
    required this.userPlants,
    required this.plantLogs,
    required this.plantProblems,
  });

  final List<PlantIdentification> identifications;
  final List<UserPlant> userPlants;
  final List<PlantLog> plantLogs;
  final List<PlantProblem> plantProblems;
}

class LocalPersistenceService {
  static const _identificationsKey = 'identifications_v2';
  static const _userPlantsKey = 'user_plants_v1';
  static const _plantLogsKey = 'plant_logs_v2';
  static const _plantProblemsKey = 'plant_problems_v2';

  final ImageAssetStore _imageAssetStore = const ImageAssetStore();

  Future<LocalPersistenceSnapshot> loadAll() async {
    final preferences = await SharedPreferences.getInstance();

    return LocalPersistenceSnapshot(
      identifications: await _decodeIdentificationList(
        preferences.getString(_identificationsKey),
      ),
      userPlants: _decodeList(
        preferences.getString(_userPlantsKey),
        UserPlant.fromJson,
      ),
      plantLogs: await _decodePlantLogs(preferences.getString(_plantLogsKey)),
      plantProblems: await _decodePlantProblems(
        preferences.getString(_plantProblemsKey),
      ),
    );
  }

  Future<void> saveIdentifications(List<PlantIdentification> items) async {
    final preferences = await SharedPreferences.getInstance();
    final previousRaw = preferences.getString(_identificationsKey);
    final previousPaths = _extractStoredPaths(previousRaw);
    final encoded = <Map<String, dynamic>>[];

    for (final item in items) {
      final photoStoragePath = await _persistPhoto(
        category: 'identifications',
        id: item.id,
        bytes: item.photoBytes,
      );

      encoded.add(
        item.toJson(
          includePhotoBytes: photoStoragePath == null,
          photoStoragePath: photoStoragePath,
        ),
      );
    }

    await preferences.setString(_identificationsKey, jsonEncode(encoded));
    await _cleanupRemovedPaths(
      previousPaths: previousPaths,
      nextPaths: _extractStoredPathsFromMaps(encoded),
    );
  }

  Future<void> saveUserPlants(List<UserPlant> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _userPlantsKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> savePlantLogs(List<PlantLog> items) async {
    final preferences = await SharedPreferences.getInstance();
    final previousRaw = preferences.getString(_plantLogsKey);
    final previousPaths = _extractStoredPaths(previousRaw);
    final encoded = <Map<String, dynamic>>[];

    for (final item in items) {
      final photoStoragePath = item.photoBytes == null
          ? null
          : await _persistPhoto(
              category: 'plant_logs',
              id: item.id,
              bytes: item.photoBytes!,
            );

      encoded.add(
        item.toJson(
          includePhotoBytes: photoStoragePath == null,
          photoStoragePath: photoStoragePath,
        ),
      );
    }

    await preferences.setString(_plantLogsKey, jsonEncode(encoded));
    await _cleanupRemovedPaths(
      previousPaths: previousPaths,
      nextPaths: _extractStoredPathsFromMaps(encoded),
    );
  }

  Future<void> savePlantProblems(List<PlantProblem> items) async {
    final preferences = await SharedPreferences.getInstance();
    final previousRaw = preferences.getString(_plantProblemsKey);
    final previousPaths = _extractStoredPaths(previousRaw);
    final encoded = <Map<String, dynamic>>[];

    for (final item in items) {
      final photoStoragePath = item.photoBytes == null
          ? null
          : await _persistPhoto(
              category: 'plant_problems',
              id: item.id,
              bytes: item.photoBytes!,
            );

      encoded.add(
        item.toJson(
          includePhotoBytes: photoStoragePath == null,
          photoStoragePath: photoStoragePath,
        ),
      );
    }

    await preferences.setString(_plantProblemsKey, jsonEncode(encoded));
    await _cleanupRemovedPaths(
      previousPaths: previousPaths,
      nextPaths: _extractStoredPathsFromMaps(encoded),
    );
  }

  Future<List<PlantIdentification>> _decodeIdentificationList(
    String? raw,
  ) async {
    if (raw == null || raw.isEmpty) {
      return <PlantIdentification>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = <PlantIdentification>[];

    for (final item in decoded) {
      final map = item as Map<String, dynamic>;
      final photoStoragePath = map['photoStoragePath'] as String?;
      final storedBytes = await _resolveStoredBytes(photoStoragePath);

      items.add(
        PlantIdentification.fromJson(map, resolvedPhotoBytes: storedBytes),
      );
    }

    return items;
  }

  Future<List<PlantLog>> _decodePlantLogs(String? raw) async {
    if (raw == null || raw.isEmpty) {
      return <PlantLog>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = <PlantLog>[];

    for (final item in decoded) {
      final map = item as Map<String, dynamic>;
      final photoStoragePath = map['photoStoragePath'] as String?;
      final storedBytes = await _resolveStoredBytes(photoStoragePath);

      items.add(PlantLog.fromJson(map, resolvedPhotoBytes: storedBytes));
    }

    return items;
  }

  Future<List<PlantProblem>> _decodePlantProblems(String? raw) async {
    if (raw == null || raw.isEmpty) {
      return <PlantProblem>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = <PlantProblem>[];

    for (final item in decoded) {
      final map = item as Map<String, dynamic>;
      final photoStoragePath = map['photoStoragePath'] as String?;
      final storedBytes = await _resolveStoredBytes(photoStoragePath);

      items.add(PlantProblem.fromJson(map, resolvedPhotoBytes: storedBytes));
    }

    return items;
  }

  Future<String?> _persistPhoto({
    required String category,
    required String id,
    required Uint8List bytes,
  }) {
    return _imageAssetStore.saveBinaryAsset(
      category: category,
      id: id,
      bytes: bytes,
    );
  }

  Future<Uint8List?> _resolveStoredBytes(String? photoStoragePath) {
    if (photoStoragePath == null || photoStoragePath.isEmpty) {
      return Future.value(null);
    }

    return _imageAssetStore.readBinaryAsset(photoStoragePath);
  }

  Set<String> _extractStoredPaths(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String>{};
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => (item as Map<String, dynamic>)['photoStoragePath'])
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toSet();
  }

  Set<String> _extractStoredPathsFromMaps(List<Map<String, dynamic>> items) {
    return items
        .map((item) => item['photoStoragePath'])
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toSet();
  }

  Future<void> _cleanupRemovedPaths({
    required Set<String> previousPaths,
    required Set<String> nextPaths,
  }) async {
    final removedPaths = previousPaths.difference(nextPaths);
    for (final path in removedPaths) {
      await _imageAssetStore.deleteBinaryAsset(path);
    }
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) {
      return <T>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
