import '../class_prodotti.dart';
import '../../login/jwt_api/adapter/platform_manager.dart';
import '../../login/jwt_api/query_mgws/query_mgws_inventory.dart';

class ProductMgwsStockInput {
  const ProductMgwsStockInput({
    required this.stockText,
    required this.reasonText,
  });

  final String stockText;
  final String reasonText;
}

class ProductMgwsStockFeedback {
  const ProductMgwsStockFeedback({
    required this.success,
    required this.message,
    this.details = const [],
  });

  final bool success;
  final String message;
  final List<String> details;
}

String? validateProductMgwsStock({required bool enabled, String? value}) {
  if (!enabled) return null;
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return 'Stock MGWS obbligatorio';
  final parsed = int.tryParse(normalized);
  if (parsed == null || parsed < 0) return 'Inserisci un intero non negativo';
  return null;
}

String? validateProductMgwsReason({required bool enabled, String? value}) {
  if (!enabled) return null;
  if ((value ?? '').trim().isEmpty) return 'Motivo obbligatorio';
  return null;
}

/// Controller per la creazione e gestione dei prodotti
/// Usa PlatformManager per supporto multi-piattaforma
class ProdottiCreaController {
  // Cache per evitare chiamate ripetute
  List<CategoriaProdotto>? _categoriesCache;
  List<TagProdotto>? _tagsCache;
  List<MarcaProdotto>? _brandsCache;

  ProdottiCreaController({MgwsInventoryGateway? inventoryGateway})
    : _inventoryGateway = inventoryGateway ?? QueryMgwsInventory();

  final MgwsInventoryGateway _inventoryGateway;

  // =======================================================
  // == METODI PRINCIPALI                                 ==
  // =======================================================

  /// Ottiene un singolo prodotto per ID
  Future<ProdottoGlobal> getProductById(int productId) async {
    return await PlatformManager.prodotti.getProductById(productId);
  }

  /// Ottiene tutte le varianti di un prodotto
  Future<List<VarianteProductGlobal>> getAllVarianti(int productId) async {
    return await PlatformManager.varianti.getAllVariations(productId);
  }

  /// Ottiene tutte le categorie con cache
  Future<List<CategoriaProdotto>> getCategories({
    bool forceRefresh = false,
  }) async {
    if (_categoriesCache == null || forceRefresh) {
      _categoriesCache = await PlatformManager.categorie.getCategories(
        perPage: 100,
      );
    }
    return _categoriesCache!;
  }

  /// Ottiene tutti i tag con cache
  Future<List<TagProdotto>> getTags({bool forceRefresh = false}) async {
    if (_tagsCache == null || forceRefresh) {
      _tagsCache = await PlatformManager.tag.getTags(perPage: 100);
    }
    return _tagsCache!;
  }

  /// Ottiene tutti i marchi con cache
  Future<List<MarcaProdotto>> getBrands({bool forceRefresh = false}) async {
    if (_brandsCache == null || forceRefresh) {
      _brandsCache = await PlatformManager.marchi.getBrands(perPage: 100);
    }
    return _brandsCache!;
  }

  /// Ottiene tutti gli attributi con cache
  Future<List<dynamic>> getAttributes({bool forceRefresh = false}) async {
    return await PlatformManager.attributi.getAttributes();
  }

  /// Ottiene i termini di un attributo specifico
  Future<List<dynamic>> getAttributeTerms(
    int attributeId, {
    bool forceRefresh = false,
  }) async {
    return await PlatformManager.attributi.getAttributeTerms(attributeId);
  }

  /// Crea un nuovo prodotto
  Future<ProdottoGlobal> creaProdotto(ProdottoGlobal prodotto) async {
    try {
      // Usa PlatformManager per creare il prodotto
      return await PlatformManager.prodotti.createProduct(prodotto);
    } catch (e) {
      throw Exception('Errore durante la creazione del prodotto: $e');
    }
  }

  /// Aggiorna un prodotto esistente
  Future<ProdottoGlobal> aggiornaProdotto(ProdottoGlobal prodotto) async {
    try {
      // Usa PlatformManager per aggiornare il prodotto
      return await PlatformManager.prodotti.updateProduct(prodotto);
    } catch (e) {
      throw Exception('Errore durante l\'aggiornamento del prodotto: $e');
    }
  }

  // =======================================================
  // == GESTIONE VARIANTI E ATTRIBUTI                     ==
  // =======================================================

  /// Crea o aggiorna un prodotto completo con le sue varianti
  /// Il backend si occuperà di gestire categorie, tag, attributi e varianti
  Future<ProdottoGlobal> salvaProductoConVarianti(
    ProdottoGlobal prodotto,
  ) async {
    try {
      // Il backend gestisce tutto: creazione categorie/tag/attributi/varianti
      if ((prodotto.id ?? 0) == 0) {
        // Crea prodotto nuovo
        return await creaProdotto(prodotto);
      } else {
        // Aggiorna prodotto esistente
        return await aggiornaProdotto(prodotto);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductMgwsStockFeedback> reconcileMgwsStockAfterSave({
    required ProdottoGlobal savedProduct,
    required ProductMgwsStockInput input,
  }) async {
    final productId = savedProduct.id ?? 0;
    if (productId <= 0) {
      return const ProductMgwsStockFeedback(
        success: false,
        message:
            'Prodotto salvato, ma stock MGWS non registrato: product_id mancante.',
      );
    }

    final correctStock = int.tryParse(input.stockText.trim());
    if (correctStock == null || correctStock < 0) {
      return const ProductMgwsStockFeedback(
        success: false,
        message:
            'Prodotto salvato, ma stock MGWS non registrato: stock non valido.',
      );
    }

    final reason = input.reasonText.trim();
    if (reason.isEmpty) {
      return const ProductMgwsStockFeedback(
        success: false,
        message:
            'Prodotto salvato, ma stock MGWS non registrato: motivo obbligatorio.',
      );
    }

    try {
      final result = await _inventoryGateway.reconcileStock(
        productId: productId,
        correctStock: correctStock,
        reason: reason,
      );
      final delta = result.delta == null
          ? ''
          : ' (delta ${result.delta! > 0 ? '+' : ''}${result.delta})';
      if (!result.success || result.errors.isNotEmpty) {
        return ProductMgwsStockFeedback(
          success: false,
          message:
              'Prodotto salvato, ma stock MGWS non registrato: ${result.message}$delta',
          details: result.errors,
        );
      }
      return ProductMgwsStockFeedback(
        success: true,
        message: 'Stock MGWS registrato: ${result.message}$delta',
        details: result.errors,
      );
    } catch (e) {
      return ProductMgwsStockFeedback(
        success: false,
        message: 'Prodotto salvato, ma stock MGWS non registrato: $e',
      );
    }
  }

  /// Pulisce la cache
  void clearCache() {
    _categoriesCache = null;
    _tagsCache = null;
    _brandsCache = null;
  }
}

// Extension per gestire valori null nelle liste
extension ListExtensions<T> on List<T>? {
  T? get firstOrNull {
    if (this == null || this!.isEmpty) return null;
    return this!.first;
  }
}
