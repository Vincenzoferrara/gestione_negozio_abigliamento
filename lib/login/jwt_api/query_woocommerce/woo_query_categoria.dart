import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../jwt_connect.dart';
import '../error_list.dart';
import '../../../prodotti/class_prodotti.dart';

/// Query class per la gestione delle categorie prodotti WooCommerce
/// Converte i dati WooCommerce in modelli globali multi-piattaforma
class WooQueryCategoria {
  // Singleton pattern
  static final WooQueryCategoria _instance = WooQueryCategoria._internal();
  factory WooQueryCategoria() => _instance;
  WooQueryCategoria._internal();

  final JwtConnect _auth = JwtConnect();
  WooCommerce? _woo;

  /// Ottiene l'istanza WooCommerce con autenticazione JWT
  WooCommerce _getWooCommerce() {
    if (!_auth.isConnected) {
      throw UnauthorizedException();
    }

    if (_woo != null) return _woo!;

    _woo = WooCommerce(
      baseUrl: _auth.currentSiteUrl!,
      username: '',
      password: '',
      useFaker: false,
      isDebug: false,
    );

    // Usa il Dio autenticato di JwtConnect
    _woo!.dio = _auth.getAuthenticatedDio();
    return _woo!;
  }

  /// Reset dell'istanza WooCommerce (utile dopo logout)
  void reset() {
    _woo = null;
  }

  // =======================================================
  // == CONVERSIONE WOOCOMMERCE → MODELLO GLOBALE        ==
  // =======================================================

  /// Converte WooProductCategory in CategoriaProdotto (modello globale)
  CategoriaProdotto _convertToCategoriaProdotto(WooProductCategory wooCategory) {
    return CategoriaProdotto(
      id: wooCategory.id ?? 0,
      nome: wooCategory.name ?? '',
      slug: wooCategory.slug ?? '',
      descrizione: wooCategory.description,
      immagine: wooCategory.image?.src,
      parentId: (wooCategory.parent == null || wooCategory.parent == 0) ? null : wooCategory.parent,
      count: wooCategory.count ?? 0,
      visibile: true,
    );
  }

  // =======================================================
  // == METODI CATEGORIE (Restituiscono modello globale) ==
  // =======================================================

  /// Ottiene lista categorie con paginazione e filtri
  Future<List<CategoriaProdotto>> getCategories({
    int page = 1,
    int perPage = 20,
    String? search,
    int? parent,
    bool? hideEmpty,
    String orderBy = 'name',
    String order = 'asc',
  }) async {
    try {
      final woo = _getWooCommerce();

      final wooCategories = await woo.getCategories(
        page: page,
        perPage: perPage,
        search: search,
        parent: parent,
        hideEmpty: hideEmpty,
      );

      return wooCategories.map((wc) => _convertToCategoriaProdotto(wc)).toList();
    } catch (e) {
      print('❌ Errore getCategories: $e');
      rethrow;
    }
  }

  /// Ottiene una categoria specifica per ID
  Future<CategoriaProdotto> getCategoryById(int categoryId) async {
    try {
      final woo = _getWooCommerce();
      final wooCategory = await woo.getCategory(categoryId);
      return _convertToCategoriaProdotto(wooCategory);
    } catch (e) {
      print('❌ Errore getCategoryById: $e');
      rethrow;
    }
  }

  /// Ottiene categorie principali (senza parent)
  Future<List<CategoriaProdotto>> getMainCategories({
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final woo = _getWooCommerce();
      final wooCategories = await woo.getCategories(
        parent: 0,
        page: page,
        perPage: perPage,
      );
      return wooCategories.map((wc) => _convertToCategoriaProdotto(wc)).toList();
    } catch (e) {
      print('❌ Errore getMainCategories: $e');
      rethrow;
    }
  }

  /// Ottiene sottocategorie di una categoria
  Future<List<CategoriaProdotto>> getSubcategories(int parentId, {
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final woo = _getWooCommerce();
      final wooCategories = await woo.getCategories(
        parent: parentId,
        page: page,
        perPage: perPage,
      );
      return wooCategories.map((wc) => _convertToCategoriaProdotto(wc)).toList();
    } catch (e) {
      print('❌ Errore getSubcategories: $e');
      rethrow;
    }
  }

  /// Cerca categorie per nome
  Future<List<CategoriaProdotto>> searchCategories(String searchTerm) async {
    try {
      final woo = _getWooCommerce();
      final wooCategories = await woo.getCategories(
        search: searchTerm,
        perPage: 100,
      );
      return wooCategories.map((wc) => _convertToCategoriaProdotto(wc)).toList();
    } catch (e) {
      print('❌ Errore searchCategories: $e');
      rethrow;
    }
  }

