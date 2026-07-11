// Inventory Global - Gestione inventario centralizzata via MGWS

import 'dart:async';

import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import '../login/jwt_api/query_woocommerce/woo_query_prodotti.dart';
import '../log_viewer/app_logger.dart';

enum SyncType { full, stockOnly, pricesOnly, metadataOnly }

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

class CombinedInventoryStats {
  final int totalProducts;
  final int wooProductsCount;
  final int mgwsProductsCount;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalWooValue;
  final double totalMgwsValue;
  final List<Map<String, dynamic>> discrepancies;
  final DateTime lastSyncDate;

  CombinedInventoryStats({
    required this.totalProducts,
    required this.wooProductsCount,
    required this.mgwsProductsCount,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalWooValue,
    required this.totalMgwsValue,
    required this.discrepancies,
    required this.lastSyncDate,
  });
}

class UnifiedInventoryItem {
  final int productId;
  final String productName;
  final String? sku;
  final double wooStock;
  final double? mgwsStock;
  final String? mgwsLocation;
  final String stockStatus;
  final bool isLowStock;
  final double? wooPrice;
  final double? mgwsPurchasePrice;
  final DateTime? wooLastUpdated;
  final DateTime? mgwsLastUpdated;
  final bool hasDiscrepancy;
  final String? discrepancyType;

  UnifiedInventoryItem({
    required this.productId,
    required this.productName,
    this.sku,
    required this.wooStock,
    this.mgwsStock,
    this.mgwsLocation,
    required this.stockStatus,
    this.isLowStock = false,
    this.wooPrice,
    this.mgwsPurchasePrice,
    this.wooLastUpdated,
    this.mgwsLastUpdated,
    this.hasDiscrepancy = false,
    this.discrepancyType,
  });
}

class InventoryGlobal {
  static final InventoryGlobal _instance = InventoryGlobal._internal();
  factory InventoryGlobal() => _instance;
  InventoryGlobal._internal();

  final QueryMgwsInventory _mgwsInventory = QueryMgwsInventory();
  final WooQueryProdotti _wooQuery = WooQueryProdotti();

  Future<void> initialize(String siteUrl) async {
    try {
      log.d('Initializing Inventory Global with MGWS: $siteUrl');

      final mgwsAvailable = await _mgwsInventory.isInventoryServiceAvailable();
      if (!mgwsAvailable) {
        log.w('MGWS inventory non disponibile sul sito: $siteUrl');
        throw Exception('MGWS inventory non disponibile');
      }

      log.i('✅ Inventory Global initialized successfully');
    } catch (e) {
      log.e('Error initializing Inventory Global: $e');
      rethrow;
    }
  }

