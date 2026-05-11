enum LocationPrivacyMode {
  none,
  approximate,
  exact;

  String get label {
    switch (this) {
      case LocationPrivacyMode.none:
        return 'Nao salvar';
      case LocationPrivacyMode.approximate:
        return 'Aproximada';
      case LocationPrivacyMode.exact:
        return 'Exata';
    }
  }

  String get description {
    switch (this) {
      case LocationPrivacyMode.none:
        return 'Nao salva dados de localizacao nesta identificacao.';
      case LocationPrivacyMode.approximate:
        return 'Salva apenas regiao aproximada (cidade/estado).';
      case LocationPrivacyMode.exact:
        return 'Salva latitude e longitude exatas.';
    }
  }

  String get storageValue {
    switch (this) {
      case LocationPrivacyMode.none:
        return 'none';
      case LocationPrivacyMode.approximate:
        return 'approximate';
      case LocationPrivacyMode.exact:
        return 'exact';
    }
  }

  static LocationPrivacyMode fromStorage(String? value) {
    switch (value) {
      case 'approximate':
        return LocationPrivacyMode.approximate;
      case 'exact':
        return LocationPrivacyMode.exact;
      default:
        return LocationPrivacyMode.none;
    }
  }
}
