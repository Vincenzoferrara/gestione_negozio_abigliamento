import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../woo_connect.dart';
import '../../../log_viewer/app_logger.dart';

/// Query class per la gestione delle carte fedeltà con myCred
/// Utilizza WooConnect per l'autenticazione centralizzata
class WooQueryMycredCartaFedelta {
  // Singleton pattern
  static final WooQueryMycredCartaFedelta _instance = WooQueryMycredCartaFedelta._internal();
  factory WooQueryMycredCartaFedelta() => _instance;
  WooQueryMycredCartaFedelta._internal();

  final WooConnect _wooConnect = WooConnect();
  final log = AppLogger();

  /// Getter per ottenere l'istanza Dio con autenticazione
  get _dio => _wooConnect.woo.dio;

  // =======================================================
  // == GESTIONE PUNTI CLIENTE                           ==
  // =======================================================

  /// Ottiene il saldo punti di un cliente
  Future<int> getCustomerPoints(int customerId) async {
    try {
      log.i('Recupero punti per cliente #$customerId');

      // Chiamata API myCred per ottenere il saldo punti
      // myCred salva i punti nei metadata del cliente
      final response = await _dio.get('/customers/$customerId');
      final customerData = response.data as Map<String, dynamic>;

      // Cerca nei metadata il saldo punti myCred
      final metaData = customerData['meta_data'] as List<dynamic>? ?? [];

      for (var meta in metaData) {
        if (meta['key'] == 'mycred_default') {
          final points = int.tryParse(meta['value']?.toString() ?? '0') ?? 0;
          log.d('Cliente #$customerId ha $points punti');
          return points;
        }
      }

      log.d('Cliente #$customerId non ha punti myCred');
      return 0;
    } catch (e) {
      log.e('Errore nel recupero punti cliente #$customerId: $e');
      return 0;
    }
  }

  /// Aggiunge punti a un cliente
  Future<bool> addPointsToCustomer({
    required int customerId,
    required int points,
    String? reference,
    String? note,
  }) async {
    try {
      log.i('Aggiunta $points punti a cliente #$customerId');

      // myCred REST API endpoint per aggiungere punti
      // Nota: questo richiede il plugin myCred REST API attivo
      final response = await _dio.post(
        '/mycred/v1/add-points',
        data: {
          'user_id': customerId,
          'amount': points,
          'reference': reference ?? 'manual_add',
          'entry': note ?? 'Punti aggiunti manualmente',
        },
      );

      if (response.statusCode == 200) {
        log.i('Punti aggiunti con successo a cliente #$customerId');
        return true;
      }

      return false;
    } catch (e) {
      log.e('Errore nell\'aggiunta punti a cliente #$customerId: $e');
      return false;
    }
  }

  /// Sottrae punti da un cliente
  Future<bool> deductPointsFromCustomer({
    required int customerId,
    required int points,
    String? reference,
    String? note,
  }) async {
    try {
      log.i('Sottrazione $points punti da cliente #$customerId');

      final response = await _dio.post(
        '/mycred/v1/deduct-points',
        data: {
          'user_id': customerId,
          'amount': points,
          'reference': reference ?? 'manual_deduct',
          'entry': note ?? 'Punti sottratti manualmente',
        },
      );

      if (response.statusCode == 200) {
        log.i('Punti sottratti con successo da cliente #$customerId');
        return true;
      }

      return false;
    } catch (e) {
      log.e('Errore nella sottrazione punti da cliente #$customerId: $e');
      return false;
    }
  }

  // =======================================================
  // == GESTIONE CARTA FEDELTÀ                            ==
  // =======================================================

