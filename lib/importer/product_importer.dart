// Product Importer - Equivalente a WC_Product_Importer (abstract) di WooCommerce
//
// Engine per l'import batch di prodotti
// Implementa:
// - Batch processing con limiti concorrenza
// - Gestione memoria e timeout
// - Upload automatico immagini
// - Validazione e gestione errori
// - Progress tracking

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../prodotti/class_prodotti.dart';
import '../login/jwt_api/query_woocommerce/woo_query_prodotti.dart';
import '../login/jwt_api/query_woocommerce/woo_query_media.dart';
import '../login/jwt_api/query_woocommerce/woo_query_batch.dart';
import '../log_viewer/app_logger.dart';
import 'reference_resolver.dart';

/// Risultato import singolo prodotto
enum ImportOutcome { created, updated, skipped, failed }

class ProductImportResult {
  final ImportOutcome outcome;
  final int? productId;
  final String? error;
  final Map<String, dynamic> rowData;

  ProductImportResult({
    required this.outcome,
    this.productId,
    this.error,
    required this.rowData,
  });

  bool get success => outcome != ImportOutcome.failed;

  String get productName => rowData['name']?.toString() ?? 'Sconosciuto';
  String get productSku => rowData['sku']?.toString() ?? '';
}

/// Statistiche import
class ImportStats {
  int total = 0;
  int imported = 0;
  int updated = 0;
  int failed = 0;
  int skipped = 0;
  DateTime? startTime;
  DateTime? endTime;

  List<ProductImportResult> results = [];
  List<String> errors = [];

  double get successRate => total > 0 ? (imported + updated) / total * 100 : 0;

  Duration get elapsedTime {
    if (startTime == null) return Duration.zero;
    return (endTime ?? DateTime.now()).difference(startTime!);
  }

  double get productsPerSecond {
    final seconds = elapsedTime.inSeconds;
    if (seconds == 0) return 0;
    return (imported + updated) / seconds;
  }

  void addResult(ProductImportResult result) {
    results.add(result);

    switch (result.outcome) {
      case ImportOutcome.created:
        imported++;
        break;
      case ImportOutcome.updated:
        updated++;
        break;
      case ImportOutcome.skipped:
        skipped++;
        break;
      case ImportOutcome.failed:
        failed++;
        if (result.error != null) {
          errors.add('${result.productSku}: ${result.error}');
        }
        break;
    }
  }
}

/// Opzioni import
class ImportOptions {
  final bool updateExisting; // Aggiorna prodotti esistenti (cerca per SKU)
  final bool skipDuplicates; // Salta duplicati
  final bool uploadImages; // Upload automatico immagini da path locale
  final bool publishProducts; // Pubblica prodotti (o salva come draft)
  final bool useBatchApi; // Usa API batch WooCommerce (10-20x più veloce!)
  final bool enableRetry; // Abilita retry automatico per errori transitori
  final int maxRetries; // Numero massimo tentativi per errore transitorio
  final int
  retryDelayMs; // Delay iniziale tra retry (ms) - usa backoff esponenziale
  final int
  batchSize; // Numero prodotti per batch (default 100 per batch API, 30 singolo)
  final int maxConcurrent; // Max richieste parallele
  final int timeoutSeconds; // Timeout per batch (default 20s come WooCommerce)

  const ImportOptions({
    this.updateExisting = false,
    this.skipDuplicates = true,
    this.uploadImages = true,
    this.publishProducts = false,
    this.useBatchApi = true, // Abilitato di default!
    this.enableRetry = true, // Retry abilitato di default
    this.maxRetries = 3, // Max 3 tentativi
    this.retryDelayMs = 1000, // 1 secondo iniziale
    this.batchSize = 100, // Aumentato a 100 per batch API
    this.maxConcurrent = 5,
    this.timeoutSeconds = 20,
  });
}

/// Product Importer - Engine import batch
/// Implementa la logica di WC_Product_Importer
class ProductImporter {
  final WooQueryProdotti _productQuery = WooQueryProdotti();
  final WooQueryMedia _mediaQuery = WooQueryMedia();
  final WooQueryBatch _batchQuery = WooQueryBatch();
  final ReferenceResolver _referenceResolver = ReferenceResolver();

  final Map<String, ProdottoGlobal?> _existingBySkuCache = {};

  ImportOptions options;
  ImportStats stats = ImportStats();

  // Callback per progress tracking
  void Function(ImportStats stats)? onProgress;

  ProductImporter({this.options = const ImportOptions(), this.onProgress});