  /// Crea una nuova categoria
  Future<CategoriaProdotto> createCategory({
    required String name,
    String? slug,
    int? parent,
    String? description,
    String? display,
    int? image,
    int? menuOrder,
  }) async {
    try {
      final woo = _getWooCommerce();

      final categoryData = {
        'name': name,
        if (slug != null) 'slug': slug,
        if (parent != null) 'parent': parent,
        if (description != null) 'description': description,
        if (display != null) 'display': display,
        if (image != null) 'image': {'id': image},
        if (menuOrder != null) 'menu_order': menuOrder,
      };

      final wooCategory = await woo.createCategory(WooProductCategory.fromJson(categoryData));
      return _convertToCategoriaProdotto(wooCategory);
    } catch (e) {
      print('❌ Errore createCategory: $e');
      rethrow;
    }
  }

  /// Aggiorna una categoria esistente
  Future<CategoriaProdotto> updateCategory({
    required int categoryId,
    String? name,
    String? slug,
    int? parent,
    String? description,
    String? display,
    int? image,
    int? menuOrder,
  }) async {
    try {
      final woo = _getWooCommerce();

      // Prima ottieni la categoria esistente
      final existingCategory = await woo.getCategory(categoryId);

      // Crea una nuova categoria con i campi aggiornati
      final updatedCategory = WooProductCategory(
        id: categoryId,
        name: name ?? existingCategory.name,
        slug: slug ?? existingCategory.slug,
        parent: parent ?? existingCategory.parent,
        description: description ?? existingCategory.description,
        display: display != null ? WooCategoryDisplay.values.firstWhere(
          (e) => e.name == display,
          orElse: () => existingCategory.display ?? WooCategoryDisplay.both,
        ) : existingCategory.display,
        image: image != null ? WooProductCategoryImage(id: image) : existingCategory.image,
        menuOrder: menuOrder ?? existingCategory.menuOrder,
        count: existingCategory.count,
      );

      final wooCategory = await woo.updateCategory(updatedCategory);
      return _convertToCategoriaProdotto(wooCategory);
    } catch (e) {
      print('❌ Errore updateCategory: $e');
      rethrow;
    }
  }

  /// Elimina una categoria
  Future<bool> deleteCategory({
    required int categoryId,
    bool force = false,
  }) async {
    final woo = _getWooCommerce();
    return await woo.deleteCategory(categoryId, force: force);
  }

  /// Ottiene tutte le categorie (uso con cautela!)
  Future<List<CategoriaProdotto>> getAllCategories() async {
    try {
      final woo = _getWooCommerce();
      final List<CategoriaProdotto> allCategories = [];
      int currentPage = 1;
      bool hasMore = true;

      while (hasMore) {
        final wooCategories = await woo.getCategories(
          page: currentPage,
          perPage: 100,
        );

        if (wooCategories.isEmpty) {
          hasMore = false;
        } else {
          allCategories.addAll(wooCategories.map((wc) => _convertToCategoriaProdotto(wc)));
          currentPage++;
        }
      }

      return allCategories;
    } catch (e) {
      print('❌ Errore getAllCategories: $e');
      rethrow;
    }
  }

