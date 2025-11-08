/// Helper per parsing sicuro dei report WooCommerce
///
/// Questo helper è necessario perché l'API WooCommerce può restituire
/// alcuni campi numerici come String invece di int, causando errori
/// di tipo durante la deserializzazione JSON del package woocommerce_flutter_api.
library;

/// Parse sicuro di un valore int che potrebbe essere String
int? parseIntSafe(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  // Fallback: prova a convertire a stringa e poi parsare
  return int.tryParse(value.toString());
}

/// Parse sicuro di un valore double che potrebbe essere String
double? parseDoubleSafe(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  // Fallback: prova a convertire a stringa e poi parsare
  return double.tryParse(value.toString());
}

/// Parse sicuro di un valore String
String parseStringSafe(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  if (value is String) return value;
  return value.toString();
}
