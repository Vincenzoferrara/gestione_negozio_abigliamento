// Inventory Global - Gestione inventario centralizzata
//
// Coordina tutte le operazioni di inventario tra WooCommerce e ATUM
// Fornisce un'interfaccia unificata per la gestione stock

import 'dart:async';
import '../login/jwt_api/query_atum_inventory/atum_connect.dart';
import '../login/jwt_api/query_woocommerce/woo_query_prodotti.dart';
import '../log_viewer/app_logger.dart';

/// Tipi di sincronizzazione inventario
enum SyncType {
  full, // Sincronizzazione completa
  stockOnly, // Solo stock
  pricesOnly, // Solo prezzi
  metadataOnly, // Solo metadata
}

/// Risultato sincronizzazione
class SyncResult {
  final bool success;
  final String? message;
  final int syncedProducts;
  final List<String> errors;
  final Map<String, dynamic>? details;

  SyncResult({
    required this.success,
    this.message,
    this.syncedProducts = 0,
    this.errors = const [],
    this.details,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'] ?? false,
      message: json['message'],
      syncedProducts: json['synced_products'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
      details: json['details'],
    );
  }
}

/// Statistiche inventario combinate
class CombinedInventoryStats {
  final int totalProducts;
  final int wooProductsCount;
  final int atumProductsCount;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalWooValue;
  final double totalAtumValue;
  final List<Map<String, dynamic>> discrepancies;
  final DateTime lastSyncDate;

  CombinedInventoryStats({
    required this.totalProducts,
    required this.wooProductsCount,
    required this.atumProductsCount,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalWooValue,
    required this.totalAtumValue,
    required this.discrepancies,
    required this.lastSyncDate,
  });
}

/// Prodotto inventario unificato
class UnifiedInventoryItem {
  final int productId;
  final String productName;
  final String? sku;
  final double wooStock;
  final double? atumStock;
  final String? atumLocation;
  final String stockStatus;
  final bool isLowStock;
  final double? wooPrice;
  final double? atumPurchasePrice;
  final DateTime? wooLastUpdated;
  final DateTime? atumLastUpdated;
  final bool hasDiscrepancy;
  final String? discrepancyType;

  UnifiedInventoryItem({
    required this.productId,
    required this.productName,
    this.sku,
    required this.wooStock,
    this.atumStock,
    this.atumLocation,
    required this.stockStatus,
    this.isLowStock = false,
    this.wooPrice,
    this.atumPurchasePrice,
    this.wooLastUpdated,
    this.atumLastUpdated,
    this.hasDiscrepancy = false,
    this.discrepancyType,
  });
}

/// Service centralizzato per gestione inventario
class InventoryGlobal {
  // Singleton
  static final InventoryGlobal _instance = InventoryGlobal._internal();
  factory InventoryGlobal() => _instance;
  InventoryGlobal._internal();

  final AtumConnect _atumConnect = AtumConnect();
  final WooQueryProdotti _wooQuery = WooQueryProdotti();

  /// Inizializza la connessione ATUM
  Future<void> initialize(String siteUrl) async {
    try {
      log.d('Initializing Inventory Global with ATUM: $siteUrl');

      // Configura ATUM con la stessa autenticazione JWT
      _atumConnect.configureAtum(siteUrl);

      // Verifica che ATUM sia disponibile
      final atumAvailable = await _atumConnect.isAtumAvailable();
      if (!atumAvailable) {
        log.w('ATUM non disponibile sul sito: $siteUrl');
        throw Exception('ATUM non disponibile');
      }

      log.i('✅ Inventory Global initialized successfully');
    } catch (e) {
      log.e('Error initializing Inventory Global: $e');
      rethrow;
    }
  }

