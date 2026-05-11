import 'diagnosis_options.dart';

class DiagnosisResult {
  const DiagnosisResult({
    required this.problemType,
    required this.probableDiagnosis,
    required this.suggestedTreatment,
    required this.treatmentStatus,
    required this.treatmentStatusOption,
    required this.disclaimer,
  });

  final String problemType;
  final String probableDiagnosis;
  final String suggestedTreatment;
  final String treatmentStatus;
  final TreatmentStatusOption treatmentStatusOption;
  final String disclaimer;
}
