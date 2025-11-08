import '../login/jwt_api/query/cupon_query.dart';

/// Modello di visualizzazione per i coupon.
/// Converte i dati WooCommerce in un formato più semplice per la UI.
class CouponDisplay {
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

  CouponDisplay({
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

  /// Crea un CouponDisplay da un WooCoupon
  factory CouponDisplay.fromWooCoupon(WooCoupon woo) {
    return CouponDisplay(
      id: woo.id,
      code: woo.code,
      amount: woo.amount,
      status: woo.status,
      discountType: woo.discountType,
      description: woo.description,
      dateExpires: woo.dateExpires,
      dateCreated: woo.dateCreated,
      dateModified: woo.dateModified,
      usageCount: woo.usageCount,
      individualUse: woo.individualUse,
      productIds: woo.productIds,
      excludedProductIds: woo.excludedProductIds,
      usageLimit: woo.usageLimit,
      usageLimitPerUser: woo.usageLimitPerUser,
      limitUsageToXItems: woo.limitUsageToXItems,
      freeShipping: woo.freeShipping,
      productCategories: woo.productCategories,
      excludedProductCategories: woo.excludedProductCategories,
      excludeSaleItems: woo.excludeSaleItems,
      minimumAmount: woo.minimumAmount,
      maximumAmount: woo.maximumAmount,
      emailRestrictions: woo.emailRestrictions,
    );
  }

  /// Verifica se il coupon è scaduto
  bool get isExpired {
    if (dateExpires == null) return false;
    return DateTime.now().isAfter(dateExpires!);
  }

  /// Verifica se il coupon è attivo
  bool get isActive {
    return status == 'publish' && !isExpired;
  }

  /// Verifica se il coupon ha raggiunto il limite di utilizzi
  bool get hasReachedUsageLimit {
    if (usageLimit == null) return false;
    return usageCount >= usageLimit!;
  }

  /// Calcola la percentuale di utilizzo
  double get usagePercentage {
    if (usageLimit == null || usageLimit == 0) return 0.0;
    return (usageCount / usageLimit!) * 100;
  }

  /// Ottiene il display formattato dello sconto
  String get discountDisplay {
    switch (discountType) {
      case 'percent':
        return '$amount%';
      case 'fixed_cart':
      case 'fixed_product':
        return '€$amount';
      default:
        return amount;
    }
  }

  /// Ottiene il display formattato della data di scadenza
  String get expiryDisplay {
    if (dateExpires == null) return 'Nessuna scadenza';
    if (isExpired) return 'Scaduto il ${_formatDate(dateExpires!)}';
    return _formatDate(dateExpires!);
  }

  /// Ottiene il display formattato del tipo di sconto
  String get discountTypeDisplay {
    switch (discountType) {
      case 'percent':
        return 'Percentuale';
      case 'fixed_cart':
        return 'Fisso Carrello';
      case 'fixed_product':
        return 'Fisso Prodotto';
      default:
        return 'Altro';
    }
  }

  /// Ottiene il display formattato dello status
  String get statusDisplay {
    switch (status) {
      case 'publish':
        return isExpired ? 'Scaduto' : 'Attivo';
      case 'draft':
        return 'Bozza';
      case 'trash':
        return 'Cestino';
      default:
        return status;
    }
  }

  /// Ottiene un sommario del coupon
  String get summary {
    final parts = <String>[
      discountDisplay,
      if (freeShipping) 'Spedizione Gratis',
      if (minimumAmount != null) 'Min €$minimumAmount',
      if (usageLimit != null) 'Max $usageLimit utilizzi',
    ];
    return parts.join(' • ');
  }

  /// Verifica se il coupon è riservato a utenti specifici
  bool get hasEmailRestrictions => emailRestrictions.isNotEmpty;

  /// Verifica se il coupon è applicabile a prodotti specifici
  bool get hasProductRestrictions => productIds.isNotEmpty || excludedProductIds.isNotEmpty;

  /// Verifica se il coupon è applicabile a categorie specifiche
  bool get hasCategoryRestrictions => productCategories.isNotEmpty || excludedProductCategories.isNotEmpty;

  /// Verifica se il coupon ha restrizioni
  bool get hasRestrictions =>
    hasEmailRestrictions ||
    hasProductRestrictions ||
    hasCategoryRestrictions ||
    minimumAmount != null ||
    maximumAmount != null;

  /// Ottiene un elenco delle restrizioni
  List<String> get restrictionsList {
    final restrictions = <String>[];

    if (minimumAmount != null) {
      restrictions.add('Importo minimo: €$minimumAmount');
    }
    if (maximumAmount != null) {
      restrictions.add('Importo massimo: €$maximumAmount');
    }
    if (usageLimit != null) {
      restrictions.add('Limite utilizzi: $usageLimit (usati: $usageCount)');
    }
    if (usageLimitPerUser != null) {
      restrictions.add('Limite per utente: $usageLimitPerUser');
    }
    if (emailRestrictions.isNotEmpty) {
      restrictions.add('Email: ${emailRestrictions.join(", ")}');
    }
    if (productIds.isNotEmpty) {
      restrictions.add('${productIds.length} prodotto/i specifico/i');
    }
    if (excludedProductIds.isNotEmpty) {
      restrictions.add('${excludedProductIds.length} prodotto/i escluso/i');
    }
    if (productCategories.isNotEmpty) {
      restrictions.add('${productCategories.length} categoria/e specifica/che');
    }
    if (excludedProductCategories.isNotEmpty) {
      restrictions.add('${excludedProductCategories.length} categoria/e esclusa/e');
    }
    if (excludeSaleItems) {
      restrictions.add('Esclusi prodotti in saldo');
    }
    if (individualUse) {
      restrictions.add('Uso individuale (non combinabile)');
    }
    if (freeShipping) {
      restrictions.add('Include spedizione gratuita');
    }

    return restrictions;
  }

  /// Formatta una data
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Crea una copia del coupon con modifiche
  CouponDisplay copyWith({
    String? code,
    String? amount,
    String? status,
    String? discountType,
    String? description,
    DateTime? dateExpires,
    int? usageCount,
    bool? individualUse,
    List<int>? productIds,
    List<int>? excludedProductIds,
    int? usageLimit,
    int? usageLimitPerUser,
    int? limitUsageToXItems,
    bool? freeShipping,
    List<int>? productCategories,
    List<int>? excludedProductCategories,
    bool? excludeSaleItems,
    String? minimumAmount,
    String? maximumAmount,
    List<String>? emailRestrictions,
  }) {
    return CouponDisplay(
      id: id,
      code: code ?? this.code,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      discountType: discountType ?? this.discountType,
      description: description ?? this.description,
      dateExpires: dateExpires ?? this.dateExpires,
      dateCreated: dateCreated,
      dateModified: DateTime.now(),
      usageCount: usageCount ?? this.usageCount,
      individualUse: individualUse ?? this.individualUse,
      productIds: productIds ?? this.productIds,
      excludedProductIds: excludedProductIds ?? this.excludedProductIds,
      usageLimit: usageLimit ?? this.usageLimit,
      usageLimitPerUser: usageLimitPerUser ?? this.usageLimitPerUser,
      limitUsageToXItems: limitUsageToXItems ?? this.limitUsageToXItems,
      freeShipping: freeShipping ?? this.freeShipping,
      productCategories: productCategories ?? this.productCategories,
      excludedProductCategories: excludedProductCategories ?? this.excludedProductCategories,
      excludeSaleItems: excludeSaleItems ?? this.excludeSaleItems,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumAmount: maximumAmount ?? this.maximumAmount,
      emailRestrictions: emailRestrictions ?? this.emailRestrictions,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is CouponDisplay &&
    runtimeType == other.runtimeType &&
    id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CouponDisplay(id: $id, code: $code, discount: $discountDisplay, status: $statusDisplay)';
}

/// Modello di visualizzazione per le statistiche dei coupon
class CouponStatsDisplay {
  final int totalCoupons;
  final int activeCoupons;
  final int totalUsage;
  final String totalDiscount;
  final String period;

  CouponStatsDisplay({
    required this.totalCoupons,
    required this.activeCoupons,
    required this.totalUsage,
    required this.totalDiscount,
    required this.period,
  });

  /// Crea un CouponStatsDisplay da CouponStats
  factory CouponStatsDisplay.fromCouponStats(CouponStats stats) {
    return CouponStatsDisplay(
      totalCoupons: stats.totalCoupons,
      activeCoupons: stats.activeCoupons,
      totalUsage: stats.totalUsage,
      totalDiscount: stats.totalDiscount,
      period: stats.period,
    );
  }

  /// Calcola la percentuale di coupon attivi
  double get activePercentage {
    if (totalCoupons == 0) return 0.0;
    return (activeCoupons / totalCoupons) * 100;
  }

  /// Calcola la media di utilizzi per coupon
  double get averageUsagePerCoupon {
    if (activeCoupons == 0) return 0.0;
    return totalUsage / activeCoupons;
  }

  /// Ottiene il display formattato dello sconto totale
  String get totalDiscountFormatted => '€$totalDiscount';

  /// Ottiene il display formattato del periodo
  String get periodDisplay {
    switch (period) {
      case 'month':
        return 'Mese corrente';
      case 'year':
        return 'Anno corrente';
      case 'all':
        return 'Tutto il tempo';
      default:
        return period;
    }
  }

  @override
  String toString() =>
    'CouponStatsDisplay(total: $totalCoupons, active: $activeCoupons, usage: $totalUsage, discount: $totalDiscountFormatted)';
}

/// Enum per i tipi di sconto
enum DiscountType {
  percent('percent', 'Percentuale', '%'),
  fixedCart('fixed_cart', 'Fisso Carrello', '€'),
  fixedProduct('fixed_product', 'Fisso Prodotto', '€');

  final String value;
  final String label;
  final String symbol;

  const DiscountType(this.value, this.label, this.symbol);

  static DiscountType fromValue(String value) {
    return DiscountType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DiscountType.percent,
    );
  }

  @override
  String toString() => label;
}

/// Enum per gli status dei coupon
enum CouponStatus {
  publish('publish', 'Pubblicato'),
  draft('draft', 'Bozza'),
  trash('trash', 'Cestino');

  final String value;
  final String label;

  const CouponStatus(this.value, this.label);

  static CouponStatus fromValue(String value) {
    return CouponStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CouponStatus.draft,
    );
  }

  @override
  String toString() => label;
}

/// Helper per formattare i valori dei coupon
class CouponFormatter {
  /// Formatta un importo in euro
  static String formatAmount(String amount) {
    final value = double.tryParse(amount) ?? 0.0;
    return '€${value.toStringAsFixed(2)}';
  }

  /// Formatta una percentuale
  static String formatPercentage(String amount) {
    return '$amount%';
  }

  /// Formatta lo sconto in base al tipo
  static String formatDiscount(String amount, String discountType) {
    switch (discountType) {
      case 'percent':
        return formatPercentage(amount);
      case 'fixed_cart':
      case 'fixed_product':
        return formatAmount(amount);
      default:
        return amount;
    }
  }

  /// Formatta una data
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formatta una data con ora
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Calcola i giorni rimanenti fino alla scadenza
  static int daysUntilExpiry(DateTime expiryDate) {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  /// Ottiene un messaggio per i giorni rimanenti
  static String expiryMessage(DateTime? expiryDate) {
    if (expiryDate == null) return 'Nessuna scadenza';

    final days = daysUntilExpiry(expiryDate);

    if (days < 0) return 'Scaduto ${-days} giorni fa';
    if (days == 0) return 'Scade oggi';
    if (days == 1) return 'Scade domani';
    if (days < 7) return 'Scade tra $days giorni';
    if (days < 30) return 'Scade tra ${(days / 7).floor()} settimane';
    return 'Scade tra ${(days / 30).floor()} mesi';
  }
}

/// Helper per validare i dati dei coupon
class CouponValidator {
  /// Valida il codice coupon
  static String? validateCode(String? code) {
    if (code == null || code.isEmpty) {
      return 'Il codice coupon è obbligatorio';
    }
    if (code.length < 3) {
      return 'Il codice deve contenere almeno 3 caratteri';
    }
    if (code.length > 50) {
      return 'Il codice non può superare 50 caratteri';
    }
    if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(code)) {
      return 'Il codice può contenere solo lettere maiuscole, numeri, trattini e underscore';
    }
    return null;
  }

  /// Valida l'importo dello sconto
  static String? validateAmount(String? amount, String discountType) {
    if (amount == null || amount.isEmpty) {
      return 'L\'importo è obbligatorio';
    }

    final value = double.tryParse(amount);
    if (value == null) {
      return 'Importo non valido';
    }

    if (value <= 0) {
      return 'L\'importo deve essere maggiore di 0';
    }

    if (discountType == 'percent' && value > 100) {
      return 'La percentuale non può superare 100%';
    }

    return null;
  }

  /// Valida l'importo minimo
  static String? validateMinimumAmount(String? minimum, String? maximum) {
    if (minimum == null || minimum.isEmpty) return null;

    final minValue = double.tryParse(minimum);
    if (minValue == null) {
      return 'Importo minimo non valido';
    }

    if (minValue < 0) {
      return 'L\'importo minimo non può essere negativo';
    }

    if (maximum != null && maximum.isNotEmpty) {
      final maxValue = double.tryParse(maximum);
      if (maxValue != null && minValue > maxValue) {
        return 'L\'importo minimo non può essere maggiore del massimo';
      }
    }

    return null;
  }

  /// Valida l'importo massimo
  static String? validateMaximumAmount(String? maximum, String? minimum) {
    if (maximum == null || maximum.isEmpty) return null;

    final maxValue = double.tryParse(maximum);
    if (maxValue == null) {
      return 'Importo massimo non valido';
    }

    if (maxValue < 0) {
      return 'L\'importo massimo non può essere negativo';
    }

    if (minimum != null && minimum.isNotEmpty) {
      final minValue = double.tryParse(minimum);
      if (minValue != null && maxValue < minValue) {
        return 'L\'importo massimo non può essere minore del minimo';
      }
    }

    return null;
  }

  /// Valida il limite di utilizzi
  static String? validateUsageLimit(String? limit) {
    if (limit == null || limit.isEmpty) return null;

    final value = int.tryParse(limit);
    if (value == null) {
      return 'Limite non valido';
    }

    if (value < 1) {
      return 'Il limite deve essere almeno 1';
    }

    return null;
  }

  /// Valida la data di scadenza
  static String? validateExpiryDate(DateTime? date) {
    if (date == null) return null;

    if (date.isBefore(DateTime.now())) {
      return 'La data di scadenza non può essere nel passato';
    }

    return null;
  }

  /// Valida un indirizzo email
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return null;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Indirizzo email non valido';
    }

    return null;
  }
}
