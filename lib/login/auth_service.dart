import 'package:flutter/foundation.dart';
import 'jwt_api/jwt_connect.dart';

/// Stati di autenticazione
enum AuthState {
  checking,        // Verifica autenticazione in corso
  authenticated,   // Utente autenticato
  notAuthenticated // Utente non autenticato
}

/// Tipo di piattaforma e-commerce
enum PlatformType {
  woocommerce,
  prestashop,
  shopify,
  // Aggiungi altre piattaforme qui
}

/// Interface per connettori di autenticazione
/// Permette di supportare diverse piattaforme: WooCommerce, PrestaShop, Shopify, etc.
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
}

/// Servizio centralizzato per la gestione dell'autenticazione
/// Supporta diverse piattaforme e-commerce tramite AuthConnector
class AuthService extends ChangeNotifier {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthConnector? _activeConnector;
  AuthState _authState = AuthState.checking;
  PlatformType _currentPlatform = PlatformType.woocommerce; // Default

  /// Stato corrente di autenticazione
  AuthState get authState => _authState;

  /// Piattaforma attualmente in uso
  PlatformType get currentPlatform => _currentPlatform;

  /// Verifica se l'utente è autenticato
  bool get isAuthenticated => _activeConnector?.isConnected ?? false;

  /// URL del sito corrente
  String? get currentSiteUrl => _activeConnector?.currentSiteUrl;

  /// Inizializza il connector per la piattaforma specificata
  void _initializeConnector(PlatformType platform) {
    switch (platform) {
      case PlatformType.woocommerce:
        _activeConnector = JwtConnect();
        break;
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop connector non ancora implementato');
      case PlatformType.shopify:
        throw UnimplementedError('Shopify connector non ancora implementato');
    }
    _currentPlatform = platform;
  }

  /// Controlla lo stato di autenticazione all'avvio
  Future<void> checkAuthentication({PlatformType? platform}) async {
    _authState = AuthState.checking;
    notifyListeners();

    try {
      if (_activeConnector == null) {
        _initializeConnector(platform ?? PlatformType.woocommerce);
      }

      final bool isLoggedIn = await _activeConnector!.tryAutoConnect();
      _authState = isLoggedIn ? AuthState.authenticated : AuthState.notAuthenticated;
    } catch (e) {
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
  }) async {
    _authState = AuthState.checking;
    notifyListeners();

    try {
      if (_activeConnector == null || _currentPlatform != platform) {
        _initializeConnector(platform);
      }

      await _activeConnector!.connect(
        siteUrl: siteUrl,
        username: username,
        password: password,
        customEndpoint: customEndpoint,
      );

      _authState = AuthState.authenticated;
    } catch (e) {
      _authState = AuthState.notAuthenticated;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Esegue il logout
  Future<void> logout() async {
    _authState = AuthState.checking;
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
    _authState = AuthState.notAuthenticated;
    notifyListeners();
  }

  /// Refresh del token
  Future<bool> refreshToken() async {
    if (_activeConnector == null) return false;

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
