import '../login/jwt_api/adapter/platform_manager.dart';
import '../login/jwt_api/query_wordpress/query_user_wordpress.dart';
import '../log_viewer/app_logger.dart';

const bool _debugUtentiRawPayload = false;

/// Controller per la gestione degli utenti
class UtentiGestioneController {
  static const Set<String> capabilityWhitelist = {
    'read',
    'mgws_stock_read',
    'mgws_stock_move',
    'mgws_order_accept',
  };

  List<dynamic> utenti = [];
  bool isLoading = false;
  bool isSaving = false; // Per loading salvataggio
  String? errorMessage;
  final QueryUserWordPress _userApi = QueryUserWordPress();

  /// Carica la lista utenti dalla piattaforma corrente
  Future<void> caricaUtenti() async {
    try {
      isLoading = true;
      errorMessage = null;

      // Usa PlatformManager per determinare la piattaforma e chiamare la query appropriata
      final queryUtenti = PlatformManager.utenti;

      // Chiama getUtenti per ottenere la lista
      final utentiData = await queryUtenti.getUtenti();

      // Usa dati grezzi
      utenti = utentiData;

      log.d('Utenti ricevuti: ${utentiData.length}');
      if (_debugUtentiRawPayload) {
        // Evita di loggare email/password o payload troppo grande: stampa solo campi chiave.
        for (final utente in utentiData) {
          if (utente is Map<String, dynamic>) {
            log.d(
              'Utente ${utente['id']}: roles=${utente['roles']} capabilities_keys=${(utente['capabilities'] is Map) ? (utente['capabilities'] as Map).keys.toList() : null}',
            );
          }
        }
      }
    } catch (e) {
      errorMessage = 'Errore nel caricamento utenti: $e';
    } finally {
      isLoading = false;
    }
  }

  /// Salva modifiche capabilities per un utente
  Future<bool> salvaCapabilities(
    dynamic utente,
    Map<String, bool> modifiche,
  ) async {
    try {
      isSaving = true;
      errorMessage = null;

      if (utente is! Map<String, dynamic>) {
        throw Exception('Utente non valido');
      }
      final userId = (utente['id'] is int)
          ? (utente['id'] as int)
          : int.tryParse(utente['id']?.toString() ?? '');
      if (userId == null || userId <= 0) {
        throw Exception('ID utente non valido');
      }

      final filtered = <String, bool>{};
      modifiche.forEach((key, value) {
        if (capabilityWhitelist.contains(key)) {
          filtered[key] = value;
        }
      });
      if (filtered.isEmpty) {
        throw Exception('Nessuna capability modificabile nella whitelist');
      }

      final updated = await _userApi.updateUserPermissions(
        userId: userId,
        capabilities: filtered,
      );
      _mergeUserUpdate(userId, updated);

      return true;
    } catch (e) {
      errorMessage = 'Errore nel salvataggio: $e';
      return false;
    } finally {
      isSaving = false;
    }
  }

  Future<Map<String, dynamic>> generaAppPassword({
    required int userId,
    required String name,
  }) {
    return _userApi.createApplicationPassword(userId: userId, name: name);
  }

  Future<Map<String, dynamic>> generaWooApiKey({
    required int userId,
    required String description,
    String permissions = 'read_write',
  }) {
    return _userApi.createWooApiKey(
      userId: userId,
      description: description,
      permissions: permissions,
    );
  }

  Future<Map<String, dynamic>> caricaPermessiUtente(int userId) {
    return _userApi.getUserPermissions(userId);
  }

  Future<bool> salvaRuoliUtente({
    required int userId,
    required List<String> roles,
  }) async {
    try {
      isSaving = true;
      errorMessage = null;
      if (roles.isEmpty) {
        throw Exception('Seleziona almeno un ruolo');
      }
      final updated = await _userApi.updateUserPermissions(
        userId: userId,
        roles: roles,
      );
      _mergeUserUpdate(userId, updated);
      return true;
    } catch (e) {
      errorMessage = 'Errore nel salvataggio ruoli: $e';
      return false;
    } finally {
      isSaving = false;
    }
  }

  Future<List<Map<String, dynamic>>> listaAppPassword(int userId) async {
    final resp = await _userApi.listApplicationPasswords(userId);
    final raw = resp['items'];
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> revocaAppPassword({required int userId, required String uuid}) {
    return _userApi.deleteApplicationPassword(userId: userId, uuid: uuid);
  }

  Future<List<Map<String, dynamic>>> listaWooApiKeys(int userId) async {
    final resp = await _userApi.listWooApiKeys(userId);
    final raw = resp['items'];
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> revocaWooApiKey({required int userId, required int keyId}) {
    return _userApi.deleteWooApiKey(userId: userId, keyId: keyId);
  }

  void _mergeUserUpdate(int userId, Map<String, dynamic> updated) {
    final idx = utenti.indexWhere((u) {
      if (u is! Map<String, dynamic>) return false;
      return (u['id']?.toString() ?? '') == userId.toString();
    });
    if (idx < 0 || utenti[idx] is! Map<String, dynamic>) {
      return;
    }

    final current = Map<String, dynamic>.from(
      utenti[idx] as Map<String, dynamic>,
    );
    if (updated['capabilities'] is Map) {
      current['capabilities'] = Map<String, dynamic>.from(
        updated['capabilities'] as Map,
      );
    }
    if (updated['roles'] is List) {
      current['roles'] = List<String>.from(updated['roles'] as List);
    }
    utenti[idx] = current;
  }

  /// Filtra utenti in base alla query di ricerca
  void setSearchQuery(String query) {
    // Per ora, semplice filtro locale
    // In futuro, può essere implementato filtro server-side
  }

  /// Seleziona un utente
  void selezionaUtente(dynamic utente) {
    // Logica per selezione, se necessaria
  }

  /// Verifica se un utente è selezionato
  bool isUtenteSelezionato(dynamic utente) {
    // Implementazione se necessaria
    return false;
  }

  /// Seleziona un utente
  /* void selezionaUtente(Utente utente) {
    // Logica per selezione, se necessaria
  }

  /// Verifica se un utente è selezionato
  bool isUtenteSelezionato(Utente utente) {
    // Implementazione se necessaria
    return false;
  } */
}
