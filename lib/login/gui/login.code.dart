import '../jwt_api/jwt_connect.dart';

class LoginCode {
  final JwtConnect _jwt = JwtConnect();

  /// Normalizza un URL convertendo 127.0.0.1 in localhost
  /// Necessario per compatibilità con JWT token
  String _normalizeUrl(String url) {
    return url.replaceAll('127.0.0.1', 'localhost');
  }

  /// Tenta il login automatico utilizzando le credenziali salvate
  Future<bool> tryAutoLogin() => _jwt.tryAutoConnect();

  /// Esegue solo il login senza test di prodotti
  Future<void> performLogin({
    required String siteUrl,
    required String username,
    required String password,
    String? customJwtEndpoint,
  }) async {
    // Normalizza l'URL prima del login
    final normalizedUrl = _normalizeUrl(siteUrl);

    await _jwt.connect(
      siteUrl: normalizedUrl,
      username: username,
      password: password,
      customEndpoint: customJwtEndpoint,
    );
  }

  /// Disconnette l'utente
  Future<void> logout() => _jwt.disconnect();
  
  /// Verifica se l'utente è attualmente connesso
  bool get isConnected => _jwt.isConnected;
  
  /// Ottiene l'URL del sito salvato in cache
  String? get cachedSiteUrl => _jwt.currentSiteUrl;
}

final loginCode = LoginCode();