  /// Import batch di prodotti
  /// Equivalente a WC_Product_Importer::import()
  Future<ImportStats> importProducts(List<Map<String, dynamic>> rows) async {
    try {
      log.i('🚀 Inizio import: ${rows.length} prodotti');

      stats = ImportStats();
      stats.total = rows.length;
      stats.startTime = DateTime.now();

      _existingBySkuCache.clear();

      // Pre-carica cache categorie e tag per performance
      log.i('📦 Pre-caricamento cache riferimenti...');
      await _referenceResolver.preloadCache();

      // Dividi in batch (come fa WooCommerce)
      final batches = _splitIntoBatches(rows, options.batchSize);
      log.d(
        '📦 Creati ${batches.length} batch di ${options.batchSize} prodotti',
      );

      // Processa batch sequenzialmente (con timeout check)
      for (int i = 0; i < batches.length; i++) {
        final batchNum = i + 1;
        log.i('📦 Processing batch $batchNum/${batches.length}');

        final batchStartTime = DateTime.now();

        // Check timeout (come WooCommerce::time_exceeded())
        if (_timeExceeded(batchStartTime)) {
          log.w('⏱️ Timeout raggiunto, interrompo import');
          break;
        }

        // Check memoria (come WooCommerce::memory_exceeded())
        if (await _memoryExceeded()) {
          log.w('💾 Memoria insufficiente, interrompo import');
          break;
        }

        await _processBatch(batches[i]);

        // Notifica progress
        onProgress?.call(stats);
      }

      stats.endTime = DateTime.now();

      log.i(
        '✅ Import completato: ${stats.imported} importati, ${stats.failed} falliti',
      );
      log.i(
        '📊 Tempo: ${stats.elapsedTime.inSeconds}s, Velocità: ${stats.productsPerSecond.toStringAsFixed(2)} prod/s',
      );

      return stats;
    } catch (e, stack) {
      log.e('❌ Errore import batch', e, stack);
      stats.endTime = DateTime.now();
      rethrow;
    }
  }

  /// Processa un batch di prodotti
  Future<void> _processBatch(List<Map<String, dynamic>> batch) async {
    if (options.useBatchApi) {
      // Usa API batch WooCommerce (molto più veloce!)
      await _processBatchWithApi(batch);
    } else {
      // Fallback: processa prodotti in parallelo uno alla volta
      await _processBatchSequential(batch);
    }
  }

