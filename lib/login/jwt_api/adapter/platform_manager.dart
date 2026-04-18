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
import '../query_woocommerce/woo_query_marchi.dart';
import '../query_woocommerce/woo_query_mycred_carta_fedelta.dart';
import '../query_wordpress/query_user_wordpress.dart';
import '../woo_connect.dart';

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
  static WooQueryMarchi? _wooMarchi;
  static WooQueryMycredCartaFedelta? _wooCartaFedelta;
  static QueryUserWordPress? _wordpress_user;

  /// Ottiene la piattaforma attualmente attiva
  static PlatformType get currentPlatform => _currentPlatform;

  /// Nome della piattaforma corrente
  static String get platformName => _currentPlatform.name;

  /// Verifica se la connessione è pronta
  static bool get isReady {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        return WooConnect().isReady;
      case PlatformType.shopify:
      case PlatformType.prestashop:
        return false;
    }
  }

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
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooProdotti ??= WooQueryProdotti();
        return _wooProdotti;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Categorie per la piattaforma corrente
  static dynamic get categorie {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooCategorie ??= WooQueryCategoria();
        return _wooCategorie;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Tag per la piattaforma corrente
  static dynamic get tag {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooTag ??= WooQueryTag();
        return _wooTag;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Marchi per la piattaforma corrente
  static dynamic get marchi {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooMarchi ??= WooQueryMarchi();
        return _wooMarchi;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Coupon per la piattaforma corrente
  static dynamic get coupon {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooCoupon ??= WooQueryCoupon();
        return _wooCoupon;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Clienti per la piattaforma corrente
  static dynamic get clienti {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooClienti ??= WooQueryClienti();
        return _wooClienti;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Ordini per la piattaforma corrente
  static dynamic get ordini {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooOrdini ??= WooQueryOrdini();
        return _wooOrdini;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Varianti per la piattaforma corrente
  static dynamic get varianti {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooVarianti ??= WooQueryVarianti();
        return _wooVarianti;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Attributi per la piattaforma corrente
  static dynamic get attributi {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooAttributi ??= WooQueryAttributi();
        return _wooAttributi;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Media per la piattaforma corrente
  static dynamic get media {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooMedia ??= WooQueryMedia();
        return _wooMedia;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Report per la piattaforma corrente
  static dynamic get report {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooReport ??= WooQueryReport();
        return _wooReport;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Batch per la piattaforma corrente
  static dynamic get batch {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooBatch ??= WooQueryBatch();
        return _wooBatch;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  // =========================================================================
  // ==                         METADATA HELPERS                             ==
  // =========================================================================

  /// Aggiorna i metadata di un prodotto
  static Future<bool> updateProductMetadata(
    int productId,
    Map<String, dynamic> metadata,
  ) async {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        final prodotti = PlatformManager.prodotti;
        return await prodotti.updateProductMetadata(productId, metadata);
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Recupera i metadata di un prodotto
  static Future<Map<String, String>> getProductMetadata(int productId) async {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        final prodotti = PlatformManager.prodotti;
        return await prodotti.getProductMetadata(productId);
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Recupera i metadata di una variante prodotto per la piattaforma corrente
  static Future<Map<String, String>> getProductVariationMetadata(
    int productId,
    int variationId,
  ) async {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        final varianti = PlatformManager.varianti;
        return await varianti.getProductVariationMetadata(
          productId,
          variationId,
        );
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  /// Query Carta Fedeltà (myCred) per la piattaforma corrente
  static dynamic get cartaFedelta {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wooCartaFedelta ??= WooQueryMycredCartaFedelta();
        return _wooCartaFedelta;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }

  // =========================================================================
  // ==                        GESTIONE UTENTI                              ==
  // =========================================================================

  /// Query Utenti per la piattaforma corrente
  static dynamic get utenti {
    switch (_currentPlatform) {
      case PlatformType.woocommerce:
        _wordpress_user ??= QueryUserWordPress();
        return _wordpress_user;
      case PlatformType.shopify:
        throw UnimplementedError('Shopify non implementato');
      case PlatformType.prestashop:
        throw UnimplementedError('PrestaShop non implementato');
    }
  }
}

/// Enum per le piattaforme e-commerce supportate
enum PlatformType { woocommerce, shopify, prestashop }
