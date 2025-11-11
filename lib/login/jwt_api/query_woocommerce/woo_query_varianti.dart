import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../woo_connect.dart';
import '../../../prodotti/class_prodotti.dart';
import 'woo_query_attributi.dart';
import '../../../log_viewer/app_logger.dart';

/// Query class per la gestione delle varianti prodotti WooCommerce
/// Utilizza WooConnect per l'autenticazione centralizzata
/// Converte i dati WooCommerce in modelli globali multi-piattaforma
class WooQueryVarianti {
  // Singleton pattern
  static final WooQueryVarianti _instance = WooQueryVarianti._internal();
  factory WooQueryVarianti() => _instance;
  WooQueryVarianti._internal();

  final WooConnect _wooConnect = WooConnect();

  /// Ottiene l'istanza WooCommerce autenticata da WooConnect
  WooCommerce get _woo => _wooConnect.woo;

  // =======================================================
  // == CONVERSIONE WOOCOMMERCE → MODELLO GLOBALE        ==
  // =======================================================

  /// Converte JSON diretto in VarianteWoo (modello globale) - fallback per problemi di tipo
  VarianteProductGlobal _convertJsonToVarianteWoo(Map<String, dynamic> variationData, {List<AttributoVariante>? attributiProdotto}) {
    // Converte attributi - prima prova dalla variante, poi dagli attributi del prodotto
    final List<dynamic> attributesData = variationData['attributes'] ?? [];
    List<AttributoVariante> attributi = [];
    
    if (attributesData.isNotEmpty) {
      // Se la variante ha attributi, usali
      attributi = attributesData.map((attrData) {
        return AttributoVariante(
          id: attrData['id'] ?? 0,
          nome: attrData['name'] ?? '',
          opzione: attrData['option'] ?? '',
          slug: attrData['slug'] ?? '',
        );
      }).toList();
    } else if (attributiProdotto != null) {
      // Se la variante non ha attributi specifici, non mostrare attributi generici
      // Evita di mostrare tutti gli attributi del prodotto su ogni variante
      attributi = [];
    }

    // Gestisce immagine
    String? immagineUrl;
    final imageData = variationData['image'];
    if (imageData != null && imageData['src'] != null) {
      immagineUrl = imageData['src'];
    }

    return VarianteProductGlobal(
      id: variationData['id'] ?? 0,
      nome: variationData['description'] ?? '',
      attributi: attributi,
      sku: variationData['sku'] ?? '',
      prezzo: double.tryParse(variationData['regular_price']?.toString() ?? '0') ?? 0.0,
      prezzoScontato: variationData['sale_price'] != null
          ? double.tryParse(variationData['sale_price'].toString())
          : null,
      quantita: variationData['stock_quantity'] ?? 0,
      immagineUrl: immagineUrl,
      immaginiAggiuntive: [],
      peso: variationData['weight']?.toString(),
      dimensioni: variationData['dimensions'] != null
          ? DimensioniProdotto(
              lunghezza: double.tryParse(variationData['dimensions']['length']?.toString() ?? '0') ?? 0.0,
              larghezza: double.tryParse(variationData['dimensions']['width']?.toString() ?? '0') ?? 0.0,
              altezza: double.tryParse(variationData['dimensions']['height']?.toString() ?? '0') ?? 0.0,
            )
          : null,
      attiva: variationData['stock_status'] == 'instock',
    );
  }

