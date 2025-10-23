// Reference Resolver - Gestione automatica riferimenti (categorie, tag, ecc.)
//
// Implementa la logica WooCommerce per creare automaticamente:
// - Categorie se non esistono (con supporto gerarchia Cat>SubCat)
// - Tag se non esistono
// - Attributi se non esistono
//
// Equivalente a WC_Product_Importer::get_attribute_taxonomy_id() e simili

import '../login/jwt_api/query_woocommerce/woo_query_categoria.dart';
import '../login/jwt_api/query_woocommerce/woo_query_tag.dart';
import '../prodotti/class_prodotti.dart';
import '../log_viewer/app_logger.dart';

/// Cache locale per evitare query ridondanti
class _Cache {
  final Map<String, CategoriaProdotto> categories = {};
  final Map<String, TagProdotto> tags = {};

  void clear() {
    categories.clear();
    tags.clear();
  }
}

/// Resolver per riferimenti prodotto
/// Crea automaticamente categorie/tag se non esistono (come fa WooCommerce)
class ReferenceResolver {
  final WooQueryCategoria _categoryQuery = WooQueryCategoria();
  final WooQueryTag _tagQuery = WooQueryTag();

  final _Cache _cache = _Cache();

  /// Reset cache
  void clearCache() {
    _cache.clear();
  }

  // ========================================================================
  // CATEGORIE
  // ========================================================================

  /// Risolve una lista di nomi categorie in IDs
  /// Crea categorie se non esistono
  /// Supporta gerarchia: "Abbigliamento>Uomo>T-Shirt"
  ///
  /// Equivalente a WooCommerce che crea automaticamente categorie mancanti
  Future<List<int>> resolveCategoryNames(List<String> categoryNames) async {
    final List<int> categoryIds = [];

    for (final categoryPath in categoryNames) {
      try {
        final id = await _resolveCategoryPath(categoryPath.trim());
        if (id != null) {
          categoryIds.add(id);
        }
      } catch (e) {
        log.e('❌ Errore risoluzione categoria "$categoryPath"', e);
        // Continua con altre categorie
      }
    }

    return categoryIds;
  }

  /// Risolve un path di categoria (es: "Parent>Child>SubChild")
  /// Crea l'intera gerarchia se non esiste
  Future<int?> _resolveCategoryPath(String path) async {
    // Splitta path per gerarchia (separatore: >)
    final parts = path.split('>').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) return null;

    int? parentId;

    // Processa ogni livello della gerarchia
    for (int i = 0; i < parts.length; i++) {
      final categoryName = parts[i];
      final categoryKey = parentId != null
          ? '$parentId:$categoryName'
          : categoryName;

      // Check cache prima
      if (_cache.categories.containsKey(categoryKey)) {
        parentId = _cache.categories[categoryKey]!.id;
        continue;
      }

      // Cerca categoria esistente
      CategoriaProdotto? category = await _findCategory(categoryName, parentId);

      // Se non esiste, crea
      if (category == null) {
        log.i('📁 Creazione categoria: "$categoryName"${parentId != null ? " (parent: $parentId)" : ""}');
        category = await _createCategory(categoryName, parentId);
      }

      // Salva in cache
      _cache.categories[categoryKey] = category;
      parentId = category.id;
    }

