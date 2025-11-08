// Query WooCommerce - PRODOTTI
//
// Gestisce tutte le operazioni sui prodotti usando woocommerce_flutter_api
// L'autenticazione è gestita centralmente da WooConnect
// Converte i dati WooCommerce in modelli globali multi-piattaforma

import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../woo_connect.dart';
import '../../../prodotti/class_prodotti.dart';
import '../../../log_viewer/app_logger.dart';
import 'woo_query_categoria.dart';
import 'woo_query_tag.dart';

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

  final WooConnect _wooConnect = WooConnect();

  /// Ottiene l'istanza WooCommerce autenticata da WooConnect
  WooCommerce get _woo => _wooConnect.woo;

  // =======================================================
  // == CONVERSIONE WOOCOMMERCE → MODELLO GLOBALE        ==
  // =======================================================

  /// Converte WooProduct in Prodotto globale
  ///
  /// Le conversioni null → default sono gestite dal costruttore di Prodotto_global
  /// tramite le helper functions centralizzate (intNotNull, stringNotNull, doubleNotNull)
  Prodotto_global convert_wooproduct_To_Prodotto_global(WooProduct wooProduct) {
    // Helper per gestire stringhe vuote e null (ritorna null se stringa vuota)
    String? handleEmptyString(String? value) {
      if (value == null || value.isEmpty) return null;
      return value;
    }

    log.d('🔄 Conversione prodotto ID: ${wooProduct.id}, Nome: ${wooProduct.name}');

    return Prodotto_global(
      id: wooProduct.id,
      nome: wooProduct.name,
      sku: wooProduct.sku,
      prezzoNormale: wooProduct.regularPrice,
      prezzoScontato: wooProduct.salePrice,
      descrizioneBreve: wooProduct.shortDescription,
      descrizioneCompleta: handleEmptyString(wooProduct.description),
      immagineUrl: wooProduct.images.isNotEmpty ? wooProduct.images.first.src : null,
      immaginiAggiuntive: wooProduct.images.skip(1).map((img) => img.src ?? '').toList(),
      categoria: wooProduct.categories.isNotEmpty
          ? [CategoriaProdotto(
              id: wooProduct.categories.first.id,
              nome: wooProduct.categories.first.name ?? '',
              slug: wooProduct.categories.first.slug ?? '',
            )]
          : null,
      tag: wooProduct.tags.map((tag) => TagProdotto(
        id: tag.id,
        nome: tag.name ?? '',
        slug: tag.slug ?? '',
      )).toList(),
      inStock: wooProduct.stockStatus?.name == 'instock',
      quantitaTotale: wooProduct.stockQuantity,
      peso: handleEmptyString(wooProduct.weight),
      dimensioni: wooProduct.dimensions != null &&
              ((wooProduct.dimensions!.length?.isNotEmpty ?? false) ||
               (wooProduct.dimensions!.width?.isNotEmpty ?? false) ||
               (wooProduct.dimensions!.height?.isNotEmpty ?? false))
          ? DimensioniProdotto(
              lunghezza: double.tryParse(wooProduct.dimensions!.length ?? ''),
              larghezza: double.tryParse(wooProduct.dimensions!.width ?? ''),
              altezza: double.tryParse(wooProduct.dimensions!.height ?? ''),
            )
          : null,
      dataCreazione: wooProduct.dateCreated,
      dataModifica: wooProduct.dateModified,
      status: wooProduct.status?.name,
      varianti: [], // Le varianti vengono caricate separatamente se necessario
    );
  }

  /// Converte Prodotto_global in Map per API WooCommerce
  ///
  /// Trasforma il modello interno Prodotto_global in un Map compatibile con l'API WooCommerce.
  /// Gestisce sia prodotti semplici che variabili, preparando i dati necessari per la creazione/aggiornamento.
  /* WooProduct _convert_prodotto_global_To_WooProduct(Prodotto_global prodotto/* , List<WooProductCategory> categoryId, List<WooProductTag> tagIds */) {
   
   
    final bool isVariable = prodotto.varianti.isNotEmpty;

    // Dati base del prodotto
    //final data = <String, dynamic>{

    final data = WooProduct(
      name: prodotto.nome,
      //type: isVariable ? 'variable' : 'simple',
      sku: prodotto.sku.isNotEmpty ? prodotto.sku : '',
      shortDescription: prodotto.descrizioneBreve,
      description: '',  // Verrà sovrascritto se presente descrizioneCompleta
      //status: prodotto.status.isNotEmpty ? prodotto.status : 'draft',
      //categories: categoryId,  // Verrà popolato dal chiamante con gli ID categoria
      //tags: tagIds,  // Verrà popolato dal chiamante con gli ID tag
      //images: [],  // Verrà popolato se ci sono immagini
    );

    /* // Per prodotti semplici, imposta prezzo e stock
    if (!isVariable) {
      data.regular_price = prodotto.prezzoNormale;
      data.manageStock= true;
      data.stockStatus = prodotto.inStock ? 'instock' : 'outofstock';

      // Prezzo scontato (opzionale)
      if (prodotto.prezzoScontato != null && prodotto.prezzoScontato! > 0) {
        data['sale_price'] = prodotto.prezzoScontato.toString();
      }

      // Quantità (opzionale)
      if (prodotto.quantitaTotale != null) {
        data['stock_quantity'] = prodotto.quantitaTotale;
      }
    } else {
      // Per prodotti variabili, NON impostare prezzo e stock a livello di prodotto
      // Questi vengono gestiti a livello di varianti
      data['manage_stock'] = false;
    }

    // Descrizione completa (opzionale)
    if (prodotto.descrizioneCompleta != null && prodotto.descrizioneCompleta!.isNotEmpty) {
      data['description'] = prodotto.descrizioneCompleta;
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
    } */

    /* // Attributi per prodotti variabili
    if (prodotto.varianti.isNotEmpty) {
      // Mappa: lowercase -> {nome originale, set di opzioni}
      final attributiMap = <String, Map<String, dynamic>>{};

      // Raccogli tutti gli attributi dalle varianti
      for (final variante in prodotto.varianti) {
        for (final attr in variante.attributi) {
          final nomeKey = attr.nome.toLowerCase();
          if (!attributiMap.containsKey(nomeKey)) {
            attributiMap[nomeKey] = {
              'nome': attr.nome, // Nome originale (case-sensitive)
              'opzioni': <String>{},
            };
          }
          (attributiMap[nomeKey]!['opzioni'] as Set<String>).add(attr.opzione);
        }
      }

      // Converti in formato WooCommerce
      data['attributes'] = attributiMap.values.map((attrData) {
        return {
          'name': attrData['nome'], // Usa il nome originale
          'visible': true,
          'variation': true,
          'options': (attrData['opzioni'] as Set<String>).toList(),
        };
      }).toList();
    } */

    return data;
  } */

  /// Crea WooProduct da Prodotto_global usando costruttore manuale (senza JSON)
  ///
  /// Questo approccio evita i bug di WooProduct.fromJson() creando l'oggetto
  /// direttamente con il costruttore. Le immagini includono DateTime.
   WooProduct convert_prodotto_global_To_WooProduct(
    Prodotto_global prodotto, 
    //int? categoryId,
    //List<int>? tagIds,
   ){
    final now = DateTime.now();
    final nowUtc = now.toUtc();
    final bool isVariable = prodotto.varianti?.isNotEmpty ?? false;

    return WooProduct(
      name: prodotto.nome,
      type: isVariable ? WooProductType.variable : WooProductType.simple,
      status: WooProductStatus.fromString(prodotto.status),
      sku: (prodotto.sku?.isNotEmpty ?? false) ? prodotto.sku : null,
      // Per prodotti variabili, NON impostare prezzo e stock a livello prodotto
      regularPrice: !isVariable && (prodotto.prezzoNormale ?? 0) > 0 ? prodotto.prezzoNormale : null,
      salePrice: !isVariable ? prodotto.prezzoScontato : null,
      description: prodotto.descrizioneCompleta,
      shortDescription: prodotto.descrizioneBreve,
      manageStock: !isVariable && prodotto.quantitaTotale != null,
      stockQuantity: !isVariable ? prodotto.quantitaTotale : null,
      weight: prodotto.peso,
      dimensions: prodotto.dimensioni != null
          ? WooProductDimension(
              length: prodotto.dimensioni!.lunghezza.toString(),
              width: prodotto.dimensioni!.larghezza.toString(),
              height: prodotto.dimensioni!.altezza.toString(),
            )
          : null,
      // categories: categoryId != null
      //     ? [WooProductCategory(id: categoryId)]
      //     : [],
      // tags: tagIds != null && tagIds.isNotEmpty
      //     ? tagIds.map((id) => WooProductTag(id, null, null)).toList()
      //     : [],
      images: [
        if (prodotto.immagineUrl?.isNotEmpty ?? false)
          WooProductImage(
            null,
            prodotto.immagineUrl,
            prodotto.nome,
            null,
            now,
            nowUtc,
            now,
            nowUtc,
          ),
        /* ...prodotto.immaginiAggiuntive.map((url) => WooProductImage(
              null,
              url,
              prodotto.nome,
              null,
              now,
              nowUtc,
              now,
              nowUtc,
            )), */
      ],
    );
  }
  
  
  
  /// Converte Map in WooProduct, assicurando compatibilità con WooProduct.fromJson
  ///
  /// Secondo la documentazione ufficiale WooCommerce REST API v3, solo 'name' è obbligatorio.
  /// Tuttavia, WooProduct.fromJson del package woocommerce_flutter_api ha problemi con:
  /// - DateTime fields che chiamano DateTime.parse() senza controllo null
  /// - Cast diretti su liste (cast int) che falliscono se null
  ///
  /// Questa funzione fornisce valori sicuri per questi campi problematici.
  /* WooProduct _convertToWooProductInput(Map<String, dynamic> data) {
    // Helper per normalizzare liste di oggetti (categories, tags)
    List<Map<String, dynamic>> normalizeList(dynamic list) {
      if (list == null || list is! List) return [];
      return list.whereType<Map>().map((item) => {
        'id': item['id'],
        'name': stringNotNull(item['name'] as String?),
        'slug': stringNotNull(item['slug'] as String?),
      }).toList();
    }

    // Prendi i dati come sono, sovrascrivi solo i campi problematici
    //final safeData = Map<String, dynamic>.from(data);

    // Fix per DateTime.parse() che crashano se null/empty (package bug)
    // Il package chiama DateTime.parse() anche su stringhe vuote, quindi usiamo una data valida
    /* const epochDate = '1970-01-01T00:00:00';

    safeData['date_created'] ??= DateTime.now().toIso8601String();
    safeData['date_created_gmt'] ??= DateTime.now().toUtc().toIso8601String();
    safeData['date_modified'] ??= DateTime.now().toIso8601String();
    safeData['date_modified_gmt'] ??= DateTime.now().toUtc().toIso8601String();

    // Per le date di vendita: usa epochDate invece di stringa vuota per evitare crash
    safeData['date_on_sale_from'] ??= epochDate;
    safeData['date_on_sale_from_gmt'] ??= epochDate;
    safeData['date_on_sale_to'] ??= epochDate;
    safeData['date_on_sale_to_gmt'] ??= epochDate;

    // Fix per campi String che non possono essere null
    safeData['slug'] ??= '';
    safeData['permalink'] ??= '';
    safeData['description'] ??= '';
    safeData['short_description'] ??= '';
    safeData['sku'] ??= '';
    safeData['price'] ??= '0';
    safeData['regular_price'] ??= '0';
    safeData['sale_price'] ??= '0';
    safeData['price_html'] ??= '';
    safeData['type'] ??= 'simple';
    safeData['status'] ??= 'publish';
    safeData['catalog_visibility'] ??= 'visible';
    safeData['tax_status'] ??= 'taxable';
    safeData['tax_class'] ??= '';
    safeData['stock_status'] ??= 'instock';
    safeData['backorders'] ??= 'no';
    safeData['weight'] ??= '';
    safeData['shipping_class'] ??= '';
    safeData['average_rating'] ??= '0';
    safeData['external_url'] ??= '';
    safeData['button_text'] ??= '';

    // Fix per .cast<int>() che fallisce se null (package bug)
    safeData['related_ids'] ??= [];
    safeData['upsell_ids'] ??= [];
    safeData['cross_sell_ids'] ??= [];
    safeData['variations'] ??= [];
    safeData['grouped_products'] ??= [];

    // Fix per liste di oggetti
    safeData['downloads'] ??= [];
    safeData['categories'] = normalizeList(safeData['categories']);
    safeData['tags'] = normalizeList(safeData['tags']);
    safeData['images'] ??= [];
    safeData['attributes'] ??= [];
    safeData['default_attributes'] ??= [];
    safeData['meta_data'] ??= [];

    // Fix per dimensions
    safeData['dimensions'] ??= {'length': '', 'width': '', 'height': ''};  */

    //return WooProduct.fromJson(safeData);
  }  */

  // =======================================================
  // == METODI PRODOTTI (Restituiscono modello globale)  ==
  // =======================================================

  /// Ottiene lista prodotti con paginazione e filtri
  Future<List<Prodotto_global>> getProducts({
    int page = 1,
    int perPage = 20,
    ProductFilters? filters,
  }) async {
    try {
      final woo = _woo;

      final wooProducts = await woo.getProducts(
        page: page,
        perPage: perPage,
        search: filters?.search,
        category: filters?.category,
        status: filters?.status ?? WooFilterStatus.publish,
      );

      // Converti in modello globale
      final converted = <Prodotto_global>[];
      for (final wp in wooProducts) {
        try {
          converted.add(convert_wooproduct_To_Prodotto_global(wp));
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
  Future<Prodotto_global> getProductById(int productId) async {
    try {
      final woo = _woo;
      final wooProduct = await woo.getProduct(productId);
      return convert_wooproduct_To_Prodotto_global(wooProduct);
    } catch (e) {
      log.e('❌ Errore getProductById: $productId', e);
      rethrow;
    }
  }

  /// Cerca prodotti per termine
  Future<List<Prodotto_global>> searchProducts(
    String searchTerm, {
    int limit = 20,
  }) async {
    return await getProducts(
      perPage: limit,
      filters: ProductFilters(search: searchTerm),
    );
  }

  /// Ottiene prodotti per categoria
  Future<List<Prodotto_global>> getProductsByCategory(
    int categoryId, {
    int limit = 50,
  }) async {
    return await getProducts(
      perPage: limit,
      filters: ProductFilters(category: categoryId),
    );
  }

  /// Ottiene prodotti in esaurimento
  Future<List<Prodotto_global>> getOutOfStockProducts({int limit = 100}) async {
    return await getProducts(
      perPage: limit,
      filters: ProductFilters(stockStatus: 'outofstock'),
    );
  }

  /// Crea un nuovo prodotto (accetta Prodotto_global)
  ///
  /// Gestisce automaticamente:
  /// - Creazione di categorie se non esistono
  /// - Creazione di tag se non esistono
  /// - Conversione type-safe usando mapper diretto (evita bug di WooProduct.fromJson)
  Future<Prodotto_global> createProduct(Prodotto_global prodotto) async {
    final woo = _woo;

    try {
      log.i('🔵 Creazione prodotto: ${prodotto.nome}');

      // STEP 1: Gestione categoria
      /* int? categoryId;
      if (prodotto.categoria.isNotEmpty && prodotto.categoria != 'Senza categoria') {
        log.d('📁 Verifica/Crea categoria: ${prodotto.categoria}');
        final wooQueryCategoria = WooQueryCategoria();
        final categoria = await wooQueryCategoria.createCategoryIfNotExists(
          name: prodotto.categoria,
          slug: prodotto.categoria.toLowerCase().replaceAll(' ', '-'),
        );
        categoryId = categoria.id;
        log.i('✅ Categoria pronta: ${categoria.nome} (ID $categoryId)');
      } */

      // STEP 2: Gestione tag
     /*  List<int> tagIds = <int>[];
      if (prodotto.tag.isNotEmpty) {
        log.d('🏷️ Verifica/Crea ${prodotto.tag.length} tag...');
        final wooQueryTag = WooQueryTag();
        for (final tagName in prodotto.tag) {
          final tag = await wooQueryTag.createTagIfNotExists(
            name: tagName,
            slug: tagName.toLowerCase().replaceAll(' ', '-'),
          );
          tagIds.add(tag.id);
          log.i('✅ Tag pronto: $tagName (ID ${tag.id})');
        }
      } */

      // STEP 3: Creazione WooProduct manuale (senza JSON)
      log.d('🔧 Creazione WooProduct con costruttore manuale...');
      final wooProductInput = convert_prodotto_global_To_WooProduct(
        prodotto);

      log.d('📤 Dati da inviare: ${wooProductInput.toJson()}');
      
      final wooProduct = await woo.createProduct(wooProductInput);

      log.i('✅ CREATE PRODUCT - Success: ${wooProduct.id}');

      // Converte il WooProduct ricevuto dal server nel modello Prodotto_global
      return convert_wooproduct_To_Prodotto_global(wooProduct);

    } catch (e) {
      log.e('❌ Errore createProduct', e);
      rethrow;
    }
  }

  /// Aggiorna un prodotto esistente (accetta Prodotto_global)
  Future<Prodotto_global> updateProduct(Prodotto_global prodotto) async {
     try {
      if ((prodotto.id ?? 0) == 0) {
        throw Exception('Product ID is required for update');
      }

      final woo = _woo;

      log.d('🔵 UPDATE PRODUCT ${prodotto.id}');

      final wooProductInput = convert_prodotto_global_To_WooProduct(prodotto);
      final wooProduct = await woo.updateProduct(prodotto.id!, wooProductInput); 

      log.i('✅ UPDATE PRODUCT - Success: ${wooProduct.id}');

      return convert_wooproduct_To_Prodotto_global(wooProduct);
    } catch (e) {
      log.e('❌ Errore updateProduct: ${prodotto.id}', e);
      rethrow;
    } 
  }

  /// Elimina un prodotto
  Future<bool> deleteProduct(int productId, {bool force = false}) async {
    try {
      final woo = _woo;

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
  Future<Prodotto_global> updateProductStock(
    int productId, {
    required int stockQuantity,
    String? stockStatus,
  }) async {
    try {
      final woo = _woo;

      log.d('🔵 UPDATE STOCK - Product $productId: qty=$stockQuantity, status=$stockStatus');

      // Crea WooProduct minimo solo con dati stock
      final wooProductInput = WooProduct(
        stockQuantity: stockQuantity,
        manageStock: true,
        stockStatus: stockStatus != null ? WooProductStockStatus.fromString(stockStatus) : null,
      );

      final wooProduct = await woo.updateProduct(productId, wooProductInput);

      log.i('✅ UPDATE STOCK - Success: ${wooProduct.id}');

      return convert_wooproduct_To_Prodotto_global(wooProduct);
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
      final woo = _woo;

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
      final woo = _woo;

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
    /* try {
      // Usa il Dio del plugin (ha già JWT configurato)
      final response = await woo.dio.get(
        '/products',wooProductInput
        queryParameters: {
          'per_page': 1,
          'status': status.toString().split('.').last,
        },
      );

      return int.tryParse(response.headers.value('x-wp-total') ?? '0') ?? 0;
    } catch (e) { */
      return 0;
    //}
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
