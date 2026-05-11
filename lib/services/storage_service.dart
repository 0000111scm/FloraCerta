import 'package:flutter/foundation.dart';

import '../features/diagnosis/models/plant_problem.dart';
import '../features/identification/models/plant_identification.dart';
import '../features/my_plants/models/plant_log.dart';
import '../features/my_plants/models/user_plant.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final ValueNotifier<List<PlantIdentification>> identifications =
      ValueNotifier<List<PlantIdentification>>(<PlantIdentification>[]);
  final ValueNotifier<List<UserPlant>> userPlants =
      ValueNotifier<List<UserPlant>>(<UserPlant>[]);
  final ValueNotifier<List<PlantLog>> plantLogs = ValueNotifier<List<PlantLog>>(
    <PlantLog>[],
  );
  final ValueNotifier<List<PlantProblem>> plantProblems =
      ValueNotifier<List<PlantProblem>>(<PlantProblem>[]);

  void saveIdentification(PlantIdentification identification) {
    final updated = List<PlantIdentification>.from(identifications.value)
      ..insert(0, identification);
    identifications.value = updated;
  }

  void updateIdentification(PlantIdentification identification) {
    final updated = identifications.value
        .map((item) => item.id == identification.id ? identification : item)
        .toList();
    identifications.value = updated;
  }

  void removeIdentification(String identificationId) {
    final updated = identifications.value
        .where((item) => item.id != identificationId)
        .toList();
    identifications.value = updated;
  }

  void saveUserPlant(UserPlant userPlant) {
    final updated = List<UserPlant>.from(userPlants.value)
      ..insert(0, userPlant);
    userPlants.value = updated;
  }

  void updateUserPlant(UserPlant userPlant) {
    final updated = userPlants.value
        .map((item) => item.id == userPlant.id ? userPlant : item)
        .toList();
    userPlants.value = updated;
  }

  void removeUserPlant(String userPlantId) {
    final updated = userPlants.value
        .where((item) => item.id != userPlantId)
        .toList();
    userPlants.value = updated;
  }

  void savePlantLog(PlantLog plantLog) {
    final updated = List<PlantLog>.from(plantLogs.value)..insert(0, plantLog);
    plantLogs.value = updated;
  }

  void updatePlantLog(PlantLog plantLog) {
    final updated = plantLogs.value
        .map((item) => item.id == plantLog.id ? plantLog : item)
        .toList();
    plantLogs.value = updated;
  }

  void removePlantLog(String plantLogId) {
    final updated = plantLogs.value
        .where((item) => item.id != plantLogId)
        .toList();
    plantLogs.value = updated;
  }

  void savePlantProblem(PlantProblem plantProblem) {
    final updated = List<PlantProblem>.from(plantProblems.value)
      ..insert(0, plantProblem);
    plantProblems.value = updated;
  }

  void updatePlantProblem(PlantProblem plantProblem) {
    final updated = plantProblems.value
        .map((item) => item.id == plantProblem.id ? plantProblem : item)
        .toList();
    plantProblems.value = updated;
  }

  void removePlantProblem(String plantProblemId) {
    final updated = plantProblems.value
        .where((item) => item.id != plantProblemId)
        .toList();
    plantProblems.value = updated;
  }

  UserPlant? findUserPlantById(String id) {
    for (final plant in userPlants.value) {
      if (plant.id == id) {
        return plant;
      }
    }
    return null;
  }

  List<PlantLog> logsForPlant(String userPlantId) {
    return plantLogs.value
        .where((log) => log.userPlantId == userPlantId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<PlantProblem> problemsForPlant(String userPlantId) {
    return plantProblems.value
        .where((problem) => problem.userPlantId == userPlantId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