  /// Converte WooProductVariation in VarianteWoo (modello globale)
  VarianteProductGlobal _convertToVarianteWoo(WooProductVariation wooVariation, {List<AttributoVariante>? attributiProdotto}) {
    // Converte attributi
    List<AttributoVariante> attributi = [];

    if (wooVariation.attributes.isNotEmpty) {
      attributi = wooVariation.attributes.map((attr) {
        // WooProductItemAttribute ha 'options' che è una lista
        final opzione = attr.options?.isNotEmpty == true ? attr.options!.first : '';
        final nomeAttr = attr.name ?? '';

        // Cerca l'attributo corrispondente nel prodotto per ottenere il tipo
        AttributoVariante? attrProdotto;
        if (attributiProdotto != null) {
          attrProdotto = attributiProdotto.where((a) => a.nome == nomeAttr && a.opzione == opzione).firstOrNull;
        }

        return AttributoVariante(
          id: attr.id,
          nome: nomeAttr,
          opzione: opzione,
          slug: attr.name?.toLowerCase().replaceAll(' ', '-'),
          tipo: attrProdotto?.tipo ?? TipoAttributo.select,
          valore: attrProdotto?.valore,
        );
      }).toList();
    } else if (attributiProdotto != null) {
      // Se la variante non ha attributi specifici, non mostrare attributi generici
      // Evita di mostrare tutti gli attributi del prodotto su ogni variante
      attributi = [];
    }

    return VarianteProductGlobal(
      id: wooVariation.id ?? 0,
      nome: wooVariation.description ?? '',
      attributi: attributi,
      sku: wooVariation.sku ?? '',
      prezzo: double.tryParse(wooVariation.regularPrice?.toString() ?? '0') ?? 0.0,
      prezzoScontato: wooVariation.salePrice != null
          ? double.tryParse(wooVariation.salePrice!.toString())
          : null,
      quantita: wooVariation.stockQuantity ?? 0,
      immagineUrl: wooVariation.image?.src,
      immaginiAggiuntive: [],
      peso: wooVariation.weight?.toString(),
      dimensioni: wooVariation.dimensions?.length != null
          ? DimensioniProdotto(
              lunghezza: double.tryParse(wooVariation.dimensions.length ?? '0') ?? 0.0,
              larghezza: double.tryParse(wooVariation.dimensions.width ?? '0') ?? 0.0,
              altezza: double.tryParse(wooVariation.dimensions.height ?? '0') ?? 0.0,
            )
          : null,
      attiva: wooVariation.status == WooProductStatus.publish,
    );
  }

  /// Converte VarianteWoo in Map per API WooCommerce
  Map<String, dynamic> _convertToWooVariationData(VarianteProductGlobal variante) {
    final data = <String, dynamic>{
      'regular_price': variante.prezzo.toString(),
      'sku': variante.sku.isNotEmpty ? variante.sku : null,
      'manage_stock': true,
      'stock_quantity': variante.quantita,
      'status': variante.attiva ? 'publish' : 'private',
    };

    // Prezzo scontato
    if (variante.prezzoScontato != null && variante.prezzoScontato! > 0) {
      data['sale_price'] = variante.prezzoScontato.toString();
    }

    // Peso
    if (variante.peso != null && variante.peso!.isNotEmpty) {
      data['weight'] = variante.peso;
    }

    // Dimensioni
    if (variante.dimensioni != null) {
      data['dimensions'] = {
        'length': variante.dimensioni!.lunghezza.toString(),
        'width': variante.dimensioni!.larghezza.toString(),
        'height': variante.dimensioni!.altezza.toString(),
      };
    }

    // Attributi
    data['attributes'] = variante.attributi.map((attr) => {
      'name': attr.nome,
      'option': attr.opzione,
    }).toList();

    // Immagine
    if (variante.immagineUrl != null && variante.immagineUrl!.isNotEmpty) {
      data['image'] = {
        'src': variante.immagineUrl,
      };
    }

    return data;
  }

  // =======================================================
  // == METODI VARIANTI (Restituiscono modello globale)  ==
  // =======================================================

  /// Ottiene tutte le varianti di un prodotto
  Future<List<VarianteProductGlobal>> getProductVariations(
    int productId, {
    int page = 1,
    int perPage = 100,
    String? search,
    List<AttributoVariante>? attributiProdotto,
  }) async {
    try {
      final woo = _woo;

      // Prova prima con il metodo standard della libreria
      try {
        final wooVariations = await woo.getProductVaritaions(
          productId,
          page: page,
          perPage: perPage,
          search: search,
        );
        return wooVariations.map((v) => _convertToVarianteWoo(v, attributiProdotto: attributiProdotto)).toList();
      } catch (e) {
        // Se fallisce per l'errore di tipo, usa una chiamata diretta con Dio
        log.d('Errore libreria WooCommerce, tentativo con chiamata diretta: $e');
        
        final response = await _woo.dio.get(
          '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations',
          queryParameters: {
            'page': page,
            'per_page': perPage,
            if (search != null) 'search': search,
          },
        );

        final List<dynamic> variationsData = response.data;
        return variationsData.map((variationData) {
          return _convertJsonToVarianteWoo(variationData, attributiProdotto: attributiProdotto);
        }).toList();
      }
    } catch (e) {
      log.e('Errore caricamento varianti per prodotto $productId: $e');
      rethrow;
    }
  }

