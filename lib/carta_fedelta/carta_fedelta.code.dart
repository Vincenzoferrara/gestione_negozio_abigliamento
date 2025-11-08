import '../login/jwt_api/adapter/platform_manager.dart';
import '../log_viewer/app_logger.dart';

/// Controller per la gestione delle carte fedeltà
class CartaFedeltaController {
  // Usa PlatformManager per accedere alle query
  dynamic get _cartaFedeltaQuery => PlatformManager.cartaFedelta;

  final log = AppLogger();

  // Stato
  List<Map<String, dynamic>> _clientiConCarta = [];
  Map<String, dynamic>? _cartaSelezionata;
  Map<String, dynamic>? _statistiche;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Getters
  List<Map<String, dynamic>> get clientiConCarta => _clientiFiltrati;
  Map<String, dynamic>? get cartaSelezionata => _cartaSelezionata;
  Map<String, dynamic>? get statistiche => _statistiche;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCartaSelezionata => _cartaSelezionata != null;
  String get searchQuery => _searchQuery;

  /// Carica tutti i clienti con carta fedeltà
  Future<void> caricaClientiConCarta() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      log.i('Caricamento clienti con carta fedeltà...');

      // Ottieni tutti i clienti
      final clienti = await PlatformManager.clienti.getAllCustomers();
      _clientiConCarta = [];

      // Filtra solo clienti con carta fedeltà
      for (var cliente in clienti) {
        if (cliente.id != null) {
          final carta = await _cartaFedeltaQuery.getCustomerLoyaltyCard(cliente.id);

          if (carta != null) {
            _clientiConCarta.add(carta);
          }
        }
      }

