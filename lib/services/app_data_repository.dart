import 'package:flutter/foundation.dart';

import '../features/diagnosis/models/plant_problem.dart';
import '../features/identification/models/plant_identification.dart';
import '../features/identification/models/scan_training_sample.dart';
import '../features/my_plants/models/plant_log.dart';
import '../features/my_plants/models/user_plant.dart';
import 'local_persistence_service.dart';
import 'storage_service.dart';

class AppDataRepository {
  AppDataRepository._();

  static final AppDataRepository instance = AppDataRepository._();

  final LocalPersistenceService _localPersistenceService =
      LocalPersistenceService();
  final StorageService _storageService = StorageService.instance;
  bool _initialized = false;

  ValueListenable<List<PlantIdentification>> get identificationsListenable =>
      _storageService.identifications;

  ValueListenable<List<UserPlant>> get userPlantsListenable =>
      _storageService.userPlants;

  ValueListenable<List<PlantLog>> get plantLogsListenable =>
      _storageService.plantLogs;

  ValueListenable<List<PlantProblem>> get plantProblemsListenable =>
      _storageService.plantProblems;
  ValueListenable<List<ScanTrainingSample>> get scanSamplesListenable =>
      _storageService.scanSamples;

  bool get isUsingPersistentLocalStorage => true;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final snapshot = await _localPersistenceService.loadAll();
    _storageService.identifications.value = snapshot.identifications;
    _storageService.userPlants.value = snapshot.userPlants;
    _storageService.plantLogs.value = snapshot.plantLogs;
    _storageService.plantProblems.value = snapshot.plantProblems;
    _storageService.scanSamples.value = snapshot.scanSamples;
    _initialized = true;
  }

  void saveIdentification(PlantIdentification identification) {
    _storageService.saveIdentification(identification);
    _persistIdentifications();
  }

  void updateIdentification(PlantIdentification identification) {
    _storageService.updateIdentification(identification);
    _persistIdentifications();
  }

  void removeIdentification(String identificationId) {
    _storageService.removeIdentification(identificationId);
    _persistIdentifications();
  }

  void saveUserPlant(UserPlant userPlant) {
    _storageService.saveUserPlant(userPlant);
    _persistUserPlants();
  }

  void updateUserPlant(UserPlant userPlant) {
    _storageService.updateUserPlant(userPlant);
    _persistUserPlants();
  }

  void removeUserPlant(String userPlantId) {
    _storageService.removeUserPlant(userPlantId);
    final filteredLogs = _storageService.plantLogs.value
        .where((item) => item.userPlantId != userPlantId)
        .toList();
    _storageService.plantLogs.value = filteredLogs;
    final filteredProblems = _storageService.plantProblems.value
        .where((item) => item.userPlantId != userPlantId)
        .toList();
    _storageService.plantProblems.value = filteredProblems;
    _persistUserPlants();
    _persistPlantLogs();
    _persistPlantProblems();
  }

  void savePlantLog(PlantLog plantLog) {
    _storageService.savePlantLog(plantLog);
    _persistPlantLogs();
  }

  void updatePlantLog(PlantLog plantLog) {
    _storageService.updatePlantLog(plantLog);
    _persistPlantLogs();
  }

  void removePlantLog(String plantLogId) {
    _storageService.removePlantLog(plantLogId);
    _persistPlantLogs();
  }

  void savePlantProblem(PlantProblem plantProblem) {
    _storageService.savePlantProblem(plantProblem);
    _persistPlantProblems();
  }

  void updatePlantProblem(PlantProblem plantProblem) {
    _storageService.updatePlantProblem(plantProblem);
    _persistPlantProblems();
  }

  void removePlantProblem(String plantProblemId) {
    _storageService.removePlantProblem(plantProblemId);
    _persistPlantProblems();
  }

  void saveScanSamples(List<ScanTrainingSample> samples) {
    _storageService.saveScanSamples(samples);
    _persistScanSamples();
  }

  UserPlant? findUserPlantById(String id) {
    return _storageService.findUserPlantById(id);
  }

  List<PlantLog> logsForPlant(String userPlantId) {
    return _storageService.logsForPlant(userPlantId);
  }

  List<PlantProblem> problemsForPlant(String userPlantId) {
    return _storageService.problemsForPlant(userPlantId);
  }

  void _persistIdentifications() {
    _localPersistenceService.saveIdentifications(
      _storageService.identifications.value,
    );
  }

  void _persistUserPlants() {
    _localPersistenceService.saveUserPlants(_storageService.userPlants.value);
  }

  void _persistPlantLogs() {
    _localPersistenceService.savePlantLogs(_storageService.plantLogs.value);
  }

  void _persistPlantProblems() {
    _localPersistenceService.savePlantProblems(
      _storageService.plantProblems.value,
    );
  }

  void _persistScanSamples() {
    _localPersistenceService.saveScanSamples(_storageService.scanSamples.value);
  }
}