  /// Batch update categorie
  Future<Map<String, dynamic>> batchUpdateCategories({
    List<Map<String, dynamic>>? create,
    List<Map<String, dynamic>>? update,
    List<int>? delete,
  }) async {
    final batchData = {
      if (create != null && create.isNotEmpty) 'create': create,
      if (update != null && update.isNotEmpty) 'update': update,
      if (delete != null && delete.isNotEmpty) 'delete': delete,
    };

    // Usa Dio diretto perché batch non è nel package
    final response = await _auth.getAuthenticatedDio().post(
      '${_auth.currentSiteUrl}/wp-json/wc/v3/products/categories/batch',
      data: batchData,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Ottiene l'albero delle categorie (gerarchico)
  Future<List<Map<String, dynamic>>> getCategoryTree() async {
    try {
      final mainCategories = await getMainCategories(perPage: 100);
      final List<Map<String, dynamic>> tree = [];

      for (var category in mainCategories) {
        final subcategories = await getSubcategories(category.id);
        tree.add({
          'category': category,
          'subcategories': subcategories,
        });
      }

      return tree;
    } catch (e) {
      print('❌ Errore getCategoryTree: $e');
      rethrow;
    }
  }

  /// Conta i prodotti in una categoria
  Future<int> countProductsInCategory(int categoryId) async {
    try {
      final category = await getCategoryById(categoryId);
      return category.count;
    } catch (e) {
      print('❌ Errore countProductsInCategory: $e');
      return 0;
    }
  }

  /// Verifica se una categoria ha sottocategorie
  Future<bool> hasSubcategories(int categoryId) async {
    final subcategories = await getSubcategories(categoryId, perPage: 1);
    return subcategories.isNotEmpty;
  }

  /// Ottiene categorie vuote
  Future<List<CategoriaProdotto>> getEmptyCategories() async {
    try {
      final woo = _getWooCommerce();
      final wooCategories = await woo.getCategories(
        hideEmpty: true,
        perPage: 100,
      );
      return wooCategories.map((wc) => _convertToCategoriaProdotto(wc)).toList();
    } catch (e) {
      print('❌ Errore getEmptyCategories: $e');
      rethrow;
    }
  }

  /// Riordina le categorie
  Future<List<CategoriaProdotto>> reorderCategories(
    List<Map<String, dynamic>> categoriesWithOrder,
  ) async {
    try {
      final updates = categoriesWithOrder.map((item) {
        return {
          'id': item['id'],
          'menu_order': item['menu_order'],
        };
      }).toList();

      await batchUpdateCategories(update: updates);
      return await getCategories(perPage: 100);
    } catch (e) {
      print('❌ Errore reorderCategories: $e');
      rethrow;
    }
  }

  /// Sposta una categoria sotto un nuovo parent
  Future<CategoriaProdotto> moveCategory({
    required int categoryId,
    required int newParentId,
  }) async {
    return await updateCategory(
      categoryId: categoryId,
      parent: newParentId,
    );
  }

  /// Ottiene il percorso (breadcrumb) di una categoria
  Future<List<CategoriaProdotto>> getCategoryPath(int categoryId) async {
    try {
      final List<CategoriaProdotto> path = [];
      CategoriaProdotto? currentCategory = await getCategoryById(categoryId);

      while (currentCategory != null) {
        path.insert(0, currentCategory);
        if (currentCategory.parentId != null && currentCategory.parentId! > 0) {
          currentCategory = await getCategoryById(currentCategory.parentId!);
        } else {
          currentCategory = null;
        }
      }

      return path;
    } catch (e) {
      print('❌ Errore getCategoryPath: $e');
      rethrow;
    }
  }

  /// Ottiene statistiche categorie
  Future<Map<String, dynamic>> getCategoryStats() async {
    final response = await _auth.getAuthenticatedDio().get(
      '${_auth.currentSiteUrl}/wp-json/wc/v3/products/categories',
      queryParameters: {'per_page': 1, 'page': 1},
    );

    final totalCategories = int.tryParse(
      response.headers.value('x-wp-total') ?? '0'
    ) ?? 0;

    final mainCategories = await getMainCategories(perPage: 1);
    final emptyCategories = await getEmptyCategories();

    return {
      'total_categories': totalCategories,
      'main_categories_count': mainCategories.length,
      'empty_categories_count': emptyCategories.length,
    };
  }

  /// Ottiene categorie più popolari (con più prodotti)
  Future<List<CategoriaProdotto>> getPopularCategories({int limit = 10}) async {
    try {
      final categories = await getCategories(hideEmpty: true, perPage: 100);

      // Ordina per count (numero di prodotti) decrescente
      categories.sort((a, b) => b.count.compareTo(a.count));

      return categories.take(limit).toList();
    } catch (e) {
      print('❌ Errore getPopularCategories: $e');
      rethrow;
    }
  }

  /// Conta i prodotti in una categoria (ricorsivo per sottocategorie)
  Future<int> getTotalProductsInCategory(int categoryId, {bool includeSubcategories = true}) async {
    try {
      var total = 0;

      // Conta prodotti nella categoria corrente
      final category = await getCategoryById(categoryId);
      total += category.count;

      // Se richiesto, conta anche nelle sottocategorie
      if (includeSubcategories) {
        final subCategories = await getSubcategories(categoryId);
        for (final subCategory in subCategories) {
          total += await getTotalProductsInCategory(subCategory.id, includeSubcategories: true);
        }
      }

      return total;
    } catch (e) {
      print('❌ Errore getTotalProductsInCategory: $e');
      return 0;
    }
  }

  /// Verifica se una categoria può essere eliminata (non ha prodotti né sottocategorie)
  Future<bool> canDeleteCategory(int categoryId) async {
    try {
      final category = await getCategoryById(categoryId);
      final hasProducts = category.count > 0;
      final hasSubcategoriesResult = await hasSubcategories(categoryId);

      return !hasProducts && !hasSubcategoriesResult;
    } catch (e) {
      print('❌ Errore canDeleteCategory: $e');
      return false;
    }
  }

  /// Ottiene statistiche categoria dettagliate
  Future<Map<String, dynamic>> getCategoryDetailedStats(int categoryId) async {
    try {
      final category = await getCategoryById(categoryId);
      final subCategories = await getSubcategories(categoryId);
      final totalProducts = await getTotalProductsInCategory(categoryId);
      final path = await getCategoryPath(categoryId);

      return {
        'nome': category.nome,
        'slug': category.slug,
        'prodotti_diretti': category.count,
        'prodotti_totali': totalProducts,
        'sottocategorie': subCategories.length,
        'livello_profondita': path.length,
        'path': path.map((c) => c.nome).join(' > '),
      };
    } catch (e) {
      print('❌ Errore getCategoryDetailedStats: $e');
      rethrow;
    }
  }
}