  /// Ottiene una singola variante per ID
  Future<VarianteProductGlobal> getVariationById(int productId, int variationId) async {
    final woo = _woo;
    final wooVariation = await woo.getProductVariation(productId, variationId);
    return _convertToVarianteWoo(wooVariation);
  }

  /// Verifica che tutti gli attributi e termini di una variante esistano
  Future<void> _verificaECreaAttributiVariante(VarianteProductGlobal variante) async {
    if (variante.attributi.isEmpty) {
      throw Exception('La variante deve avere almeno un attributo');
    }

    log.e('🔍 Verifica attributi per variante ${variante.sku}...');

    // Importa WooQueryAttributi per accedere ai metodi
    final attributiQuery = WooQueryAttributi();

    for (final attr in variante.attributi) {
      // STEP 1: Verifica/crea l'attributo globale
      log.e('  → Verifica attributo: ${attr.nome}');
      final attributo = await attributiQuery.createAttributeIfNotExists(
        name: attr.nome,
        type: attr.tipo.value,
        hasArchives: true,
      );

      if (attributo.id == null) {
        throw Exception('Impossibile creare/trovare attributo: ${attr.nome}');
      }

      // STEP 2: Verifica/crea il termine dell'attributo
      log.e('  → Verifica termine: ${attr.opzione}');
      await attributiQuery.createAttributeTermIfNotExists(
        attributeId: attributo.id!,
        name: attr.opzione,
      );
    }

    log.e('✅ Tutti gli attributi della variante sono stati verificati');
  }

  /// Crea varianti per un prodotto se non esistono
  /// Questo è l'UNICO metodo da usare per creare varianti
  /// Accetta List<VarianteProductGlobal> e gestisce la creazione/aggiornamento
  Future<List<VarianteProductGlobal>> createVariationsIfNotExists({
    required int productId,
    required List<VarianteProductGlobal> varianti,
  }) async {
    try {
      final List<VarianteProductGlobal> variantiCreate = [];

      log.i('🔵 VARIANTE: Gestione ${varianti.length} varianti per prodotto $productId...');
      log.d('🔍 VARIANTE: Dettaglio varianti da creare:');
      for (final variante in varianti) {
        log.d('  - ${variante.nome} (SKU: ${variante.sku}, Prezzo: ${variante.prezzo})');
        log.d('    Attributi: ${variante.attributi.map((a) => "${a.nome}:${a.opzione}").toList()}');
      }

      for (final variante in varianti) {
        try {
          log.i('🔧 VARIANTE: Inizio creazione variante ${variante.sku}...');
          
          // STEP 1: Verifica che tutti gli attributi e termini esistano
          log.d('🔍 VARIANTE: STEP 1 - Verifica attributi per ${variante.sku}');
          await _verificaECreaAttributiVariante(variante);
          log.d('✅ VARIANTE: STEP 1 completato - Attributi verificati');

          // STEP 2: Crea la variante
          log.d('🔍 VARIANTE: STEP 2 - Conversione dati variante');
          final variationData = _convertToWooVariationData(variante);
          log.d('🔍 VARIANTE: Dati variante: $variationData');

          log.d('🔍 VARIANTE: STEP 3 - Chiamata API POST');
          final response = await _wooConnect.woo.dio.post(
            '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations',
            data: variationData,
          );

          log.d('🔍 VARIANTE: STEP 4 - Parsing response');
          final wooVariation = WooProductVariation.fromJson(response.data as Map<String, dynamic>);
          final nuovaVariante = _convertToVarianteWoo(wooVariation);

          log.i('✅ VARIANTE: ${variante.sku} creata con successo (ID: ${nuovaVariante.id})');
          variantiCreate.add(nuovaVariante);
        } catch (e) {
          log.e('❌ VARIANTE: Errore creazione variante ${variante.sku}: $e');
          log.e('🔍 VARIANTE: STACK TRACE: ${StackTrace.current}');
          // Continua con le altre varianti anche se una fallisce
        }
      }

      return variantiCreate;
    } catch (e) {
      log.e('❌ Errore createVariationsIfNotExists: $e');
      rethrow;
    }
  }

