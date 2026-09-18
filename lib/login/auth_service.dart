import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'jwt_api/jwt_connect.dart';
import 'jwt_api/query_mgws/mgws_availability.dart';
import 'wp_admin_api/wordpress_connect.dart';

/// Stati di autenticazione
enum AuthState {
  checking, // Verifica autenticazione in corso
  authenticated, // Utente autenticato
  notAuthenticated, // Utente non autenticato
}

/// Tipo di piattaforma e-commerce ammessa lato app.
enum PlatformType { woocommerce }

/// Interface per connettori di autenticazione
/// L'app autentica solo verso WooCommerce/MGWS nel perimetro WordPress ammesso.
abstract class AuthConnector {
  bool get isConnected;
  String? get currentSiteUrl;
  Future<bool> tryAutoConnect();
  Future<void> connect({
    required String siteUrl,
    required String username,
    required String password,
    String? customEndpoint,
  });
  Future<void> disconnect();
  Future<bool> refreshToken();
  Dio getAuthenticatedDio();
}

/// Servizio centralizzato per la gestione dell'autenticazione
/// Usa il connettore WordPress ammesso dall'app.
class AuthService extends ChangeNotifier {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthConnector? _activeConnector;
  AuthState _authState = AuthState.checking;
  PlatformType _currentPlatform = PlatformType.woocommerce;

  /// Stato corrente di autenticazione
  AuthState get authState => _authState;

  /// Piattaforma attualmente in uso
  PlatformType get currentPlatform => _currentPlatform;

  /// Verifica se l'utente è autenticato
  bool get isAuthenticated => _activeConnector?.isConnected ?? false;

  /// URL del sito corrente
  String? get currentSiteUrl => _activeConnector?.currentSiteUrl;

  /// Inizializza il connector per il tipo di autenticazione specificato.
  ///
  /// [authType] determina quale connector usare:
  /// - `jwt` o `woocommerceApi` → JwtConnect
  /// - `wordpress` → WordPressConnect (Basic Auth, no JWT)
  void _initializeConnector(PlatformType platform, {AuthType authType = AuthType.jwt}) {
    _currentPlatform = platform;
    if (authType == AuthType.wordpress) {
      _activeConnector = WordPressConnect();
    } else {
      _activeConnector = JwtConnect();
    }
  }

  /// Restituisce un'istanza Dio autenticata dal connector attivo.
  ///
  /// Usa AuthService per ottenere il Dio corretto in base al tipo di auth
  /// attivo (JWT Bearer o WordPress Basic Auth). Questo sostituisce
  /// le chiamate dirette a `JwtConnect().getAuthenticatedDio()`.
  Dio getAuthenticatedDio() {
    if (_activeConnector == null) {
      throw StateError('Nessun connector attivo. Chiamare checkAuthentication() prima.');
    }
    return _activeConnector!.getAuthenticatedDio();
  }

  /// Controlla lo stato di autenticazione all'avvio
  Future<void> checkAuthentication({PlatformType? platform}) async {
    _authState = AuthState.checking;
    mgwsAvailability.markUnavailable();
    notifyListeners();

    try {
      if (_activeConnector == null) {
        _initializeConnector(platform ?? PlatformType.woocommerce);
      }

      final bool isLoggedIn = await _activeConnector!.tryAutoConnect();
      if (isLoggedIn) {
        await mgwsAvailability.refresh();
      }
      _authState = isLoggedIn
          ? AuthState.authenticated
          : AuthState.notAuthenticated;
    } catch (e) {
      mgwsAvailability.markUnavailable();
      _authState = AuthState.notAuthenticated;
    }
    notifyListeners();
  }

  /// Esegue il login
  Future<void> login({
    required PlatformType platform,
    required String siteUrl,
    required String username,
    required String password,
    String? customEndpoint,
    AuthType authType = AuthType.jwt,
  }) async {
    _authState = AuthState.checking;
    mgwsAvailability.markUnavailable();
    notifyListeners();

    try {
      if (_activeConnector == null || _currentPlatform != platform) {
        _initializeConnector(platform, authType: authType);
      }

      await _activeConnector!.connect(
        siteUrl: siteUrl,
        username: username,
        password: password,
        customEndpoint: customEndpoint,
      );

      await mgwsAvailability.refresh();
      _authState = AuthState.authenticated;
    } catch (e) {
      mgwsAvailability.markUnavailable();
      _authState = AuthState.notAuthenticated;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Esegue il logout
  Future<void> logout() async {
    _authState = AuthState.checking;
    mgwsAvailability.markUnavailable();
    notifyListeners();

    try {
      if (_activeConnector != null) {
        await _activeConnector!.disconnect();
      }
    } catch (e) {
      // Ignora errori durante il logout
    }

    _authState = AuthState.notAuthenticated;
    notifyListeners();
  }

  /// Forza la ri-autenticazione (quando il token scade)
  void forceReauth() {
    mgwsAvailability.markUnavailable();
    _authState = AuthState.notAuthenticated;
    notifyListeners();
  }

  /// Refresh del token
  Future<bool> refreshToken() async {
    if (_activeConnector == null) {
      mgwsAvailability.markUnavailable();
      return false;
    }

    try {
      final success = await _activeConnector!.refreshToken();
      if (!success) {
        forceReauth();
      }
      return success;
    } catch (e) {
      forceReauth();
      return false;
    }
  }
}
