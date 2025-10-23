import '../query_woocommerce/woo_query_prodotti.dart';
import '../query_woocommerce/woo_query_categoria.dart';
import '../query_woocommerce/woo_query_tag.dart';
import '../query_woocommerce/woo_query_coupon.dart';
import '../query_woocommerce/woo_query_clienti.dart';
import '../query_woocommerce/woo_query_ordini.dart';
import '../query_woocommerce/woo_query_varianti.dart';
import '../query_woocommerce/woo_query_attributi.dart';
import '../query_woocommerce/woo_query_media.dart';
import '../query_woocommerce/woo_query_report.dart';
import '../query_woocommerce/woo_query_batch.dart';

/// Manager centrale per gestire la piattaforma e-commerce attiva
///
/// Esempio d'uso:
/// ```dart
/// // Usa la piattaforma corrente (default: WooCommerce)
/// final products = await PlatformManager.prodotti.getProducts(page: 1, perPage: 20);
/// final categories = await PlatformManager.categorie.getCategories();
///
/// // Cambia piattaforma
/// PlatformManager.setPlatform(PlatformType.shopify);
/// ```
class PlatformManager {
  static PlatformType _currentPlatform = PlatformType.woocommerce;

  // Istanze singleton delle query (lazy initialization)
  static WooQueryProdotti? _wooProdotti;
  static WooQueryCategoria? _wooCategorie;
  static WooQueryTag? _wooTag;
  static WooQueryCoupon? _wooCoupon;
  static WooQueryClienti? _wooClienti;
  static WooQueryOrdini? _wooOrdini;
  static WooQueryVarianti? _wooVarianti;
  static WooQueryAttributi? _wooAttributi;
  static WooQueryMedia? _wooMedia;
  static WooQueryReport? _wooReport;
  static WooQueryBatch? _wooBatch;

  /// Ottiene la piattaforma attualmente attiva
  static PlatformType get currentPlatform => _currentPlatform;

  /// Nome della piattaforma corrente
  static String get platformName => _currentPlatform.name;

  /// Cambia la piattaforma attiva
  static void setPlatform(PlatformType platform) {
    _currentPlatform = platform;
  }

  /// Reset alla piattaforma predefinita (WooCommerce)
  static void reset() {
    _currentPlatform = PlatformType.woocommerce;
  }

  // =========================================================================
  // ==                         QUERY ACCESSORS                             ==
  // =========================================================================

  /// Query Prodotti per la piattaforma corrente
  static dynamic get prodotti {
    switch (platformName) {
      case 'woocommerce':
        _wooProdotti ??= WooQueryProdotti();
        return _wooProdotti;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Categorie per la piattaforma corrente
  static dynamic get categorie {
    switch (platformName) {
      case 'woocommerce':
        _wooCategorie ??= WooQueryCategoria();
        return _wooCategorie;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Tag per la piattaforma corrente
  static dynamic get tag {
    switch (platformName) {
      case 'woocommerce':
        _wooTag ??= WooQueryTag();
        return _wooTag;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Coupon per la piattaforma corrente
  static dynamic get coupon {
    switch (platformName) {
      case 'woocommerce':
        _wooCoupon ??= WooQueryCoupon();
        return _wooCoupon;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Clienti per la piattaforma corrente
  static dynamic get clienti {
    switch (platformName) {
      case 'woocommerce':
        _wooClienti ??= WooQueryClienti();
        return _wooClienti;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Ordini per la piattaforma corrente
  static dynamic get ordini {
    switch (platformName) {
      case 'woocommerce':
        _wooOrdini ??= WooQueryOrdini();
        return _wooOrdini;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Varianti per la piattaforma corrente
  static dynamic get varianti {
    switch (platformName) {
      case 'woocommerce':
        _wooVarianti ??= WooQueryVarianti();
        return _wooVarianti;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Attributi per la piattaforma corrente
  static dynamic get attributi {
    switch (platformName) {
      case 'woocommerce':
        _wooAttributi ??= WooQueryAttributi();
        return _wooAttributi;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Media per la piattaforma corrente
  static dynamic get media {
    switch (platformName) {
      case 'woocommerce':
        _wooMedia ??= WooQueryMedia();
        return _wooMedia;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Report per la piattaforma corrente
  static dynamic get report {
    switch (platformName) {
      case 'woocommerce':
        _wooReport ??= WooQueryReport();
        return _wooReport;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }

  /// Query Batch per la piattaforma corrente
  static dynamic get batch {
    switch (platformName) {
      case 'woocommerce':
        _wooBatch ??= WooQueryBatch();
        return _wooBatch;
      case 'shopify':
        throw UnimplementedError('Shopify non implementato');
      case 'prestashop':
        throw UnimplementedError('PrestaShop non implementato');
      default:
        throw Exception('Piattaforma non supportata: $platformName');
    }
  }
}

/// Enum per le piattaforme e-commerce supportate
enum PlatformType {
  woocommerce,
  shopify,
  prestashop,
}