  /// Sincronizza stock da WooCommerce a ATUM
  Future<SyncResult> syncStockFromWooToAtum({
    List<int>? productIds,
    SyncType syncType = SyncType.full,
  }) async {
    try {
      log.d('Syncing stock from WooCommerce to ATUM...');

      final syncedProducts = <int>[];
      final errors = <String>[];
      int successCount = 0;

      // Ottieni prodotti da WooCommerce
      final wooProducts = productIds != null
          ? await Future.wait(
              productIds.map((id) => _wooQuery.getProductById(id)).toList(),
            )
          : await _wooQuery.getProducts(perPage: 100);

      for (final wooProduct in wooProducts) {
        try {
          // Sincronizza stock se necessario
          if (syncType == SyncType.full || syncType == SyncType.stockOnly) {
            final syncSuccess = await _atumConnect.atumDio
                .put(
                  '/stock/sync',
                  data: {
                    'product_id': wooProduct.id,
                    'woo_stock': wooProduct.quantitaTotale,
                    'sync_type': syncType.name,
                  },
                )
                .then((response) => response.data['success'] ?? false);

            if (syncSuccess) {
              syncedProducts.add(wooProduct.id!);
              successCount++;
            } else {
              errors.add(
                'Failed to sync product ${wooProduct.id}: ${wooProduct.nome}',
              );
            }
          }

          // Sincronizza prezzi se necessario
          if (syncType == SyncType.full || syncType == SyncType.pricesOnly) {
            // TODO: Implementare sincronizzazione prezzi
          }

          // Sincronizza metadata se necessario
          if (syncType == SyncType.full || syncType == SyncType.metadataOnly) {
            // TODO: Implementare sincronizzazione metadata
          }
        } catch (e) {
          errors.add('Error syncing product ${wooProduct.id}: $e');
        }
      }

      final result = SyncResult(
        success: errors.isEmpty,
        syncedProducts: successCount,
        errors: errors,
        message: 'Sync completed: $successCount/${wooProducts.length}',
      );

      if (result.success) {
        log.i('✅ Stock sync completed: $successCount products synced');
      } else {
        log.w('⚠️ Stock sync completed with ${errors.length} errors');
      }

      return result;
    } catch (e) {
      log.e('Error in stock sync: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        errors: ['Sync error: $e'],
      );
    }
  }

  /// Sincronizza da ATUM a WooCommerce
  Future<SyncResult> syncStockFromAtumToWoo({
    List<int>? productIds,
    SyncType syncType = SyncType.stockOnly,
  }) async {
    try {
      log.d('Syncing stock from ATUM to WooCommerce...');

      final syncedProducts = <int>[];
      final errors = <String>[];
      int successCount = 0;

      // Ottieni stock ATUM
      final atumStocks = productIds != null
          ? await Future.wait(
              productIds.map((id) => _getAtumStockForProduct(id)).toList(),
            )
          : await _getAllAtumStock();

      for (final atumStock in atumStocks) {
        try {
          // Aggiorna stock WooCommerce
          await _wooQuery.updateProductStock(
            atumStock['product_id'],
            stockQuantity: atumStock['current_stock']?.toInt() ?? 0,
            stockStatus: atumStock['stock_status'] ?? 'instock',
          );
          syncedProducts.add(atumStock['product_id']);
          successCount++;
        } catch (e) {
          errors.add('Error syncing product ${atumStock['product_id']}: $e');
        }
      }

      final result = SyncResult(
        success: errors.isEmpty,
        syncedProducts: successCount,
        errors: errors,
        message: 'ATUM→Woo sync completed: $successCount/${atumStocks.length}',
      );

      if (result.success) {
        log.i('✅ ATUM→Woo stock sync completed: $successCount products synced');
      } else {
        log.w('⚠️ ATUM→Woo stock sync completed with ${errors.length} errors');
      }

      return result;
    } catch (e) {
      log.e('Error in ATUM→Woo stock sync: $e');
      return SyncResult(
        success: false,
        message: 'ATUM→Woo sync failed: $e',
        errors: ['Sync error: $e'],
      );
    }
  }

  /// Ottiene stock combinato WooCommerce + ATUM
  Future<List<UnifiedInventoryItem>> getUnifiedInventory({
    String? search,
    String? stockStatus,
    String? location,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting unified inventory...');

      // Ottieni prodotti da WooCommerce
      final wooProducts = await _wooQuery.getProducts(
        perPage: perPage,
        filters: ProductFilters(search: search, stockStatus: stockStatus),
      );

      // Ottieni stock ATUM per ogni prodotto
      final unifiedItems = <UnifiedInventoryItem>[];

      for (final wooProduct in wooProducts) {
        try {
          final atumStock = await _getAtumStockForProduct(wooProduct.id!);

          final item = UnifiedInventoryItem(
            productId: wooProduct.id!,
            productName: wooProduct.nome ?? '',
            sku: wooProduct.sku,
            wooStock: wooProduct.quantitaTotale?.toDouble() ?? 0.0,
            atumStock: atumStock['current_stock'],
            atumLocation: atumStock['location'],
            stockStatus: _determineStockStatus(
              wooProduct.inStock,
              atumStock['current_stock'],
            ),
            isLowStock: atumStock['is_low_stock'] ?? false,
            wooPrice: wooProduct.prezzoNormale,
            atumPurchasePrice: atumStock['purchase_price'],
            wooLastUpdated: wooProduct.dataModifica,
            atumLastUpdated: atumStock['last_updated'] != null
                ? DateTime.tryParse(atumStock['last_updated'])
                : null,
            hasDiscrepancy:
                (wooProduct.quantitaTotale ?? 0) !=
                (atumStock['current_stock'] ?? 0),
            discrepancyType:
                (wooProduct.quantitaTotale ?? 0) >
                    (atumStock['current_stock'] ?? 0)
                ? 'woo_higher'
                : 'atum_higher',
          );

          unifiedItems.add(item);
        } catch (e) {
          log.e(
            'Error getting unified inventory for product ${wooProduct.id}: $e',
          );
        }
      }

      return unifiedItems;
    } catch (e) {
      log.e('Error getting unified inventory: $e');
      rethrow;
    }
  }

