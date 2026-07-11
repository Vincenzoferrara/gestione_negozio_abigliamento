import 'package:dio/dio.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import 'package:gestione_negozio_abbigliamento/log_viewer/app_logger.dart';
import 'jwt_connect.dart';
import 'error_list.dart';

/// Classe singleton per gestire la connessione WooCommerce
///
/// COME USARE:
/// ```dart
/// // Ottieni l'istanza WooCommerce autenticata (usa SEMPRE questa!)
/// final woo = WooConnect().woo;
///
/// // Usa l'istanza per le query
/// final products = await woo.getProducts();
/// final orders = await woo.getOrders();
///
/// // Dopo logout, resetta l'istanza
/// WooConnect().reset();
/// ```
///
/// IMPORTANTE: NON creare nuove istanze WooCommerce manualmente!
/// Usa sempre WooConnect().woo per ottenere l'istanza autenticata.
class WooConnect {
  // Singleton pattern
  static final WooConnect _instance = WooConnect._internal();
  factory WooConnect() => _instance;
  WooConnect._internal();

  final JwtConnect _auth = JwtConnect();
  WooCommerce? _woo;
  bool _isJWT = true;
  String? _consumerKey;
  String? _consumerSecret;

  /// Ottiene l'istanza WooCommerce autenticata (JWT o API)
  ///
  /// Questa è l'UNICA istanza WooCommerce per tutta l'app.
  /// L'autenticazione avviene tramite JWT Bearer token o WooCommerce API.
  ///
  /// Throws [UnauthorizedException] se non autenticato
  WooCommerce get woo {
    log.d('🛒 WooConnect: Richiesta istanza WooCommerce');

    // Se già esiste un'istanza, riutilizzala
    if (_woo != null) {
      log.v('♻️ Riuso istanza WooCommerce esistente');
      return _woo!;
    }

    if (_isJWT) {
      // Autenticazione JWT
      if (!_auth.isConnected) {
        log.e('❌ Tentativo di accesso WooCommerce senza autenticazione JWT');
        throw UnauthorizedException();
      }

      log.d('🔧 Creazione nuova istanza WooCommerce con JWT per: ${_auth.currentSiteUrl}');

      // Crea WooCommerce con JWT Bearer token tramite interceptor
      _woo = WooCommerce(
        baseUrl: _auth.currentSiteUrl!,
        username: '', // Non usato - usiamo JWT
        password: '', // Non usato - usiamo JWT
        useFaker: false,
        isDebug: true,
        interceptors: [
          InterceptorsWrapper(
            onRequest: (options, handler) {
              // Sostituisci Basic Auth con JWT Bearer token
              final token = _auth.session?.token;
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
                log.v('🔑 JWT token aggiunto alla richiesta');
              }
              return handler.next(options);
            },
          ),
        ],
      );

      log.i('✅ WooCommerce inizializzato con JWT Bearer Token');
    } else {
      // Autenticazione WooCommerce API
      if (_consumerKey == null || _consumerSecret == null || _auth.currentSiteUrl == null) {
        log.e('❌ Tentativo di accesso WooCommerce senza credenziali API');
        throw UnauthorizedException();
      }

      log.d('🔧 Creazione nuova istanza WooCommerce con API per: ${_auth.currentSiteUrl}');

      // Crea WooCommerce con Consumer Key e Secret
      _woo = WooCommerce(
        baseUrl: _auth.currentSiteUrl!,
        username: _consumerKey!,
        password: _consumerSecret!,
        useFaker: false,
        isDebug: true,
        interceptors: [],
      );

      log.i('✅ WooCommerce inizializzato con Consumer Key/Secret');
    }

    return _woo!;
  }

  /// Verifica se la connessione è pronta
  bool get isReady => _isJWT ? _auth.isConnected : (_consumerKey != null && _consumerSecret != null);

  /// Ottiene l'URL del sito corrente
  String? get siteUrl => _auth.currentSiteUrl;

  /// Verifica se l'utente è autenticato
  bool get isAuthenticated => _isJWT ? _auth.isConnected : (_consumerKey != null && _consumerSecret != null);

  /// Connessione con JWT
  Future<void> connectWithJwt({
    required String siteUrl,
    required String username,
    required String password,
    String? customEndpoint,
  }) async {
    log.d('🔑 WooConnect: Connessione con JWT');
    _isJWT = true;
    _consumerKey = null;
    _consumerSecret = null;
    _woo = null;

    await _auth.connect(
      siteUrl: siteUrl,
      username: username,
      password: password,
      customEndpoint: customEndpoint,
    );

    log.i('✅ Connessione JWT completata');
  }

  /// Connessione con WooCommerce API
  Future<void> connectWithApi({
    required String siteUrl,
    required String consumerKey,
    required String consumerSecret,
  }) async {
    log.d('🔑 WooConnect: Connessione con API');
    _isJWT = false;
    _consumerKey = consumerKey;
    _consumerSecret = consumerSecret;
    _woo = null;

    // Salva l'URL del sito in _auth per compatibilità
    _auth.setSiteUrl(siteUrl);

    log.i('✅ Connessione API configurata');
  }

  /// Tenta la connessione automatica
  Future<bool> tryAutoConnect() async {
    // Per ora supporta solo JWT auto-connect
    if (_isJWT) {
      final success = await _auth.tryAutoConnect();
      if (success) {
        // Reset dell'istanza WooCommerce per forzare la ricreazione
        // con le credenziali appena caricate
        _woo = null;
        log.i('✅ Auto-connect riuscito, WooCommerce pronto per essere inizializzato');
      }
      return success;
    }
    return false;
  }

  /// Disconnessione
  Future<void> disconnect() async {
    log.d('🔄 WooConnect: Disconnessione');
    _woo = null;
    _isJWT = true;
    _consumerKey = null;
    _consumerSecret = null;
    await _auth.disconnect();
  }

  /// Reset della connessione (chiamalo dopo logout)
  void reset() {
    log.d('🔄 WooConnect: Reset istanza WooCommerce');
    _woo = null;
  }

  /// Test di connessione - verifica che WooCommerce risponda
  Future<bool> testConnection() async {
    try {
      log.d('🧪 WooConnect: Test connessione WooCommerce');

      // Verifica prima che siamo autenticati
      if (!isAuthenticated) {
        log.w('❌ Test connessione saltato: non autenticato');
        return false;
      }

      // Prova a fare una richiesta semplice (ottenere 1 prodotto)
      await woo.getProducts(perPage: 1, page: 1);

      log.i('✅ Test connessione WooCommerce riuscito');
      return true;
    } catch (e) {
      log.e('❌ Test connessione WooCommerce fallito', e);

      // Se la connessione fallisce, potrebbe essere che:
      // 1. Il server non è raggiungibile
      // 2. Il token è scaduto/non valido
      // 3. Le credenziali non sono più valide
      // In tutti questi casi, meglio disconnettere l'utente
      log.w('Disconnessione automatica dopo test fallito');
      await disconnect();

      return false;
    }
  }

}
