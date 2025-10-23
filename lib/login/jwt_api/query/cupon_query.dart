/*
 * coupons_query.dart
 * 
 * Servizio per la gestione dei Coupon WooCommerce.
 * Fornisce funzionalità per creare, modificare, eliminare e gestire
 * coupon di sconto con diverse tipologie e restrizioni.
 * 
 * Tipologie supportate:
 * - Sconto fisso sul carrello
 * - Sconto percentuale
 * - Sconto fisso sul prodotto
 * - Spedizione gratuita
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
// ==           CLASSE BASE PER I SERVIZI COUPON        ==
// =======================================================

/// Classe base astratta per tutti i servizi coupon WooCommerce.
/// Fornisce funzionalità comuni per le richieste API dei coupon.
abstract class _CouponService {
  final JwtConnect _jwt;
  
  _CouponService(this._jwt);

  /// Esegue una richiesta HTTP autenticata per i coupon.
  /// 
  /// [method] - Metodo HTTP (GET, POST, PUT, DELETE)
  /// [endpoint] - Endpoint dell'API WooCommerce
  /// [queryParams] - Parametri di query opzionali
  /// [body] - Corpo della richiesta per POST/PUT
  /// 
  /// Throws [UnauthorizedException] se il token JWT non è valido
  /// Throws [CouponException] per errori specifici dei coupon
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
        final String message = jsonBody['message'] ?? 'Errore sconosciuto con i coupon.';
        
        // Gestisce errori specifici dei coupon
        switch (code) {
          case 'woocommerce_rest_coupon_invalid_code':
            throw CouponNotFoundException();
          case 'woocommerce_rest_coupon_code_already_exists':
            throw CouponCodeAlreadyExistsException();
          case 'woocommerce_rest_coupon_expired':
            throw CouponExpiredException();
          case 'woocommerce_rest_coupon_usage_limit_reached':
            throw CouponUsageLimitException();
          default:
            throw GenericCouponException(code: code, message: message, statusCode: response.statusCode);
        }
      }
      
      return jsonBody;
      
    } on FormatException {
      throw InvalidResponseFormatException();
    }
  }
}

// =======================================================
// ==              SERVIZIO GESTIONE COUPON             ==
// =======================================================

/// Servizio per la gestione completa dei coupon WooCommerce.
/// 
/// Fornisce funzionalità per:
/// - Creazione di nuovi coupon con diverse tipologie di sconto
/// - Modifica di coupon esistenti
/// - Eliminazione e archiviazione coupon
/// - Recupero e ricerca coupon
/// - Gestione delle restrizioni e limitazioni d'uso
class CouponManagementService extends _CouponService {
  CouponManagementService(JwtConnect jwt) : super(jwt);

  /// Crea un nuovo coupon.
  /// 
  /// [data] - Dati del coupon da creare
  /// 
  /// Returns [WooCoupon] - Il coupon creato
  /// Throws [CouponCodeAlreadyExistsException] se il codice esiste già
  Future<WooCoupon> create(CreateCouponData data) async {
    final couponData = await _request('POST', 'wc/v3/coupons', body: data.toJson());
    return WooCoupon.fromJson(couponData);
  }

  /// Recupera un coupon tramite ID.
  /// 
  /// [couponId] - ID del coupon
  /// 
  /// Returns [WooCoupon] - Il coupon richiesto
  /// Throws [CouponNotFoundException] se il coupon non esiste
  Future<WooCoupon> getById(int couponId) async {
    final couponData = await _request('GET', 'wc/v3/coupons/$couponId');
    return WooCoupon.fromJson(couponData);
  }

  /// Recupera un coupon tramite codice.
  /// 
  /// [code] - Codice del coupon
  /// 
  /// Returns [WooCoupon] - Il coupon richiesto
  /// Throws [CouponNotFoundException] se il coupon non esiste
  Future<WooCoupon> getByCode(String code) async {
    final List<WooCoupon> coupons = await list(search: code, perPage: 1);
    
    if (coupons.isEmpty || coupons.first.code.toLowerCase() != code.toLowerCase()) {
      throw CouponNotFoundException();
    }
    
    return coupons.first;
  }

  /// Recupera una lista di coupon con filtri opzionali.
  /// 
  /// [page] - Numero di pagina (default: 1)
  /// [perPage] - Coupon per pagina (default: 10, max: 100)
  /// [search] - Termine di ricerca per codice coupon
  /// [status] - Status del coupon (publish, draft, trash)
  /// [type] - Tipo di sconto (fixed_cart, percent, fixed_product, percent_product)
  /// 
  /// Returns Lista di [WooCoupon]
  Future<List<WooCoupon>> list({
    int page = 1,
    int perPage = 10,
    String? search,
    String? status,
    String? type,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (type != null && type.isNotEmpty) queryParams['discount_type'] = type;
    
    final List<dynamic> couponsData = await _request('GET', 'wc/v3/coupons', queryParams: queryParams);
    return couponsData.map((data) => WooCoupon.fromJson(data)).toList();
  }

  /// Aggiorna un coupon esistente.
  /// 
  /// [couponId] - ID del coupon da aggiornare
  /// [data] - Dati di aggiornamento
  /// 
  /// Returns [WooCoupon] - Il coupon aggiornato
  /// Throws [CouponNotFoundException] se il coupon non esiste
  Future<WooCoupon> update(int couponId, UpdateCouponData data) async {
    final couponData = await _request('PUT', 'wc/v3/coupons/$couponId', body: data.toJson());
    return WooCoupon.fromJson(couponData);
  }

  /// Elimina un coupon.
  /// 
  /// [couponId] - ID del coupon da eliminare
  /// [force] - Se true, elimina permanentemente. Se false, sposta nel cestino
  /// 
  /// Throws [CouponNotFoundException] se il coupon non esiste
  Future<void> delete(int couponId, {bool force = false}) async {
    final queryParams = force ? {'force': 'true'} : <String, String>{};
    await _request('DELETE', 'wc/v3/coupons/$couponId', queryParams: queryParams);
  }

  /// Verifica la validità di un coupon per un ordine specifico.
  /// 
  /// [couponCode] - Codice del coupon da verificare
  /// [orderTotal] - Totale dell'ordine
  /// [productIds] - Lista degli ID prodotti nell'ordine (opzionale)
  /// [categoryIds] - Lista degli ID categorie (opzionale)
  /// [customerEmail] - Email del cliente (opzionale)
  /// 
  /// Returns [CouponValidation] con risultato della validazione
  Future<CouponValidation> validateCoupon({
    required String couponCode,
    required String orderTotal,
    List<int>? productIds,
    List<int>? categoryIds,
    String? customerEmail,
  }) async {
    try {
      final coupon = await getByCode(couponCode);
      
      // Verifica se il coupon è attivo
      if (coupon.status != 'publish') {
        return CouponValidation(
          isValid: false,
          errorMessage: 'Il coupon non è attivo.',
        );
      }
      
      // Verifica data di scadenza
      if (coupon.dateExpires != null && DateTime.now().isAfter(coupon.dateExpires!)) {
        return CouponValidation(
          isValid: false,
          errorMessage: 'Il coupon è scaduto.',
        );
      }
      
      // Verifica limite di utilizzi
      if (coupon.usageLimit != null && coupon.usageCount >= coupon.usageLimit!) {
        return CouponValidation(
          isValid: false,
          errorMessage: 'Il coupon ha raggiunto il limite di utilizzi.',
        );
      }
      
      // Verifica importo minimo
      final orderAmount = double.tryParse(orderTotal) ?? 0.0;
      final minimumAmount = double.tryParse(coupon.minimumAmount ?? '0') ?? 0.0;
      if (minimumAmount > 0 && orderAmount < minimumAmount) {
        return CouponValidation(
          isValid: false,
          errorMessage: 'Importo minimo richiesto: ${coupon.minimumAmount}',
        );
      }
      
      // Verifica importo massimo
      final maximumAmount = double.tryParse(coupon.maximumAmount ?? '0') ?? 0.0;
      if (maximumAmount > 0 && orderAmount > maximumAmount) {
        return CouponValidation(
          isValid: false,
          errorMessage: 'Importo massimo consentito: ${coupon.maximumAmount}',
        );
      }
      
      // Se tutte le verifiche passano
      return CouponValidation(
        isValid: true,
        coupon: coupon,
        discountAmount: _calculateDiscount(coupon, orderAmount),
      );
      
    } on CouponNotFoundException {
      return CouponValidation(
        isValid: false,
        errorMessage: 'Codice coupon non valido.',
      );
    }
  }

  /// Calcola l'importo dello sconto applicabile.
  String _calculateDiscount(WooCoupon coupon, double orderAmount) {
    switch (coupon.discountType) {
      case 'percent':
        final discountPercent = double.tryParse(coupon.amount) ?? 0.0;
        return (orderAmount * (discountPercent / 100)).toStringAsFixed(2);
      case 'fixed_cart':
      case 'fixed_product':
        return coupon.amount;
      default:
        return '0.00';
    }
  }

  /// Recupera le statistiche di utilizzo dei coupon.
  /// 
  /// [period] - Periodo di analisi (month, year, custom)
  /// [startDate] - Data inizio per periodo custom
  /// [endDate] - Data fine per periodo custom
  /// 
  /// Returns [CouponStats] con le statistiche
  Future<CouponStats> getUsageStats({
    String period = 'month',
    String? startDate,
    String? endDate,
  }) async {
    // Recupera tutti i coupon attivi
    final activeCoupons = await list(status: 'publish', perPage: 100);
    
    // Calcola statistiche aggregate
    int totalCoupons = activeCoupons.length;
    int usedCoupons = activeCoupons.where((c) => c.usageCount > 0).length;
    int totalUsage = activeCoupons.fold(0, (sum, c) => sum + c.usageCount);
    String totalDiscount = activeCoupons.fold(0.0, (sum, c) {
      // Stima approssimativa - in un caso reale dovremmo consultare gli ordini
      return sum + (c.usageCount * (double.tryParse(c.amount) ?? 0.0));
    }).toStringAsFixed(2);
    
    return CouponStats(
      totalCoupons: totalCoupons,
      activeCoupons: usedCoupons,
      totalUsage: totalUsage,
      totalDiscount: totalDiscount,
      period: period,
    );
  }
}

// =======================================================
// ==                 MODELLI DI DATI                   ==
// =======================================================

/// Dati per creare un nuovo coupon.
class CreateCouponData {
  final String code;
  final String discountType;
  final String amount;
  final String status;
  final String? description;
  final DateTime? dateExpires;
  final int? usageLimit;
  final int? usageLimitPerUser;
  final int? limitUsageToXItems;
  final bool freeShipping;
  final List<int>? productIds;
  final List<int>? excludedProductIds;
  final List<int>? productCategories;
  final List<int>? excludedProductCategories;
  final bool excludeSaleItems;
  final String? minimumAmount;
  final String? maximumAmount;
  final List<String>? emailRestrictions;

  CreateCouponData({
    required this.code,
    required this.discountType,
    required this.amount,
    this.status = 'publish',
    this.description,
    this.dateExpires,
    this.usageLimit,
    this.usageLimitPerUser,
    this.limitUsageToXItems,
    this.freeShipping = false,
    this.productIds,
    this.excludedProductIds,
    this.productCategories,
    this.excludedProductCategories,
    this.excludeSaleItems = false,
    this.minimumAmount,
    this.maximumAmount,
    this.emailRestrictions,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'code': code,
      'discount_type': discountType,
      'amount': amount,
      'status': status,
      'free_shipping': freeShipping,
      'exclude_sale_items': excludeSaleItems,
    };

    if (description != null) json['description'] = description;
    if (dateExpires != null) json['date_expires'] = dateExpires!.toIso8601String();
    if (usageLimit != null) json['usage_limit'] = usageLimit;
    if (usageLimitPerUser != null) json['usage_limit_per_user'] = usageLimitPerUser;
    if (limitUsageToXItems != null) json['limit_usage_to_x_items'] = limitUsageToXItems;
    if (productIds != null) json['product_ids'] = productIds;
    if (excludedProductIds != null) json['excluded_product_ids'] = excludedProductIds;
    if (productCategories != null) json['product_categories'] = productCategories;
    if (excludedProductCategories != null) json['excluded_product_categories'] = excludedProductCategories;
    if (minimumAmount != null) json['minimum_amount'] = minimumAmount;
    if (maximumAmount != null) json['maximum_amount'] = maximumAmount;
    if (emailRestrictions != null) json['email_restrictions'] = emailRestrictions;

    return json;
  }
}

/// Dati per aggiornare un coupon esistente.
class UpdateCouponData {
  final String? code;
  final String? discountType;
  final String? amount;
  final String? status;
  final String? description;
  final DateTime? dateExpires;
  final int? usageLimit;
  final int? usageLimitPerUser;
  final int? limitUsageToXItems;
  final bool? freeShipping;
  final List<int>? productIds;
  final List<int>? excludedProductIds;
  final List<int>? productCategories;
  final List<int>? excludedProductCategories;
  final bool? excludeSaleItems;
  final String? minimumAmount;
  final String? maximumAmount;
  final List<String>? emailRestrictions;

  UpdateCouponData({
    this.code,
    this.discountType,
    this.amount,
    this.status,
    this.description,
    this.dateExpires,
    this.usageLimit,
    this.usageLimitPerUser,
    this.limitUsageToXItems,
    this.freeShipping,
    this.productIds,
    this.excludedProductIds,
    this.productCategories,
    this.excludedProductCategories,
    this.excludeSaleItems,
    this.minimumAmount,
    this.maximumAmount,
    this.emailRestrictions,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (code != null) json['code'] = code;
    if (discountType != null) json['discount_type'] = discountType;
    if (amount != null) json['amount'] = amount;
    if (status != null) json['status'] = status;
    if (description != null) json['description'] = description;
    if (dateExpires != null) json['date_expires'] = dateExpires!.toIso8601String();
    if (usageLimit != null) json['usage_limit'] = usageLimit;
    if (usageLimitPerUser != null) json['usage_limit_per_user'] = usageLimitPerUser;
    if (limitUsageToXItems != null) json['limit_usage_to_x_items'] = limitUsageToXItems;
    if (freeShipping != null) json['free_shipping'] = freeShipping;
    if (productIds != null) json['product_ids'] = productIds;
    if (excludedProductIds != null) json['excluded_product_ids'] = excludedProductIds;
    if (productCategories != null) json['product_categories'] = productCategories;
    if (excludedProductCategories != null) json['excluded_product_categories'] = excludedProductCategories;
    if (excludeSaleItems != null) json['exclude_sale_items'] = excludeSaleItems;
    if (minimumAmount != null) json['minimum_amount'] = minimumAmount;
    if (maximumAmount != null) json['maximum_amount'] = maximumAmount;
    if (emailRestrictions != null) json['email_restrictions'] = emailRestrictions;

    return json;
  }
}

/// Modello per un coupon WooCommerce.
class WooCoupon {
  final int id;
  final String code;
  final String amount;
  final String status;
  final String discountType;
  final String description;
  final DateTime? dateExpires;
  final DateTime dateCreated;
  final DateTime dateModified;
  final int usageCount;
  final bool individualUse;
  final List<int> productIds;
  final List<int> excludedProductIds;
  final int? usageLimit;
  final int? usageLimitPerUser;
  final int? limitUsageToXItems;
  final bool freeShipping;
  final List<int> productCategories;
  final List<int> excludedProductCategories;
  final bool excludeSaleItems;
  final String? minimumAmount;
  final String? maximumAmount;
  final List<String> emailRestrictions;

  WooCoupon({
    required this.id,
    required this.code,
    required this.amount,
    required this.status,
    required this.discountType,
    required this.description,
    this.dateExpires,
    required this.dateCreated,
    required this.dateModified,
    required this.usageCount,
    required this.individualUse,
    required this.productIds,
    required this.excludedProductIds,
    this.usageLimit,
    this.usageLimitPerUser,
    this.limitUsageToXItems,
    required this.freeShipping,
    required this.productCategories,
    required this.excludedProductCategories,
    required this.excludeSaleItems,
    this.minimumAmount,
    this.maximumAmount,
    required this.emailRestrictions,
  });

  factory WooCoupon.fromJson(Map<String, dynamic> json) {
    return WooCoupon(
      id: json['id'],
      code: json['code'] ?? '',
      amount: json['amount'] ?? '0',
      status: json['status'] ?? 'draft',
      discountType: json['discount_type'] ?? 'fixed_cart',
      description: json['description'] ?? '',
      dateExpires: json['date_expires'] != null ? DateTime.tryParse(json['date_expires']) : null,
      dateCreated: DateTime.parse(json['date_created_gmt']),
      dateModified: DateTime.parse(json['date_modified_gmt']),
      usageCount: json['usage_count'] ?? 0,
      individualUse: json['individual_use'] ?? false,
      productIds: (json['product_ids'] as List<dynamic>?)?.cast<int>() ?? [],
      excludedProductIds: (json['excluded_product_ids'] as List<dynamic>?)?.cast<int>() ?? [],
      usageLimit: json['usage_limit'],
      usageLimitPerUser: json['usage_limit_per_user'],
      limitUsageToXItems: json['limit_usage_to_x_items'],
      freeShipping: json['free_shipping'] ?? false,
      productCategories: (json['product_categories'] as List<dynamic>?)?.cast<int>() ?? [],
      excludedProductCategories: (json['excluded_product_categories'] as List<dynamic>?)?.cast<int>() ?? [],
      excludeSaleItems: json['exclude_sale_items'] ?? false,
      minimumAmount: json['minimum_amount'],
      maximumAmount: json['maximum_amount'],
      emailRestrictions: (json['email_restrictions'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Modello per la validazione di un coupon.
class CouponValidation {
  final bool isValid;
  final String? errorMessage;
  final WooCoupon? coupon;
  final String? discountAmount;

  CouponValidation({
    required this.isValid,
    this.errorMessage,
    this.coupon,
    this.discountAmount,
  });
}

/// Modello per le statistiche dei coupon.
class CouponStats {
  final int totalCoupons;
  final int activeCoupons;
  final int totalUsage;
  final String totalDiscount;
  final String period;

  CouponStats({
    required this.totalCoupons,
    required this.activeCoupons,
    required this.totalUsage,
    required this.totalDiscount,
    required this.period,
  });
}

/// Servizio principale per aggregare tutti i servizi coupon
class CouponsService {
  final JwtConnect _jwt;
  
  late final CouponManagementService couponManagementService;

  CouponsService(this._jwt) {
    couponManagementService = CouponManagementService(_jwt);
  }
}