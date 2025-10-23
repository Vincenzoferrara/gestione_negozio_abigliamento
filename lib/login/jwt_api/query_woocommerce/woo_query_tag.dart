import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../jwt_connect.dart';
import '../error_list.dart';
import '../../../prodotti/class_prodotti.dart';

/// Query class per la gestione dei tag prodotti WooCommerce
/// Converte i dati WooCommerce in modelli globali multi-piattaforma
class WooQueryTag {
  // Singleton pattern
  static final WooQueryTag _instance = WooQueryTag._internal();
  factory WooQueryTag() => _instance;
  WooQueryTag._internal();

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

  /// Converte WooProductTag in TagProdotto (modello globale)
  TagProdotto _convertToTagProdotto(WooProductTag wooTag) {
    return TagProdotto(
      id: wooTag.id ?? 0,
      nome: wooTag.name ?? '',
      slug: wooTag.slug ?? '',
      descrizione: wooTag.description,
      count: wooTag.count ?? 0,
    );
  }

  // =======================================================
  // == METODI TAG (Restituiscono modello globale)       ==
  // =======================================================

  /// Ottiene lista tag con paginazione e filtri
  Future<List<TagProdotto>> getTags({
    int page = 1,
    int perPage = 100,
    String? search,
    bool hideEmpty = false,
  }) async {
    try {
      final woo = _getWooCommerce();

      final wooTags = await woo.getProductTags(
        page: page,
        perPage: perPage,
        search: search,
        hideEmpty: hideEmpty,
      );

      return wooTags.map((wt) => _convertToTagProdotto(wt)).toList();
    } catch (e) {
      print('❌ Errore getTags: $e');
      rethrow;
    }
  }

  /// Ottiene un tag per ID
  Future<TagProdotto> getTagById(int tagId) async {
    try {
      final woo = _getWooCommerce();
      final wooTag = await woo.getProductTag(tagId);
      return _convertToTagProdotto(wooTag);
    } catch (e) {
      print('❌ Errore getTagById: $e');
      rethrow;
    }
  }

  /// Cerca tag per nome
  Future<List<TagProdotto>> searchTags(String searchTerm) async {
    try {
      final woo = _getWooCommerce();
      final wooTags = await woo.getProductTags(
        search: searchTerm,
        perPage: 100,
      );
      return wooTags.map((wt) => _convertToTagProdotto(wt)).toList();
    } catch (e) {
      print('❌ Errore searchTags: $e');
      rethrow;
    }
  }

  /// Crea un nuovo tag
  Future<TagProdotto> createTag({
    required String name,
    String? slug,
    String? description,
  }) async {
    try {
      final woo = _getWooCommerce();

      final tag = WooProductTag(
        null, // id
        name,
        slug,
        description,
        0, // count
      );

      final wooTag = await woo.createProductTag(tag);
      return _convertToTagProdotto(wooTag);
    } catch (e) {
      print('❌ Errore createTag: $e');
      rethrow;
    }
  }

  /// Aggiorna un tag esistente
  Future<TagProdotto> updateTag({
    required int tagId,
    String? name,
    String? slug,
    String? description,
  }) async {
    try {
      final woo = _getWooCommerce();

      // Prima ottieni il tag esistente
      final existingTag = await woo.getProductTag(tagId);

      // Crea un nuovo tag con i campi aggiornati
      final updatedTag = WooProductTag(
        tagId,
        name ?? existingTag.name,
        slug ?? existingTag.slug,
        description ?? existingTag.description,
        existingTag.count,
      );

      final wooTag = await woo.updateProductTag(updatedTag);
      return _convertToTagProdotto(wooTag);
    } catch (e) {
      print('❌ Errore updateTag: $e');
      rethrow;
    }
  }

  /// Elimina un tag
  Future<bool> deleteTag({
    required int tagId,
  }) async {
    try {
      final woo = _getWooCommerce();
      await woo.deleteProductTag(tagId);
      return true;
    } catch (e) {
      print('❌ Errore deleteTag: $e');
      rethrow;
    }
  }

  /// Ottiene tutti i tag (uso con cautela!)
  Future<List<TagProdotto>> getAllTags() async {
    try {
      final woo = _getWooCommerce();
      final List<TagProdotto> allTags = [];
      int currentPage = 1;
      bool hasMore = true;

      while (hasMore) {
        final wooTags = await woo.getProductTags(
          page: currentPage,
          perPage: 100,
        );

        if (wooTags.isEmpty) {
          hasMore = false;
        } else {
          allTags.addAll(wooTags.map((wt) => _convertToTagProdotto(wt)));
          currentPage++;
        }
      }

      return allTags;
    } catch (e) {
      print('❌ Errore getAllTags: $e');
      rethrow;
    }
  }

  /// Batch update tag (usa Dio diretto)
  Future<Map<String, dynamic>> batchUpdateTags({
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
      '\${_auth.currentSiteUrl}/wp-json/wc/v3/products/tags/batch',
      data: batchData,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Verifica se un tag esiste per nome
  Future<bool> tagExists(String name) async {
    try {
      final tags = await searchTags(name);
      return tags.any((tag) => tag.nome.toLowerCase() == name.toLowerCase());
    } catch (e) {
      print('❌ Errore tagExists: $e');
      return false;
    }
  }

  /// Ottiene tag per slug
  Future<TagProdotto?> getTagBySlug(String slug) async {
    try {
      final woo = _getWooCommerce();
      final wooTags = await woo.getProductTags(
        slug: slug,
        perPage: 1,
      );

      return wooTags.isNotEmpty ? _convertToTagProdotto(wooTags.first) : null;
    } catch (e) {
      print('❌ Errore getTagBySlug: $e');
      return null;
    }
  }

  /// Ottiene statistiche tag
  Future<Map<String, dynamic>> getTagStats() async {
    final response = await _auth.getAuthenticatedDio().get(
      '\${_auth.currentSiteUrl}/wp-json/wc/v3/products/tags',
      queryParameters: {'per_page': 1, 'page': 1},
    );

    final totalTags = int.tryParse(
      response.headers.value('x-wp-total') ?? '0'
    ) ?? 0;

    return {
      'total_tags': totalTags,
    };
  }

  /// Ottiene tag più usati
  Future<List<TagProdotto>> getTopTags({int limit = 10}) async {
    try {
      final woo = _getWooCommerce();
      final wooTags = await woo.getProductTags(
        perPage: limit,
        orderBy: WooSortProductTag.count,
        order: WooSortOrder.desc,
        hideEmpty: true,
      );
      return wooTags.map((wt) => _convertToTagProdotto(wt)).toList();
    } catch (e) {
      print('❌ Errore getTopTags: $e');
      rethrow;
    }
  }
}