  /// Esegue un'operazione con retry automatico per errori transitori
  /// Implementa backoff esponenziale: 1s, 2s, 4s, 8s, etc.
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    String operationName = 'operazione',
  }) async {
    if (!options.enableRetry) {
      return await operation();
    }

    int attempt = 0;
    Duration delay = Duration(milliseconds: options.retryDelayMs);

    while (true) {
      attempt++;

      try {
        return await operation();
      } catch (e) {
        final isRetryable = _isRetryableError(e);
        final shouldRetry = isRetryable && attempt < options.maxRetries;

        if (!shouldRetry) {
          // Non ritentare: rilancia l'errore
          log.e('❌ $operationName fallita dopo $attempt tentativi', e);
          rethrow;
        }

        // Calcola delay con backoff esponenziale
        final currentDelay = delay * (1 << (attempt - 1)); // 2^(attempt-1)

        final errorText = e.toString();
        final preview = errorText.length <= 140
            ? errorText
            : errorText.substring(0, 140);

        log.w(
          '⚠️ $operationName fallita (tentativo $attempt/${options.maxRetries}), '
          'riprovo tra ${currentDelay.inMilliseconds}ms: $preview...',
        );

        await Future.delayed(currentDelay);
      }
    }
  }

  /// Determina se un errore è transitorio e può essere ritentato
  bool _isRetryableError(dynamic error) {
    // Errori di rete (timeout, connessione)
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true; // Errori di rete: ritenta

        case DioExceptionType.badResponse:
          // HTTP 429 (Too Many Requests), 502 (Bad Gateway), 503 (Service Unavailable), 504 (Gateway Timeout)
          final statusCode = error.response?.statusCode;
          return statusCode == 429 ||
              statusCode == 502 ||
              statusCode == 503 ||
              statusCode == 504;

        default:
          return false; // Altri errori Dio: non ritentare
      }
    }

    // SocketException: problemi di connessione
    if (error is SocketException) {
      return true;
    }

    // TimeoutException
    if (error is TimeoutException) {
      return true;
    }

    // Default: non ritentare
    return false;
  }

  /// Processa batch usando API batch WooCommerce (10-20x più veloce)
  Future<void> _processBatchWithApi(List<Map<String, dynamic>> batch) async {
    try {
      log.i('🚀 Uso API batch per ${batch.length} prodotti');

      // 1. Pre-processing: risolvi riferimenti e upload immagini per tutti
      final processedRows = <Map<String, dynamic>>[];
      for (final row in batch) {
        try {
          // Risolvi riferimenti (categorie, tag)
          await _resolveReferences(row);

          // Upload immagini se necessario
          if (options.uploadImages && row.containsKey('local_image_path')) {
            await _uploadProductImages(row);
          }

          processedRows.add(row);
        } catch (e) {
          log.w('⚠️ Errore pre-processing riga: $e');
          stats.addResult(
            ProductImportResult(
              outcome: ImportOutcome.failed,
              error: 'Errore pre-processing: $e',
              rowData: row,
            ),
          );
        }
      }

      if (processedRows.isEmpty) {
        log.w('⚠️ Nessuna riga valida nel batch');
        return;
      }

      // 2. Separa tra prodotti da creare e da aggiornare
      final toCreate = <Map<String, dynamic>>[];
      final toUpdate = <Map<String, dynamic>>[];
      final toSkip = <Map<String, dynamic>>[];

      for (final row in processedRows) {
        // Cerca prodotto esistente per SKU
        final existingProduct = await _findExistingProduct(row['sku']);

        if (existingProduct != null) {
          if (options.updateExisting) {
            row['id'] = existingProduct.id; // Aggiungi ID per update
            toUpdate.add(row);
          } else if (options.skipDuplicates) {
            row['id'] = existingProduct.id;
            toSkip.add(row);
          }
        } else {
          toCreate.add(row);
        }
      }

      log.d(
        '📊 Create: ${toCreate.length}, Update: ${toUpdate.length}, Skip: ${toSkip.length}',
      );

      // Registra gli skipped (non entrano nella batch API)
      for (final row in toSkip) {
        stats.addResult(
          ProductImportResult(
            outcome: ImportOutcome.skipped,
            productId: row['id'] as int?,
            rowData: row,
          ),
        );
      }

      // 3. Converti righe in formato WooCommerce
      final createData = toCreate
          .map((row) => _convertRowToApiData(row, null))
          .toList();
      final updateData = toUpdate
          .map((row) => _convertRowToApiData(row, row['id'] as int?))
          .toList();

      // 4. Esegui chiamata batch API con retry automatico
      final batchData = _batchQuery.createProductsBatchData(
        create: createData.isNotEmpty ? createData : null,
        update: updateData.isNotEmpty ? updateData : null,
      );

      if (batchData.isEmpty) {
        log.i('✅ Batch vuoto (tutti saltati)');
        return;
      }

      final response = await _executeWithRetry(
        () => _batchQuery.batchUpdateProducts(batchData),
        operationName: 'Batch API (${batch.length} prodotti)',
      );

      // 5. Processa risultati
      _processBatchApiResponse(response, toCreate, toUpdate);

      log.i('✅ Batch API completato');
    } catch (e, stack) {
      log.e('❌ Errore batch API', e, stack);

      // Fallback: riprova uno alla volta
      log.w('⚠️ Fallback a processing sequenziale');
      await _processBatchSequential(batch);
    }
  }

  /// Processa risposta API batch
  void _processBatchApiResponse(
    Map<String, dynamic> response,
    List<Map<String, dynamic>> createRows,
    List<Map<String, dynamic>> updateRows,
  ) {
    // Processa prodotti creati
    if (response.containsKey('create')) {
      final created = response['create'] as List;
      for (int i = 0; i < created.length; i++) {
        final item = created[i] as Map<String, dynamic>;
        final row = i < createRows.length ? createRows[i] : <String, dynamic>{};

        if (item.containsKey('error')) {
          final errorData = item['error'] as Map<String, dynamic>?;
          stats.addResult(
            ProductImportResult(
              outcome: ImportOutcome.failed,
              error: errorData?['message']?.toString() ?? 'Errore sconosciuto',
              rowData: row,
            ),
          );
        } else {
          stats.addResult(
            ProductImportResult(
              outcome: ImportOutcome.created,
              productId: item['id'] as int?,
              rowData: row,
            ),
          );
        }
      }
    }

    // Processa prodotti aggiornati
    if (response.containsKey('update')) {
      final updated = response['update'] as List;
      for (int i = 0; i < updated.length; i++) {
        final item = updated[i] as Map<String, dynamic>;
        final row = i < updateRows.length ? updateRows[i] : <String, dynamic>{};

        if (item.containsKey('error')) {
          final errorData = item['error'] as Map<String, dynamic>?;
          stats.addResult(
            ProductImportResult(
              outcome: ImportOutcome.failed,
              error: errorData?['message']?.toString() ?? 'Errore sconosciuto',
              rowData: row,
            ),
          );
        } else {
          stats.addResult(
            ProductImportResult(
              outcome: ImportOutcome.updated,
              productId: item['id'] as int?,
              rowData: row,
            ),
          );
        }
      }
    }
  }

  /// Converte riga CSV in formato API WooCommerce (Map)
  Map<String, dynamic> _convertRowToApiData(
    Map<String, dynamic> row,
    int? productId,
  ) {
    final apiData = <String, dynamic>{};

    if (productId != null) {
      apiData['id'] = productId;
    }

    _applyTypeData(apiData, row);

    // Campi base
    if (row.containsKey('name')) apiData['name'] = row['name'];
    if (row.containsKey('sku')) apiData['sku'] = row['sku'];
    if (row.containsKey('regular_price'))
      apiData['regular_price'] = row['regular_price'].toString();
    if (row.containsKey('sale_price'))
      apiData['sale_price'] = row['sale_price'].toString();
    if (row.containsKey('description'))
      apiData['description'] = row['description'];
    if (row.containsKey('short_description'))
      apiData['short_description'] = row['short_description'];
    if (row.containsKey('catalog_visibility')) {
      apiData['catalog_visibility'] = row['catalog_visibility'];
    }
    if (row.containsKey('date_on_sale_from')) {
      apiData['date_on_sale_from'] = row['date_on_sale_from'];
    }
    if (row.containsKey('date_on_sale_to')) {
      apiData['date_on_sale_to'] = row['date_on_sale_to'];
    }
    if (row.containsKey('tax_status')) apiData['tax_status'] = row['tax_status'];
    if (row.containsKey('tax_class')) apiData['tax_class'] = row['tax_class'];

    // Status
    apiData['status'] = _resolveWooStatus(row);
    if (row.containsKey('featured')) {
      apiData['featured'] = row['featured'] == true;
    }

    // Categorie (usa IDs risolti)
    if (row.containsKey('category_ids')) {
      apiData['categories'] = (row['category_ids'] as List<int>)
          .map((id) => {'id': id})
          .toList();
    }

    // Tag (usa IDs risolti)
    if (row.containsKey('tag_ids')) {
      apiData['tags'] = (row['tag_ids'] as List<int>)
          .map((id) => {'id': id})
          .toList();
    }

    // Immagini
    if (row.containsKey('images')) {
      final images = row['images'] as List<String>;
      apiData['images'] = images.map((url) => {'src': url}).toList();
    }

    // Stock
    if (row.containsKey('stock_quantity')) {
      apiData['stock_quantity'] = row['stock_quantity'];
      apiData['manage_stock'] = true;
    }
    if (row.containsKey('manage_stock')) {
      apiData['manage_stock'] = row['manage_stock'] == true;
    }
    if (row.containsKey('stock_status')) {
      apiData['stock_status'] = row['stock_status'];
    }
    if (row.containsKey('low_stock_amount')) {
      apiData['low_stock_amount'] = row['low_stock_amount'];
    }
    if (row.containsKey('backorders')) {
      apiData['backorders'] = row['backorders'];
    }
    if (row.containsKey('sold_individually')) {
      apiData['sold_individually'] = row['sold_individually'] == true;
    }

    // Dimensioni e peso
    if (row.containsKey('weight')) apiData['weight'] = row['weight'].toString();
    if (row.containsKey('length')) {
      apiData['dimensions'] = apiData['dimensions'] ?? {};
      apiData['dimensions']['length'] = row['length'].toString();
    }
    if (row.containsKey('width')) {
      apiData['dimensions'] = apiData['dimensions'] ?? {};
      apiData['dimensions']['width'] = row['width'].toString();
    }
    if (row.containsKey('height')) {
      apiData['dimensions'] = apiData['dimensions'] ?? {};
      apiData['dimensions']['height'] = row['height'].toString();
    }

    if (row.containsKey('reviews_allowed')) {
      apiData['reviews_allowed'] = row['reviews_allowed'] == true;
    }
    if (row.containsKey('purchase_note')) {
      apiData['purchase_note'] = row['purchase_note'];
    }
    if (row.containsKey('shipping_class_id')) {
      apiData['shipping_class'] = row['shipping_class_id'];
    }
    if (row.containsKey('download_limit')) {
      apiData['download_limit'] = row['download_limit'];
    }
    if (row.containsKey('download_expiry')) {
      apiData['download_expiry'] = row['download_expiry'];
    }
    if (row.containsKey('parent_id')) {
      final parentId = row['parent_id'];
      if (parentId is int) {
        apiData['parent_id'] = parentId;
      }
    }
    if (row.containsKey('grouped_products')) {
      apiData['grouped_products'] = _resolveRelatedProductIds(
        row['grouped_products'],
      );
    }
    if (row.containsKey('upsell_ids')) {
      apiData['upsell_ids'] = _resolveRelatedProductIds(row['upsell_ids']);
    }
    if (row.containsKey('cross_sell_ids')) {
      apiData['cross_sell_ids'] = _resolveRelatedProductIds(row['cross_sell_ids']);
    }
    if (row.containsKey('product_url')) {
      apiData['external_url'] = row['product_url'];
    }
    if (row.containsKey('button_text')) {
      apiData['button_text'] = row['button_text'];
    }
    if (row.containsKey('menu_order')) {
      apiData['menu_order'] = row['menu_order'];
    }

    final attributes = _buildAttributes(row, apiData['type']?.toString());
    if (attributes.isNotEmpty) {
      apiData['attributes'] = attributes;
    }

    final defaultAttributes = _buildDefaultAttributes(row);
    if (defaultAttributes.isNotEmpty) {
      apiData['default_attributes'] = defaultAttributes;
    }

    final downloads = _buildDownloads(row);
    if (downloads.isNotEmpty) {
      apiData['downloads'] = downloads;
      apiData['downloadable'] = true;
    }

    final metaData = _buildMetaData(row);
    if (metaData.isNotEmpty) {
      apiData['meta_data'] = metaData;
    }

    return apiData;
  }

  /// Processa batch sequenzialmente (uno alla volta) - Fallback
  Future<void> _processBatchSequential(List<Map<String, dynamic>> batch) async {
    // Processa prodotti in parallelo (con limite concorrenza)
    for (int i = 0; i < batch.length; i += options.maxConcurrent) {
      final chunk = batch.skip(i).take(options.maxConcurrent).toList();

      final chunkFutures = chunk.map((row) => _processProduct(row)).toList();
      final results = await Future.wait(chunkFutures);

      for (final result in results) {
        stats.addResult(result);
      }
    }
  }

  /// Processa singolo prodotto
  /// Equivalente a WC_Product_Importer::process_item()
  Future<ProductImportResult> _processProduct(Map<String, dynamic> row) async {
    try {
      log.d('🔄 Processo prodotto: ${row['name']} (${row['sku']})');

      // 1. Risolvi riferimenti (categorie, tag) - CREA SE NON ESISTONO
      await _resolveReferences(row);

      // 2. Upload immagini se necessario
      if (options.uploadImages && row.containsKey('local_image_path')) {
        await _uploadProductImages(row);
      }

      // 3. Verifica se prodotto esiste (per SKU)
      final existingProduct = await _findExistingProduct(row['sku']);

      // 4. Decidi azione: create, update o skip
      if (existingProduct != null) {
        if (options.updateExisting) {
          // Update
          return await _updateProduct(existingProduct, row);
        } else if (options.skipDuplicates) {
          // Skip
          log.d('⏭️ Skipped: ${row['sku']} (già esistente)');
          return ProductImportResult(
            outcome: ImportOutcome.skipped,
            productId: existingProduct.id,
            rowData: row,
          );
        }
      }

      // 5. Crea nuovo prodotto
      return await _createProduct(row);
    } catch (e) {
      log.e('❌ Errore import prodotto ${row['sku']}', e);
      return ProductImportResult(
        outcome: ImportOutcome.failed,
        error: e.toString(),
        rowData: row,
      );
    }
  }

  /// Risolve riferimenti (categorie, tag) - Crea se non esistono
  /// Equivalente a WooCommerce che auto-crea categorie/tag mancanti
  Future<void> _resolveReferences(Map<String, dynamic> row) async {
    try {
      // Risolvi categorie
      if (row.containsKey('categories')) {
        final categories = row['categories'];
        List<String> categoryNames = [];

        if (categories is List) {
          categoryNames = categories.map((e) => e.toString()).toList();
        } else if (categories is String && categories.isNotEmpty) {
          categoryNames = [categories];
        }

        if (categoryNames.isNotEmpty) {
          log.d('📁 Risoluzione categorie: $categoryNames');
          final categoryIds = await _referenceResolver.resolveCategoryNames(
            categoryNames,
          );
          row['category_ids'] = categoryIds;
        }
      }

      // Risolvi tag
      if (row.containsKey('tags')) {
        final tags = row['tags'];
        List<String> tagNames = [];

        if (tags is List) {
          tagNames = tags.map((e) => e.toString()).toList();
        } else if (tags is String && tags.isNotEmpty) {
          tagNames = [tags];
        }

        if (tagNames.isNotEmpty) {
          log.d('🏷️ Risoluzione tag: $tagNames');
          final tagIds = await _referenceResolver.resolveTagNames(tagNames);
          row['tag_ids'] = tagIds;
        }
      }

      if (row.containsKey('parent_id')) {
        final parentId = await _resolveProductReference(row['parent_id']);
        if (parentId != null) {
          row['parent_id'] = parentId;
        }
      }

      for (final key in ['grouped_products', 'upsell_ids', 'cross_sell_ids']) {
        if (!row.containsKey(key)) continue;
        final ids = await _resolveProductReferenceList(row[key]);
        if (ids.isNotEmpty) {
          row[key] = ids;
        } else {
          row.remove(key);
        }
      }
    } catch (e) {
      log.w('⚠️ Errore risoluzione riferimenti', e);
      // Non blocca import, continua senza categorie/tag
    }
  }

  Future<int?> _resolveProductReference(dynamic reference) async {
    if (reference is int) return reference;
    if (reference is String) {
      final byId = int.tryParse(reference.trim());
      if (byId != null) return byId;

      final existing = await _findExistingProduct(reference.trim());
      return existing?.id;
    }

    return null;
  }

  Future<List<int>> _resolveProductReferenceList(dynamic references) async {
    if (references is! List) return const [];

    final resolved = <int>[];
    for (final reference in references) {
      final id = await _resolveProductReference(reference);
      if (id != null) {
        resolved.add(id);
      }
    }

    return resolved;
  }

  /// Upload immagini prodotto
  Future<void> _uploadProductImages(Map<String, dynamic> row) async {
    try {
      final localPath = row['local_image_path'] as String?;
      if (localPath == null || localPath.isEmpty) return;

      final List<String> imagePaths = localPath.contains('|')
          ? localPath.split('|').map((e) => e.trim()).toList()
          : [localPath];

      final List<String> uploadedUrls = [];

      for (final path in imagePaths) {
        try {
          final file = File(path);
          if (!await file.exists()) {
            log.w('⚠️ File immagine non trovato: $path');
            continue;
          }

          log.d('📤 Upload immagine: $path');
          final media = await _executeWithRetry(
            () => _mediaQuery.uploadMedia(
              path,
              title: row['name']?.toString(),
              altText: row['name']?.toString(),
            ),
            operationName: 'Upload immagine ${path.split('/').last}',
          );

          uploadedUrls.add(media.url);
          log.d('✅ Immagine caricata: ${media.url}');
        } catch (e) {
          log.e('❌ Errore upload immagine $path', e);
          // Continua con altre immagini
        }
      }

      // Aggiorna row con URLs immagini caricate
      if (uploadedUrls.isNotEmpty) {
        final existing = row['images'] as List<String>? ?? [];
        row['images'] = [...existing, ...uploadedUrls];
      }
    } catch (e) {
      log.e('❌ Errore upload immagini', e);
      // Non blocca import, continua senza immagini
    }
  }

  /// Cerca prodotto esistente per SKU
  Future<ProdottoGlobal?> _findExistingProduct(String? sku) async {
    if (sku == null || sku.isEmpty) return null;

    final cached = _existingBySkuCache[sku];
    if (_existingBySkuCache.containsKey(sku)) {
      return cached;
    }

    try {
      final products = await _productQuery.searchProducts(sku, limit: 1);
      final found = products.isNotEmpty ? products.first : null;
      _existingBySkuCache[sku] = found;
      return found;
    } catch (e) {
      log.w('⚠️ Errore ricerca prodotto per SKU $sku', e);
      _existingBySkuCache[sku] = null;
      return null;
    }
  }

  /// Crea nuovo prodotto
  Future<ProductImportResult> _createProduct(Map<String, dynamic> row) async {
    try {
      final createdId = await _createProductViaApi(row);

      log.i('✅ Creato: ${row['name']} (ID: $createdId)');

      final sku = row['sku']?.toString();
      if (sku?.isNotEmpty == true) {
        _existingBySkuCache[sku!] = await _productQuery.getProductById(createdId);
      }

      return ProductImportResult(
        outcome: ImportOutcome.created,
        productId: createdId,
        rowData: row,
      );
    } catch (e) {
      log.e('❌ Errore creazione prodotto', e);
      return ProductImportResult(
        outcome: ImportOutcome.failed,
        error: e.toString(),
        rowData: row,
      );
    }
  }

  /// Aggiorna prodotto esistente
  Future<ProductImportResult> _updateProduct(
    ProdottoGlobal existing,
    Map<String, dynamic> row,
  ) async {
    try {
      final existingId = existing.id;
      if (existingId == null) {
        throw Exception('Prodotto esistente senza ID WooCommerce');
      }

      final updatedId = await _updateProductViaApi(existingId, row);

      log.i('✅ Aggiornato: ${row['name']} (ID: $updatedId)');

      final sku = row['sku']?.toString() ?? existing.sku;
      if (sku?.isNotEmpty == true) {
        _existingBySkuCache[sku!] = await _productQuery.getProductById(updatedId);
      }

      return ProductImportResult(
        outcome: ImportOutcome.updated,
        productId: updatedId,
        rowData: row,
      );
    } catch (e) {
      log.e('❌ Errore aggiornamento prodotto', e);
      return ProductImportResult(
        outcome: ImportOutcome.failed,
        error: e.toString(),
        rowData: row,
      );
    }
  }

  /// Converte riga CSV in ProdottoWoo
  /// Equivalente a WC_Product_Importer::expand_data()
  // ignore: unused_element
  ProdottoGlobal _convertRowToProdotto(
    Map<String, dynamic> row,
    int? productId,
  ) {
    return ProdottoGlobal(
      id: productId ?? 0,
      nome: row['name']?.toString() ?? '',
      sku: row['sku']?.toString() ?? '',
      prezzoNormale: _getDouble(row, 'regular_price'),
      prezzoScontato: _getDoubleOrNull(row, 'sale_price'),
      descrizioneBreve: row['short_description']?.toString() ?? '',
      descrizioneCompleta: row['description']?.toString(),
      immagineUrl: _getFirstImage(row),
      immaginiAggiuntive: _getAdditionalImages(row),
      categoria: _getFirstCategory(row),
      tag: _getTags(row),
      inStock: _getStockStatus(row),
      quantitaTotale: _getIntOrNull(row, 'stock_quantity'),
      peso: row['weight']?.toString(),
      dimensioni: _getDimensions(row),
      status: _resolveWooStatus(row),
      varianti: [], // Le varianti si gestiscono a parte
    );
  }

  String _resolveWooStatus(Map<String, dynamic> row) {
    final directStatus = row['status']?.toString().trim();
    if (directStatus != null && directStatus.isNotEmpty) {
      return directStatus;
    }

    final published = row['published'];
    if (published is int) {
      switch (published) {
        case 1:
          return 'publish';
        case 0:
          return 'private';
        case -1:
          return 'draft';
      }
    }

    return options.publishProducts ? 'publish' : 'draft';
  }

  void _applyTypeData(Map<String, dynamic> apiData, Map<String, dynamic> row) {
    final rawType = row['type'];
    final parts = rawType is List
        ? rawType.map((e) => e.toString().trim().toLowerCase()).toList()
        : rawType is String
            ? rawType
                .split(',')
                .map((e) => e.trim().toLowerCase())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];

    if (parts.isEmpty) return;

    final baseType = parts.firstWhere(
      (value) => value != 'virtual' && value != 'downloadable',
      orElse: () => 'simple',
    );

    apiData['type'] = baseType;
    if (parts.contains('virtual')) apiData['virtual'] = true;
    if (parts.contains('downloadable')) apiData['downloadable'] = true;
  }

  List<Map<String, dynamic>> _buildAttributes(
    Map<String, dynamic> row,
    String? productType,
  ) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final entry in row.entries) {
      final match = RegExp(r'^attributes:(name|value|visible|taxonomy|default):(\d+)$')
          .firstMatch(entry.key);
      if (match == null) continue;

      final kind = match.group(1)!;
      final index = match.group(2)!;
      final bucket = grouped.putIfAbsent(index, () => {});
      bucket[kind] = entry.value;
    }

    final isVariableContext = productType == 'variable' || productType == 'variation';
    final attributes = <Map<String, dynamic>>[];
    final sortedKeys = grouped.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    for (final key in sortedKeys) {
      final item = grouped[key]!;
      final name = item['name']?.toString().trim();
      if (name == null || name.isEmpty) continue;

      final options = item['value'] is List
          ? (item['value'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : <String>[];
      if (options.isEmpty) continue;

      final hasDefault = item.containsKey('default') && item['default'].toString().trim().isNotEmpty;
      attributes.add({
        'name': name,
        'visible': item['visible'] == true,
        'variation': isVariableContext || hasDefault,
        'options': options,
      });
    }

    return attributes;
  }

  List<Map<String, dynamic>> _buildDefaultAttributes(Map<String, dynamic> row) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final entry in row.entries) {
      final match = RegExp(r'^attributes:(name|default):(\d+)$').firstMatch(entry.key);
      if (match == null) continue;

      final kind = match.group(1)!;
      final index = match.group(2)!;
      final bucket = grouped.putIfAbsent(index, () => {});
      bucket[kind] = entry.value;
    }

    final defaults = <Map<String, dynamic>>[];
    final sortedKeys = grouped.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    for (final key in sortedKeys) {
      final item = grouped[key]!;
      final name = item['name']?.toString().trim();
      final option = item['default']?.toString().trim();
      if (name == null || name.isEmpty || option == null || option.isEmpty) continue;
      defaults.add({'name': name, 'option': option});
    }
    return defaults;
  }

  List<Map<String, dynamic>> _buildDownloads(Map<String, dynamic> row) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final entry in row.entries) {
      final match = RegExp(r'^downloads:(id|name|url):(\d+)$').firstMatch(entry.key);
      if (match == null) continue;

      final kind = match.group(1)!;
      final index = match.group(2)!;
      final bucket = grouped.putIfAbsent(index, () => {});
      bucket[kind] = entry.value;
    }

    final downloads = <Map<String, dynamic>>[];
    final sortedKeys = grouped.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    for (final key in sortedKeys) {
      final item = grouped[key]!;
      final url = item['url']?.toString().trim();
      if (url == null || url.isEmpty) continue;
      downloads.add({
        if (item['id'] != null && item['id'].toString().trim().isNotEmpty) 'id': item['id'].toString().trim(),
        'name': item['name']?.toString().trim().isNotEmpty == true ? item['name'].toString().trim() : 'Download $key',
        'file': url,
      });
    }
    return downloads;
  }

  List<Map<String, dynamic>> _buildMetaData(Map<String, dynamic> row) {
    final meta = <Map<String, dynamic>>[];
    for (final entry in row.entries) {
      if (!entry.key.startsWith('meta:')) continue;
      final key = entry.key.substring(5).trim();
      if (key.isEmpty) continue;
      meta.add({'key': key, 'value': entry.value});
    }
    return meta;
  }

  Future<int> _createProductViaApi(Map<String, dynamic> row) async {
    final payload = _convertRowToApiData(row, null);
    final response = await _executeWithRetry(
      () => _batchQuery.batchCreateProducts([payload]),
      operationName: 'Creazione prodotto ${row['sku']}',
    );

    final createdList = (response['create'] as List?) ?? const [];
    final created = createdList.isNotEmpty
        ? Map<String, dynamic>.from(createdList.first as Map)
        : null;
    if (created == null) {
      throw Exception('Risposta WooCommerce vuota durante la creazione');
    }
    if (created.containsKey('error')) {
      throw Exception(created['error']?['message']?.toString() ?? 'Errore creazione prodotto');
    }

    final id = created['id'];
    if (id is! int) {
      throw Exception('ID prodotto non restituito da WooCommerce');
    }
    return id;
  }

  Future<int> _updateProductViaApi(int productId, Map<String, dynamic> row) async {
    final payload = _convertRowToApiData(row, productId);
    final response = await _executeWithRetry(
      () => _batchQuery.batchUpdateProducts({'update': [payload]}),
      operationName: 'Aggiornamento prodotto ${row['sku']}',
    );

    final updatedList = (response['update'] as List?) ?? const [];
    final updated = updatedList.isNotEmpty
        ? Map<String, dynamic>.from(updatedList.first as Map)
        : null;
    if (updated == null) {
      throw Exception('Risposta WooCommerce vuota durante l\'aggiornamento');
    }
    if (updated.containsKey('error')) {
      throw Exception(updated['error']?['message']?.toString() ?? 'Errore aggiornamento prodotto');
    }

    final id = updated['id'];
    if (id is! int) {
      throw Exception('ID prodotto non restituito da WooCommerce');
    }
    return id;
  }

  List<int> _resolveRelatedProductIds(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item is int ? item : int.tryParse(item.toString()))
        .whereType<int>()
        .toList();
  }

  // Helper per estrarre valori tipizzati
  double _getDouble(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double? _getDoubleOrNull(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _getIntOrNull(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _getFirstImage(Map<String, dynamic> row) {
    final images = row['images'];
    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }
    if (images is String && images.isNotEmpty) {
      return images;
    }
    return '';
  }

  List<String> _getAdditionalImages(Map<String, dynamic> row) {
    final images = row['images'];
    if (images is List && images.length > 1) {
      return images.skip(1).map((e) => e.toString()).toList();
    }
    return [];
  }

  List<CategoriaProdotto>? _getFirstCategory(Map<String, dynamic> row) {
    final categories = row['categories'];
    if (categories is List && categories.isNotEmpty) {
      final categoryName = categories.first.toString();
      return [
        CategoriaProdotto(nome: categoryName, slug: categoryName.toLowerCase()),
      ];
    }
    if (categories is String && categories.isNotEmpty) {
      return [
        CategoriaProdotto(nome: categories, slug: categories.toLowerCase()),
      ];
    }
    return [
      CategoriaProdotto(nome: 'Senza categoria', slug: 'senza-categoria'),
    ];
  }

  List<TagProdotto>? _getTags(Map<String, dynamic> row) {
    final tags = row['tags'];
    if (tags is List) {
      return tags
          .map(
            (e) => TagProdotto(
              nome: e.toString(),
              slug: e.toString().toLowerCase(),
            ),
          )
          .toList();
    }
    if (tags is String && tags.isNotEmpty) {
      return [TagProdotto(nome: tags, slug: tags.toLowerCase())];
    }
    return [];
  }

  bool _getStockStatus(Map<String, dynamic> row) {
    final status = row['stock_status']?.toString().toLowerCase();
    return status != 'outofstock' && status != 'out of stock';
  }

  DimensioniProdotto? _getDimensions(Map<String, dynamic> row) {
    final length = _getDoubleOrNull(row, 'length');
    final width = _getDoubleOrNull(row, 'width');
    final height = _getDoubleOrNull(row, 'height');

    if (length != null || width != null || height != null) {
      return DimensioniProdotto(
        lunghezza: length ?? 0,
        larghezza: width ?? 0,
        altezza: height ?? 0,
      );
    }
    return null;
  }

  // ========================================================================
  // GESTIONE RISORSE (come WooCommerce)
  // ========================================================================

  /// Check se è stato superato il timeout
  /// Equivalente a WC_Product_Importer::time_exceeded()
  bool _timeExceeded(DateTime batchStartTime) {
    // Timeout per singolo batch (stile WooCommerce)
    final elapsed = DateTime.now().difference(batchStartTime);
    return elapsed.inSeconds > options.timeoutSeconds;
  }

  /// Check se memoria sta per esaurirsi
  /// Equivalente a WC_Product_Importer::memory_exceeded()
  Future<bool> _memoryExceeded() async {
    // Flutter non ha accesso diretto alla memoria come PHP
    // Usiamo un approccio più conservativo
    try {
      final info = ProcessInfo.currentRss;
      final maxMemory = ProcessInfo.maxRss;

      if (maxMemory <= 0) {
        return false; // Valore non affidabile/non disponibile
      }

      // Se uso memoria > 90% del max, interrompi (come WooCommerce)
      return info > (maxMemory * 0.9);
    } catch (e) {
      // Se non riusciamo a leggere memoria, assumiamo OK
      return false;
    }
  }

  /// Divide lista in batch
  List<List<T>> _splitIntoBatches<T>(List<T> items, int batchSize) {
    final List<List<T>> batches = [];

    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }

    return batches;
  }
}