  /// Crea una nuova variante (accetta VarianteWoo) - VERIFICA ATTRIBUTI PRIMA
  Future<VarianteProductGlobal> createVariation({
    required int productId,
    required VarianteProductGlobal variante,
  }) async {
    try {
      // STEP 1: Verifica che tutti gli attributi e termini esistano
      await _verificaECreaAttributiVariante(variante);

      // STEP 2: Crea la variante
      log.e('🔵 Creazione variante ${variante.sku} per prodotto $productId');
      final variationData = _convertToWooVariationData(variante);

      final response = await _wooConnect.woo.dio.post(
        '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations',
        data: variationData,
      );

      final wooVariation = WooProductVariation.fromJson(response.data as Map<String, dynamic>);
      final nuovaVariante = _convertToVarianteWoo(wooVariation);

      log.e('✅ Variante ${variante.sku} creata con successo (ID: ${nuovaVariante.id})');
      return nuovaVariante;
    } catch (e) {
      log.e('❌ Errore createVariation: $e');
      rethrow;
    }
  }

  /// Aggiorna una variante esistente (accetta VarianteWoo)
  Future<VarianteProductGlobal> updateVariation({
    required int productId,
    required VarianteProductGlobal variante,
  }) async {
    final variationData = _convertToWooVariationData(variante);

    final response = await _wooConnect.woo.dio.put(
      '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations/${variante.id}',
      data: variationData,
    );

    final wooVariation = WooProductVariation.fromJson(response.data as Map<String, dynamic>);
    return _convertToVarianteWoo(wooVariation);
  }

  /// Elimina una variante (usa Dio diretto)
  Future<bool> deleteVariation({
    required int productId,
    required int variationId,
    bool force = false,
  }) async {
    await _wooConnect.woo.dio.delete(
      '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations/$variationId',
      queryParameters: {'force': force},
    );

    return true;
  }

  /// Aggiorna solo lo stock di una variante
  Future<VarianteProductGlobal> updateVariationStock({
    required int productId,
    required int variationId,
    int? stockQuantity,
    String? stockStatus,
    bool? manageStock,
  }) async {
    // Prima ottieni la variante esistente
    final variante = await getVariationById(productId, variationId);

    // Aggiorna solo i campi stock
    final varianteAggiornata = VarianteProductGlobal(
      id: variante.id,
      nome: variante.nome,
      attributi: variante.attributi,
      sku: variante.sku,
      prezzo: variante.prezzo,
      prezzoScontato: variante.prezzoScontato,
      quantita: stockQuantity ?? variante.quantita,
      immagineUrl: variante.immagineUrl,
      immaginiAggiuntive: variante.immaginiAggiuntive,
      peso: variante.peso,
      dimensioni: variante.dimensioni,
      attiva: variante.attiva,
    );

    return await updateVariation(
      productId: productId,
      variante: varianteAggiornata,
    );
  }

  /// Ottiene tutte le varianti di un prodotto (senza paginazione)
  Future<List<VarianteProductGlobal>> getAllVariations(int productId) async {
    final List<VarianteProductGlobal> allVariations = [];
    int currentPage = 1;
    bool hasMore = true;

    while (hasMore) {
      final variations = await getProductVariations(
        productId,
        page: currentPage,
        perPage: 100,
      );

      if (variations.isEmpty) {
        hasMore = false;
      } else {
        allVariations.addAll(variations);
        currentPage++;
      }
    }

    return allVariations;
  }

