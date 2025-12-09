import 'package:wordpress_client/wordpress_client.dart';
import '../jwt_connect.dart';
import '../../../log_viewer/app_logger.dart';

/// Query class per utenti WordPress con App Password
class QueryUserWordPress {
  // Singleton pattern
  static final QueryUserWordPress _instance = QueryUserWordPress._internal();
  factory QueryUserWordPress() => _instance;
  QueryUserWordPress._internal();

  WordpressClient? _client;

  /// Inizializza il client WordPress API con Basic JWT
  Future<void> _initialize() async {
    if (_client != null) return; // Already initialized

    final jwtConnect = JwtConnect();

    // Usa l'URL del sito corrente o prova a caricarlo dalla sessione
    String baseUrl = jwtConnect.currentSiteUrl ?? '';
    if (baseUrl.isEmpty) {
      // Prova a caricare la sessione salvata
      await jwtConnect.tryAutoConnect();
      baseUrl = jwtConnect.currentSiteUrl ?? '';
    }

    if (baseUrl.isNotEmpty) {
      final baseUri = Uri.parse('$baseUrl/wp-json/wp/v2');
      _client = WordpressClient(
        baseUrl: baseUri,
        bootstrapper: (bootstrapper) => bootstrapper
            .withStatisticDelegate((baseUrl, requestCount) {
              // Statistic delegate
            })
            .withDebugMode(true)
            .withDefaultAuthorization(
              WordpressAuth.basicJwt(
                user: 'testuser',
                password: 'testpassword',
              ), // Sostituisci con valori reali
            )
            .build(),
      );
      log.d('WordpressClient inizializzato con URL: $baseUrl');
    }
  }

  /// Ottiene lista utenti WordPress con paginazione e filtri
  Future<List<dynamic>> getUtenti({
    int page = 1,
    int perPage = 20,
    String? search,
    String? role,
    String? orderBy = 'registered_date',
    String order = 'desc',
  }) async {
    try {
      log.d(
        'Caricamento utenti WordPress: page=$page, perPage=$perPage, search=$search, role=$role',
      );

      await _initialize();

      if (_client == null) {
        throw Exception('Client non inizializzato');
      }

      // Usa wordpress_client per users (assumendo supporto)
      // Nota: wordpress_client potrebbe non avere users nativo, fallback a Dio se necessario
      final jwtConnect = JwtConnect();
      final baseUrl = jwtConnect.currentSiteUrl ?? '';

      if (baseUrl.isEmpty) {
        throw Exception('Nessun URL del sito configurato');
      }

      // Per ora, usa Dio con wordpress_client per auth (se supportato)
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'orderby': orderBy,
        'order': order,
        'context': 'edit', // Per includere capabilities e roles
      };

      if (search != null) params['search'] = search;
      if (role != null) params['role'] = role;

      log.d('Parametri richiesta: $params');

      // Usa Dio per la chiamata diretta, poiché wordpress_client potrebbe non avere users
      final dio = jwtConnect.getAuthenticatedDio();

      final response = await dio.get(
        '$baseUrl/wp-json/wp/v2/users',
        queryParameters: params,
      );

      log.d(
        'Risposta HTTP: ${response.statusCode} - ${response.statusMessage}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = response.data;
        log.d('Caricati ${usersData.length} utenti da WordPress');

        return usersData;
      } else if (response.statusCode == 404) {
        log.e('Endpoint /wp-json/wp/v2/users non trovato su $baseUrl');
        throw Exception(
          'Endpoint /wp-json/wp/v2/users non trovato. Verifica che WordPress REST API sia attiva.',
        );
      } else if (response.statusCode == 401) {
        log.e('Non autorizzato ad accedere agli utenti');
        throw Exception(
          'Non autorizzato. Verifica che l\'app password sia valida.',
        );
      } else if (response.statusCode == 403) {
        log.w('Accesso negato con context=edit, riprovo con context=view');
        // Riprova con context=view se edit fallisce per permessi
        final fallbackParams = Map<String, dynamic>.from(params);
        fallbackParams['context'] = 'view';

        final fallbackResponse = await dio.get(
          '$baseUrl/wp-json/wp/v2/users',
          queryParameters: fallbackParams,
        );

        if (fallbackResponse.statusCode == 200) {
          final List<dynamic> usersData = fallbackResponse.data;
          log.d('Caricati ${usersData.length} utenti con context=view');
          return usersData;
        } else {
          log.e('Accesso negato anche con context=view');
          throw Exception(
            'Accesso negato. L\'utente non ha permessi sufficienti.',
          );
        }
      }

      log.e(
        'Errore HTTP non gestito: ${response.statusCode} - ${response.statusMessage}',
      );
      throw Exception(
        'Errore HTTP ${response.statusCode}: ${response.statusMessage}',
      );
    } catch (e, stackTrace) {
      log.e('Errore nel caricamento utenti WordPress', e, stackTrace);
      throw Exception('Errore nel caricamento utenti WordPress: $e');
    }
  }

  /// Verifica disponibilità del servizio
  Future<bool> isServiceAvailable() async {
    try {
      await _initialize();
      final jwtConnect = JwtConnect();
      return jwtConnect.isConnected;
    } catch (e) {
      return false;
    }
  }
}
