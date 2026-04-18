// ATUM Stock Query - Gestione stock ATUM
//
// Gestisce tutte le operazioni sullo stock dei prodotti
// Include: aggiornamento quantità, cambio stato, batch operations

import 'dart:async';

import './atum_connect.dart';
import '../../../log_viewer/app_logger.dart';

/// Stati stock ATUM
enum AtumStockStatus {
  inStock,
  outOfStock,
  onBackorder,
  lowStock,
}

/// Tipi movimento stock
enum StockMovementType {
  stockIn,
  out,
  adjustment,
  sale,
  stockReturn,
  transfer,
}

/// Filtri per operazioni stock
class StockFilters {
  final String? search;
  final AtumStockStatus? stockStatus;
  final String? location;
  final int? categoryId;
  final bool? lowStockOnly;
  final bool? includeVariations;
  final String? sku;
  final String? orderBy;
  final String? order;
  final int? page;
  final int? perPage;

  StockFilters({
    this.search,
    this.stockStatus,
    this.location,
    this.categoryId,
    this.lowStockOnly,
    this.includeVariations,
    this.sku,
    this.orderBy,
    this.order,
    this.page,
    this.perPage,
  });
}

/// Informazioni stock prodotto ATUM
class AtumStockInfo {
  final int productId;
  final String productName;
  final String? sku;
  final double currentStock;
  final double? reservedStock;
  final double? availableStock;
  final AtumStockStatus stockStatus;
  final double? lowStockThreshold;
  final bool isLowStock;
  final bool manageStock;
  final bool? backordersAllowed;
  final String? location;
  final DateTime? lastUpdated;
  final double? purchasePrice;
  final double? regularPrice;
  final double? salePrice;

  AtumStockInfo({
    required this.productId,
    required this.productName,
    this.sku,
    required this.currentStock,
    this.reservedStock,
    this.availableStock,
    required this.stockStatus,
    this.lowStockThreshold,
    this.isLowStock = false,
    this.manageStock = false,
    this.backordersAllowed,
    this.location,
    this.lastUpdated,
    this.purchasePrice,
    this.regularPrice,
    this.salePrice,
  });

  factory AtumStockInfo.fromJson(Map<String, dynamic> json) {
    return AtumStockInfo(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      sku: json['sku'],
      currentStock: (json['current_stock'] ?? 0).toDouble(),
      reservedStock: json['reserved_stock']?.toDouble(),
      availableStock: json['available_stock']?.toDouble(),
      stockStatus: AtumStockStatus.values.firstWhere(
        (status) => status.name == (json['stock_status'] ?? 'instock'),
        orElse: () => AtumStockStatus.inStock,
      ),
      lowStockThreshold: json['low_stock_threshold']?.toDouble(),
      isLowStock: json['is_low_stock'] ?? false,
      manageStock: json['manage_stock'] ?? false,
      backordersAllowed: json['backorders_allowed'],
      location: json['location'],
      lastUpdated: json['last_updated'] != null 
          ? DateTime.tryParse(json['last_updated']) 
          : null,
      purchasePrice: json['purchase_price']?.toDouble(),
      regularPrice: json['regular_price']?.toDouble(),
      salePrice: json['sale_price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId.toString(),
      'product_name': productName,
      'sku': sku,
      'current_stock': currentStock,
      'reserved_stock': reservedStock,
      'available_stock': availableStock,
        'stock_status': stockStatus.name,
      'low_stock_threshold': lowStockThreshold,
      'is_low_stock': isLowStock,
      'manage_stock': manageStock,
      'backorders_allowed': backordersAllowed,
      'location': location,
      'last_updated': lastUpdated?.toIso8601String(),
      'purchase_price': purchasePrice,
      'regular_price': regularPrice,
      'sale_price': salePrice,
    };
  }
}

/// Risultato aggiornamento stock
class StockUpdateResult {
  final bool success;
  final String? message;
  final AtumStockInfo? updatedStock;

  StockUpdateResult({
    required this.success,
    this.message,
    this.updatedStock,
  });

