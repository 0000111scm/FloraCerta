import '../features/diagnosis/models/diagnosis_result.dart';
import '../features/diagnosis/models/diagnosis_options.dart';

class PlantDiagnosisService {
  const PlantDiagnosisService();

  DiagnosisResult generateMockDiagnosis({
    required String plantName,
    required String symptoms,
    DiagnosisProblemType selectedProblemType = DiagnosisProblemType.unknown,
  }) {
    final normalized = symptoms.toLowerCase();

    if (selectedProblemType == DiagnosisProblemType.wateringOrDrainage ||
        normalized.contains('amarela') ||
        normalized.contains('amarel') ||
        normalized.contains('murcha')) {
      return DiagnosisResult(
        problemType: 'Estresse de rega ou drenagem',
        probableDiagnosis:
            'Exemplo local: $plantName pode estar reagindo a excesso de agua, drenagem ruim ou raiz com pouca oxigenacao.',
        suggestedTreatment:
            'Revise a frequencia de rega, confira se o vaso drena bem e observe a umidade do substrato antes de regar novamente.',
        treatmentStatus: 'Acompanhar nos proximos dias',
        treatmentStatusOption: TreatmentStatusOption.monitor,
        disclaimer:
            'Resposta mockada apenas para demonstrar o fluxo. Nao representa diagnostico botanico real.',
      );
    }

    if (selectedProblemType == DiagnosisProblemType.fungal ||
        normalized.contains('mancha') ||
        normalized.contains('fung') ||
        normalized.contains('bolor')) {
      return DiagnosisResult(
        problemType: 'Possivel problema fungico',
        probableDiagnosis:
            'Exemplo local: os sintomas lembram manchas foliares associadas a excesso de umidade e baixa ventilacao.',
        suggestedTreatment:
            'Isole folhas mais afetadas, reduza molhamento das folhas e melhore ventilacao e iluminacao do ambiente.',
        treatmentStatus: 'Monitorar evolucao',
        treatmentStatusOption: TreatmentStatusOption.inTreatment,
        disclaimer:
            'Resposta mockada apenas para demonstrar o fluxo. Nao representa diagnostico botanico real.',
      );
    }

    if (selectedProblemType == DiagnosisProblemType.pest ||
        normalized.contains('praga') ||
        normalized.contains('inseto') ||
        normalized.contains('cochonilha') ||
        normalized.contains('pulg')) {
      return DiagnosisResult(
        problemType: 'Possivel infestacao de pragas',
        probableDiagnosis:
            'Exemplo local: ha sinais que podem indicar pragas comuns em plantas ornamentais, como cochonilhas ou pulgoes.',
        suggestedTreatment:
            'Inspecione verso das folhas, limpe manualmente as areas afetadas e avalie tratamento apropriado conforme a praga observada.',
        treatmentStatus: 'Inspecao recomendada',
        treatmentStatusOption: TreatmentStatusOption.monitor,
        disclaimer:
            'Resposta mockada apenas para demonstrar o fluxo. Nao representa diagnostico botanico real.',
      );
    }

    if (selectedProblemType == DiagnosisProblemType.nutrition) {
      return DiagnosisResult(
        problemType: 'Possivel desequilibrio nutricional',
        probableDiagnosis:
            'Exemplo local: os sintomas podem indicar baixa disponibilidade de nutrientes ou substrato esgotado.',
        suggestedTreatment:
            'Avalie adubacao equilibrada, condicao do substrato e resposta da planta nas proximas semanas.',
        treatmentStatus: 'Acompanhar resposta da adubacao',
        treatmentStatusOption: TreatmentStatusOption.inTreatment,
        disclaimer:
            'Resposta mockada apenas para demonstrar o fluxo. Nao representa diagnostico botanico real.',
      );
    }

    return DiagnosisResult(
      problemType: 'Observacao geral',
      probableDiagnosis:
          'Exemplo local: os sintomas informados sugerem necessidade de observacao adicional antes de qualquer conclusao confiavel.',
      suggestedTreatment:
          'Registre novas fotos, acompanhe mudancas nas folhas e no substrato e compare com proximos registros da planta.',
      treatmentStatus: 'Sem conclusao definitiva',
      treatmentStatusOption: TreatmentStatusOption.unresolved,
      disclaimer:
          'Resposta mockada apenas para demonstrar o fluxo. Nao representa diagnostico botanico real.',
    );
  }
}
