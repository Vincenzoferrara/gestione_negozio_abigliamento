/*
 * tax_query.dart
 * 
 * Servizio per la gestione delle Tasse WooCommerce.
 * Fornisce funzionalità per gestire aliquote fiscali, classi di tasse,
 * zone fiscali e calcoli automatici delle imposte.
 * 
 * Funzionalità principali:
 * - Gestione classi di tasse
 * - Configurazione aliquote fiscali per zone
 * - Calcolo automatico delle tasse
 * - Gestione zone fiscali
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
// ==           CLASSE BASE PER I SERVIZI TASSE         ==
// =======================================================

/// Classe base astratta per tutti i servizi tasse WooCommerce.
/// Fornisce funzionalità comuni per le richieste API delle tasse.
abstract class _TaxService {
  final JwtConnect _jwt;
  
  _TaxService(this._jwt);

  /// Esegue una richiesta HTTP autenticata per le tasse.
  /// 
  /// [method] - Metodo HTTP (GET, POST, PUT, DELETE)
  /// [endpoint] - Endpoint dell'API WooCommerce
  /// [queryParams] - Parametri di query opzionali
  /// [body] - Corpo della richiesta per POST/PUT
  /// 
  /// Throws [UnauthorizedException] se il token JWT non è valido
  /// Throws [TaxException] per errori specifici delle tasse
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
        final String message = jsonBody['message'] ?? 'Errore sconosciuto con le tasse.';
        
        // Gestisce errori specifici delle tasse
        switch (code) {
          case 'woocommerce_rest_tax_class_invalid':
            throw TaxClassNotFoundException();
          case 'woocommerce_rest_tax_rate_invalid':
            throw TaxRateNotFoundException();
          case 'woocommerce_rest_invalid_tax_location':
            throw InvalidTaxLocationException();
          default:
            throw GenericTaxException(code: code, message: message, statusCode: response.statusCode);
        }
      }
      
      return jsonBody;
      
    } on FormatException {
      throw InvalidResponseFormatException();
    }
  }
}

// =======================================================
// ==            SERVIZIO GESTIONE CLASSI TASSE         ==
// =======================================================

/// Servizio per la gestione delle classi di tasse WooCommerce.
/// 
/// Le classi di tasse raggruppano prodotti con la stessa aliquota fiscale.
/// Esempi: "Standard", "Ridotta", "Esentasse", ecc.
class TaxClassService extends _TaxService {
  TaxClassService(JwtConnect jwt) : super(jwt);

  /// Recupera tutte le classi di tasse configurate.
  /// 
  /// Returns Lista di [WooTaxClass]
  Future<List<WooTaxClass>> list() async {
    final List<dynamic> taxClassesData = await _request('GET', 'wc/v3/taxes/classes');
    return taxClassesData.map((data) => WooTaxClass.fromJson(data)).toList();
  }

  /// Crea una nuova classe di tasse.
  /// 
  /// [data] - Dati della classe di tasse da creare
  /// 
  /// Returns [WooTaxClass] - La classe di tasse creata
  Future<WooTaxClass> create(CreateTaxClassData data) async {
    final taxClassData = await _request('POST', 'wc/v3/taxes/classes', body: data.toJson());
    return WooTaxClass.fromJson(taxClassData);
  }

  /// Elimina una classe di tasse.
  /// 
  /// [slug] - Slug della classe di tasse da eliminare
  /// [force] - Se true, elimina permanentemente
  /// 
  /// Throws [TaxClassNotFoundException] se la classe non esiste
  Future<void> delete(String slug, {bool force = true}) async {
    final queryParams = force ? {'force': 'true'} : <String, String>{};
    await _request('DELETE', 'wc/v3/taxes/classes/$slug', queryParams: queryParams);
  }
}

// =======================================================
// ==           SERVIZIO GESTIONE ALIQUOTE TASSE        ==
// =======================================================

/// Servizio per la gestione delle aliquote fiscali WooCommerce.
/// 
/// Le aliquote definiscono le percentuali di tassa da applicare
/// per diverse zone geografiche e classi di prodotti.
class TaxRateService extends _TaxService {
  TaxRateService(JwtConnect jwt) : super(jwt);

  /// Recupera tutte le aliquote fiscali con filtri opzionali.
  /// 
  /// [page] - Numero di pagina (default: 1)
  /// [perPage] - Aliquote per pagina (default: 10, max: 100)
  /// [taxClass] - Filtro per classe di tasse
  /// [country] - Filtro per paese (codice ISO 2 caratteri)
  /// [state] - Filtro per stato/provincia
  /// 
  /// Returns Lista di [WooTaxRate]
  Future<List<WooTaxRate>> list({
    int page = 1,
    int perPage = 10,
    String? taxClass,
    String? country,
    String? state,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    
    if (taxClass != null && taxClass.isNotEmpty) queryParams['class'] = taxClass;
    if (country != null && country.isNotEmpty) queryParams['country'] = country;
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    
    final List<dynamic> taxRatesData = await _request('GET', 'wc/v3/taxes', queryParams: queryParams);
    return taxRatesData.map((data) => WooTaxRate.fromJson(data)).toList();
  }

  /// Crea una nuova aliquota fiscale.
  /// 
  /// [data] - Dati dell'aliquota fiscale da creare
  /// 
  /// Returns [WooTaxRate] - L'aliquota fiscale creata
  Future<WooTaxRate> create(CreateTaxRateData data) async {
    final taxRateData = await _request('POST', 'wc/v3/taxes', body: data.toJson());
    return WooTaxRate.fromJson(taxRateData);
  }

  /// Recupera un'aliquota fiscale tramite ID.
  /// 
  /// [taxRateId] - ID dell'aliquota fiscale
  /// 
  /// Returns [WooTaxRate] - L'aliquota richiesta
  /// Throws [TaxRateNotFoundException] se l'aliquota non esiste
  Future<WooTaxRate> getById(int taxRateId) async {
    final taxRateData = await _request('GET', 'wc/v3/taxes/$taxRateId');
    return WooTaxRate.fromJson(taxRateData);
  }

  /// Aggiorna un'aliquota fiscale esistente.
  /// 
  /// [taxRateId] - ID dell'aliquota da aggiornare
  /// [data] - Dati di aggiornamento
  /// 
  /// Returns [WooTaxRate] - L'aliquota aggiornata
  /// Throws [TaxRateNotFoundException] se l'aliquota non esiste
  Future<WooTaxRate> update(int taxRateId, UpdateTaxRateData data) async {
    final taxRateData = await _request('PUT', 'wc/v3/taxes/$taxRateId', body: data.toJson());
    return WooTaxRate.fromJson(taxRateData);
  }

  /// Elimina un'aliquota fiscale.
  /// 
  /// [taxRateId] - ID dell'aliquota da eliminare
  /// [force] - Se true, elimina permanentemente
  /// 
  /// Throws [TaxRateNotFoundException] se l'aliquota non esiste
  Future<void> delete(int taxRateId, {bool force = true}) async {
    final queryParams = force ? {'force': 'true'} : <String, String>{};
    await _request('DELETE', 'wc/v3/taxes/$taxRateId', queryParams: queryParams);
  }

  /// Recupera le aliquote fiscali per una zona specifica.
  /// 
  /// [country] - Codice paese ISO 2 caratteri
  /// [state] - Codice stato/provincia (opzionale)
  /// [city] - Nome città (opzionale)
  /// [postcode] - Codice postale (opzionale)
  /// 
  /// Returns Lista di [WooTaxRate] applicabili alla zona
  Future<List<WooTaxRate>> getByLocation({
    required String country,
    String? state,
    String? city,
    String? postcode,
  }) async {
    final queryParams = <String, String>{'country': country};
    
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (postcode != null && postcode.isNotEmpty) queryParams['postcode'] = postcode;
    
    final List<WooTaxRate> allRates = await list(perPage: 100);
    
    // Filtra le aliquote applicabili alla zona specifica
    return allRates.where((rate) {
      // Verifica paese
      if (rate.country != country && rate.country.isNotEmpty) return false;
      
      // Verifica stato (se specificato)
      if (state != null && rate.state.isNotEmpty && rate.state != state) return false;
      
      // Verifica città (se specificata)
      if (city != null && rate.cities.isNotEmpty && !rate.cities.contains(city)) return false;
      
      // Verifica codice postale (se specificato)
      if (postcode != null && rate.postcodes.isNotEmpty) {
        bool matchesPostcode = rate.postcodes.any((pc) {
          // Supporta wildcards semplici
          if (pc.contains('*')) {
            final pattern = pc.replaceAll('*', '');
            return postcode.startsWith(pattern);
          }
          return pc == postcode;
        });
        if (!matchesPostcode) return false;
      }
      
      return true;
    }).toList();
  }
}

// =======================================================
// ==            SERVIZIO CALCOLO TASSE                 ==
// =======================================================

/// Servizio per il calcolo automatico delle tasse WooCommerce.
/// 
/// Fornisce funzionalità per calcolare l'importo delle tasse
/// per prodotti, ordini e carrelli in base alla zona fiscale.
class TaxCalculationService extends _TaxService {
  TaxCalculationService(JwtConnect jwt) : super(jwt);

  /// Calcola le tasse per un prodotto in una zona specifica.
  /// 
  /// [productPrice] - Prezzo del prodotto
  /// [taxClass] - Classe di tasse del prodotto (opzionale, default: standard)
  /// [country] - Codice paese ISO 2 caratteri
  /// [state] - Codice stato/provincia (opzionale)
  /// [city] - Nome città (opzionale)
  /// [postcode] - Codice postale (opzionale)
  /// [priceIncludesTax] - Se il prezzo include già le tasse
  /// 
  /// Returns [TaxCalculation] con i dettagli del calcolo
  Future<TaxCalculation> calculateProductTax({
    required String productPrice,
    String taxClass = 'standard',
    required String country,
    String? state,
    String? city,
    String? postcode,
    bool priceIncludesTax = false,
  }) async {
    final price = double.tryParse(productPrice) ?? 0.0;
    if (price <= 0) {
      return TaxCalculation(
        priceExcludingTax: productPrice,
        taxAmount: '0.00',
        priceIncludingTax: productPrice,
        taxBreakdown: [],
      );
    }

    // Recupera le aliquote applicabili
    final taxRateService = TaxRateService(_jwt);
    final applicableRates = await taxRateService.getByLocation(
      country: country,
      state: state,
      city: city,
      postcode: postcode,
    );

    // Filtra per classe di tasse
    final rates = applicableRates.where((rate) => 
      rate.taxClass == taxClass || 
      (taxClass == 'standard' && rate.taxClass.isEmpty)
    ).toList();

    if (rates.isEmpty) {
      return TaxCalculation(
        priceExcludingTax: productPrice,
        taxAmount: '0.00',
        priceIncludingTax: productPrice,
        taxBreakdown: [],
      );
    }

    // Calcola le tasse
    double totalTaxRate = 0.0;
    List<TaxBreakdownItem> breakdown = [];

    for (final rate in rates) {
      final rateValue = double.tryParse(rate.rate) ?? 0.0;
      totalTaxRate += rateValue;
      
      breakdown.add(TaxBreakdownItem(
        rateId: rate.id,
        name: rate.name,
        rate: rate.rate,
        taxAmount: _calculateTaxForRate(price, rateValue, priceIncludesTax).toStringAsFixed(2),
      ));
    }

    double priceExTax, taxAmount, priceIncTax;

    if (priceIncludesTax) {
      // Il prezzo include già le tasse
      priceIncTax = price;
      priceExTax = price / (1 + (totalTaxRate / 100));
      taxAmount = priceIncTax - priceExTax;
    } else {
      // Il prezzo è senza tasse
      priceExTax = price;
      taxAmount = price * (totalTaxRate / 100);
      priceIncTax = priceExTax + taxAmount;
    }

    return TaxCalculation(
      priceExcludingTax: priceExTax.toStringAsFixed(2),
      taxAmount: taxAmount.toStringAsFixed(2),
      priceIncludingTax: priceIncTax.toStringAsFixed(2),
      taxBreakdown: breakdown,
    );
  }

  /// Calcola l'importo della tassa per una singola aliquota.
  double _calculateTaxForRate(double price, double rate, bool priceIncludesTax) {
    if (priceIncludesTax) {
      return (price * rate) / (100 + rate);
    } else {
      return price * (rate / 100);
    }
  }

  /// Calcola le tasse per un intero carrello.
  /// 
  /// [items] - Lista degli articoli nel carrello
  /// [country] - Codice paese ISO 2 caratteri
  /// [state] - Codice stato/provincia (opzionale)
  /// [city] - Nome città (opzionale)
  /// [postcode] - Codice postale (opzionale)
  /// [priceIncludesTax] - Se i prezzi includono già le tasse
  /// 
  /// Returns [CartTaxCalculation] con il riepilogo delle tasse
  Future<CartTaxCalculation> calculateCartTax({
    required List<CartTaxItem> items,
    required String country,
    String? state,
    String? city,
    String? postcode,
    bool priceIncludesTax = false,
  }) async {
    List<TaxCalculation> itemCalculations = [];
    double totalTaxAmount = 0.0;
    double totalPriceExTax = 0.0;
    double totalPriceIncTax = 0.0;

    for (final item in items) {
      final calculation = await calculateProductTax(
        productPrice: item.price,
        taxClass: item.taxClass,
        country: country,
        state: state,
        city: city,
        postcode: postcode,
        priceIncludesTax: priceIncludesTax,
      );

      // Moltiplica per la quantità
      final quantity = item.quantity;
      final itemTaxAmount = (double.tryParse(calculation.taxAmount) ?? 0.0) * quantity;
      final itemPriceExTax = (double.tryParse(calculation.priceExcludingTax) ?? 0.0) * quantity;
      final itemPriceIncTax = (double.tryParse(calculation.priceIncludingTax) ?? 0.0) * quantity;

      totalTaxAmount += itemTaxAmount;
      totalPriceExTax += itemPriceExTax;
      totalPriceIncTax += itemPriceIncTax;

      itemCalculations.add(TaxCalculation(
        priceExcludingTax: itemPriceExTax.toStringAsFixed(2),
        taxAmount: itemTaxAmount.toStringAsFixed(2),
        priceIncludingTax: itemPriceIncTax.toStringAsFixed(2),
        taxBreakdown: calculation.taxBreakdown,
      ));
    }

    return CartTaxCalculation(
      itemCalculations: itemCalculations,
      totalPriceExcludingTax: totalPriceExTax.toStringAsFixed(2),
      totalTaxAmount: totalTaxAmount.toStringAsFixed(2),
      totalPriceIncludingTax: totalPriceIncTax.toStringAsFixed(2),
    );
  }
}

// =======================================================
// ==                 MODELLI DI DATI                   ==
// =======================================================

/// Dati per creare una nuova classe di tasse.
class CreateTaxClassData {
  final String name;
  final String slug;

  CreateTaxClassData({
    required this.name,
    required this.slug,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
  };
}

/// Dati per creare una nuova aliquota fiscale.
class CreateTaxRateData {
  final String country;
  final String state;
  final String rate;
  final String name;
  final int priority;
  final bool compound;
  final bool shipping;
  final int order;
  final String taxClass;
  final List<String>? postcodes;
  final List<String>? cities;

  CreateTaxRateData({
    required this.country,
    this.state = '',
    required this.rate,
    required this.name,
    this.priority = 1,
    this.compound = false,
    this.shipping = true,
    this.order = 0,
    this.taxClass = 'standard',
    this.postcodes,
    this.cities,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'country': country,
      'state': state,
      'rate': rate,
      'name': name,
      'priority': priority,
      'compound': compound,
      'shipping': shipping,
      'order': order,
      'class': taxClass,
    };

    if (postcodes != null && postcodes!.isNotEmpty) {
      json['postcodes'] = postcodes;
    }
    if (cities != null && cities!.isNotEmpty) {
      json['cities'] = cities;
    }

    return json;
  }
}

/// Dati per aggiornare un'aliquota fiscale esistente.
class UpdateTaxRateData {
  final String? country;
  final String? state;
  final String? rate;
  final String? name;
  final int? priority;
  final bool? compound;
  final bool? shipping;
  final int? order;
  final String? taxClass;
  final List<String>? postcodes;
  final List<String>? cities;

  UpdateTaxRateData({
    this.country,
    this.state,
    this.rate,
    this.name,
    this.priority,
    this.compound,
    this.shipping,
    this.order,
    this.taxClass,
    this.postcodes,
    this.cities,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (country != null) json['country'] = country;
    if (state != null) json['state'] = state;
    if (rate != null) json['rate'] = rate;
    if (name != null) json['name'] = name;
    if (priority != null) json['priority'] = priority;
    if (compound != null) json['compound'] = compound;
    if (shipping != null) json['shipping'] = shipping;
    if (order != null) json['order'] = order;
    if (taxClass != null) json['class'] = taxClass;
    if (postcodes != null) json['postcodes'] = postcodes;
    if (cities != null) json['cities'] = cities;

    return json;
  }
}

/// Modello per una classe di tasse WooCommerce.
class WooTaxClass {
  final String slug;
  final String name;

  WooTaxClass({
    required this.slug,
    required this.name,
  });

  factory WooTaxClass.fromJson(Map<String, dynamic> json) {
    return WooTaxClass(
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

/// Modello per un'aliquota fiscale WooCommerce.
class WooTaxRate {
  final int id;
  final String country;
  final String state;
  final String rate;
  final String name;
  final int priority;
  final bool compound;
  final bool shipping;
  final int order;
  final String taxClass;
  final List<String> postcodes;
  final List<String> cities;

  WooTaxRate({
    required this.id,
    required this.country,
    required this.state,
    required this.rate,
    required this.name,
    required this.priority,
    required this.compound,
    required this.shipping,
    required this.order,
    required this.taxClass,
    required this.postcodes,
    required this.cities,
  });

  factory WooTaxRate.fromJson(Map<String, dynamic> json) {
    return WooTaxRate(
      id: json['id'],
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      rate: json['rate'] ?? '0',
      name: json['name'] ?? '',
      priority: json['priority'] ?? 1,
      compound: json['compound'] ?? false,
      shipping: json['shipping'] ?? true,
      order: json['order'] ?? 0,
      taxClass: json['class'] ?? 'standard',
      postcodes: (json['postcodes'] as List<dynamic>?)?.cast<String>() ?? [],
      cities: (json['cities'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Modello per il calcolo delle tasse su un prodotto.
class TaxCalculation {
  final String priceExcludingTax;
  final String taxAmount;
  final String priceIncludingTax;
  final List<TaxBreakdownItem> taxBreakdown;

  TaxCalculation({
    required this.priceExcludingTax,
    required this.taxAmount,
    required this.priceIncludingTax,
    required this.taxBreakdown,
  });
}

/// Dettaglio di una singola aliquota nel calcolo delle tasse.
class TaxBreakdownItem {
  final int rateId;
  final String name;
  final String rate;
  final String taxAmount;

  TaxBreakdownItem({
    required this.rateId,
    required this.name,
    required this.rate,
    required this.taxAmount,
  });
}

/// Modello per un articolo nel calcolo delle tasse del carrello.
class CartTaxItem {
  final String price;
  final String taxClass;
  final int quantity;

  CartTaxItem({
    required this.price,
    this.taxClass = 'standard',
    this.quantity = 1,
  });
}

/// Modello per il calcolo delle tasse dell'intero carrello.
class CartTaxCalculation {
  final List<TaxCalculation> itemCalculations;
  final String totalPriceExcludingTax;
  final String totalTaxAmount;
  final String totalPriceIncludingTax;

  CartTaxCalculation({
    required this.itemCalculations,
    required this.totalPriceExcludingTax,
    required this.totalTaxAmount,
    required this.totalPriceIncludingTax,
  });
}

/// Servizio principale per aggregare tutti i servizi tasse
class TaxService {
  final JwtConnect _jwt;
  
  late final TaxClassService taxClassService;
  late final TaxRateService taxRateService;
  late final TaxCalculationService taxCalculationService;

  TaxService(this._jwt) {
    taxClassService = TaxClassService(_jwt);
    taxRateService = TaxRateService(_jwt);
    taxCalculationService = TaxCalculationService(_jwt);
  }
}