  /// Ottiene statistiche combinate
  Future<CombinedInventoryStats> getCombinedStatistics() async {
    try {
      log.d('Getting combined inventory statistics...');

      // Statistiche WooCommerce
      final wooStats = await _wooQuery.getProductStats();

      // Statistiche ATUM
      final atumStats = await _atumConnect.atumDio
          .get('/inventory/statistics')
          .then((response) => response.data)
          .catchError((e) => <String, dynamic>{});

      final discrepancies = <Map<String, dynamic>>[];

      // Confronta e identifica discrepanze
      if (wooStats['total_products'] != atumStats['total_products']) {
        discrepancies.add({
          'type': 'product_count',
          'woo_count': wooStats['total_products'],
          'atum_count': atumStats['total_products'],
        });
      }

      return CombinedInventoryStats(
        totalProducts:
            ((wooStats['total_products'] ?? 0) +
                (atumStats['total_products'] ?? 0)) ~/
            2,
        wooProductsCount: wooStats['total_products'] ?? 0,
        atumProductsCount: atumStats['total_products'] ?? 0,
        inStockCount:
            ((wooStats['in_stock_count'] ?? 0) +
                (atumStats['in_stock_count'] ?? 0)) ~/
            2,
        lowStockCount:
            ((wooStats['low_stock_count'] ?? 0) +
                (atumStats['low_stock_count'] ?? 0)) ~/
            2,
        outOfStockCount:
            ((wooStats['out_of_stock_count'] ?? 0) +
                (atumStats['out_of_stock_count'] ?? 0)) ~/
            2,
        totalWooValue: wooStats['total_value']?.toDouble() ?? 0.0,
        totalAtumValue: atumStats['total_value']?.toDouble() ?? 0.0,
        discrepancies: discrepancies,
        lastSyncDate: DateTime.now(),
      );
    } catch (e) {
      log.e('Error getting combined statistics: $e');
      rethrow;
    }
  }

  /// Ottiene prodotti in esaurimento combinate
  Future<List<UnifiedInventoryItem>> getCombinedLowStock({
    double? threshold,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      log.d('Getting combined low stock items...');

      // Ottieni low stock da WooCommerce
      final wooLowStock = await _wooQuery.getOutOfStockProducts(limit: perPage);

      // Ottieni low stock da ATUM
      final atumLowStock = await _atumConnect.atumDio
          .get('/inventory/low-stock')
          .then(
            (response) => List<Map<String, dynamic>>.from(response.data ?? []),
          )
          .catchError((e) => <Map<String, dynamic>>[]);

      final combinedLowStock = <UnifiedInventoryItem>[];

      // Combina i risultati
      for (final wooProduct in wooLowStock) {
        final atumStock = atumLowStock.firstWhere(
          (item) => item['product_id'] == wooProduct.id,
          orElse: () => <String, dynamic>{},
        );

        combinedLowStock.add(
          UnifiedInventoryItem(
            productId: wooProduct.id!,
            productName: wooProduct.nome ?? '',
            sku: wooProduct.sku,
            wooStock: wooProduct.quantitaTotale?.toDouble() ?? 0.0,
            atumStock: atumStock['current_stock'],
            atumLocation: atumStock['location'],
            stockStatus: 'outofstock',
            isLowStock: true,
            wooPrice: wooProduct.prezzoNormale,
            atumPurchasePrice: atumStock['purchase_price'],
            wooLastUpdated: wooProduct.dataModifica,
            atumLastUpdated: atumStock['last_updated'] != null
                ? DateTime.tryParse(atumStock['last_updated'])
                : null,
            hasDiscrepancy: false,
          ),
        );
      }

      return combinedLowStock;
    } catch (e) {
      log.e('Error getting combined low stock: $e');
      rethrow;
    }
  }

