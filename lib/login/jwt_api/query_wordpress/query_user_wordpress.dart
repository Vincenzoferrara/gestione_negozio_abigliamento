import '../jwt_connect.dart';
import '../query_mgws/mgws_availability.dart';
import '../../../log_viewer/app_logger.dart';

/// Query class per utenti gestiti via MGWS.
class QueryUserWordPress {
  // Singleton pattern
  static final QueryUserWordPress _instance = QueryUserWordPress._internal();
  factory QueryUserWordPress() => _instance;
  QueryUserWordPress._internal();

  /// Inizializza la connessione MGWS/Woo già autenticata.
  Future<void> _initialize() async {
    final jwtConnect = JwtConnect();
    if ((jwtConnect.currentSiteUrl ?? '').isEmpty) {
      await jwtConnect.tryAutoConnect();
    }
  }

  /// Ottiene lista utenti tramite MGWS con paginazione e filtri.
  Future<List<dynamic>> getUtenti({
    int page = 1,
    int perPage = 20,
    String? search,
    String? role,
    String? orderBy = 'registered_date',
    String order = 'desc',
  }) async {
    try {
      if (!await mgwsAvailability.refresh()) {
        log.w('Servizio utenti MGWS non disponibile');
        return const <dynamic>[];
      }

      log.d(
        'Caricamento utenti MGWS: page=$page, perPage=$perPage, search=$search, role=$role',
      );

      await _initialize();

      final jwtConnect = JwtConnect();
      final baseUrl = jwtConnect.currentSiteUrl ?? '';

      if (baseUrl.isEmpty) {
        throw Exception('Nessun URL del sito configurato');
      }

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

      final response = await _authorizedGet(
        '/wp-json/mgws/v1/users',
        queryParameters: params,
      );

      log.d(
        'Risposta HTTP: ${response.statusCode} - ${response.statusMessage}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = response.data;
        log.d('Caricati ${usersData.length} utenti da MGWS');

        return usersData;
      } else if (response.statusCode == 404) {
        log.e('Endpoint /wp-json/mgws/v1/users non trovato su $baseUrl');
        throw Exception(
          'Endpoint MGWS utenti non trovato. Verifica che il plugin sia attivo.',
        );
      } else if (response.statusCode == 401) {
        log.e('Non autorizzato ad accedere agli utenti');
        throw Exception(
          'Non autorizzato. Verifica che l\'autenticazione MGWS sia valida.',
        );
      } else if (response.statusCode == 403) {
        log.w('Accesso negato agli utenti tramite MGWS');
        throw Exception(
          'Accesso negato. L\'utente non ha permessi sufficienti.',
        );
      }

      log.e(
        'Errore HTTP non gestito: ${response.statusCode} - ${response.statusMessage}',
      );
      throw Exception(
        'Errore HTTP ${response.statusCode}: ${response.statusMessage}',
      );
    } catch (e, stackTrace) {
      log.e('Errore nel caricamento utenti WordPress', e, stackTrace);
      throw Exception('Errore nel caricamento utenti MGWS: $e');
    }
  }

  /// Verifica disponibilità del servizio
  Future<bool> isServiceAvailable() async {
    return await mgwsAvailability.refresh();
  }

  Future<Map<String, dynamic>> getUserPermissions(int userId) async {
    final endpoint = '/wp-json/mgws/v1/users/$userId/permissions';
    final response = await _authorizedGet(endpoint);
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Impossibile leggere permessi utente');
  }

  Future<Map<String, dynamic>> updateUserPermissions({
    required int userId,
    List<String>? roles,
    Map<String, bool>? capabilities,
  }) async {
    final endpoint = '/wp-json/mgws/v1/users/$userId/permissions';
    final payload = <String, dynamic>{
      if (roles != null) 'roles': roles,
      if (capabilities != null) 'capabilities': capabilities,
    };

    if (payload.isEmpty) {
      throw Exception('Nessuna modifica da salvare');
    }

    final response = await _authorizedPatch(endpoint, payload);
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Impossibile aggiornare permessi utente');
  }

