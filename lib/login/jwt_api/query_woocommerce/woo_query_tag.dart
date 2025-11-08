import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../woo_connect.dart';
import '../../../prodotti/class_prodotti.dart';

/// Query class per la gestione dei tag prodotti WooCommerce
/// Converte i dati WooCommerce in modelli globali multi-piattaforma
class WooQueryTag {
  // Singleton pattern
  static final WooQueryTag _instance = WooQueryTag._internal();
  factory WooQueryTag() => _instance;
  WooQueryTag._internal();

  final WooConnect _wooConnect = WooConnect();

  /// Ottiene l'istanza WooCommerce autenticata da WooConnect
  WooCommerce get _woo => _wooConnect.woo;

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
      final woo = _woo;

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
      final woo = _woo;
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
      final woo = _woo;
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

  /// Crea un nuovo tag (VERIFICA ESISTENZA PRIMA)
  Future<TagProdotto> createTag({
    required String name,
    String? slug,
    String? description,
  }) async {
    try {
      // STEP 1: Verifica se il tag esiste già
      final existing = await findTagByName(name);
      if (existing != null) {
        print('ℹ️ Tag "$name" già esistente (ID: ${existing.id}), uso quello esistente');
        return existing;
      }

      // STEP 2: Crea il nuovo tag
      print('🔵 Creazione nuovo tag: $name');
      final woo = _woo;

      final tag = WooProductTag(
        null, // id
        name,
        slug ?? name.toLowerCase().replaceAll(' ', '-'),
        description,
        0, // count
      );

      final wooTag = await woo.createProductTag(tag);
      print('✅ Tag "$name" creato con successo (ID: ${wooTag.id})');
      return _convertToTagProdotto(wooTag);
    } catch (e) {
      print('❌ Errore createTag: $e');
      rethrow;
    }
  }

  /// Trova un tag per nome (case-insensitive)
  Future<TagProdotto?> findTagByName(String name) async {
    try {
      final tags = await searchTags(name);
      // Cerca match esatto case-insensitive
      for (final tag in tags) {
        if (tag.nome.toLowerCase() == name.toLowerCase()) {
          return tag;
        }
      }
      return null;
    } catch (e) {
      print('❌ Errore findTagByName: $e');
      return null;
    }
  }

  /// Crea tag SE NON ESISTE, altrimenti ritorna quello esistente
  Future<TagProdotto> createTagIfNotExists({
    required String name,
    String? slug,
    String? description,
  }) async {
    return await createTag(name: name, slug: slug, description: description);
  }

  /// Aggiorna un tag esistente
  Future<TagProdotto> updateTag({
    required int tagId,
    String? name,
    String? slug,
    String? description,
  }) async {
    try {
      final woo = _woo;

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
      final woo = _woo;
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
      final woo = _woo;
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

    // Usa l'istanza Dio del plugin che ha già l'autenticazione JWT
    final response = await _woo.dio.post(
      '/products/tags/batch',
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
      final woo = _woo;
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
    final response = await _woo.dio.get(
      '/products/tags',
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
      final woo = _woo;
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
