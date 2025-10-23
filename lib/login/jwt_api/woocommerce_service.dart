// WooCommerce Service
//
// Classe centralizzata per gestire l'accesso a WooCommerce dopo autenticazione JWT
// Fornisce un'istanza WooCommerce autenticata e pronta all'uso

import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import 'package:gestione_negozio_abigliamento/log_viewer/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'jwt_connect.dart';
import 'error_list.dart';

/// Interceptor per convertire URL da formato standard a formato rest_route
class RestRouteInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Converti URL da /wp-json/wc/v3/... a /?rest_route=/wc/v3/...
    final uri = Uri.parse(options.uri.toString());

    // Se l'URL contiene /wp-json/, convertilo
    if (uri.path.contains('/wp-json/')) {
      final route = uri.path.replaceFirst('/wp-json/', '/');

      // Costruisci il nuovo URL con rest_route
      final newUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: '/',
        queryParameters: {
          'rest_route': route,
          ...uri.queryParameters,
        },
      );

      options.path = newUri.toString();
      log.v('🔄 URL convertito: ${uri.path} → ${newUri.toString()}');
    }

    super.onRequest(options, handler);
  }
}

/// Servizio centralizzato per accesso WooCommerce
class WooCommerceService {
  // Singleton
  static final WooCommerceService _instance = WooCommerceService._internal();
  factory WooCommerceService() => _instance;
  WooCommerceService._internal();

  final JwtConnect _auth = JwtConnect();
  WooCommerce? _wooInstance;

  /// Ottiene l'istanza WooCommerce autenticata con JWT
  ///
  /// Questa istanza è pronta all'uso con tutte le API WooCommerce
  /// L'autenticazione avviene tramite il token JWT di JwtConnect
  WooCommerce getWooCommerce() {
    log.d('🛒 Richiesta istanza WooCommerce...');

    if (!_auth.isConnected) {
      log.e('❌ Tentativo di accesso WooCommerce senza autenticazione JWT');
      throw UnauthorizedException();
    }

    // Se già esiste un'istanza, riutilizzala
    if (_wooInstance != null) {
      log.v('♻️ Riuso istanza WooCommerce esistente');
      return _wooInstance!;
    }

    log.d('🔧 Creazione nuova istanza WooCommerce per: ${_auth.currentSiteUrl}');

    // Crea nuova istanza WooCommerce con credenziali dummy
    // (verranno sovrascritte con JWT)
    _wooInstance = WooCommerce(
      baseUrl: _auth.currentSiteUrl!,
      username: 'jwt', // Dummy - verrà sovrascritto
      password: 'jwt', // Dummy - verrà sovrascritto
      useFaker: false,
      isDebug: true, // Abilita log di debug
    );

    // Crea un nuovo Dio con autenticazione JWT
    // IMPORTANTE: Non aggiungere /wp-json/wc/v3 qui perché il pacchetto lo aggiunge automaticamente
    final jwtDio = Dio(BaseOptions(
      baseUrl: _auth.currentSiteUrl!,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Authorization': 'Bearer ${_auth.session!.token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Aggiungi l'interceptor per convertire gli URL a formato rest_route
    jwtDio.interceptors.add(RestRouteInterceptor());

    // Aggiungi il logger se in debug mode (dopo l'interceptor URL così vedi l'URL convertito)
    if (_wooInstance!.isDebug) {
      jwtDio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ));
    }

    // Sostituisci il Dio con quello autenticato JWT
    _wooInstance!.dio = jwtDio;

    log.i('✅ Istanza WooCommerce creata e autenticata con JWT');
    return _wooInstance!;
  }

  /// Reset dell'istanza WooCommerce
  ///
  /// Utile dopo logout o quando si vuole forzare la ricreazione dell'istanza
  void reset() {
    log.d('🔄 Reset istanza WooCommerce');
    _wooInstance = null;
  }

  /// Verifica se il servizio è disponibile e autenticato
  bool get isReady => _auth.isConnected;

  /// Ottiene l'URL del sito WooCommerce corrente
  String? get siteUrl => _auth.currentSiteUrl;

  /// Test di connessione - verifica che WooCommerce risponda
  Future<bool> testConnection() async {
    try {
      log.d('🧪 Test connessione WooCommerce...');
      final woo = getWooCommerce();

      // Prova a fare una richiesta semplice (es. ottenere 1 prodotto)
      await woo.getProducts(perPage: 1, page: 1);

      log.i('✅ Test connessione WooCommerce riuscito');
      return true;
    } catch (e) {
      log.e('❌ Test connessione WooCommerce fallito', e);
      return false;
    }
  }

  /// Ottiene informazioni di sistema WooCommerce
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      log.d('ℹ️ Recupero informazioni sistema WooCommerce...');
      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/system_status',
      );

      log.i('✅ Informazioni sistema recuperate');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      log.e('❌ Errore recupero informazioni sistema', e);
      rethrow;
    }
  }
}