  Future<Map<String, dynamic>> createApplicationPassword({
    required int userId,
    required String name,
  }) async {
    final endpoint = '/wp-json/mgws/v1/users/$userId/app-passwords';
    final response = await _authorizedPost(endpoint, {'name': name.trim()});
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Impossibile generare app password');
  }

  Future<Map<String, dynamic>> listApplicationPasswords(int userId) async {
    final endpoint = '/wp-json/mgws/v1/users/$userId/app-passwords';
    final response = await _authorizedGet(endpoint);
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Impossibile caricare app password');
  }

  Future<void> deleteApplicationPassword({
    required int userId,
    required String uuid,
  }) async {
    final endpoint = '/wp-json/mgws/v1/users/$userId/app-passwords/$uuid';
    final response = await _authorizedDelete(endpoint);
    if (response.statusCode != 200) {
      throw Exception('Impossibile revocare app password');
    }
  }

  Future<Map<String, dynamic>> createWooApiKey({
    required int userId,
    required String description,
    String permissions = 'read_write',
  }) async {
    final endpoint = '/wp-json/mgws/v1/users/$userId/woo-keys';
    final response = await _authorizedPost(endpoint, {
      'description': description.trim(),
      'permissions': permissions,
    });
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Impossibile generare chiave WooCommerce');
  }

  Future<Map<String, dynamic>> listWooApiKeys(int userId) async {
    final endpoint = '/wp-json/mgws/v1/users/$userId/woo-keys';
    final response = await _authorizedGet(endpoint);
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Impossibile caricare chiavi WooCommerce');
  }

  Future<void> deleteWooApiKey({
    required int userId,
    required int keyId,
  }) async {
    final endpoint = '/wp-json/mgws/v1/users/$userId/woo-keys/$keyId';
    final response = await _authorizedDelete(endpoint);
    if (response.statusCode != 200) {
      throw Exception('Impossibile revocare chiave WooCommerce');
    }
  }

  Future<dynamic> _authorizedGet(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _authorizedGetWithQuery(endpoint, queryParameters: queryParameters);
  }

  Future<dynamic> _authorizedGetWithQuery(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureMgwsAvailable();
    final jwtConnect = JwtConnect();
    final baseUrl = await _ensureBaseUrl(jwtConnect);
    final dio = jwtConnect.getAuthenticatedDio();
    return dio.get('$baseUrl$endpoint', queryParameters: queryParameters);
  }

  Future<dynamic> _authorizedPatch(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    await _ensureMgwsAvailable();
    final jwtConnect = JwtConnect();
    final baseUrl = await _ensureBaseUrl(jwtConnect);
    final dio = jwtConnect.getAuthenticatedDio();
    return await dio.patch('$baseUrl$endpoint', data: payload);
  }

  Future<dynamic> _authorizedPost(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    await _ensureMgwsAvailable();
    final jwtConnect = JwtConnect();
    final baseUrl = await _ensureBaseUrl(jwtConnect);
    final dio = jwtConnect.getAuthenticatedDio();
    return await dio.post('$baseUrl$endpoint', data: payload);
  }

  Future<dynamic> _authorizedDelete(String endpoint) async {
    await _ensureMgwsAvailable();
    final jwtConnect = JwtConnect();
    final baseUrl = await _ensureBaseUrl(jwtConnect);
    final dio = jwtConnect.getAuthenticatedDio();
    return await dio.delete('$baseUrl$endpoint');
  }

  Future<String> _ensureBaseUrl(JwtConnect jwtConnect) async {
    String baseUrl = jwtConnect.currentSiteUrl ?? '';
    if (baseUrl.isEmpty) {
      await jwtConnect.tryAutoConnect();
      baseUrl = jwtConnect.currentSiteUrl ?? '';
    }
    if (baseUrl.isEmpty) {
      throw Exception('Nessun sito connesso');
    }
    return baseUrl;
  }

  Future<void> _ensureMgwsAvailable() async {
    if (!await mgwsAvailability.refresh()) {
      throw StateError('Backend MGWS non disponibile');
    }
  }
}
