import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../jwt_connect.dart';
import '../error_list.dart';

/// Query class per la gestione dei coupon/codici sconto WooCommerce
/// Utilizza JwtConnect per l'autenticazione centralizzata
class WooQueryCoupon {
  // Singleton pattern
  static final WooQueryCoupon _instance = WooQueryCoupon._internal();
  factory WooQueryCoupon() => _instance;
  WooQueryCoupon._internal();

  final JwtConnect _auth = JwtConnect();
  WooCommerce? _woo;

  /// Ottiene l'istanza WooCommerce con autenticazione JWT
  WooCommerce _getWooCommerce() {
    if (!_auth.isConnected) {
      throw UnauthorizedException();
    }

    if (_woo != null) return _woo!;

    _woo = WooCommerce(
      baseUrl: _auth.currentSiteUrl!,
      username: '',
      password: '',
      useFaker: false,
      isDebug: false,
    );

    // Usa il Dio autenticato di JwtConnect
    _woo!.dio = _auth.getAuthenticatedDio();
    return _woo!;
  }

  /// Reset dell'istanza WooCommerce (utile dopo logout)
  void reset() {
    _woo = null;
  }

  /// Ottiene lista coupon con paginazione e filtri
  Future<List<WooCoupon>> getCoupons({
    int page = 1,
    int perPage = 20,
    String? search,
    String? code,
  }) async {
    final woo = _getWooCommerce();

    return await woo.getCoupons(
      page: page,
      perPage: perPage,
      search: search,
      code: code,
    );
  }

  /// Ottiene un coupon specifico per ID
  Future<WooCoupon> getCouponById(int couponId) async {
    final woo = _getWooCommerce();
    return await woo.getCoupon(couponId);
  }

  /// Ottiene coupon per codice
  Future<WooCoupon> getCouponByCode(String code) async {
    final woo = _getWooCommerce();
    final coupons = await woo.getCoupons(
      code: code,
      perPage: 1,
    );

    if (coupons.isEmpty) {
      throw Exception('WooCoupon non trovato');
    }

    return coupons.first;
  }

  /// Crea un nuovo coupon
  Future<WooCoupon> createCoupon({
    required String code,
    String? discountType,
    String? amount,
    bool? individualUse,
    bool? excludeSaleItems,
    String? minimumAmount,
    String? maximumAmount,
    List<int>? productIds,
    List<int>? excludedProductIds,
    int? usageLimit,
    int? usageLimitPerUser,
    int? limitUsageToXItems,
    DateTime? dateExpires,
    List<WooMetaData>? metaData,
  }) async {
    final woo = _getWooCommerce();

    final coupon = WooCoupon(
      code: code,
      discountType: discountType,
      amount: amount,
      individualUse: individualUse,
      excludeSaleItems: excludeSaleItems,
      minimumAmount: minimumAmount,
      maximumAmount: maximumAmount,
      productIds: productIds,
      excludedProductIds: excludedProductIds,
      usageLimit: usageLimit,
      usageLimitPerUser: usageLimitPerUser,
      limitUsageToXItems: limitUsageToXItems,
      dateExpires: dateExpires,
      metaData: metaData,
    );

    return await woo.createCoupon(coupon);
  }

  /// Aggiorna un coupon esistente
  Future<WooCoupon> updateCoupon({
    required int couponId,
    String? code,
    String? discountType,
    String? amount,
    bool? individualUse,
    bool? excludeSaleItems,
    String? minimumAmount,
    String? maximumAmount,
    List<int>? productIds,
    List<int>? excludedProductIds,
    int? usageLimit,
    int? usageLimitPerUser,
    DateTime? dateExpires,
    List<WooMetaData>? metaData,
  }) async {
    final woo = _getWooCommerce();

    // Prima ottieni il coupon esistente
    final existingCoupon = await woo.getCoupon(couponId);

    // Crea un nuovo coupon con i campi aggiornati
    final updatedCoupon = WooCoupon(
      id: couponId,
      code: code ?? existingCoupon.code,
      discountType: discountType ?? existingCoupon.discountType,
      amount: amount ?? existingCoupon.amount,
      individualUse: individualUse ?? existingCoupon.individualUse,
      excludeSaleItems: excludeSaleItems ?? existingCoupon.excludeSaleItems,
      minimumAmount: minimumAmount ?? existingCoupon.minimumAmount,
      maximumAmount: maximumAmount ?? existingCoupon.maximumAmount,
      productIds: productIds ?? existingCoupon.productIds,
      excludedProductIds: excludedProductIds ?? existingCoupon.excludedProductIds,
      usageLimit: usageLimit ?? existingCoupon.usageLimit,
      usageLimitPerUser: usageLimitPerUser ?? existingCoupon.usageLimitPerUser,
      dateExpires: dateExpires ?? existingCoupon.dateExpires,
      metaData: metaData ?? existingCoupon.metaData,
    );

    return await woo.updateCoupon(updatedCoupon);
  }

  /// Elimina un coupon
  Future<bool> deleteCoupon({
    required int couponId,
    bool force = false,
  }) async {
    final woo = _getWooCommerce();
    return await woo.deleteCoupon(couponId, force: force);
  }