    return parentId;
  }

  /// Cerca categoria per nome e parent
  Future<CategoriaProdotto?> _findCategory(String name, int? parentId) async {
    try {
      final categories = await _categoryQuery.searchCategories(name);

      // Filtra per nome esatto e parent
      for (final cat in categories) {
        if (cat.nome.toLowerCase() == name.toLowerCase()) {
          // Verifica parent
          if (parentId == null && (cat.parentId == null || cat.parentId == 0)) {
            return cat;
          } else if (parentId != null && cat.parentId == parentId) {
            return cat;
          }
        }
      }

      return null;
    } catch (e) {
      log.w('⚠️ Errore ricerca categoria "$name"', e);
      return null;
    }
  }

  /// Crea nuova categoria
  Future<CategoriaProdotto> _createCategory(String name, int? parentId) async {
    try {
      return await _categoryQuery.createCategory(
        name: name,
        parent: parentId,
        slug: _generateSlug(name),
      );
    } catch (e) {
      log.e('❌ Errore creazione categoria "$name"', e);
      rethrow;
    }
  }

  // ========================================================================
  // TAG
  // ========================================================================

  /// Risolve una lista di nomi tag in IDs
  /// Crea tag se non esistono
  ///
  /// Equivalente a WooCommerce che crea automaticamente tag mancanti
  Future<List<int>> resolveTagNames(List<String> tagNames) async {
    final List<int> tagIds = [];

    for (final tagName in tagNames) {
      if (tagName.trim().isEmpty) continue;

      try {
        // Check cache
        if (_cache.tags.containsKey(tagName)) {
          tagIds.add(_cache.tags[tagName]!.id);
          continue;
        }

        // Cerca tag esistente
        TagProdotto? tag = await _findTag(tagName);

        // Se non esiste, crea
        if (tag == null) {
          log.i('🏷️ Creazione tag: "$tagName"');
          tag = await _createTag(tagName);
        }

        // Salva in cache
        _cache.tags[tagName] = tag;
        tagIds.add(tag.id);

      } catch (e) {
        log.e('❌ Errore risoluzione tag "$tagName"', e);
        // Continua con altri tag
      }
    }

    return tagIds;
  }

  /// Cerca tag per nome
  Future<TagProdotto?> _findTag(String name) async {
    try {
      final tags = await _tagQuery.searchTags(name);

      // Cerca match esatto (case insensitive)
      for (final tag in tags) {
        if (tag.nome.toLowerCase() == name.toLowerCase()) {
          return tag;
        }
      }

      return null;
    } catch (e) {
      log.w('⚠️ Errore ricerca tag "$name"', e);
      return null;
    }
  }

  /// Crea nuovo tag
  Future<TagProdotto> _createTag(String name) async {
    try {
      return await _tagQuery.createTag(
        name: name,
        slug: _generateSlug(name),
      );
    } catch (e) {
      log.e('❌ Errore creazione tag "$name"', e);
      rethrow;
    }
  }

  // ========================================================================
  // UTILITY
  // ========================================================================

  /// Genera slug da nome (lowercase, spazi → trattini)
  /// Equivalente a sanitize_title() di WordPress
  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Rimuovi caratteri speciali
        .replaceAll(RegExp(r'\s+'), '-') // Spazi → trattini
        .replaceAll(RegExp(r'-+'), '-') // Trattini multipli → singolo
        .replaceAll(RegExp(r'^-|-$'), ''); // Rimuovi trattini iniziali/finali
  }

  /// Pre-carica categorie e tag esistenti in cache (opzionale, per performance)
  /// Utile prima di import massivi
  Future<void> preloadCache() async {
    try {
      log.i('📦 Pre-caricamento cache categorie e tag...');

      // Carica tutte le categorie
      final categories = await _categoryQuery.getAllCategories();
      for (final cat in categories) {
        final key = cat.parentId != null && cat.parentId! > 0
            ? '${cat.parentId}:${cat.nome}'
            : cat.nome;
        _cache.categories[key] = cat;
      }

      // Carica tutti i tag
      final tags = await _tagQuery.getAllTags();
      for (final tag in tags) {
        _cache.tags[tag.nome] = tag;
      }

      log.i('✅ Cache caricata: ${_cache.categories.length} categorie, ${_cache.tags.length} tag');

    } catch (e) {
      log.w('⚠️ Errore pre-caricamento cache', e);
      // Non blocca l'import, continua senza cache
    }
  }

  /// Ottiene statistiche cache
  Map<String, int> getCacheStats() {
    return {
      'categories': _cache.categories.length,
      'tags': _cache.tags.length,
    };
  }
}
