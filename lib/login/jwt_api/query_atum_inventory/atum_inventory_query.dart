// ATUM Inventory Query - Gestione inventario base
//
// Gestisce tutte le operazioni di base sull'inventario ATUM
// Include: livelli inventario, statistiche, movimenti base

import 'dart:async';

import './atum_connect.dart';
import '../../../log_viewer/app_logger.dart';

/// Filtri per la ricerca inventario
class InventoryFilters {
  final String? search;
  final String? stockStatus;
  final String? location;
  final String? supplier;
  final bool? lowStock;
  final String? orderBy;
  final String? order;
  final int? page;
  final int? perPage;

  InventoryFilters({
    this.search,
    this.stockStatus,
    this.location,
    this.supplier,
    this.lowStock,
    this.orderBy,
    this.order,
    this.page,
    this.perPage,
  });
}

/// Livello inventario ATUM
class AtumInventoryLevel {
  final int productId;
  final String productName;
  final String? sku;
  final double currentStock;
  final double? lowStockThreshold;
  final String stockStatus;
  final String? location;
  final String? lastUpdated;
  final bool isLowStock;

  AtumInventoryLevel({
    required this.productId,
    required this.productName,
    this.sku,
    required this.currentStock,
    this.lowStockThreshold,
    required this.stockStatus,
    this.location,
    this.lastUpdated,
    this.isLowStock = false,
  });

  factory AtumInventoryLevel.fromJson(Map<String, dynamic> json) {
    return AtumInventoryLevel(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      sku: json['sku'],
      currentStock: (json['current_stock'] ?? 0).toDouble(),
      lowStockThreshold: json['low_stock_threshold']?.toDouble(),
      stockStatus: json['stock_status'] ?? 'unknown',
      location: json['location'],
      lastUpdated: json['last_updated'],
      isLowStock: json['is_low_stock'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId.toString(),
      'product_name': productName,
      'sku': sku,
      'current_stock': currentStock,
      'low_stock_threshold': lowStockThreshold,
      'stock_status': stockStatus,
      'location': location,
      'last_updated': lastUpdated,
      'is_low_stock': isLowStock,
    };
  }
}

/// Statistiche inventario ATUM
class AtumInventoryStats {
  final int totalProducts;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalValue;
  final int controlledProducts;

  AtumInventoryStats({
    required this.totalProducts,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalValue,
    required this.controlledProducts,
  });

  factory AtumInventoryStats.fromJson(Map<String, dynamic> json) {
    return AtumInventoryStats(
      totalProducts: json['total_products'] ?? 0,
      inStockCount: json['in_stock_count'] ?? 0,
      lowStockCount: json['low_stock_count'] ?? 0,
      outOfStockCount: json['out_of_stock_count'] ?? 0,
      totalValue: (json['total_value'] ?? 0).toDouble(),
      controlledProducts: json['controlled_products'] ?? 0,
    );
  }
}

/// Movimento inventario ATUM
class AtumInventoryMovement {
  final int id;
  final int productId;
  final String productName;
  final String movementType; // 'in', 'out', 'adjustment'
  final double quantity;
  final String? reason;
  final String? location;
  final DateTime createdAt;
  final String? createdBy;

  AtumInventoryMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.quantity,
    this.reason,
    this.location,
    required this.createdAt,
    this.createdBy,
  });

  factory AtumInventoryMovement.fromJson(Map<String, dynamic> json) {
    return AtumInventoryMovement(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      movementType: json['movement_type'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      reason: json['reason'],
      location: json['location'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      createdBy: json['created_by'],
    );
  }
}

/// Service per gestire l'inventario ATUM
class AtumInventoryQuery {
  // Singleton
  static final AtumInventoryQuery _instance = AtumInventoryQuery._internal();
  factory AtumInventoryQuery() => _instance;
  AtumInventoryQuery._internal();

  final AtumConnect _atumConnect = AtumConnect();

  /// Ottiene l'istanza ATUM autenticata
  AtumConnect get _atum => _atumConnect;

  // =======================================================
  // == METODI INVENTARIO BASE                      ==
  // =======================================================

  /// Ottiene lista livelli inventario con filtri
  Future<List<AtumInventoryLevel>> getInventoryLevels({
    InventoryFilters? filters,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM inventory levels...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (filters?.search != null) 'search': filters!.search!,
        if (filters?.stockStatus != null) 'stock_status': filters!.stockStatus!,
        if (filters?.location != null) 'location': filters!.location!,
        if (filters?.supplier != null) 'supplier': filters!.supplier!,
        if (filters?.lowStock == true) 'low_stock_only': 'true',
        if (filters?.orderBy != null) 'orderby': filters!.orderBy!,
        if (filters?.order != null) 'order': filters!.order!,
      };

      final response = await _atum.atumRequest('GET', '/inventory/levels', queryParams: queryParams);
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumInventoryLevel.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting inventory levels: $e');
      rethrow;
    }
  }

  /// Ottiene prodotti in esaurimento
  Future<List<AtumInventoryLevel>> getLowStockItems({
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      log.d('Getting ATUM low stock items...');
      
      final response = await _atum.atumRequest('GET', '/inventory/low-stock', queryParams: <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      });

      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumInventoryLevel.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting low stock items: $e');
      rethrow;
    }
  }

  /// Ottiene stock disponibile
  Future<List<AtumInventoryLevel>> getStockOnHand({
    String? location,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM stock on hand...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'stock_status': 'instock',
        if (location != null) 'location': location,
      };

      final response = await _atum.atumRequest('GET', '/inventory/stock-on-hand', queryParams: queryParams);
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumInventoryLevel.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting stock on hand: $e');
      rethrow;
    }
  }

  /// Ottiene movimenti inventario
  Future<List<AtumInventoryMovement>> getInventoryMovements({
    int? productId,
    String? movementType,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM inventory movements...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (productId != null) 'product_id': productId.toString(),
        if (movementType != null) 'movement_type': movementType,
        if (location != null) 'location': location,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await _atum.atumRequest('GET', '/inventory/movements', queryParams: queryParams);
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumInventoryMovement.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting inventory movements: $e');
      rethrow;
    }
  }

  /// Ottiene statistiche inventario
  Future<AtumInventoryStats> getInventoryStatistics() async {
    try {
      log.d('Getting ATUM inventory statistics...');
      
      final response = await _atum.atumRequest('GET', '/inventory/statistics');
      
      return AtumInventoryStats.fromJson(response['data'] ?? {});
    } catch (e) {
      log.e('Error getting inventory statistics: $e');
      rethrow;
    }
  }

  /// Ottiene livelli inventario per categoria
  Future<List<AtumInventoryLevel>> getInventoryByCategory(
    int categoryId, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM inventory by category: $categoryId');
      
      final response = await _atum.atumRequest('GET', '/inventory/by-category', queryParams: <String, String>{
        'category_id': categoryId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
      });

      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumInventoryLevel.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting inventory by category: $e');
      rethrow;
    }
  }

  /// Ottiene inventario per fornitore
  Future<List<AtumInventoryLevel>> getInventoryBySupplier(
    int supplierId, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM inventory by supplier: $supplierId');
      
      final response = await _atum.atumRequest('GET', '/inventory/by-supplier', queryParams: <String, String>{
        'supplier_id': supplierId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
      });

      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumInventoryLevel.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting inventory by supplier: $e');
      rethrow;
    }
  }

  /// Aggiunge movimento inventario
  Future<bool> addInventoryMovement({
    required int productId,
    required String movementType,
    required double quantity,
    String? reason,
    String? location,
  }) async {
    try {
      log.d('Adding ATUM inventory movement: product=$productId, type=$movementType, qty=$quantity');
      
      final data = {
        'product_id': productId.toString(),
        'movement_type': movementType,
        'quantity': quantity,
        'reason': reason,
        'location': location,
      };

      final response = await _atum.atumRequest('POST', '/inventory/movements', data: data);
      
      log.i('✅ Inventory movement added successfully');
      return response['success'] ?? false;
    } catch (e) {
      log.e('Error adding inventory movement: $e');
      rethrow;
    }
  }

  /// Aggiorna livello inventario
  Future<bool> updateInventoryLevel({
    required int productId,
    required double newStockLevel,
    String? location,
    String? reason,
  }) async {
    try {
      log.d('Updating ATUM inventory level: product=$productId, new_level=$newStockLevel');
      
      final data = {
        'product_id': productId.toString(),
        'new_stock_level': newStockLevel,
        'location': location,
        'reason': reason,
      };

      final response = await _atum.atumRequest('PUT', '/inventory/levels', data: data);
      
      log.i('✅ Inventory level updated successfully');
      return response['success'] ?? false;
    } catch (e) {
      log.e('Error updating inventory level: $e');
      rethrow;
    }
  }

  /// Ottiene widget controllo stock
  Future<Map<String, dynamic>> getStockControlWidget() async {
    try {
      log.d('Getting ATUM stock control widget...');
      
      final response = await _atum.atumRequest('GET', '/inventory/stock-widget');
      
      return response['data'] ?? {};
    } catch (e) {
      log.e('Error getting stock control widget: $e');
      rethrow;
    }
  }

  /// Verifica disponibilità servizio inventario
  Future<bool> isInventoryServiceAvailable() async {
    try {
      await getInventoryStatistics();
      return true;
    } catch (e) {
      log.w('ATUM Inventory service not available: $e');
      return false;
    }
  }
}