  factory StockUpdateResult.fromJson(Map<String, dynamic> json) {
    return StockUpdateResult(
      success: json['success'] ?? false,
      message: json['message'],
      updatedStock: json['data'] != null 
          ? AtumStockInfo.fromJson(json['data'])
          : null,
    );
  }
}

/// Service per gestire lo stock ATUM
class AtumStockQuery {
  // Singleton
  static final AtumStockQuery _instance = AtumStockQuery._internal();
  factory AtumStockQuery() => _instance;
  AtumStockQuery._internal();

  final AtumConnect _atumConnect = AtumConnect();

  /// Ottiene l'istanza ATUM autenticata
  AtumConnect get _atum => _atumConnect;

  // =======================================================
  // == METODI GESTIONE STOCK                        ==
  // =======================================================

  /// Ottiene stock singolo prodotto
  Future<AtumStockInfo?> getProductStock(int productId) async {
    try {
      log.d('Getting ATUM stock for product: $productId');
      
      final response = await _atum.atumRequest('GET', '/stock/product/$productId');
      
      if (response['success'] == true) {
        return AtumStockInfo.fromJson(response['data']);
      } else {
        log.w('Product not found: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error getting product stock: $e');
      rethrow;
    }
  }

  /// Aggiorna quantità stock prodotto
  Future<StockUpdateResult> updateStockQuantity({
    required int productId,
    required double newQuantity,
    String? reason,
    String? location,
    StockMovementType movementType = StockMovementType.adjustment,
  }) async {
    try {
      log.d('Updating ATUM stock: product=$productId, new_qty=$newQuantity');
      
      final data = {
        'product_id': productId.toString(),
        'new_quantity': newQuantity,
        'movement_type': movementType.name,
        'reason': reason ?? 'Stock adjustment via Flutter app',
        'location': location,
      };

      final response = await _atum.atumRequest('PUT', '/stock/update', data: data);
      
      final result = StockUpdateResult.fromJson(response);
      
      if (result.success) {
        log.i('✅ Stock updated successfully: product=$productId, new_qty=$newQuantity');
      } else {
        log.w('⚠️ Stock update failed: ${result.message}');
      }
      
      return result;
    } catch (e) {
      log.e('Error updating stock quantity: $e');
      rethrow;
    }
  }

  /// Imposta stato stock
  Future<StockUpdateResult> setStockStatus({
    required int productId,
    required AtumStockStatus newStatus,
    String? reason,
  }) async {
    try {
      log.d('Setting ATUM stock status: product=$productId, status=${newStatus.name}');
      
      final data = {
        'product_id': productId.toString(),
        'stock_status': newStatus.name,
        'reason': reason ?? 'Status change via Flutter app',
      };

      final response = await _atum.atumRequest('PUT', '/stock/status', data: data);
      
      final result = StockUpdateResult.fromJson(response);
      
      if (result.success) {
        log.i('✅ Stock status updated successfully: product=$productId, status=${newStatus.name}');
      } else {
        log.w('⚠️ Stock status update failed: ${result.message}');
      }
      
      return result;
    } catch (e) {
      log.e('Error setting stock status: $e');
      rethrow;
    }
  }

  /// Ottiene lista prodotti con filtri stock
  Future<List<AtumStockInfo>> getStockList({
    StockFilters? filters,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM stock list...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (filters?.search != null) 'search': filters!.search!,
        if (filters?.stockStatus != null) 'stock_status': filters!.stockStatus!.name,
        if (filters?.location != null) 'location': filters!.location!,
        if (filters?.categoryId != null) 'category_id': filters!.categoryId.toString(),
        if (filters?.lowStockOnly == true) 'low_stock_only': 'true',
        if (filters?.includeVariations == true) 'include_variations': 'true',
        if (filters?.sku != null) 'sku': filters!.sku!,
        if (filters?.orderBy != null) 'orderby': filters!.orderBy!,
        if (filters?.order != null) 'order': filters!.order!,
      };

      final response = await _atum.atumRequest('GET', '/stock/list', queryParams: queryParams);
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumStockInfo.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting stock list: $e');
      rethrow;
    }
  }

  /// Aggiornamento batch stock
  Future<Map<String, dynamic>> batchUpdateStock({
    required List<Map<String, dynamic>> updates,
  }) async {
    try {
      log.d('Batch updating ATUM stock: ${updates.length} items');
      
      final data = {
        'updates': updates,
      };

      final response = await _atum.atumRequest('POST', '/stock/batch-update', data: data);
      
      log.i('✅ Batch stock update completed: ${response['updated_count'] ?? 0} items updated');
      return response;
    } catch (e) {
      log.e('Error in batch stock update: $e');
      rethrow;
    }
  }

