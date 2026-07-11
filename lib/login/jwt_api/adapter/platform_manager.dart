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
import '../query_mgws/query_mgws_pos.dart';
import '../query_wordpress/query_user_wordpress.dart';
import '../woo_connect.dart';
import 'loyalty_gateway.dart';

/// Manager centrale per il perimetro WordPress ammesso dall'app.
///
/// L'app consuma WooCommerce direttamente per le sue API e MGWS per funzioni
/// native custom come loyalty e inventario. Non sono previsti provider esterni
/// o failback lato app.
class PlatformManager {
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
  static LoyaltyGateway? _loyaltyGateway;
  static QueryMgwsPos? _mgwsPos;
  static QueryUserWordPress? _wordpress_user;

  /// Ottiene la piattaforma attualmente attiva
  static PlatformType get currentPlatform => PlatformType.woocommerce;

  /// Nome della piattaforma corrente
  static String get platformName => PlatformType.woocommerce.name;

  /// Verifica se la connessione è pronta
  static bool get isReady => WooConnect().isReady;

  /// Compatibilita API: l'unica piattaforma ammessa lato app e WooCommerce.
  static void setPlatform(PlatformType platform) {}

  /// Reset alla piattaforma predefinita (WooCommerce)
  static void reset() {}

  // =========================================================================
  // ==                         QUERY ACCESSORS                             ==
  // =========================================================================

  /// Query Prodotti per la piattaforma corrente
  static dynamic get prodotti {
    _wooProdotti ??= WooQueryProdotti();
    return _wooProdotti;
  }

  /// Query Categorie per la piattaforma corrente
  static dynamic get categorie {
    _wooCategorie ??= WooQueryCategoria();
    return _wooCategorie;
  }

  /// Query Tag per la piattaforma corrente
  static dynamic get tag {
    _wooTag ??= WooQueryTag();
    return _wooTag;
  }

  /// Query Marchi per la piattaforma corrente
  static dynamic get marchi {
    _wooMarchi ??= WooQueryMarchi();
    return _wooMarchi;
  }

  /// Query Coupon per la piattaforma corrente
  static dynamic get coupon {
    _wooCoupon ??= WooQueryCoupon();
    return _wooCoupon;
  }

  /// Query Clienti per la piattaforma corrente
  static dynamic get clienti {
    _wooClienti ??= WooQueryClienti();
    return _wooClienti;
  }

  /// Query Ordini per la piattaforma corrente
  static dynamic get ordini {
    _wooOrdini ??= WooQueryOrdini();
    return _wooOrdini;
  }

  /// Query Varianti per la piattaforma corrente
  static dynamic get varianti {
    _wooVarianti ??= WooQueryVarianti();
    return _wooVarianti;
  }

  /// Query Attributi per la piattaforma corrente
  static dynamic get attributi {
    _wooAttributi ??= WooQueryAttributi();
    return _wooAttributi;
  }

  /// Query Media per la piattaforma corrente
  static dynamic get media {
    _wooMedia ??= WooQueryMedia();
    return _wooMedia;
  }

  /// Query Report per la piattaforma corrente
  static dynamic get report {
    _wooReport ??= WooQueryReport();
    return _wooReport;
  }

  /// Query Batch per la piattaforma corrente
  static dynamic get batch {
    _wooBatch ??= WooQueryBatch();
    return _wooBatch;
  }

  // =========================================================================
  // ==                         METADATA HELPERS                             ==
  // =========================================================================

  /// Aggiorna i metadata di un prodotto
  static Future<bool> updateProductMetadata(
    int productId,
    Map<String, dynamic> metadata,
  ) async {
    final prodotti = PlatformManager.prodotti;
    return await prodotti.updateProductMetadata(productId, metadata);
  }

  /// Recupera i metadata di un prodotto
  static Future<Map<String, String>> getProductMetadata(int productId) async {
    final prodotti = PlatformManager.prodotti;
    return await prodotti.getProductMetadata(productId);
  }

  /// Recupera i metadata di una variante prodotto per la piattaforma corrente
  static Future<Map<String, String>> getProductVariationMetadata(
    int productId,
    int variationId,
  ) async {
    final varianti = PlatformManager.varianti;
    return await varianti.getProductVariationMetadata(productId, variationId);
  }

  /// Query Carta Fedeltà via MGWS per la piattaforma corrente
  static dynamic get cartaFedelta {
    _loyaltyGateway ??= LoyaltyGateway();
    return _loyaltyGateway;
  }

  /// Checkout POS via MGWS.
  static dynamic get pos {
    _mgwsPos ??= QueryMgwsPos();
    return _mgwsPos;
  }

  // =========================================================================
  // ==                        GESTIONE UTENTI                              ==
  // =========================================================================

  /// Query Utenti per la piattaforma corrente
  static dynamic get utenti {
    _wordpress_user ??= QueryUserWordPress();
    return _wordpress_user;
  }
}

/// Enum per le piattaforme e-commerce supportate
enum PlatformType { woocommerce }
