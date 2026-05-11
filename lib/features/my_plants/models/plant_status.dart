enum PlantStatus {
  healthy('Saudavel'),
  attention('Atencao'),
  recovering('Em recuperacao'),
  sick('Doente'),
  unknown('Desconhecido');

  const PlantStatus(this.label);

  final String label;

  static PlantStatus fromName(String value) {
    return PlantStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PlantStatus.unknown,
    );
  }
}
