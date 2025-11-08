import '../jwt_api/woo_connect.dart';

class LoginCode {
  final WooConnect _woo = WooConnect();

  /// Normalizza un URL convertendo 127.0.0.1 in localhost
  /// Necessario per compatibilità con JWT token
  String _normalizeUrl(String url) {
    return url.replaceAll('127.0.0.1', 'localhost');
  }

  /// Tenta il login automatico utilizzando le credenziali salvate
  Future<bool> tryAutoLogin() => _woo.tryAutoConnect();

  /// Testa la connessione al server
  Future<bool> testConnection() => _woo.testConnection();

  /// Esegue il login con JWT
  Future<void> performLogin({
    required String siteUrl,
    required String username,
    required String password,
    String? customJwtEndpoint,
  }) async {
    // Normalizza l'URL prima del login
    final normalizedUrl = _normalizeUrl(siteUrl);

    await _woo.connectWithJwt(
      siteUrl: normalizedUrl,
      username: username,
      password: password,
      customEndpoint: customJwtEndpoint,
    );
  }

  /// Esegue il login con WooCommerce API (Consumer Key/Secret)
  Future<void> performApiLogin({
    required String siteUrl,
    required String consumerKey,
    required String consumerSecret,
  }) async {
    // Normalizza l'URL prima del login
    final normalizedUrl = _normalizeUrl(siteUrl);

    await _woo.connectWithApi(
      siteUrl: normalizedUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );
  }

  /// Disconnette l'utente
  Future<void> logout() => _woo.disconnect();

  /// Verifica se l'utente è attualmente connesso
  bool get isConnected => _woo.isAuthenticated;

  /// Ottiene l'URL del sito salvato in cache
  String? get cachedSiteUrl => _woo.siteUrl;
}

final loginCode = LoginCode();