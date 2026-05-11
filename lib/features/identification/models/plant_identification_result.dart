class PlantIdentificationResult {
  const PlantIdentificationResult({
    required this.popularName,
    required this.scientificName,
    required this.confidence,
    required this.description,
    required this.similarSpecies,
    required this.light,
    required this.water,
    required this.soil,
    required this.pruning,
    required this.fertilization,
    required this.toxicity,
    this.sourceLabel,
    this.disclaimer,
  });

  final String popularName;
  final String scientificName;
  final double confidence;
  final String description;
  final List<String> similarSpecies;
  final String light;
  final String water;
  final String soil;
  final String pruning;
  final String fertilization;
  final String toxicity;
  final String? sourceLabel;
  final String? disclaimer;

  factory PlantIdentificationResult.mock({
    String? userDescription,
    String? reason,
  }) {
    final descriptionSuffix = userDescription == null || userDescription.isEmpty
        ? ''
        : ' Descricao informada: $userDescription.';

    return PlantIdentificationResult(
      popularName: 'Jiboia',
      scientificName: 'Epipremnum aureum',
      confidence: 0.92,
      description:
          'Trepadeira ornamental muito popular em ambientes internos, com folhas vistosas e crescimento vigoroso.$descriptionSuffix',
      similarSpecies: [
        'Filodendro-brasil',
        'Scindapsus pictus',
        'Monstera adansonii jovem',
      ],
      light: 'Prefere luz indireta brilhante, mas tolera meia-sombra.',
      water:
          'Regue quando os primeiros centimetros do substrato estiverem secos.',
      soil: 'Substrato leve, organico e com boa drenagem.',
      pruning: 'Pode podar pontas e ramos longos para estimular volume.',
      fertilization: 'Adubacao leve a cada 30 a 45 dias nas estacoes quentes.',
      toxicity: 'Pode ser toxica para pets e criancas se ingerida.',
      sourceLabel: 'Exemplo local',
      disclaimer:
          reason ??
          'Resultado gerado localmente para demonstrar o fluxo, sem consulta a API externa.',
    );
  }
}
