// Query WooCommerce - PRODOTTI
//
// Gestisce tutte le operazioni sui prodotti usando woocommerce_flutter_api
// L'autenticazione è gestita centralmente da JwtConnect
// Converte i dati WooCommerce in modelli globali multi-piattaforma

import 'package:dio/dio.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../jwt_connect.dart';
import '../error_list.dart';
import '../../../prodotti/class_prodotti.dart';
import '../../../log_viewer/app_logger.dart';

/// Filtri per la ricerca prodotti
class ProductFilters {
  final String? search;
  final int? category;
  final String? tag;
  final String? sku;
  final WooFilterStatus? status;
  final String? stockStatus;
  final bool? featured;
  final String? orderBy;
  final String? order;

  ProductFilters({
    this.search,
    this.category,
    this.tag,
    this.sku,
    this.status,
    this.stockStatus,
    this.featured,
    this.orderBy,
    this.order,
  });
}

/// Service per gestire i prodotti WooCommerce
class WooQueryProdotti {
  // Singleton
  static final WooQueryProdotti _instance = WooQueryProdotti._internal();
  factory WooQueryProdotti() => _instance;
  WooQueryProdotti._internal();

  final JwtConnect _auth = JwtConnect();
  WooCommerce? _woo;

  /// Inizializza WooCommerce con JWT authentication
  /// Usa il plugin ma con JWT invece di Basic Auth
  WooCommerce _getWooCommerce() {
    if (!_auth.isConnected) {
      throw UnauthorizedException();
    }

    if (_woo != null) return _woo!;

    log.d('🔧 Inizializzazione WooCommerce con JWT Bearer Token');

    // Crea WooCommerce con JWT Bearer token
    // Usa /wp-json/wc/v3 come formato standard (non /?rest_route=)
    _woo = WooCommerce(
      baseUrl: _auth.currentSiteUrl!,  // Es. http://localhost:8080
      username: '', // Vuoto - usiamo JWT non Basic Auth
      password: '', // Vuoto - usiamo JWT non Basic Auth
      apiPath: '/wp-json/wc/v3',  // Path standard WooCommerce REST API
      isDebug: true,
      interceptors: [
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Sostituisci Basic Auth con JWT Bearer token
            final token = _auth.session?.token;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              log.d('🔑 JWT Bearer token aggiunto alla richiesta');
            }

            log.d('🌐 Richiesta: ${options.method} ${options.uri}');
            return handler.next(options);
          },
          onError: (error, handler) {
            log.e('❌ Errore API: ${error.response?.statusCode} - ${error.message}');
            return handler.next(error);
          },
        ),
      ],
    );

    log.i('✅ WooCommerce inizializzato con JWT Bearer Token');
    return _woo!;
  }

  /// Reset dell'istanza (utile dopo logout)
  void reset() {
    _woo = null;
  }

  /// Test connessione WooCommerce API
  Future<bool> testConnection() async {
    try {
      log.d('🔍 Testing WooCommerce connection');

      final woo = _getWooCommerce();

      // Testa la connessione provando a leggere i prodotti (max 1)
      await woo.getProducts(perPage: 1);

      log.d('✅ WooCommerce API is accessible');
      return true;
    } catch (e) {
      log.d('❌ WooCommerce API test failed: $e');
      return false;
    }
  }

  // =======================================================
  // == CONVERSIONE WOOCOMMERCE → MODELLO GLOBALE        ==
  // =======================================================

  /// Converte WooProduct in ProdottoWoo (modello globale)
  ProdottoWoo _convertToProdottoWoo(WooProduct wooProduct) {
    // Helper per gestire stringhe vuote e null
    String? handleEmptyString(String? value) {
      if (value == null || value.isEmpty) return null;
      return value;
    }

    log.d('🔄 Conversione prodotto ID: ${wooProduct.id}, Nome: ${wooProduct.name}');
    log.d('   Weight type: ${wooProduct.weight.runtimeType}, value: "${wooProduct.weight}"');
    log.d('   Description type: ${wooProduct.description.runtimeType}, value: "${wooProduct.description}"');

    return ProdottoWoo(
      id: wooProduct.id ?? 0,
      nome: wooProduct.name ?? '',
      sku: wooProduct.sku ?? '',
      prezzoNormale: wooProduct.regularPrice ?? 0.0,
      prezzoScontato: wooProduct.salePrice,
      descrizioneBreve: wooProduct.shortDescription ?? '',
      descrizioneCompleta: handleEmptyString(wooProduct.description),
      immagineUrl: wooProduct.images.isNotEmpty
          ? wooProduct.images.first.src ?? ''
          : '',
      immaginiAggiuntive: wooProduct.images.skip(1).map((img) => img.src ?? '').toList(),
      categoria: wooProduct.categories.isNotEmpty
          ? wooProduct.categories.first.name ?? 'Senza categoria'
          : 'Senza categoria',
      tag: wooProduct.tags.map((tag) => tag.name ?? '').toList(),
      inStock: wooProduct.stockStatus?.name == 'instock',
      quantitaTotale: wooProduct.stockQuantity,
      peso: handleEmptyString(wooProduct.weight),
      dimensioni: wooProduct.dimensions != null &&
              ((wooProduct.dimensions!.length?.isNotEmpty ?? false) ||
               (wooProduct.dimensions!.width?.isNotEmpty ?? false) ||
               (wooProduct.dimensions!.height?.isNotEmpty ?? false))
          ? DimensioniProdotto(
              lunghezza: double.tryParse(wooProduct.dimensions!.length ?? '') ?? 0.0,
              larghezza: double.tryParse(wooProduct.dimensions!.width ?? '') ?? 0.0,
              altezza: double.tryParse(wooProduct.dimensions!.height ?? '') ?? 0.0,
            )
          : null,
      dataCreazione: wooProduct.dateCreated,
      dataModifica: wooProduct.dateModified,
      status: wooProduct.status?.name ?? 'draft',
      varianti: [], // Le varianti vengono caricate separatamente se necessario
    );
  }

  /// Converte ProdottoWoo in Map per API WooCommerce
  Map<String, dynamic> _convertToWooProductData(ProdottoWoo prodotto) {
    final data = <String, dynamic>{
      'name': prodotto.nome,
      'type': prodotto.varianti.isEmpty ? 'simple' : 'variable',
      'sku': prodotto.sku.isNotEmpty ? prodotto.sku : null,
      'regular_price': prodotto.prezzoNormale.toString(),
      'short_description': prodotto.descrizioneBreve,
      'status': prodotto.status.isNotEmpty ? prodotto.status : 'draft',
      'manage_stock': true,
      'stock_status': prodotto.inStock ? 'instock' : 'outofstock',
    };

    // Prezzo scontato (opzionale)
    if (prodotto.prezzoScontato != null && prodotto.prezzoScontato! > 0) {
      data['sale_price'] = prodotto.prezzoScontato.toString();
    }

    // Descrizione completa (opzionale)
    if (prodotto.descrizioneCompleta != null && prodotto.descrizioneCompleta!.isNotEmpty) {
      data['description'] = prodotto.descrizioneCompleta;
    }

    // Quantità (opzionale)
    if (prodotto.quantitaTotale != null) {
      data['stock_quantity'] = prodotto.quantitaTotale;
    }

    // Peso (opzionale)
    if (prodotto.peso != null && prodotto.peso!.isNotEmpty) {
      data['weight'] = prodotto.peso;
    }

    // Dimensioni (opzionali)
    if (prodotto.dimensioni != null) {
      data['dimensions'] = {
        'length': prodotto.dimensioni!.lunghezza.toString(),
        'width': prodotto.dimensioni!.larghezza.toString(),
        'height': prodotto.dimensioni!.altezza.toString(),
      };
    }

    // Immagini
    if (prodotto.immagineUrl.isNotEmpty) {
      final images = <Map<String, dynamic>>[];
      images.add({'src': prodotto.immagineUrl, 'position': 0});

      for (int i = 0; i < prodotto.immaginiAggiuntive.length; i++) {
        images.add({'src': prodotto.immaginiAggiuntive[i], 'position': i + 1});
      }

      data['images'] = images;
    }

    // Attributi per prodotti variabili
    if (prodotto.varianti.isNotEmpty) {
      final attributiMap = <String, Set<String>>{};

      // Raccogli tutti gli attributi dalle varianti
      for (final variante in prodotto.varianti) {
        for (final attr in variante.attributi) {
          final nomeKey = attr.nome.toLowerCase();
          if (!attributiMap.containsKey(nomeKey)) {
            attributiMap[nomeKey] = <String>{};
          }
          attributiMap[nomeKey]!.add(attr.opzione);
        }
      }

      // Converti in formato WooCommerce
      data['attributes'] = attributiMap.entries.map((entry) {
        return {
          'name': entry.key.split(' ').map((word) =>
            word[0].toUpperCase() + word.substring(1)
          ).join(' '),
          'visible': true,
          'variation': true,
          'options': entry.value.toList(),
        };
      }).toList();
    }

    return data;
  }

  // =======================================================
  // == METODI PRODOTTI (Restituiscono modello globale)  ==
  // =======================================================

  /// Ottiene lista prodotti con paginazione e filtri
  Future<List<ProdottoWoo>> getProducts({
    int page = 1,
    int perPage = 20,
    ProductFilters? filters,
  }) async {
    try {
      final woo = _getWooCommerce();

      final wooProducts = await woo.getProducts(
        page: page,
        perPage: perPage,
        search: filters?.search,
        category: filters?.category,
        status: filters?.status ?? WooFilterStatus.publish,
      );

      // Converti in modello globale
      final converted = <ProdottoWoo>[];
      for (final wp in wooProducts) {
        try {
          converted.add(_convertToProdottoWoo(wp));
        } catch (e, stack) {
          log.e('❌ Errore conversione prodotto ID ${wp.id} "${wp.name}"', e);
          log.e('   Stack trace:', stack);
          rethrow;
        }
      }
      return converted;
    } catch (e) {
      log.e('❌ Errore getProducts', e);
      rethrow;
    }
  }

  /// Ottiene un singolo prodotto per ID
  Future<ProdottoWoo> getProductById(int productId) async {
    try {
      final woo = _getWooCommerce();
      final wooProduct = await woo.getProduct(productId);
      return _convertToProdottoWoo(wooProduct);
    } catch (e) {
      log.e('❌ Errore getProductById: $productId', e);
      rethrow;
    }
  }

  /// Cerca prodotti per termine
  Future<List<ProdottoWoo>> searchProducts(
    String searchTerm, {
    int limit = 20,
  }) async {
    return await getProducts(
      perPage: limit,
      filters: ProductFilters(search: searchTerm),
    );
  }

  /// Ottiene prodotti per categoria
  Future<List<ProdottoWoo>> getProductsByCategory(
    int categoryId, {
    int limit = 50,
  }) async {
    return await getProducts(
      perPage: limit,
      filters: ProductFilters(category: categoryId),
    );
  }

  /// Ottiene prodotti in esaurimento
  Future<List<ProdottoWoo>> getOutOfStockProducts({int limit = 100}) async {
    return await getProducts(
      perPage: limit,
      filters: ProductFilters(stockStatus: 'outofstock'),
    );
  }

  /// Crea un nuovo prodotto (accetta ProdottoWoo)
  Future<ProdottoWoo> createProduct(ProdottoWoo prodotto) async {
    final woo = _getWooCommerce();
    final productData = _convertToWooProductData(prodotto);

    try {
      log.d('🔵 CREATE PRODUCT - Data: $productData');
      log.d('🔍 TYPE VALUE: ${productData['type']}');
      log.d('🔍 VARIANTI: ${prodotto.varianti.length}');

      // Usa Dio direttamente per evitare problemi con WooProduct.fromJson/toJson
      // Il plugin potrebbe interpretare male alcuni campi quando fa la conversione
      final response = await woo.dio.post(
        '/products',
        data: productData,
      );

      log.i('✅ CREATE PRODUCT - Success: ${response.data['id']}');

      // Converti la risposta in WooProduct poi in ProdottoWoo
      final wooProduct = WooProduct.fromJson(response.data as Map<String, dynamic>);
      return _convertToProdottoWoo(wooProduct);
    } catch (e) {
      if (e is DioException && e.response != null) {
        log.e('❌ Errore createProduct - Status: ${e.response?.statusCode}');
        log.e('❌ Risposta server: ${e.response?.data}');
        log.e('❌ Dati inviati: $productData');
      }
      log.e('❌ Errore createProduct', e);
      rethrow;
    }
  }

  /// Aggiorna un prodotto esistente (accetta ProdottoWoo)
  Future<ProdottoWoo> updateProduct(ProdottoWoo prodotto) async {
    try {
      if (prodotto.id == null) {
        throw Exception('Product ID is required for update');
      }

      final woo = _getWooCommerce();
      final productData = _convertToWooProductData(prodotto);

      log.d('🔵 UPDATE PRODUCT ${prodotto.id} - Data: $productData');

      // Converti i dati in WooProduct e usa il metodo del plugin
      final wooProductInput = WooProduct.fromJson(productData);

      // Usa il metodo updateProduct del plugin
      final wooProduct = await woo.updateProduct(prodotto.id!, wooProductInput);

      log.i('✅ UPDATE PRODUCT - Success: ${wooProduct.id}');

      return _convertToProdottoWoo(wooProduct);
    } catch (e) {
      log.e('❌ Errore updateProduct: ${prodotto.id}', e);
      rethrow;
    }
  }

  /// Elimina un prodotto
  Future<bool> deleteProduct(int productId, {bool force = false}) async {
    try {
      final woo = _getWooCommerce();

      log.d('🔵 DELETE PRODUCT $productId (force: $force)');

      // Usa il metodo deleteProduct del plugin
      await woo.deleteProduct(productId, force: force);

      log.i('✅ DELETE PRODUCT - Success: $productId');

      return true;
    } catch (e) {
      log.e('❌ Errore deleteProduct: $e');
      rethrow;
    }
  }

  /// Aggiorna lo stock di un prodotto
  Future<ProdottoWoo> updateProductStock(
    int productId, {
    required int stockQuantity,
    String? stockStatus,
  }) async {
    try {
      final woo = _getWooCommerce();

      log.d('🔵 UPDATE STOCK - Product $productId: qty=$stockQuantity, status=$stockStatus');

      // Crea un WooProduct parziale con solo i campi stock
      final partialProduct = WooProduct.fromJson({
        'stock_quantity': stockQuantity,
        if (stockStatus != null) 'stock_status': stockStatus,
        'manage_stock': true,
      });

      // Usa il metodo updateProduct del plugin
      final wooProduct = await woo.updateProduct(productId, partialProduct);

      log.i('✅ UPDATE STOCK - Success: ${wooProduct.id}');

      return _convertToProdottoWoo(wooProduct);
    } catch (e) {
      log.e('❌ Errore updateProductStock: $e');
      rethrow;
    }
  }

  /// Operazioni batch sui prodotti (usa Dio del plugin per endpoint non disponibili)
  Future<Map<String, dynamic>> batchUpdateProducts({
    List<Map<String, dynamic>>? create,
    List<Map<String, dynamic>>? update,
    List<int>? delete,
  }) async {
    try {
      final woo = _getWooCommerce();

      final batchData = <String, dynamic>{};
      if (create != null && create.isNotEmpty) batchData['create'] = create;
      if (update != null && update.isNotEmpty) batchData['update'] = update;
      if (delete != null && delete.isNotEmpty) batchData['delete'] = delete;

      if (batchData.isEmpty) {
        throw Exception('Nessuna operazione batch specificata');
      }

      log.d('🔵 BATCH UPDATE - ${batchData.length} operations');

      // Usa il Dio del plugin (ha già JWT configurato)
      final response = await woo.dio.post(
        '/products/batch',
        data: batchData,
      );

      log.i('✅ BATCH UPDATE - Success');

      return response.data as Map<String, dynamic>;
    } catch (e) {
      log.e('❌ Errore batchUpdateProducts: $e');
      rethrow;
    }
  }

  /// Ottiene statistiche rapide sui prodotti
  Future<Map<String, int>> getProductStats() async {
    try {
      final woo = _getWooCommerce();

      // Chiamate parallele per ottenere conteggi
      final futures = await Future.wait([
        _getProductCount(woo, WooFilterStatus.publish),
        _getProductCount(woo, WooFilterStatus.draft),
        _getProductCountByStock(woo, 'outofstock'),
      ]);

      return {
        'total_published': futures[0],
        'total_drafts': futures[1],
        'out_of_stock': futures[2],
      };
    } catch (e) {
      log.d('❌ Errore getProductStats: $e');
      return {
        'total_published': 0,
        'total_drafts': 0,
        'out_of_stock': 0,
      };
    }
  }

  /// Helper: ottiene il conteggio prodotti per stato
  Future<int> _getProductCount(
    WooCommerce woo,
    WooFilterStatus status,
  ) async {
    try {
      // Usa il Dio del plugin (ha già JWT configurato)
      final response = await woo.dio.get(
        '/products',
        queryParameters: {
          'per_page': 1,
          'status': status.toString().split('.').last,
        },
      );

      return int.tryParse(response.headers.value('x-wp-total') ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Helper: ottiene il conteggio prodotti per stock status
  Future<int> _getProductCountByStock(
    WooCommerce woo,
    String stockStatus,
  ) async {
    try {
      // Usa il Dio del plugin (ha già JWT configurato)
      final response = await woo.dio.get(
        '/products',
        queryParameters: {
          'per_page': 1,
          'stock_status': stockStatus,
        },
      );

      return int.tryParse(response.headers.value('x-wp-total') ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Verifica disponibilità del servizio
  Future<bool> isServiceAvailable() async {
    try {
      await getProducts(perPage: 1);
      return true;
    } catch (e) {
      return false;
    }
  }
}