  /// Ottiene i dati della carta fedeltà di un cliente
  Future<Map<String, dynamic>?> getCustomerLoyaltyCard(int customerId) async {
    try {
      log.i('Recupero carta fedeltà per cliente #$customerId');

      final response = await _dio.get('/customers/$customerId');
      final customerData = response.data as Map<String, dynamic>;

      // Estrai i dati della carta fedeltà dai metadata
      final metaData = customerData['meta_data'] as List<dynamic>? ?? [];

      String? cardNumber;
      int points = 0;
      String? tier;

      for (var meta in metaData) {
        final key = meta['key'] as String?;
        final value = meta['value'];

        if (key == 'loyalty_card_number') {
          cardNumber = value?.toString();
        } else if (key == 'mycred_default') {
          points = int.tryParse(value?.toString() ?? '0') ?? 0;
        } else if (key == 'loyalty_tier') {
          tier = value?.toString();
        }
      }

      if (cardNumber == null) {
        log.d('Cliente #$customerId non ha carta fedeltà');
        return null;
      }

      return {
        'customer_id': customerId,
        'card_number': cardNumber,
        'points': points,
        'tier': tier ?? 'bronze',
        'first_name': customerData['first_name'] ?? '',
        'last_name': customerData['last_name'] ?? '',
        'email': customerData['email'] ?? '',
      };
    } catch (e) {
      log.e('Errore nel recupero carta fedeltà cliente #$customerId: $e');
      return null;
    }
  }

  /// Cerca un cliente per numero carta fedeltà
  Future<Map<String, dynamic>?> findCustomerByCardNumber(String cardNumber) async {
    try {
      log.i('Ricerca cliente con carta fedeltà: $cardNumber');

      // Cerca tutti i clienti (con paginazione)
      final response = await _dio.get(
        '/customers',
        queryParameters: {
          'per_page': 100,
          'search': cardNumber, // WooCommerce cerca anche nei metadata
        },
      );

      final customers = response.data as List<dynamic>;

      for (var customerData in customers) {
        final metaData = customerData['meta_data'] as List<dynamic>? ?? [];

        for (var meta in metaData) {
          if (meta['key'] == 'loyalty_card_number' &&
              meta['value']?.toString() == cardNumber) {

            // Cliente trovato
            final customerId = customerData['id'] as int;
            log.i('Cliente trovato con carta $cardNumber: #$customerId');

            return await getCustomerLoyaltyCard(customerId);
          }
        }
      }

      log.d('Nessun cliente trovato con carta $cardNumber');
      return null;
    } catch (e) {
      log.e('Errore nella ricerca cliente per carta $cardNumber: $e');
      return null;
    }
  }

  /// Crea o aggiorna la carta fedeltà di un cliente
  Future<bool> createOrUpdateLoyaltyCard({
    required int customerId,
    required String cardNumber,
    String tier = 'bronze',
  }) async {
    try {
      log.i('Creazione/aggiornamento carta fedeltà per cliente #$customerId');

      // Ottieni il cliente corrente
      final getResponse = await _dio.get('/customers/$customerId');
      final customerData = getResponse.data as Map<String, dynamic>;

      // Prepara i nuovi metadata
      final metaData = List<Map<String, dynamic>>.from(
        customerData['meta_data'] as List<dynamic>? ?? []
      );

      // Rimuovi metadata esistenti per la carta fedeltà
      metaData.removeWhere((meta) =>
        meta['key'] == 'loyalty_card_number' ||
        meta['key'] == 'loyalty_tier'
      );

      // Aggiungi nuovi metadata
      metaData.add({'key': 'loyalty_card_number', 'value': cardNumber});
      metaData.add({'key': 'loyalty_tier', 'value': tier});

      // Aggiorna il cliente
      final updateResponse = await _dio.put(
        '/customers/$customerId',
        data: {
          'meta_data': metaData,
        },
      );

      if (updateResponse.statusCode == 200) {
        log.i('Carta fedeltà aggiornata con successo per cliente #$customerId');
        return true;
      }

      return false;
    } catch (e) {
      log.e('Errore nella creazione/aggiornamento carta fedeltà: $e');
      return false;
    }
  }

