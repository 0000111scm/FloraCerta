enum DiagnosisProblemType {
  unknown,
  pest,
  fungal,
  wateringOrDrainage,
  nutrition,
}

extension DiagnosisProblemTypeX on DiagnosisProblemType {
  String get label {
    switch (this) {
      case DiagnosisProblemType.unknown:
        return 'Nao definido';
      case DiagnosisProblemType.pest:
        return 'Praga';
      case DiagnosisProblemType.fungal:
        return 'Fungico';
      case DiagnosisProblemType.wateringOrDrainage:
        return 'Rega/Drenagem';
      case DiagnosisProblemType.nutrition:
        return 'Nutricao';
    }
  }
}

enum TreatmentStatusOption { monitor, inTreatment, improved, unresolved }

extension TreatmentStatusOptionX on TreatmentStatusOption {
  String get label {
    switch (this) {
      case TreatmentStatusOption.monitor:
        return 'Monitorar';
      case TreatmentStatusOption.inTreatment:
        return 'Em tratamento';
      case TreatmentStatusOption.improved:
        return 'Melhorando';
      case TreatmentStatusOption.unresolved:
        return 'Sem melhora';
    }
  }
}