  /// Ottiene tutti i coupon (uso con cautela!)
  Future<List<WooCoupon>> getAllCoupons() async {
    final woo = _getWooCommerce();
    final List<WooCoupon> allCoupons = [];
    int currentPage = 1;
    bool hasMore = true;

    while (hasMore) {
      final coupons = await woo.getCoupons(
        page: currentPage,
        perPage: 100,
      );

      if (coupons.isEmpty) {
        hasMore = false;
      } else {
        allCoupons.addAll(coupons);
        currentPage++;
      }
    }

    return allCoupons;
  }

  /// Batch update coupon (usa Dio diretto)
  Future<Map<String, dynamic>> batchUpdateCoupons({
    List<Map<String, dynamic>>? create,
    List<Map<String, dynamic>>? update,
    List<int>? delete,
  }) async {
    final batchData = {
      if (create != null && create.isNotEmpty) 'create': create,
      if (update != null && update.isNotEmpty) 'update': update,
      if (delete != null && delete.isNotEmpty) 'delete': delete,
    };

    final response = await _auth.getAuthenticatedDio().post(
      '${_auth.currentSiteUrl}/wp-json/wc/v3/coupons/batch',
      data: batchData,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Verifica validità coupon
  Future<Map<String, dynamic>> validateCoupon(
    String code, {
    List<int>? productIds,
    double? cartTotal,
  }) async {
    try {
      final coupon = await getCouponByCode(code);

      // Controlla se il coupon è valido
      final now = DateTime.now();
      final dateExpires = coupon.dateExpires;

      final isExpired = dateExpires != null && dateExpires.isBefore(now);
      final usageLimit = coupon.usageLimit;
      final usageCount = coupon.usageCount ?? 0;
      final isLimitReached = usageLimit != null && usageCount >= usageLimit;

      final minimumAmount = coupon.minimumAmount != null
        ? double.tryParse(coupon.minimumAmount!)
        : null;
      final meetsMinimum = minimumAmount == null ||
        (cartTotal != null && cartTotal >= minimumAmount);

      return {
        'valid': !isExpired && !isLimitReached && meetsMinimum,
        'coupon': coupon,
        'expired': isExpired,
        'limit_reached': isLimitReached,
        'meets_minimum': meetsMinimum,
        'discount_type': coupon.discountType,
        'amount': coupon.amount,
      };
    } catch (e) {
      throw Exception('Errore nella validazione coupon: $e');
    }
  }

  /// Ottiene statistiche utilizzo coupon
  Future<Map<String, dynamic>> getCouponStats(int couponId) async {
    final coupon = await getCouponById(couponId);

    return {
      'coupon_id': couponId,
      'code': coupon.code,
      'usage_count': coupon.usageCount ?? 0,
      'usage_limit': coupon.usageLimit,
      'usage_limit_per_user': coupon.usageLimitPerUser,
      'discount_type': coupon.discountType,
      'amount': coupon.amount,
      'date_expires': coupon.dateExpires,
      'minimum_amount': coupon.minimumAmount,
      'maximum_amount': coupon.maximumAmount,
    };
  }

  /// Verifica se codice coupon esiste già
  Future<bool> couponCodeExists(String code) async {
    try {
      await getCouponByCode(code);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene coupon attivi (non scaduti)
  Future<List<WooCoupon>> getActiveCoupons({int page = 1, int perPage = 100}) async {
    final allCoupons = await getCoupons(page: page, perPage: perPage);
    final now = DateTime.now();

    return allCoupons.where((coupon) {
      if (coupon.dateExpires == null) return true;
      return coupon.dateExpires!.isAfter(now);
    }).toList();
  }

  /// Ottiene coupon scaduti
  Future<List<WooCoupon>> getExpiredCoupons() async {
    final allCoupons = await getAllCoupons();
    final now = DateTime.now();

    return allCoupons.where((coupon) {
      if (coupon.dateExpires == null) return false;
      return coupon.dateExpires!.isBefore(now);
    }).toList();
  }

  /// Ottiene coupon con limite di utilizzo raggiunto
  Future<List<WooCoupon>> getFullyUsedCoupons() async {
    final allCoupons = await getAllCoupons();

    return allCoupons.where((coupon) {
      if (coupon.usageLimit == null) return false;
      return (coupon.usageCount ?? 0) >= coupon.usageLimit!;
    }).toList();
  }

  /// Cerca coupon per codice parziale
  Future<List<WooCoupon>> searchCoupons(String searchTerm) async {
    final woo = _getWooCommerce();
    return await woo.getCoupons(
      search: searchTerm,
      perPage: 50,
    );
  }

  /// Ottiene statistiche generali coupon
  Future<Map<String, dynamic>> getAllCouponsStats() async {
    final response = await _auth.getAuthenticatedDio().get(
      '${_auth.currentSiteUrl}/wp-json/wc/v3/coupons',
      queryParameters: {'per_page': 1, 'page': 1},
    );

    final totalCoupons = int.tryParse(
      response.headers.value('x-wp-total') ?? '0'
    ) ?? 0;

    final activeCoupons = await getActiveCoupons();
    final expiredCoupons = await getExpiredCoupons();

    return {
      'total_coupons': totalCoupons,
      'active_coupons': activeCoupons.length,
      'expired_coupons': expiredCoupons.length,
    };
  }
}