  /// Rimuove la carta fedeltà da un cliente
  Future<bool> removeLoyaltyCard(int customerId) async {
    try {
      log.i('Rimozione carta fedeltà da cliente #$customerId');

      // Ottieni il cliente corrente
      final getResponse = await _dio.get('/customers/$customerId');
      final customerData = getResponse.data as Map<String, dynamic>;

      // Rimuovi metadata della carta fedeltà
      final metaData = List<Map<String, dynamic>>.from(
        customerData['meta_data'] as List<dynamic>? ?? []
      );

      metaData.removeWhere((meta) =>
        meta['key'] == 'loyalty_card_number' ||
        meta['key'] == 'loyalty_tier'
      );

      // Aggiorna il cliente
      final updateResponse = await _dio.put(
        '/customers/$customerId',
        data: {
          'meta_data': metaData,
        },
      );

      if (updateResponse.statusCode == 200) {
        log.i('Carta fedeltà rimossa con successo da cliente #$customerId');
        return true;
      }

      return false;
    } catch (e) {
      log.e('Errore nella rimozione carta fedeltà: $e');
      return false;
    }
  }

  // =======================================================
  // == STORICO PUNTI                                     ==
  // =======================================================

  /// Ottiene lo storico dei punti di un cliente
  Future<List<Map<String, dynamic>>> getPointsHistory(int customerId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      log.i('Recupero storico punti per cliente #$customerId');

      final response = await _dio.get(
        '/mycred/v1/history',
        queryParameters: {
          'user_id': customerId,
          'page': page,
          'per_page': perPage,
        },
      );

      final history = response.data as List<dynamic>;

      return history.map((entry) {
        return {
          'id': entry['id'],
          'date': entry['time'],
          'amount': entry['creds'],
          'balance': entry['balance'],
          'reference': entry['ref'],
          'note': entry['entry'],
        };
      }).toList();
    } catch (e) {
      log.e('Errore nel recupero storico punti: $e');
      return [];
    }
  }

  // =======================================================
  // == STATISTICHE                                       ==
  // =======================================================

  /// Ottiene statistiche generali del programma fedeltà
  Future<Map<String, dynamic>> getLoyaltyStats() async {
    try {
      log.i('Recupero statistiche programma fedeltà');

      final response = await _dio.get(
        '/customers',
        queryParameters: {'per_page': 100},
      );

      final customers = response.data as List<dynamic>;

      int totalCustomersWithCard = 0;
      int totalPoints = 0;
      Map<String, int> tierCounts = {
        'bronze': 0,
        'silver': 0,
        'gold': 0,
        'platinum': 0,
      };

      for (var customerData in customers) {
        final metaData = customerData['meta_data'] as List<dynamic>? ?? [];

        bool hasCard = false;
        String? tier;
        int points = 0;

        for (var meta in metaData) {
          if (meta['key'] == 'loyalty_card_number') {
            hasCard = true;
          } else if (meta['key'] == 'loyalty_tier') {
            tier = meta['value']?.toString();
          } else if (meta['key'] == 'mycred_default') {
            points = int.tryParse(meta['value']?.toString() ?? '0') ?? 0;
          }
        }

        if (hasCard) {
          totalCustomersWithCard++;
          totalPoints += points;

          if (tier != null && tierCounts.containsKey(tier)) {
            tierCounts[tier] = (tierCounts[tier] ?? 0) + 1;
          }
        }
      }

      return {
        'total_customers_with_card': totalCustomersWithCard,
        'total_points_issued': totalPoints,
        'tier_distribution': tierCounts,
      };
    } catch (e) {
      log.e('Errore nel recupero statistiche: $e');
      return {
        'total_customers_with_card': 0,
        'total_points_issued': 0,
        'tier_distribution': {'bronze': 0, 'silver': 0, 'gold': 0, 'platinum': 0},
      };
    }
  }

  /// Verifica disponibilità servizio myCred
  Future<bool> isMycredAvailable() async {
    try {
      // Prova a fare una chiamata all'API myCred
      final response = await _dio.get('/mycred/v1/status');
      return response.statusCode == 200;
    } catch (e) {
      log.w('myCred non disponibile o non configurato: $e');
      return false;
    }
  }
}
