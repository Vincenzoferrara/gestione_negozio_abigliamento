import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../woo_connect.dart';
import '../../../prodotti/class_prodotti.dart';
import 'woo_query_attributi.dart';

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

  /// Converte WooProductVariation in VarianteWoo (modello globale)
  Variante_product_global _convertToVarianteWoo(WooProductVariation wooVariation) {
    // Converte attributi
    final attributi = wooVariation.attributes.map((attr) {
      // WooProductItemAttribute ha 'options' che è una lista
      final opzione = attr.options?.isNotEmpty == true ? attr.options!.first : '';

      return AttributoVariante(
        id: attr.id,
        nome: attr.name ?? '',
        opzione: opzione,
        slug: attr.name?.toLowerCase().replaceAll(' ', '-'),
      );
    }).toList();

    return Variante_product_global(
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
  Map<String, dynamic> _convertToWooVariationData(Variante_product_global variante) {
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
  Future<List<Variante_product_global>> getProductVariations(
    int productId, {
    int page = 1,
    int perPage = 100,
    String? search,
  }) async {
    final woo = _woo;

    final wooVariations = await woo.getProductVaritaions(
      productId,
      page: page,
      perPage: perPage,
      search: search,
    );

    return wooVariations.map((v) => _convertToVarianteWoo(v)).toList();
  }

  /// Ottiene una singola variante per ID
  Future<Variante_product_global> getVariationById(int productId, int variationId) async {
    final woo = _woo;
    final wooVariation = await woo.getProductVariation(productId, variationId);
    return _convertToVarianteWoo(wooVariation);
  }

  /// Verifica che tutti gli attributi e termini di una variante esistano
  Future<void> _verificaECreaAttributiVariante(Variante_product_global variante) async {
    if (variante.attributi.isEmpty) {
      throw Exception('La variante deve avere almeno un attributo');
    }

    print('🔍 Verifica attributi per variante ${variante.sku}...');

    // Importa WooQueryAttributi per accedere ai metodi
    final attributiQuery = WooQueryAttributi();

    for (final attr in variante.attributi) {
      // STEP 1: Verifica/crea l'attributo globale
      print('  → Verifica attributo: ${attr.nome}');
      final attributo = await attributiQuery.createAttributeIfNotExists(
        name: attr.nome,
        type: attr.tipo.value,
        hasArchives: true,
      );

      if (attributo.id == null) {
        throw Exception('Impossibile creare/trovare attributo: ${attr.nome}');
      }

      // STEP 2: Verifica/crea il termine dell'attributo
      print('  → Verifica termine: ${attr.opzione}');
      await attributiQuery.createAttributeTermIfNotExists(
        attributeId: attributo.id!,
        name: attr.opzione,
      );
    }

    print('✅ Tutti gli attributi della variante sono stati verificati');
  }

  /// Crea una nuova variante (accetta VarianteWoo) - VERIFICA ATTRIBUTI PRIMA
  Future<Variante_product_global> createVariation({
    required int productId,
    required Variante_product_global variante,
  }) async {
    try {
      // STEP 1: Verifica che tutti gli attributi e termini esistano
      await _verificaECreaAttributiVariante(variante);

      // STEP 2: Crea la variante
      print('🔵 Creazione variante ${variante.sku} per prodotto $productId');
      final variationData = _convertToWooVariationData(variante);

      final response = await _wooConnect.woo.dio.post(
        '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations',
        data: variationData,
      );

      final wooVariation = WooProductVariation.fromJson(response.data as Map<String, dynamic>);
      final nuovaVariante = _convertToVarianteWoo(wooVariation);

      print('✅ Variante ${variante.sku} creata con successo (ID: ${nuovaVariante.id})');
      return nuovaVariante;
    } catch (e) {
      print('❌ Errore createVariation: $e');
      rethrow;
    }
  }

  /// Aggiorna una variante esistente (accetta VarianteWoo)
  Future<Variante_product_global> updateVariation({
    required int productId,
    required Variante_product_global variante,
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
  Future<Variante_product_global> updateVariationStock({
    required int productId,
    required int variationId,
    int? stockQuantity,
    String? stockStatus,
    bool? manageStock,
  }) async {
    // Prima ottieni la variante esistente
    final variante = await getVariationById(productId, variationId);

    // Aggiorna solo i campi stock
    final varianteAggiornata = Variante_product_global(
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
  Future<List<Variante_product_global>> getAllVariations(int productId) async {
    final List<Variante_product_global> allVariations = [];
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
  Future<List<Variante_product_global>> getAvailableVariations(int productId) async {
    final allVariations = await getAllVariations(productId);
    return allVariations.where((v) => v.quantita > 0).toList();
  }

  /// Ottiene varianti esaurite
  Future<List<Variante_product_global>> getOutOfStockVariations(int productId) async {
    final allVariations = await getAllVariations(productId);
    return allVariations.where((v) => v.quantita == 0).toList();
  }

  /// Trova variante per attributi specifici
  Future<Variante_product_global?> findVariationByAttributes({
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
  Future<Variante_product_global> updateVariationPrice({
    required int productId,
    required int variationId,
    double? regularPrice,
    double? salePrice,
  }) async {
    final variante = await getVariationById(productId, variationId);

    final varianteAggiornata = Variante_product_global(
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
  Future<Variante_product_global> toggleVariationStatus({
    required int productId,
    required int variationId,
    required bool enabled,
  }) async {
    final variante = await getVariationById(productId, variationId);

    final varianteAggiornata = Variante_product_global(
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
}