      log.i('Caricati ${_clientiConCarta.length} clienti con carta fedeltà');
    } catch (e) {
      log.e('Errore nel caricamento clienti con carta: $e');
      _errorMessage = 'Errore nel caricamento: $e';
      _clientiConCarta = [];
    } finally {
      _isLoading = false;
    }
  }

  /// Filtra i clienti in base alla ricerca
  List<Map<String, dynamic>> get _clientiFiltrati {
    if (_searchQuery.isEmpty) return _clientiConCarta;

    return _clientiConCarta.where((carta) {
      final query = _searchQuery.toLowerCase();

      final cardNumber = carta['card_number']?.toString().toLowerCase() ?? '';
      final firstName = carta['first_name']?.toString().toLowerCase() ?? '';
      final lastName = carta['last_name']?.toString().toLowerCase() ?? '';
      final email = carta['email']?.toString().toLowerCase() ?? '';

      return cardNumber.contains(query) ||
             firstName.contains(query) ||
             lastName.contains(query) ||
             email.contains(query);
    }).toList();
  }

  /// Cerca una carta per numero
  Future<Map<String, dynamic>?> cercaCartaPerNumero(String numeroCarta) async {
    try {
      log.i('Ricerca carta numero: $numeroCarta');

      final carta = await _cartaFedeltaQuery.findCustomerByCardNumber(numeroCarta);

      if (carta != null) {
        log.i('Carta trovata per cliente #${carta['customer_id']}');
        return carta;
      }

      log.w('Nessuna carta trovata con numero: $numeroCarta');
      return null;
    } catch (e) {
      log.e('Errore nella ricerca carta: $e');
      return null;
    }
  }

  /// Seleziona una carta
  void selezionaCarta(Map<String, dynamic> carta) {
    _cartaSelezionata = carta;
    log.d('Carta selezionata: ${carta['card_number']}');
  }

  /// Deseleziona la carta corrente
  void deselezionaCarta() {
    _cartaSelezionata = null;
  }

  /// Imposta la query di ricerca
  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  /// Cancella i filtri
  void cancellaFiltri() {
    _searchQuery = '';
  }

  /// Ottiene i punti di un cliente
  Future<int> getPuntiCliente(int customerId) async {
    try {
      return await _cartaFedeltaQuery.getCustomerPoints(customerId);
    } catch (e) {
      log.e('Errore nel recupero punti: $e');
      return 0;
    }
  }

  /// Aggiunge punti a un cliente
  Future<bool> aggiungiPunti({
    required int customerId,
    required int punti,
    String? note,
  }) async {
    try {
      log.i('Aggiunta $punti punti a cliente #$customerId');

      final success = await _cartaFedeltaQuery.addPointsToCustomer(
        customerId: customerId,
        points: punti,
        reference: 'manual_add',
        note: note ?? 'Punti aggiunti manualmente',
      );

      if (success) {
        log.i('Punti aggiunti con successo');

        // Aggiorna la carta selezionata se è quella del cliente
        if (_cartaSelezionata != null &&
            _cartaSelezionata!['customer_id'] == customerId) {
          final nuoviPunti = await getPuntiCliente(customerId);
          _cartaSelezionata!['points'] = nuoviPunti;
        }

        // Ricarica la lista
        await caricaClientiConCarta();
      }

      return success;
    } catch (e) {
      log.e('Errore nell\'aggiunta punti: $e');
      return false;
    }
  }

  /// Sottrae punti da un cliente
  Future<bool> sottraiPunti({
    required int customerId,
    required int punti,
    String? note,
  }) async {
    try {
      log.i('Sottrazione $punti punti da cliente #$customerId');

      final success = await _cartaFedeltaQuery.deductPointsFromCustomer(
        customerId: customerId,
        points: punti,
        reference: 'manual_deduct',
        note: note ?? 'Punti sottratti manualmente',
      );

      if (success) {
        log.i('Punti sottratti con successo');

        // Aggiorna la carta selezionata
        if (_cartaSelezionata != null &&
            _cartaSelezionata!['customer_id'] == customerId) {
          final nuoviPunti = await getPuntiCliente(customerId);
          _cartaSelezionata!['points'] = nuoviPunti;
        }

        // Ricarica la lista
        await caricaClientiConCarta();
      }

      return success;
    } catch (e) {
      log.e('Errore nella sottrazione punti: $e');
      return false;
    }
  }

  /// Crea una nuova carta fedeltà per un cliente
  Future<bool> creaCarta({
    required int customerId,
    required String numeroCarta,
    String tier = 'bronze',
  }) async {
    try {
      log.i('Creazione carta fedeltà per cliente #$customerId');

      // Verifica che il numero carta non sia già usato
      final cartaEsistente = await cercaCartaPerNumero(numeroCarta);
      if (cartaEsistente != null) {
        _errorMessage = 'Numero carta già in uso';
        log.w('Numero carta $numeroCarta già in uso');
        return false;
      }

      final success = await _cartaFedeltaQuery.createOrUpdateLoyaltyCard(
        customerId: customerId,
        cardNumber: numeroCarta,
        tier: tier,
      );

      if (success) {
        log.i('Carta fedeltà creata con successo');
        await caricaClientiConCarta();
      }

      return success;
    } catch (e) {
      log.e('Errore nella creazione carta: $e');
      _errorMessage = 'Errore nella creazione: $e';
      return false;
    }
  }

  /// Aggiorna il tier di una carta
  Future<bool> aggiornaTier({
    required int customerId,
    required String numeroCarta,
    required String nuovoTier,
  }) async {
    try {
      log.i('Aggiornamento tier per cliente #$customerId a $nuovoTier');

      final success = await _cartaFedeltaQuery.createOrUpdateLoyaltyCard(
        customerId: customerId,
        cardNumber: numeroCarta,
        tier: nuovoTier,
      );

      if (success) {
        log.i('Tier aggiornato con successo');

        // Aggiorna la carta selezionata
        if (_cartaSelezionata != null &&
            _cartaSelezionata!['customer_id'] == customerId) {
          _cartaSelezionata!['tier'] = nuovoTier;
        }

        await caricaClientiConCarta();
      }

      return success;
    } catch (e) {
      log.e('Errore nell\'aggiornamento tier: $e');
      return false;
    }
  }

  /// Rimuove una carta fedeltà
  Future<bool> rimuoviCarta(int customerId) async {
    try {
      log.i('Rimozione carta fedeltà da cliente #$customerId');

      final success = await _cartaFedeltaQuery.removeLoyaltyCard(customerId);

      if (success) {
        log.i('Carta rimossa con successo');

        // Deseleziona se era selezionata
        if (_cartaSelezionata != null &&
            _cartaSelezionata!['customer_id'] == customerId) {
          deselezionaCarta();
        }

        await caricaClientiConCarta();
      }

      return success;
    } catch (e) {
      log.e('Errore nella rimozione carta: $e');
      return false;
    }
  }

  /// Ottiene lo storico punti di un cliente
  Future<List<Map<String, dynamic>>> getStoricoPunti(int customerId) async {
    try {
      return await _cartaFedeltaQuery.getPointsHistory(customerId);
    } catch (e) {
      log.e('Errore nel recupero storico: $e');
      return [];
    }
  }

  /// Carica le statistiche del programma fedeltà
  Future<void> caricaStatistiche() async {
    try {
      log.i('Caricamento statistiche programma fedeltà...');

      _statistiche = await _cartaFedeltaQuery.getLoyaltyStats();

      log.i('Statistiche caricate con successo');
    } catch (e) {
      log.e('Errore nel caricamento statistiche: $e');
      _statistiche = null;
    }
  }

  /// Verifica disponibilità myCred
  Future<bool> verificaMycredDisponibile() async {
    try {
      return await _cartaFedeltaQuery.isMycredAvailable();
    } catch (e) {
      log.e('Errore nella verifica myCred: $e');
      return false;
    }
  }

  /// Genera un numero carta casuale
  String generaNumeroCarta() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'CF${timestamp.toString().substring(timestamp.toString().length - 8)}$random';
  }

  /// Ottiene il colore per tier
  String getColoreTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return '#E5E4E2'; // Platino
      case 'gold':
        return '#FFD700'; // Oro
      case 'silver':
        return '#C0C0C0'; // Argento
      case 'bronze':
      default:
        return '#CD7F32'; // Bronzo
    }
  }

  /// Ottiene il nome visualizzabile del tier
  String getNomeTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return 'Platino';
      case 'gold':
        return 'Oro';
      case 'silver':
        return 'Argento';
      case 'bronze':
      default:
        return 'Bronzo';
    }
  }

  /// Calcola il tier in base ai punti
  String calcolaTierDaPunti(int punti) {
    if (punti >= 1000) return 'platinum';
    if (punti >= 500) return 'gold';
    if (punti >= 250) return 'silver';
    return 'bronze';
  }
}
