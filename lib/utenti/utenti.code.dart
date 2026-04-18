import '../login/jwt_api/adapter/platform_manager.dart';
import '../log_viewer/app_logger.dart';

const bool _debugUtentiRawPayload = false;

/// Controller per la gestione degli utenti
class UtentiGestioneController {
  List<dynamic> utenti = [];
  bool isLoading = false;
  bool isSaving = false; // Per loading salvataggio
  String? errorMessage;

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

      // TODO: Implementa chiamata API per salvare capabilities
      // Es. POST /wp/v2/users/<id> con capabilities aggiornate

      // Placeholder: simula salvataggio
      await Future.delayed(Duration(seconds: 1));

      // Simula successo
      return true;
    } catch (e) {
      errorMessage = 'Errore nel salvataggio: $e';
      return false;
    } finally {
      isSaving = false;
    }
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
