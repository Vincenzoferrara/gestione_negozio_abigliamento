class ClassFormtter {
  static String formatPrezzo(double prezzo) {
    return '€${prezzo.toStringAsFixed(2)}';
  }

  static String formatPrezzoConSconto(
    double prezzoNormale,
    double? prezzoScontato,
  ) {
    if (prezzoScontato != null) {
      return '${formatPrezzo(prezzoScontato)} (era ${formatPrezzo(prezzoNormale)})';
    }
    return formatPrezzo(prezzoNormale);
  }

  static String getDisponibilitaText(bool inStock) {
    return inStock ? 'Disponibile' : 'Esaurito';
  }

  static String getVariantiCountText(int count) {
    return count == 1 ? '1 variante' : '$count varianti';
  }

  static String getVariantiCountShort(int count) {
    return '$count var.';
  }
}