  /// Esegue riconciliazione inventario
  Future<SyncResult> reconcileInventory({bool fixDiscrepancies = false}) async {
    try {
      log.d('Starting inventory reconciliation...');

      final unifiedInventory = await getUnifiedInventory();
      final discrepancies = <Map<String, dynamic>>[];
      int fixedCount = 0;

      for (final item in unifiedInventory) {
        if (item.hasDiscrepancy && fixDiscrepancies) {
          try {
            // Correggi discrepanza basandoti su ATUM (più affidabile)
            if (item.discrepancyType == 'woo_higher') {
              await _atumConnect.atumDio.put(
                '/stock/reconcile',
                data: {
                  'product_id': item.productId,
                  'correct_stock': item.wooStock,
                  'reason': 'Reconciliation: Woo stock higher than ATUM',
                },
              );
            } else {
              await _wooQuery.updateProductStock(
                item.productId,
                stockQuantity: item.atumStock?.toInt() ?? 0,
                stockStatus: item.stockStatus,
              );
            }

            fixedCount++;
          } catch (e) {
            discrepancies.add({
              'product_id': item.productId,
              'error': 'Failed to fix discrepancy: $e',
            });
          }
        }
      }

      final result = SyncResult(
        success: discrepancies.isEmpty,
        syncedProducts: fixedCount,
        errors: discrepancies.map((d) => d['error'].toString()).toList(),
        message: 'Reconciliation completed: $fixedCount discrepancies fixed',
      );

      if (result.success) {
        log.i(
          '✅ Inventory reconciliation completed: $fixedCount discrepancies fixed',
        );
      } else {
        log.w(
          '⚠️ Inventory reconciliation completed with ${discrepancies.length} errors',
        );
      }

      return result;
    } catch (e) {
      log.e('Error in inventory reconciliation: $e');
      return SyncResult(
        success: false,
        message: 'Reconciliation failed: $e',
        errors: ['Reconciliation error: $e'],
      );
    }
  }

  // =======================================================
  // == METODI HELPER                           ==
  // =======================================================

  /// Ottiene stock ATUM per prodotto
  Future<Map<String, dynamic>> _getAtumStockForProduct(int productId) async {
    try {
      final response = await _atumConnect.atumDio.get(
        '/stock/product/$productId',
      );

      return response.data ?? <String, dynamic>{};
    } catch (e) {
      log.e('Error getting ATUM stock for product $productId: $e');
      return <String, dynamic>{};
    }
  }

  /// Ottiene tutto lo stock ATUM
  Future<List<Map<String, dynamic>>> _getAllAtumStock() async {
    try {
      final response = await _atumConnect.atumDio.get('/stock/all');

      return List<Map<String, dynamic>>.from(response.data ?? []);
    } catch (e) {
      log.e('Error getting all ATUM stock: $e');
      return [];
    }
  }

  /// Determina stato stock combinato
  String _determineStockStatus(bool? wooInStock, double? atumStock) {
    if (atumStock == null) return 'unknown';

    if (atumStock == 0) {
      return 'outofstock';
    } else if (atumStock <= 5) {
      return 'lowstock';
    } else {
      return 'instock';
    }
  }

  /// Aggiorna inventario da scansione RFID
  /// Assume che i tag siano ID dei prodotti
  Future<SyncResult> updateFromRFIDScan(List<String> tagIds) async {
    try {
      log.d('Updating inventory from RFID scan: ${tagIds.length} tags');

      final updatedProducts = <int>[];
      final errors = <String>[];
      int successCount = 0;

      for (final tag in tagIds) {
        try {
          // Assume tag is product ID
          final productId = int.tryParse(tag);
          if (productId != null) {
            final product = await _wooQuery.getProductById(productId);
            if (product != null && product.id != null) {
              // Aggiorna stock (esempio: imposta a 1 se era 0, o incrementa)
              final currentStock = product.quantitaTotale ?? 0;
              final newStock = currentStock == 0 ? 1 : currentStock + 1;

              await _wooQuery.updateProductStock(
                product.id!,
                stockQuantity: newStock,
                stockStatus: newStock > 0 ? 'instock' : 'outofstock',
              );

              updatedProducts.add(product.id!);
              successCount++;
              log.i(
                'Updated stock for product ${product.nome} (ID: $tag) to $newStock',
              );
            } else {
              errors.add('Product not found for RFID tag: $tag');
            }
          } else {
            errors.add('Invalid product ID in RFID tag: $tag');
          }
        } catch (e) {
          errors.add('Error updating product for tag $tag: $e');
        }
      }

      final result = SyncResult(
        success: errors.isEmpty,
        syncedProducts: successCount,
        errors: errors,
        message:
            'RFID scan update completed: $successCount/${tagIds.length} tags processed',
      );

      if (result.success) {
        log.i(
          '✅ RFID inventory update completed: $successCount products updated',
        );
      } else {
        log.w(
          '⚠️ RFID inventory update completed with ${errors.length} errors',
        );
      }

      return result;
    } catch (e) {
      log.e('Error in RFID inventory update: $e');
      return SyncResult(
        success: false,
        message: 'RFID update failed: $e',
        errors: ['RFID update error: $e'],
      );
    }
  }

  /// Verifica disponibilità servizi
  Future<bool> areServicesAvailable() async {
    try {
      final atumAvailable = await _atumConnect.isAtumAvailable();
      final wooAvailable = await _wooQuery.isServiceAvailable();

      return atumAvailable && wooAvailable;
    } catch (e) {
      log.e('Error checking service availability: $e');
      return false;
    }
  }
}
