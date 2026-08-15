import '../login/jwt_api/jwt_connect.dart';

/// Normalizza l'URL di un'immagine proveniente da WooCommerce rispetto al
/// sito a cui l'app è effettivamente connessa.
///
/// WooCommerce restituisce URL assoluti costruiti sulla `siteurl` configurata
/// in WordPress (spesso `http://localhost:8080` o l'hostname di un container
/// docker). Su un dispositivo diverso dal server (es. smartphone in LAN)
/// quell'host non è raggiungibile: `localhost` punta al dispositivo stesso.
/// Qui l'host viene riscritto con quello del sito connesso al login.
String? resolveImageUrl(String? url) {
  final raw = url?.trim() ?? '';
  if (raw.isEmpty) return url;

  final siteUrl = JwtConnect().currentSiteUrl?.trim() ?? '';
  if (siteUrl.isEmpty) return url;

  final siteUri = Uri.tryParse(siteUrl);
  if (siteUri == null || siteUri.host.isEmpty) return url;

  // URL relativo (es. /wp-content/uploads/...): lo risolve contro la base.
  if (raw.startsWith('/')) {
    final base =
        siteUrl.endsWith('/') ? siteUrl.substring(0, siteUrl.length - 1) : siteUrl;
    return '$base$raw';
  }

  final imageUri = Uri.tryParse(raw);
  if (imageUri == null || !imageUri.hasScheme) return url;

  // Host non loopback: può essere un dominio pubblico o un IP già corretto.
  final host = imageUri.host.toLowerCase();
  final isLoopback =
      host == 'localhost' || host == '127.0.0.1' || host == '::1';
  if (!isLoopback) return url;

  return imageUri
      .replace(
        scheme: siteUri.scheme,
        host: siteUri.host,
        port: siteUri.hasPort
            ? siteUri.port
            : (siteUri.scheme == 'https' ? 443 : 80),
      )
      .toString();
}
