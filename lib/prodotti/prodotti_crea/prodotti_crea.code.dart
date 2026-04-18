import '../class_prodotti.dart';
import '../../login/jwt_api/adapter/platform_manager.dart';

/// Controller per la creazione e gestione dei prodotti
/// Usa PlatformManager per supporto multi-piattaforma
class ProdottiCreaController {
  // Cache per evitare chiamate ripetute
  List<CategoriaProdotto>? _categoriesCache;
  List<TagProdotto>? _tagsCache;
  List<MarcaProdotto>? _brandsCache;

  ProdottiCreaController();

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
