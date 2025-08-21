import '../jwt_api/jwt_connect.dart';

class LoginCode {
  final JwtConnect _jwt = JwtConnect();
  
  /// Tenta il login automatico utilizzando le credenziali salvate
  Future<bool> tryAutoLogin() => _jwt.tryAutoConnect();

  /// Esegue solo il login senza test di prodotti
  Future<void> performLogin({
    required String siteUrl,
    required String username,
    required String password,
    String? customJwtEndpoint,
  }) async {
    await _jwt.connect(
      siteUrl: siteUrl,
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