  Future<SyncResult> syncStockFromWooToMgws({
    List<int>? productIds,
    SyncType syncType = SyncType.full,
  }) async {
    try {
      log.d('Syncing stock from WooCommerce to MGWS...');

      final syncedProducts = <int>[];
      final errors = <String>[];
      int successCount = 0;

      final wooProducts = productIds != null
          ? await Future.wait(
              productIds.map((id) => _wooQuery.getProductById(id)).toList(),
            )
          : await _wooQuery.getProducts(perPage: 100);

      for (final wooProduct in wooProducts) {
        try {
          if (syncType == SyncType.full || syncType == SyncType.stockOnly) {
            final syncSuccess = await _mgwsInventory.syncWooStockToMgws(
              productId: wooProduct.id!,
              wooStock: wooProduct.quantitaTotale ?? 0,
              syncType: syncType.name,
            );

            if (syncSuccess) {
              syncedProducts.add(wooProduct.id!);
              successCount++;
            } else {
              errors.add(
                'Failed to sync product ${wooProduct.id}: ${wooProduct.nome}',
              );
            }
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

  Future<SyncResult> syncStockFromMgwsToWoo({
    List<int>? productIds,
    SyncType syncType = SyncType.stockOnly,
  }) async {
    try {
      log.d('Syncing stock from MGWS to WooCommerce...');

      final syncedProducts = <int>[];
      final errors = <String>[];
      int successCount = 0;

      final mgwsStocks = productIds != null
          ? await Future.wait(
              productIds.map((id) => _getMgwsStockForProduct(id)).toList(),
            )
          : await _getAllMgwsStock();

      for (final mgwsStock in mgwsStocks) {
        try {
          await _wooQuery.updateProductStock(
            mgwsStock['product_id'],
            stockQuantity: mgwsStock['current_stock']?.toInt() ?? 0,
            stockStatus: mgwsStock['stock_status'] ?? 'instock',
          );
          syncedProducts.add(mgwsStock['product_id']);
          successCount++;
        } catch (e) {
          errors.add('Error syncing product ${mgwsStock['product_id']}: $e');
        }
      }

      final result = SyncResult(
        success: errors.isEmpty,
        syncedProducts: successCount,
        errors: errors,
        message: 'MGWS→Woo sync completed: $successCount/${mgwsStocks.length}',
      );

      if (result.success) {
        log.i('✅ MGWS→Woo stock sync completed: $successCount products synced');
      } else {
        log.w('⚠️ MGWS→Woo stock sync completed with ${errors.length} errors');
      }

      return result;
    } catch (e) {
      log.e('Error in MGWS→Woo stock sync: $e');
      return SyncResult(
        success: false,
        message: 'MGWS→Woo sync failed: $e',
        errors: ['MGWS sync error: $e'],
      );
    }
  }

  Future<List<UnifiedInventoryItem>> getUnifiedInventory({
    String? search,
    String? stockStatus,
    String? location,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting unified inventory...');

      final wooProducts = await _wooQuery.getProducts(
        perPage: perPage,
        filters: ProductFilters(search: search, stockStatus: stockStatus),
      );

      final unifiedItems = <UnifiedInventoryItem>[];

      for (final wooProduct in wooProducts) {
        try {
          final mgwsStock = await _getMgwsStockForProduct(wooProduct.id!);

          unifiedItems.add(
            UnifiedInventoryItem(
              productId: wooProduct.id!,
              productName: wooProduct.nome ?? '',
              sku: wooProduct.sku,
              wooStock: wooProduct.quantitaTotale?.toDouble() ?? 0.0,
              mgwsStock: mgwsStock['current_stock'],
              mgwsLocation: mgwsStock['location'],
              stockStatus: _determineStockStatus(
                wooProduct.inStock,
                mgwsStock['current_stock'],
              ),
              isLowStock: mgwsStock['is_low_stock'] ?? false,
              wooPrice: wooProduct.prezzoNormale,
              mgwsPurchasePrice: mgwsStock['purchase_price'],
              wooLastUpdated: wooProduct.dataModifica,
              mgwsLastUpdated: mgwsStock['last_updated'] != null
                  ? DateTime.tryParse(mgwsStock['last_updated'])
                  : null,
              hasDiscrepancy:
                  (wooProduct.quantitaTotale ?? 0) !=
                  (mgwsStock['current_stock'] ?? 0),
              discrepancyType:
                  (wooProduct.quantitaTotale ?? 0) >
                      (mgwsStock['current_stock'] ?? 0)
                  ? 'woo_higher'
                  : 'mgws_higher',
            ),
          );
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

  Future<CombinedInventoryStats> getCombinedStatistics() async {
    try {
      log.d('Getting combined inventory statistics...');

      final wooStats = await _wooQuery.getProductStats();
      final mgwsStats = await _mgwsInventory.getStatistics();

      final discrepancies = <Map<String, dynamic>>[];

      if (wooStats['total_products'] != mgwsStats['total_products']) {
        discrepancies.add({
          'type': 'product_count',
          'woo_count': wooStats['total_products'],
          'mgws_count': mgwsStats['total_products'],
        });
      }

      return CombinedInventoryStats(
        totalProducts:
            ((wooStats['total_products'] ?? 0) +
                (mgwsStats['total_products'] ?? 0)) ~/
            2,
        wooProductsCount: wooStats['total_products'] ?? 0,
        mgwsProductsCount: mgwsStats['total_products'] ?? 0,
        inStockCount:
            ((wooStats['in_stock_count'] ?? 0) +
                (mgwsStats['in_stock_count'] ?? 0)) ~/
            2,
        lowStockCount:
            ((wooStats['low_stock_count'] ?? 0) +
                (mgwsStats['low_stock_count'] ?? 0)) ~/
            2,
        outOfStockCount:
            ((wooStats['out_of_stock_count'] ?? 0) +
                (mgwsStats['out_of_stock_count'] ?? 0)) ~/
            2,
        totalWooValue: wooStats['total_value']?.toDouble() ?? 0.0,
        totalMgwsValue: mgwsStats['total_value']?.toDouble() ?? 0.0,
        discrepancies: discrepancies,
        lastSyncDate: DateTime.now(),
      );
    } catch (e) {
      log.e('Error getting combined statistics: $e');
      rethrow;
    }
  }

  Future<List<UnifiedInventoryItem>> getCombinedLowStock({
    double? threshold,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      log.d('Getting combined low stock items...');

      final wooLowStock = await _wooQuery.getOutOfStockProducts(limit: perPage);
      final mgwsLowStock = await _mgwsInventory.getLowStockItems();

      final combinedLowStock = <UnifiedInventoryItem>[];

      for (final wooProduct in wooLowStock) {
        final mgwsStock = mgwsLowStock.firstWhere(
          (item) => item['product_id'] == wooProduct.id,
          orElse: () => <String, dynamic>{},
        );

        combinedLowStock.add(
          UnifiedInventoryItem(
            productId: wooProduct.id!,
            productName: wooProduct.nome ?? '',
            sku: wooProduct.sku,
            wooStock: wooProduct.quantitaTotale?.toDouble() ?? 0.0,
            mgwsStock: mgwsStock['current_stock'],
            mgwsLocation: mgwsStock['location'],
            stockStatus: 'outofstock',
            isLowStock: true,
            wooPrice: wooProduct.prezzoNormale,
            mgwsPurchasePrice: mgwsStock['purchase_price'],
            wooLastUpdated: wooProduct.dataModifica,
            mgwsLastUpdated: mgwsStock['last_updated'] != null
                ? DateTime.tryParse(mgwsStock['last_updated'])
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

  Future<SyncResult> reconcileInventory({bool fixDiscrepancies = false}) async {
    try {
      log.d('Starting inventory reconciliation...');

      final unifiedInventory = await getUnifiedInventory();
      final discrepancies = <Map<String, dynamic>>[];
      int fixedCount = 0;

      for (final item in unifiedInventory) {
        if (item.hasDiscrepancy && fixDiscrepancies) {
          try {
            if (item.discrepancyType == 'woo_higher') {
              await _mgwsInventory.reconcileStock(
                productId: item.productId,
                correctStock: item.wooStock.toInt(),
                reason: 'Reconciliation: Woo stock higher than MGWS',
              );
            } else {
              await _wooQuery.updateProductStock(
                item.productId,
                stockQuantity: item.mgwsStock?.toInt() ?? 0,
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

  Future<SyncResult> updateFromRFIDScan(List<String> tagIds) async {
    try {
      log.d('Updating inventory from RFID scan: ${tagIds.length} tags');

      final updatedProducts = <int>[];
      final errors = <String>[];
      int successCount = 0;

      for (final tag in tagIds) {
        try {
          final productId = int.tryParse(tag);
          if (productId != null) {
            final product = await _wooQuery.getProductById(productId);
            final wooProductId = product.id;
            if (wooProductId != null) {
              final currentStock = product.quantitaTotale ?? 0;
              final newStock = currentStock == 0 ? 1 : currentStock + 1;

              await _wooQuery.updateProductStock(
                wooProductId,
                stockQuantity: newStock,
                stockStatus: newStock > 0 ? 'instock' : 'outofstock',
              );

              await _mgwsInventory.syncWooStockToMgws(
                productId: wooProductId,
                wooStock: newStock,
                syncType: 'rfid',
              );

              updatedProducts.add(wooProductId);
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

  Future<bool> areServicesAvailable() async {
    try {
      final mgwsAvailable = await _mgwsInventory.isInventoryServiceAvailable();
      final wooAvailable = await _wooQuery.isServiceAvailable();

      return mgwsAvailable && wooAvailable;
    } catch (e) {
      log.e('Error checking service availability: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _getMgwsStockForProduct(int productId) async {
    try {
      return await _mgwsInventory.getProductStock(productId);
    } catch (e) {
      log.e('Error getting MGWS stock for product $productId: $e');
      return <String, dynamic>{};
    }
  }

  Future<List<Map<String, dynamic>>> _getAllMgwsStock() async {
    try {
      return await _mgwsInventory.getAllStock();
    } catch (e) {
      log.e('Error getting all MGWS stock: $e');
      return [];
    }
  }

  String _determineStockStatus(bool? wooInStock, double? mgwsStock) {
    if (mgwsStock == null) return 'unknown';

    if (mgwsStock == 0) {
      return 'outofstock';
    } else if (mgwsStock <= 5) {
      return 'lowstock';
    } else {
      return 'instock';
    }
  }
}