  /// Ottiene prodotti in esaurimento
  Future<List<AtumStockInfo>> getLowStockItems({
    double? threshold,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      log.d('Getting ATUM low stock items...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'low_stock_only': 'true',
        if (threshold != null) 'threshold': threshold.toString(),
      };

      final response = await _atum.atumRequest('GET', '/stock/low-stock', queryParams: queryParams);
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumStockInfo.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting low stock items: $e');
      rethrow;
    }
  }

  /// Ottiene prodotti esauriti
  Future<List<AtumStockInfo>> getOutOfStockItems({
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      log.d('Getting ATUM out of stock items...');
      
      final response = await _atum.atumRequest('GET', '/stock/out-of-stock', queryParams: <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      });

      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumStockInfo.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting out of stock items: $e');
      rethrow;
    }
  }

  /// Ottiene stock disponibile per vendita
  Future<List<AtumStockInfo>> getAvailableStock({
    String? location,
    int? categoryId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM available stock...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'stock_status': AtumStockStatus.inStock.name,
        if (location != null) 'location': location,
        if (categoryId != null) 'category_id': categoryId.toString(),
      };

      final response = await _atum.atumRequest('GET', '/stock/available', queryParams: queryParams);
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumStockInfo.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting available stock: $e');
      rethrow;
    }
  }

  /// Aggiunge movimento stock
  Future<bool> addStockMovement({
    required int productId,
    required StockMovementType movementType,
    required double quantity,
    String? reason,
    String? location,
  }) async {
    try {
      log.d('Adding ATUM stock movement: product=$productId, type=${movementType.name}, qty=$quantity');
      
      final data = {
        'product_id': productId.toString(),
        'movement_type': movementType.name,
        'quantity': quantity,
        'reason': reason,
        'location': location,
      };

      final response = await _atum.atumRequest('POST', '/stock/movement', data: data);
      
      log.i('✅ Stock movement added successfully');
      return response['success'] ?? false;
    } catch (e) {
      log.e('Error adding stock movement: $e');
      rethrow;
    }
  }

  /// Ottiene widget controllo stock
  Future<Map<String, dynamic>> getStockControlWidget() async {
    try {
      log.d('Getting ATUM stock control widget...');
      
      final response = await _atum.atumRequest('GET', '/stock/widget');
      
      return response['data'] ?? {};
    } catch (e) {
      log.e('Error getting stock control widget: $e');
      rethrow;
    }
  }

  /// Ottiene statistiche stock
  Future<Map<String, dynamic>> getStockStatistics() async {
    try {
      log.d('Getting ATUM stock statistics...');
      
      final response = await _atum.atumRequest('GET', '/stock/statistics');
      
      return response['data'] ?? {};
    } catch (e) {
      log.e('Error getting stock statistics: $e');
      rethrow;
    }
  }

  /// Sincronizza stock da WooCommerce
  Future<bool> syncStockFromWooCommerce({
    required int productId,
    required double wooStock,
    String? location,
  }) async {
    try {
      log.d('Syncing stock from WooCommerce: product=$productId, woo_stock=$wooStock');
      
      final currentAtumStock = await getProductStock(productId);
      
      if (currentAtumStock != null) {
        if (currentAtumStock.currentStock != wooStock) {
      final result = await updateStockQuantity(
            productId: productId,
            newQuantity: wooStock,
            reason: 'Sync from WooCommerce',
            location: location,
        );
        return result.success;
      } else {
        log.d('Stock already synchronized: product=$productId');
        return true;
      }
    } else {
      // Prodotto non trovato in ATUM, lo crea
      final result = await updateStockQuantity(
          productId: productId,
          newQuantity: wooStock,
          reason: 'Initial sync from WooCommerce',
          location: location,
        );
        return result.success;
      }
    } catch (e) {
      log.e('Error syncing stock from WooCommerce: $e');
      return false;
    }
  }

  /// Verifica disponibilità servizio stock
  Future<bool> isStockServiceAvailable() async {
    try {
      await getStockStatistics();
      return true;
    } catch (e) {
      log.w('ATUM Stock service not available: $e');
      return false;
    }
  }
}