/* /*
 * customers_query.dart
 * 
 * Servizio per la gestione dei Clienti WooCommerce.
 * Fornisce funzionalità per creare, modificare, eliminare e gestire
 * i clienti del negozio, inclusi indirizzi di fatturazione e spedizione.
 * 
 * Funzionalità principali:
 * - Gestione anagrafica clienti
 * - Indirizzi di fatturazione e spedizione
 * - Storico ordini cliente
 * - Statistiche e metriche cliente
 * - Segmentazione clienti
 * 
 * Dipendenze:
 * - jwt_connect.dart: Per l'autenticazione JWT
 * - error_list.dart: Per la gestione degli errori specifici
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../jwt_connect.dart';
import '../error_list.dart';

// =======================================================
// ==           CLASSE BASE PER I SERVIZI CLIENTI       ==
// =======================================================

/// Classe base astratta per tutti i servizi clienti WooCommerce.
/// Fornisce funzionalità comuni per le richieste API dei clienti.
abstract class _CustomerService {
  final JwtConnect _jwt;
  
  _CustomerService(this._jwt);

  /// Esegue una richiesta HTTP autenticata per i clienti.
  /// 
  /// [method] - Metodo HTTP (GET, POST, PUT, DELETE)
  /// [endpoint] - Endpoint dell'API WooCommerce
  /// [queryParams] - Parametri di query opzionali
  /// [body] - Corpo della richiesta per POST/PUT
  /// 
  /// Throws [UnauthorizedException] se il token JWT non è valido
  /// Throws [CustomerException] per errori specifici dei clienti
  Future<dynamic> _request(String method, String endpoint, {
    Map<String, String>? queryParams, 
    Map<String, dynamic>? body
  }) async {
    
    // Controllo preventivo della connessione
    if (_jwt.currentSiteUrl == null || !_jwt.isConnected) {
      throw UnauthorizedException();
    }

    final uri = _jwt.buildUri(_jwt.currentSiteUrl!, endpoint, queryParams: queryParams);
    
    try {
      // Esegue la richiesta autenticata
      final response = await _jwt.authenticatedRequest(method, uri, body: body);
      return _handleResponse(response);

    } on UnauthorizedException {
      // Pulisce lo stato locale se il token non è più valido
      await _jwt.disconnect();
      rethrow;
    }
  }

  /// Gestisce la risposta HTTP e converte gli errori in eccezioni specifiche.
  dynamic _handleResponse(http.Response response) {
    try {
      final jsonBody = jsonDecode(response.body);
      
      if (response.statusCode >= 400) {
        final String code = jsonBody['code'] ?? 'unknown_error';
        final String message = jsonBody['message'] ?? 'Errore sconosciuto con i clienti.';
        
        // Gestisce errori specifici dei clienti
        switch (code) {
          case 'woocommerce_rest_customer_invalid_id':
            throw CustomerNotFoundException();
          case 'woocommerce_rest_customer_invalid_email':
            throw InvalidCustomerEmailException();
          case 'registration-error-email-exists':
          case 'existing_user_email':
            throw CustomerEmailAlreadyExistsException();
          case 'woocommerce_rest_customer_invalid_username':
            throw InvalidCustomerUsernameException();
          case 'existing_user_login':
            throw CustomerUsernameAlreadyExistsException();
          default:
            throw GenericCustomerException(code: code, message: message, statusCode: response.statusCode);
        }
      }
      
      return jsonBody;
      
    } on FormatException {
      throw InvalidResponseFormatException();
    }
  }
}

// =======================================================
// ==            SERVIZIO GESTIONE CLIENTI              ==
// =======================================================

/// Servizio per la gestione completa dei clienti WooCommerce.
/// 
/// Fornisce funzionalità per:
/// - Creazione e modifica anagrafica clienti
/// - Gestione indirizzi di fatturazione e spedizione
/// - Ricerca e filtro clienti
/// - Eliminazione e archiviazione clienti
class CustomerManagementService extends _CustomerService {
  CustomerManagementService(JwtConnect jwt) : super(jwt);

  /// Crea un nuovo cliente.
  /// 
  /// [data] - Dati del cliente da creare
  /// 
  /// Returns [WooCustomer] - Il cliente creato
  /// Throws [CustomerEmailAlreadyExistsException] se l'email esiste già
  /// Throws [CustomerUsernameAlreadyExistsException] se l'username esiste già
  Future<WooCustomer> create(CreateCustomerData data) async {
    final customerData = await _request('POST', 'wc/v3/customers', body: data.toJson());
    return WooCustomer.fromJson(customerData);
  }

  /// Recupera un cliente tramite ID.
  /// 
  /// [customerId] - ID del cliente
  /// 
  /// Returns [WooCustomer] - Il cliente richiesto
  /// Throws [CustomerNotFoundException] se il cliente non esiste
  Future<WooCustomer> getById(int customerId) async {
    final customerData = await _request('GET', 'wc/v3/customers/$customerId');
    return WooCustomer.fromJson(customerData);
  }

  /// Recupera una lista di clienti con filtri opzionali.
  /// 
  /// [page] - Numero di pagina (default: 1)
  /// [perPage] - Clienti per pagina (default: 10, max: 100)
  /// [search] - Termine di ricerca per nome, email o username
  /// [email] - Filtro per email specifica
  /// [role] - Filtro per ruolo utente (customer, subscriber, ecc.)
  /// [orderBy] - Campo per ordinamento (id, include, name, registered_date)
  /// [order] - Direzione ordinamento (asc, desc)
  /// 
  /// Returns Lista di [WooCustomer]
  Future<List<WooCustomer>> list({
    int page = 1,
    int perPage = 10,
    String? search,
    String? email,
    String? role,
    String orderBy = 'id',
    String order = 'desc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'orderby': orderBy,
      'order': order,
    };
    
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (email != null && email.isNotEmpty) queryParams['email'] = email;
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    
    final List<dynamic> customersData = await _request('GET', 'wc/v3/customers', queryParams: queryParams);
    return customersData.map((data) => WooCustomer.fromJson(data)).toList();
  }

  /// Aggiorna un cliente esistente.
  /// 
  /// [customerId] - ID del cliente da aggiornare
  /// [data] - Dati di aggiornamento
  /// 
  /// Returns [WooCustomer] - Il cliente aggiornato
  /// Throws [CustomerNotFoundException] se il cliente non esiste
  Future<WooCustomer> update(int customerId, UpdateCustomerData data) async {
    final customerData = await _request('PUT', 'wc/v3/customers/$customerId', body: data.toJson());
    return WooCustomer.fromJson(customerData);
  }

  /// Elimina un cliente.
  /// 
  /// [customerId] - ID del cliente da eliminare
  /// [force] - Se true, elimina permanentemente. Se false, disattiva l'account
  /// [reassign] - ID utente a cui riassegnare contenuti (opzionale)
  /// 
  /// Throws [CustomerNotFoundException] se il cliente non esiste
  Future<void> delete(int customerId, {bool force = false, int? reassign}) async {
    final queryParams = <String, String>{'force': force.toString()};
    if (reassign != null) queryParams['reassign'] = reassign.toString();
    
    await _request('DELETE', 'wc/v3/customers/$customerId', queryParams: queryParams);
  }

  /// Recupera i clienti per paese.
  /// 
  /// [country] - Codice paese ISO 2 caratteri
  /// [limit] - Numero massimo di clienti da restituire
  /// 
  /// Returns Lista di [WooCustomer] del paese specificato
  Future<List<WooCustomer>> getByCountry(String country, {int limit = 50}) async {
    final allCustomers = await list(perPage: limit);
    
    return allCustomers.where((customer) => 
      customer.billing.country == country || 
      customer.shipping.country == country
    ).toList();
  }

  /// Cerca clienti per email parziale.
  /// 
  /// [emailFragment] - Parte dell'email da cercare
  /// [limit] - Numero massimo di risultati
  /// 
  /// Returns Lista di [WooCustomer] che corrispondono alla ricerca
  Future<List<WooCustomer>> searchByEmail(String emailFragment, {int limit = 20}) async {
    return await list(search: emailFragment, perPage: limit);
  }

  /// Recupera i clienti più attivi (con più ordini).
  /// 
  /// [limit] - Numero massimo di clienti da restituire
  /// [minOrders] - Numero minimo di ordini per essere considerati attivi
  /// 
  /// Returns Lista di [WooCustomer] ordinati per numero di ordini
  Future<List<WooCustomer>> getTopCustomers({int limit = 20, int minOrders = 1}) async {
    final customers = await list(perPage: 100);
    
    // Filtra e ordina per numero di ordini
    final activeCustomers = customers
        .where((c) => c.ordersCount >= minOrders)
        .toList()
      ..sort((a, b) => b.ordersCount.compareTo(a.ordersCount));
    
    return activeCustomers.take(limit).toList();
  }
}

// =======================================================
// ==        SERVIZIO ANALISI E STATISTICHE CLIENTI     ==
// =======================================================

/// Servizio per l'analisi e le statistiche sui clienti WooCommerce.
/// 
/// Fornisce metriche avanzate e segmentazione della clientela.
class CustomerAnalyticsService extends _CustomerService {
  CustomerAnalyticsService(JwtConnect jwt) : super(jwt);

  /// Recupera le statistiche generali della clientela.
  /// 
  /// Returns [CustomerStatistics] con le metriche principali
  Future<CustomerStatistics> getStatistics() async {
    final customers = await List(perPage: 100); // In produzione, usare paginazione
    
    if (customers.isEmpty) {
      return CustomerStatistics(
        totalCustomers: 0,
        activeCustomers: 0,
        newCustomersThisMonth: 0,
        averageOrdersPerCustomer: 0.0,
        totalCustomerValue: '0.00',
        averageCustomerValue: '0.00',
        topCountries: [],
      );
    }

    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    // Calcola metriche
    final activeCustomers = customers.where((c) => c.ordersCount > 0).length;
    final newCustomers = customers.where((c) => c.dateCreated.isAfter(monthAgo)).length;
    final totalOrders = customers.fold(0, (sum, c) => sum + c.ordersCount);
    final averageOrders = totalOrders / customers.length;
    
    final totalSpent = customers.fold(0.0, (sum, c) => 
      sum + (double.tryParse(c.totalSpent) ?? 0.0));
    final averageSpent = totalSpent / customers.length;

    // Top paesi
    final countryCounts = <String, int>{};
    for (final customer in customers) {
      final country = customer.billing.country;
      if (country.isNotEmpty) {
        countryCounts[country] = (countryCounts[country] ?? 0) + 1;
      }
    }
    
    final topCountries = countryCounts.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomerStatistics(
      totalCustomers: customers.length,
      activeCustomers: activeCustomers,
      newCustomersThisMonth: newCustomers,
      averageOrdersPerCustomer: averageOrders,
      totalCustomerValue: totalSpent.toStringAsFixed(2),
      averageCustomerValue: averageSpent.toStringAsFixed(2),
      topCountries: topCountries.take(5).map((e) => 
        CountryStatistic(country: e.key, customerCount: e.value)
      ).toList(),
    );
  }

  /// Segmenta i clienti in base al valore degli acquisti.
  /// 
  /// [highValueThreshold] - Soglia per clienti di alto valore
  /// [mediumValueThreshold] - Soglia per clienti di medio valore
  /// 
  /// Returns [CustomerSegmentation] con i segmenti di clientela
  Future<CustomerSegmentation> getCustomerSegmentation({
    double highValueThreshold = 1000.0,
    double mediumValueThreshold = 100.0,
  }) async {
    final customers = await list(perPage: 100);
    
    List<WooCustomer> highValue = [];
    List<WooCustomer> mediumValue = [];
    List<WooCustomer> lowValue = [];
    List<WooCustomer> inactive = [];

    for (final customer in customers) {
      final totalSpent = double.tryParse(customer.totalSpent) ?? 0.0;
      
      if (customer.ordersCount == 0) {
        inactive.add(customer);
      } else if (totalSpent >= highValueThreshold) {
        highValue.add(customer);
      } else if (totalSpent >= mediumValueThreshold) {
        mediumValue.add(customer);
      } else {
        lowValue.add(customer);
      }
    }

    return CustomerSegmentation(
      highValueCustomers: highValue,
      mediumValueCustomers: mediumValue,
      lowValueCustomers: lowValue,
      inactiveCustomers: inactive,
      highValueThreshold: highValueThreshold,
      mediumValueThreshold: mediumValueThreshold,
    );
  }

  /// Recupera i clienti a rischio abbandono.
  /// 
  /// [daysSinceLastOrder] - Giorni dall'ultimo ordine per considerare "a rischio"
  /// [minPreviousOrders] - Numero minimo di ordini precedenti
  /// 
  /// Returns Lista di [WooCustomer] a rischio abbandono
  Future<List<WooCustomer>> getChurnRiskCustomers({
    int daysSinceLastOrder = 90,
    int minPreviousOrders = 2,
  }) async {
    final customers = await list(perPage: 100);
    final cutoffDate = DateTime.now().subtract(Duration(days: daysSinceLastOrder));
    
    return customers.where((customer) {
      return customer.ordersCount >= minPreviousOrders &&
             customer.dateModified.isBefore(cutoffDate);
    }).toList();
  }
}

// =======================================================
// ==                 MODELLI DI DATI                   ==
// =======================================================

/// Dati per creare un nuovo cliente.
class CreateCustomerData {
  final String email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? password;
  final CustomerAddress? billing;
  final CustomerAddress? shipping;

  CreateCustomerData({
    required this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.password,
    this.billing,
    this.shipping,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'email': email};

    if (firstName != null) json['first_name'] = firstName;
    if (lastName != null) json['last_name'] = lastName;
    if (username != null) json['username'] = username;
    if (password != null) json['password'] = password;
    if (billing != null) json['billing'] = billing!.toJson();
    if (shipping != null) json['shipping'] = shipping!.toJson();

    return json;
  }
}

/// Dati per aggiornare un cliente esistente.
class UpdateCustomerData {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? password;
  final CustomerAddress? billing;
  final CustomerAddress? shipping;

  UpdateCustomerData({
    this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.password,
    this.billing,
    this.shipping,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (email != null) json['email'] = email;
    if (firstName != null) json['first_name'] = firstName;
    if (lastName != null) json['last_name'] = lastName;
    if (username != null) json['username'] = username;
    if (password != null) json['password'] = password;
    if (billing != null) json['billing'] = billing!.toJson();
    if (shipping != null) json['shipping'] = shipping!.toJson();

    return json;
  }
}

/// Modello per un indirizzo cliente.
class CustomerAddress {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;

  CustomerAddress({
    this.firstName = '',
    this.lastName = '',
    this.company = '',
    this.address1 = '',
    this.address2 = '',
    this.city = '',
    this.state = '',
    this.postcode = '',
    this.country = '',
    this.email = '',
    this.phone = '',
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'company': company,
    'address_1': address1,
    'address_2': address2,
    'city': city,
    'state': state,
    'postcode': postcode,
    'country': country,
    'email': email,
    'phone': phone,
  };
}

/// Modello per un cliente WooCommerce.
class WooCustomer {
  final int id;
  final DateTime dateCreated;
  final DateTime dateModified;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String username;
  final CustomerAddress billing;
  final CustomerAddress shipping;
  final bool isPayingCustomer;
  final String avatarUrl;
  final int ordersCount;
  final String totalSpent;

  WooCustomer({
    required this.id,
    required this.dateCreated,
    required this.dateModified,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.username,
    required this.billing,
    required this.shipping,
    required this.isPayingCustomer,
    required this.avatarUrl,
    required this.ordersCount,
    required this.totalSpent,
  });

  factory WooCustomer.fromJson(Map<String, dynamic> json) {
    return WooCustomer(
      id: json['id'],
      dateCreated: DateTime.parse(json['date_created_gmt']),
      dateModified: DateTime.parse(json['date_modified_gmt']),
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'customer',
      username: json['username'] ?? '',
      billing: CustomerAddress.fromJson(json['billing'] ?? {}),
      shipping: CustomerAddress.fromJson(json['shipping'] ?? {}),
      isPayingCustomer: json['is_paying_customer'] ?? false,
      avatarUrl: json['avatar_url'] ?? '',
      ordersCount: json['orders_count'] ?? 0,
      totalSpent: json['total_spent'] ?? '0.00',
    );
  }

  /// Restituisce il nome completo del cliente.
  String get fullName => '$firstName $lastName'.trim();

  /// Verifica se il cliente ha effettuato acquisti.
  bool get hasOrders => ordersCount > 0;

  /// Restituisce il valore totale speso come double.
  double get totalSpentValue => double.tryParse(totalSpent) ?? 0.0;
}

/// Modello per le statistiche generali della clientela.
class CustomerStatistics {
  final int totalCustomers;
  final int activeCustomers;
  final int newCustomersThisMonth;
  final double averageOrdersPerCustomer;
  final String totalCustomerValue;
  final String averageCustomerValue;
  final List<CountryStatistic> topCountries;

  CustomerStatistics({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.newCustomersThisMonth,
    required this.averageOrdersPerCustomer,
    required this.totalCustomerValue,
    required this.averageCustomerValue,
    required this.topCountries,
  });
}

/// Modello per le statistiche per paese.
class CountryStatistic {
  final String country;
  final int customerCount;

  CountryStatistic({
    required this.country,
    required this.customerCount,
  });
}

/// Modello per la segmentazione dei clienti.
class CustomerSegmentation {
  final List<WooCustomer> highValueCustomers;
  final List<WooCustomer> mediumValueCustomers;
  final List<WooCustomer> lowValueCustomers;
  final List<WooCustomer> inactiveCustomers;
  final double highValueThreshold;
  final double mediumValueThreshold;

  CustomerSegmentation({
    required this.highValueCustomers,
    required this.mediumValueCustomers,
    required this.lowValueCustomers,
    required this.inactiveCustomers,
    required this.highValueThreshold,
    required this.mediumValueThreshold,
  });

  /// Restituisce il numero totale di clienti segmentati.
  int get totalCustomers => 
    highValueCustomers.length + 
    mediumValueCustomers.length + 
    lowValueCustomers.length + 
    inactiveCustomers.length;

  /// Restituisce la percentuale di clienti di alto valore.
  double get highValuePercentage => 
    totalCustomers > 0 ? (highValueCustomers.length / totalCustomers) * 100 : 0.0;

  /// Restituisce la percentuale di clienti inattivi.
  double get inactivePercentage => 
    totalCustomers > 0 ? (inactiveCustomers.length / totalCustomers) * 100 : 0.0;
}

/// Servizio principale per aggregare tutti i servizi clienti
class CustomersService {
  final JwtConnect _jwt;
  
  late final CustomerManagementService customerManagementService;
  late final CustomerAnalyticsService customerAnalyticsService;

  CustomersService(this._jwt) {
    customerManagementService = CustomerManagementService(_jwt);
    customerAnalyticsService = CustomerAnalyticsService(_jwt);
  }
} */