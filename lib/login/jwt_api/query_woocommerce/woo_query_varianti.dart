import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import 'package:dio/dio.dart';
import '../woo_connect.dart';
import '../../../prodotti/class_prodotti.dart';
import 'woo_query_attributi.dart';
import '../../../log_viewer/app_logger.dart';
import '../../../settings/app_settings.dart';

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
  VarianteProductGlobal _convertJsonToVarianteWoo(
    Map<String, dynamic> variationData, {
    List<AttributoVariante>? attributiProdotto,
  }) {
    final metadata = <String, dynamic>{
      for (final item
          in variationData['meta_data'] as List<dynamic>? ?? const [])
        if (item is Map && item['key']?.toString().trim().isNotEmpty == true)
          item['key'].toString(): item['value'],
    };
    // Converte attributi - prima prova dalla variante, poi dagli attributi del prodotto
    final List<dynamic> attributesData = variationData['attributes'] ?? [];
    List<AttributoVariante> attributi = [];

    if (attributesData.isNotEmpty) {
      // Se la variante ha attributi, usali
      attributi = attributesData.map((attrData) {
        final attributo = AttributoVariante(
          id: attrData['id'] ?? 0,
          nome: attrData['name'] ?? '',
          opzione: attrData['option'] ?? '',
          slug: attrData['slug'] ?? '',
        );
        return attributo;
      }).toList();
    } else if (attributiProdotto != null && attributiProdotto.isNotEmpty) {
      // WORKAROUND: Se la variante non ha attributi (problema comune WooCommerce),
      // ricostruisci gli attributi usando una mappatura basata sull'ordine della variante
      final sku = variationData['sku']?.toString() ?? '';
      final varianteId = variationData['id'] as int?;

      // Raggruppa attributi del prodotto per nome
      final Map<String, List<AttributoVariante>> attributiPerNome = {};
      for (final attr in attributiProdotto) {
        attributiPerNome[attr.nome] ??= [];
        attributiPerNome[attr.nome]!.add(attr);
      }

      // Prova a estrarre informazioni dal SKU o dall'ID
      if (sku.contains('-VAR') && varianteId != null) {
        // Estrai il numero di variante dal SKU (es. VAR1, VAR2)
        final varianteNumber = _extractVarianteNumber(sku, varianteId);

        // Costruisci attributi basandoti sull'ordine degli attributi del prodotto
        final List<String> nomiAttributi = attributiPerNome.keys.toList();
        final List<AttributoVariante> attributiRicostruiti = [];

        for (int i = 0; i < nomiAttributi.length; i++) {
          final nomeAttributo = nomiAttributi[i];
          final opzioniAttributo = attributiPerNome[nomeAttributo]!;

          // Seleziona l'opzione basandoti sul numero di variante
          final indiceOpzione = (varianteNumber - 1) % opzioniAttributo.length;
          final opzioneScelta = opzioniAttributo[indiceOpzione];

          attributiRicostruiti.add(opzioneScelta);
        }

        attributi = attributiRicostruiti;
      } else {
        attributi = [];
      }
    } else {
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
      prezzo:
          double.tryParse(variationData['regular_price']?.toString() ?? '0') ??
          0.0,
      prezzoScontato: variationData['sale_price'] != null
          ? double.tryParse(variationData['sale_price'].toString())
          : null,
      quantita: variationData['stock_quantity'] ?? 0,
      immagineUrl: immagineUrl,
      immaginiAggiuntive: [],
      peso: variationData['weight']?.toString(),
      dimensioni: variationData['dimensions'] != null
          ? DimensioniProdotto(
              lunghezza:
                  double.tryParse(
                    variationData['dimensions']['length']?.toString() ?? '0',
                  ) ??
                  0.0,
              larghezza:
                  double.tryParse(
                    variationData['dimensions']['width']?.toString() ?? '0',
                  ) ??
                  0.0,
              altezza:
                  double.tryParse(
                    variationData['dimensions']['height']?.toString() ?? '0',
                  ) ??
                  0.0,
            )
          : null,
      attiva: variationData['stock_status'] == 'instock',
      metadatiCustom: metadata,
    );
  }

  /// Converte WooProductVariation in VarianteWoo (modello globale)
  VarianteProductGlobal _convertToVarianteWoo(
    WooProductVariation wooVariation, {
    List<AttributoVariante>? attributiProdotto,
  }) {
    // Converte attributi
    List<AttributoVariante> attributi = [];

    if (wooVariation.attributes.isNotEmpty) {
      attributi = wooVariation.attributes.map((attr) {
        // WooProductItemAttribute ha 'options' che è una lista
        final opzione = attr.options?.isNotEmpty == true
            ? attr.options!.first
            : '';
        final nomeAttr = attr.name ?? '';

        // Cerca l'attributo corrispondente nel prodotto per ottenere il tipo
        AttributoVariante? attrProdotto;
        if (attributiProdotto != null) {
          attrProdotto = attributiProdotto
              .where((a) => a.nome == nomeAttr && a.opzione == opzione)
              .firstOrNull;
        }

        final attributoConvertito = AttributoVariante(
          id: attr.id,
          nome: nomeAttr,
          opzione: opzione,
          slug: attr.name?.toLowerCase().replaceAll(' ', '-'),
          tipo: attrProdotto?.tipo ?? TipoAttributo.select,
          valore: attrProdotto?.valore,
        );
        return attributoConvertito;
      }).toList();
    } else if (attributiProdotto != null) {
      // Se la variante non ha attributi specifici, non mostrare attributi generici
      // Evita di mostrare tutti gli attributi del prodotto su ogni variante
      attributi = [];
    } else {
      attributi = [];
    }

    return VarianteProductGlobal(
      id: wooVariation.id ?? 0,
      nome: wooVariation.description ?? '',
      attributi: attributi,
      sku: wooVariation.sku ?? '',
      prezzo:
          double.tryParse(wooVariation.regularPrice?.toString() ?? '0') ?? 0.0,
      prezzoScontato: wooVariation.salePrice != null
          ? double.tryParse(wooVariation.salePrice!.toString())
          : null,
      quantita: wooVariation.stockQuantity ?? 0,
      immagineUrl: wooVariation.image?.src,
      immaginiAggiuntive: [],
      peso: wooVariation.weight?.toString(),
      dimensioni: DimensioniProdotto(
        lunghezza:
            double.tryParse(wooVariation.dimensions.length ?? '0') ?? 0.0,
        larghezza: double.tryParse(wooVariation.dimensions.width ?? '0') ?? 0.0,
        altezza: double.tryParse(wooVariation.dimensions.height ?? '0') ?? 0.0,
      ),
      attiva: wooVariation.status == WooProductStatus.publish,
      metadatiCustom: <String, dynamic>{
        for (final meta in wooVariation.metaData)
          if (meta.key?.trim().isNotEmpty == true) meta.key!: meta.value,
      },
    );
  }

  /// Converte VarianteWoo in Map per API WooCommerce
  Map<String, dynamic> _convertToWooVariationData(
    VarianteProductGlobal variante, {
    String? forcedStatus,
  }) {
    final normalizedForcedStatus = _normalizeStatus(forcedStatus);
    final data = <String, dynamic>{
      'regular_price': variante.prezzo.toString(),
      'sku': variante.sku.isNotEmpty ? variante.sku : null,
      'manage_stock': true,
      'stock_quantity': variante.quantita,
      'status':
          normalizedForcedStatus ?? (variante.attiva ? 'publish' : 'private'),
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
    data['attributes'] = variante.attributi
        .map((attr) => {'name': attr.nome, 'option': attr.opzione})
        .toList();

    // Immagine
    if (variante.immagineUrl != null && variante.immagineUrl!.isNotEmpty) {
      data['image'] = {'src': variante.immagineUrl};
    }

    if (variante.metadatiCustom?.isNotEmpty == true) {
      data['meta_data'] = variante.metadatiCustom!.entries
          .map((entry) => {'key': entry.key, 'value': entry.value})
          .toList(growable: false);
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
    String? includeStatus,
    List<AttributoVariante>? attributiProdotto,
  }) async {
    try {
      final woo = _woo;
      final normalizedIncludeStatus = _normalizeStatus(includeStatus);

      // Prova prima con il metodo standard della libreria
      if (normalizedIncludeStatus == null) {
        try {
          final wooVariations = await woo.getProductVaritaions(
            productId,
            page: page,
            perPage: perPage,
            search: search,
          );
          return wooVariations
              .map(
                (v) => _convertToVarianteWoo(
                  v,
                  attributiProdotto: attributiProdotto,
                ),
              )
              .toList();
        } catch (e) {
          // Se fallisce per l'errore di tipo, usa una chiamata diretta con Dio
          log.d(
            'Errore libreria WooCommerce, tentativo con chiamata diretta: $e',
          );
        }
      }

      final response = await _woo.dio.get(
        '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null) 'search': search,
          if (normalizedIncludeStatus != null)
            'include_status': normalizedIncludeStatus,
        },
      );

      final List<dynamic> variationsData = response.data;
      return variationsData.map((variationData) {
        return _convertJsonToVarianteWoo(
          variationData,
          attributiProdotto: attributiProdotto,
        );
      }).toList();
    } catch (e) {
      log.e('Errore caricamento varianti per prodotto $productId: $e');
      rethrow;
    }
  }

  /// Ottiene una singola variante per ID
  Future<VarianteProductGlobal> getVariationById(
    int productId,
    int variationId,
  ) async {
    final woo = _woo;
    final wooVariation = await woo.getProductVariation(productId, variationId);
    return _convertToVarianteWoo(wooVariation);
  }

  /// Verifica che tutti gli attributi e termini di una variante esistano
  Future<void> _verificaECreaAttributiVariante(
    VarianteProductGlobal variante,
    String attributeCaseMode,
  ) async {
    if (variante.attributi.isEmpty) {
      throw Exception('La variante deve avere almeno un attributo');
    }

    log.e('🔍 Verifica attributi per variante ${variante.sku}...');

    // Importa WooQueryAttributi per accedere ai metodi
    final attributiQuery = WooQueryAttributi();

    for (final attr in variante.attributi) {
      final rawAttributeName = attr.nome;
      final rawTermName = attr.opzione;
      final attributeName = rawAttributeName.trim();
      final termName = rawTermName.trim();

      if (attributeName.isEmpty && termName.isEmpty) {
        throw Exception(
          'Attributo variante non valido: nome e valore vuoti (SKU: ${variante.sku})',
        );
      }

      if (attributeName.isEmpty && termName.isNotEmpty) {
        throw Exception(
          'Attributo variante non valido: valore presente senza nome attributo (SKU: ${variante.sku})',
        );
      }

      if (attributeName.isNotEmpty && termName.isEmpty) {
        throw Exception(
          'Attributo variante non valido: nome attributo presente senza valore (SKU: ${variante.sku}, attributo: $attributeName)',
        );
      }

      // STEP 1: Verifica/crea l'attributo globale
      log.e('  → Verifica attributo: $attributeName');
      ProductAttribute attributo;
      final existingAttribute = await attributiQuery.findAttributeByName(
        attributeName,
      );
      if (existingAttribute != null) {
        attributo = existingAttribute;
      } else {
        final normalizedAttributeName =
            AppSettings.normalizeAttributeParameterWithMode(
              attributeName,
              attributeCaseMode,
            );
        if (normalizedAttributeName.isEmpty) {
          throw Exception(
            'Attributo variante non valido dopo normalizzazione (SKU: ${variante.sku})',
          );
        }
        log.d(
          'PCREA_PARAM_CREATE_ATTR raw="$attributeName" normalized="$normalizedAttributeName" mode=$attributeCaseMode',
        );
        attributo = await attributiQuery.createAttributeIfNotExists(
          name: normalizedAttributeName,
          type: attr.tipo.value,
          hasArchives: true,
        );
      }

      if (attributo.id == null) {
        throw Exception('Impossibile creare/trovare attributo: $attributeName');
      }

      // STEP 2: Verifica/crea il termine dell'attributo
      log.e('  → Verifica termine: $termName');
      final existingTerm = await attributiQuery.findAttributeTermByName(
        attributo.id!,
        termName,
      );
      if (existingTerm == null) {
        final normalizedTermName =
            AppSettings.normalizeAttributeParameterWithMode(
              termName,
              attributeCaseMode,
            );
        if (normalizedTermName.isEmpty) {
          throw Exception(
            'Valore attributo non valido dopo normalizzazione (SKU: ${variante.sku}, attributo: $attributeName)',
          );
        }
        log.d(
          'PCREA_PARAM_CREATE_TERM raw="$termName" normalized="$normalizedTermName" mode=$attributeCaseMode',
        );
        await attributiQuery.createAttributeTermIfNotExists(
          attributeId: attributo.id!,
          name: normalizedTermName,
        );
      }
    }

    log.e('✅ Tutti gli attributi della variante sono stati verificati');
  }

  /// Crea varianti per un prodotto se non esistono
  /// Questo è l'UNICO metodo da usare per creare varianti
  /// Accetta List<VarianteProductGlobal> e gestisce la creazione/aggiornamento
  Future<List<VarianteProductGlobal>> createVariationsIfNotExists({
    required int productId,
    required List<VarianteProductGlobal> varianti,
    String? forcedStatus,
  }) async {
    try {
      final List<VarianteProductGlobal> variantiCreate = [];
      final settings = AppSettings();
      await settings.init();
      final attributeCaseMode = settings.attributeCaseMode;

      log.i(
        '🔵 VARIANTE: Gestione ${varianti.length} varianti per prodotto $productId...',
      );
      log.d('PCREA_PARAM_CASE_MODE mode=$attributeCaseMode');
      log.d('🔍 VARIANTE: Dettaglio varianti da creare:');
      for (final variante in varianti) {
        log.d(
          '  - ${variante.nome} (SKU: ${variante.sku}, Prezzo: ${variante.prezzo})',
        );
        log.d(
          '    Attributi: ${variante.attributi.map((a) => "${a.nome}:${a.opzione}").toList()}',
        );
      }

      for (final variante in varianti) {
        try {
          log.i('🔧 VARIANTE: Inizio creazione variante ${variante.sku}...');

          // STEP 1: Verifica che tutti gli attributi e termini esistano
          log.d('🔍 VARIANTE: STEP 1 - Verifica attributi per ${variante.sku}');
          await _verificaECreaAttributiVariante(variante, attributeCaseMode);
          log.d('✅ VARIANTE: STEP 1 completato - Attributi verificati');

          // STEP 2: Crea la variante
          log.d('🔍 VARIANTE: STEP 2 - Conversione dati variante');
          final variationData = _convertToWooVariationData(
            variante,
            forcedStatus: forcedStatus,
          );
          log.d('🔍 VARIANTE: Dati variante: $variationData');

          log.d('🔍 VARIANTE: STEP 3 - Chiamata API POST');
          Map<String, dynamic> finalVariationData = Map<String, dynamic>.from(
            variationData,
          );
          dynamic response;

          try {
            response = await _wooConnect.woo.dio.post(
              '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations',
              data: finalVariationData,
            );
          } on DioException catch (e) {
            if (_isSkuDuplicateError(e) &&
                (finalVariationData['sku'] is String)) {
              final currentSku = (finalVariationData['sku'] as String).trim();
              final retrySku =
                  _extractSuggestedSku(e) ?? _fallbackSku(currentSku);
              log.w(
                '⚠️ SKU variante duplicato: $currentSku -> retry con $retrySku',
              );
              finalVariationData = Map<String, dynamic>.from(finalVariationData)
                ..['sku'] = retrySku;
              response = await _wooConnect.woo.dio.post(
                '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations',
                data: finalVariationData,
              );
            } else {
              rethrow;
            }
          }

          log.d('🔍 VARIANTE: STEP 4 - Parsing response');
          final nuovaVariante = _parseVariationResponse(
            response.data as Map<String, dynamic>,
            attributiProdotto: variante.attributi,
          );

          log.i(
            '✅ VARIANTE: ${variante.sku} creata con successo (ID: ${nuovaVariante.id})',
          );
          variantiCreate.add(nuovaVariante);
        } on DioException catch (e) {
          log.e(
            '❌ VARIANTE: Errore API creazione variante ${variante.sku}: status=${e.response?.statusCode}',
          );
          log.e('❌ VARIANTE: Response body: ${e.response?.data}');
          log.e('🔍 VARIANTE: STACK TRACE: ${StackTrace.current}');
        } catch (e) {
          log.e('❌ VARIANTE: Errore creazione variante ${variante.sku}: $e');
          log.e('🔍 VARIANTE: STACK TRACE: ${StackTrace.current}');
          // Continua con le altre varianti anche se una fallisce
        }
      }

      if (varianti.isNotEmpty && variantiCreate.isEmpty) {
        throw Exception(
          'Nessuna variante creata per prodotto $productId (tentate: ${varianti.length}).',
        );
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
    String? forcedStatus,
  }) async {
    try {
      final settings = AppSettings();
      await settings.init();

      // STEP 1: Verifica che tutti gli attributi e termini esistano
      await _verificaECreaAttributiVariante(
        variante,
        settings.attributeCaseMode,
      );

      // STEP 2: Crea la variante
      log.e('🔵 Creazione variante ${variante.sku} per prodotto $productId');
      final variationData = _convertToWooVariationData(
        variante,
        forcedStatus: forcedStatus,
      );

      final response = await _wooConnect.woo.dio.post(
        '${_wooConnect.siteUrl}/wp-json/wc/v3/products/$productId/variations',
        data: variationData,
      );

      final nuovaVariante = _parseVariationResponse(
        response.data as Map<String, dynamic>,
        attributiProdotto: variante.attributi,
      );

      log.e(
        '✅ Variante ${variante.sku} creata con successo (ID: ${nuovaVariante.id})',
      );
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

    return _parseVariationResponse(
      response.data as Map<String, dynamic>,
      attributiProdotto: variante.attributi,
    );
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
  Future<List<VarianteProductGlobal>> getAllVariations(
    int productId, {
    String? includeStatus,
  }) async {
    final List<VarianteProductGlobal> allVariations = [];
    int currentPage = 1;
    bool hasMore = true;

    while (hasMore) {
      final variations = await getProductVariations(
        productId,
        page: currentPage,
        perPage: 100,
        includeStatus: includeStatus,
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
  Future<List<VarianteProductGlobal>> getAvailableVariations(
    int productId,
  ) async {
    final allVariations = await getAllVariations(productId);
    return allVariations.where((v) => v.quantita > 0).toList();
  }

  String? _normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return null;
    final normalized = status.trim().toLowerCase();
    const allowed = {'publish', 'draft', 'private', 'pending'};
    if (!allowed.contains(normalized)) {
      log.d('Status variante non supportato ignorato: $status');
      return null;
    }
    return normalized;
  }

  bool _isSkuDuplicateError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final code = (data['code'] ?? '').toString().toLowerCase();
      final message = (data['message'] ?? '').toString().toLowerCase();
      return code.contains('sku') || message.contains('sku');
    }
    return false;
  }

  String _fallbackSku(String originalSku) {
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
    return '$originalSku-$suffix';
  }

  String? _extractSuggestedSku(DioException e) {
    final data = e.response?.data;
    if (data is! Map<String, dynamic>) return null;

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      final unique = nested['unique_sku'];
      if (unique is String && unique.trim().isNotEmpty) {
        return unique.trim();
      }
    }

    final top = data['unique_sku'];
    if (top is String && top.trim().isNotEmpty) {
      return top.trim();
    }

    return null;
  }

  VarianteProductGlobal _parseVariationResponse(
    Map<String, dynamic> variationData, {
    List<AttributoVariante>? attributiProdotto,
  }) {
    try {
      final wooVariation = WooProductVariation.fromJson(variationData);
      return _convertToVarianteWoo(wooVariation);
    } catch (e) {
      log.d(
        'Errore parsing WooProductVariation, uso fallback JSON diretto: $e',
      );
      return _convertJsonToVarianteWoo(
        variationData,
        attributiProdotto: attributiProdotto,
      );
    }
  }

  /// Ottiene varianti esaurite
  Future<List<VarianteProductGlobal>> getOutOfStockVariations(
    int productId,
  ) async {
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
          final varAttr = variation.attributi
              .where((a) => a.nome.toLowerCase() == attr.key.toLowerCase())
              .firstOrNull;

          if (varAttr == null ||
              varAttr.opzione.toLowerCase() != attr.value.toLowerCase()) {
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

  /// Estrae il numero di variante dal SKU o dall'ID
  /// Esempi: "T-SHIRT-VAR1" -> 1, "T-SHIRT-VAR2" -> 2
  int _extractVarianteNumber(String sku, int variationId) {
    // Prova a estrarre dal SKU pattern VAR1, VAR2, etc.
    final varMatch = RegExp(r'VAR(\d+)').firstMatch(sku);
    if (varMatch != null) {
      return int.tryParse(varMatch.group(1) ?? '1') ?? 1;
    }

    // Fallback: usa l'ID della variante per determinare l'ordine
    // Questo è un approccio semplificato - in produzione potresti voler
    // ordinare le varianti per ID e usare l'indice
    return variationId % 10 + 1; // Semplice euristica basata sull'ID
  }

  /// Recupera i metadata custom di una variante prodotto
  Future<Map<String, String>> getProductVariationMetadata(
    int productId,
    int variationId,
  ) async {
    try {
      log.d(
        '🔍 Recupero metadata per variante $variationId del prodotto $productId',
      );

      final response = await _woo.dio.get(
        '/products/$productId/variations/$variationId',
      );

      if (response.statusCode == 200) {
        final variationData = response.data as Map<String, dynamic>;
        final metaData = variationData['meta_data'] as List<dynamic>? ?? [];

        final metadataMap = <String, String>{};
        for (final meta in metaData) {
          if (meta['key'] != null) {
            metadataMap[meta['key'].toString()] =
                meta['value']?.toString() ?? '';
          }
        }

        log.d(
          '✅ Recuperati ${metadataMap.length} metadata per variante $variationId',
        );
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