  /// Batch update varianti (usa Dio diretto)
  Future<Map<String, dynamic>> batchUpdateVariations({
    required int productId,
    List<Map<String, dynamic>>? create,
    List<Map<String, dynamic>>? update,
    List<int>? delete,
  }) async {
    final batchData = {
      if (create != null && create.isNotEmpty) 'create': create,
      if (update != null && update.isNotEmpty) 'update': update,
      if (delete != null && delete.isNotEmpty) 'delete': delete,
    };

    final response = await _wooConnect.woo.dio.post(
      '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations/batch',
      data: batchData,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Ottiene varianti disponibili (in stock)
  Future<List<VarianteProductGlobal>> getAvailableVariations(int productId) async {
    final allVariations = await getAllVariations(productId);
    return allVariations.where((v) => v.quantita > 0).toList();
  }

  /// Ottiene varianti esaurite
  Future<List<VarianteProductGlobal>> getOutOfStockVariations(int productId) async {
    final allVariations = await getAllVariations(productId);
    return allVariations.where((v) => v.quantita == 0).toList();
  }

  /// Trova variante per attributi specifici
  Future<VarianteProductGlobal?> findVariationByAttributes({
    required int productId,
    required Map<String, String> attributes,
  }) async {
    final allVariations = await getAllVariations(productId);

    for (final variation in allVariations) {
      bool matches = true;

      if (variation.attributi.isNotEmpty) {
        for (final attr in attributes.entries) {
          final varAttr = variation.attributi.where(
            (a) => a.nome.toLowerCase() == attr.key.toLowerCase()
          ).firstOrNull;

          if (varAttr == null || varAttr.opzione.toLowerCase() != attr.value.toLowerCase()) {
            matches = false;
            break;
          }
        }
      } else {
        matches = false;
      }

      if (matches) return variation;
    }

    return null;
  }

  /// Ottiene statistiche varianti di un prodotto
  Future<Map<String, dynamic>> getVariationStats(int productId) async {
    final variations = await getAllVariations(productId);

    int totalStock = 0;
    int inStock = 0;
    int outOfStock = 0;
    double minPrice = double.infinity;
    double maxPrice = 0;

    for (final variation in variations) {
      if (variation.quantita > 0) {
        inStock++;
      } else {
        outOfStock++;
      }

      totalStock += variation.quantita;

      if (variation.prezzo < minPrice) minPrice = variation.prezzo;
      if (variation.prezzo > maxPrice) maxPrice = variation.prezzo;
    }

    return {
      'total_variations': variations.length,
      'in_stock': inStock,
      'out_of_stock': outOfStock,
      'total_stock_quantity': totalStock,
      'min_price': minPrice == double.infinity ? 0 : minPrice,
      'max_price': maxPrice,
    };
  }

  /// Aggiorna prezzo di una variante
  Future<VarianteProductGlobal> updateVariationPrice({
    required int productId,
    required int variationId,
    double? regularPrice,
    double? salePrice,
  }) async {
    final variante = await getVariationById(productId, variationId);

    final varianteAggiornata = VarianteProductGlobal(
      id: variante.id,
      nome: variante.nome,
      attributi: variante.attributi,
      sku: variante.sku,
      prezzo: regularPrice ?? variante.prezzo,
      prezzoScontato: salePrice ?? variante.prezzoScontato,
      quantita: variante.quantita,
      immagineUrl: variante.immagineUrl,
      immaginiAggiuntive: variante.immaginiAggiuntive,
      peso: variante.peso,
      dimensioni: variante.dimensioni,
      attiva: variante.attiva,
    );

    return await updateVariation(
      productId: productId,
      variante: varianteAggiornata,
    );
  }

  /// Abilita/disabilita una variante
  Future<VarianteProductGlobal> toggleVariationStatus({
    required int productId,
    required int variationId,
    required bool enabled,
  }) async {
    final variante = await getVariationById(productId, variationId);

    final varianteAggiornata = VarianteProductGlobal(
      id: variante.id,
      nome: variante.nome,
      attributi: variante.attributi,
      sku: variante.sku,
      prezzo: variante.prezzo,
      prezzoScontato: variante.prezzoScontato,
      quantita: variante.quantita,
      immagineUrl: variante.immagineUrl,
      immaginiAggiuntive: variante.immaginiAggiuntive,
      peso: variante.peso,
      dimensioni: variante.dimensioni,
      attiva: enabled,
    );

    return await updateVariation(
      productId: productId,
      variante: varianteAggiornata,
    );
  }

  /// Recupera i metadata custom di una variante prodotto
  Future<Map<String, String>> getProductVariationMetadata(int productId, int variationId) async {
    try {
      log.d('🔍 Recupero metadata per variante $variationId del prodotto $productId');
      
      final response = await _woo.dio.get('/products/$productId/variations/$variationId');
      
      if (response.statusCode == 200) {
        final variationData = response.data as Map<String, dynamic>;
        final metaData = variationData['meta_data'] as List<dynamic>? ?? [];
        
        final metadataMap = <String, String>{};
        for (final meta in metaData) {
          if (meta['key'] != null) {
            metadataMap[meta['key'].toString()] = meta['value']?.toString() ?? '';
          }
        }
        
        log.d('✅ Recuperati ${metadataMap.length} metadata per variante $variationId');
        return metadataMap;
      } else {
        log.e('❌ Errore recupero metadata variante: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      log.e('❌ Errore recupero metadata variante: $e');
      return {};
    }
  }
}
