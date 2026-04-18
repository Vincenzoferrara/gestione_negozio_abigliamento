// ATUM Purchase Order Query - Gestione ordini d'acquisto ATUM
//
// Gestisce tutte le operazioni sui Purchase Orders
// Include: creazione, lettura, aggiornamento, stato, esportazione PDF

import 'dart:async';

import './atum_connect.dart';
import '../../../log_viewer/app_logger.dart';

/// Stati Purchase Order ATUM
enum AtumPoStatus {
  draft,
  pending,
  ordered,
  received,
  processing,
  completed,
  cancelled,
}

/// Filtri per ricerca Purchase Orders
class PoFilters {
  final String? search;
  final AtumPoStatus? status;
  final int? supplierId;
  final String? dateFrom;
  final String? dateTo;
  final String? orderBy;
  final String? order;
  final int? page;
  final int? perPage;

  PoFilters({
    this.search,
    this.status,
    this.supplierId,
    this.dateFrom,
    this.dateTo,
    this.orderBy,
    this.order,
    this.page,
    this.perPage,
  });
}

/// Item Purchase Order ATUM
class AtumPoItem {
  final int id;
  final int purchaseOrderId;
  final int productId;
  final String productName;
  final String? sku;
  final double quantity;
  final double? purchasePrice;
  final double? totalAmount;
  final String? notes;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final String? status;

  AtumPoItem({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    required this.productName,
    this.sku,
    required this.quantity,
    this.purchasePrice,
    this.totalAmount,
    this.notes,
    this.expectedDate,
    this.receivedDate,
    this.status,
  });

  factory AtumPoItem.fromJson(Map<String, dynamic> json) {
    return AtumPoItem(
      id: json['id'] ?? 0,
      purchaseOrderId: json['purchase_order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      sku: json['sku'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      purchasePrice: json['purchase_price']?.toDouble(),
      totalAmount: json['total_amount']?.toDouble(),
      notes: json['notes'],
      expectedDate: json['expected_date'] != null 
          ? DateTime.tryParse(json['expected_date']) 
          : null,
      receivedDate: json['received_date'] != null 
          ? DateTime.tryParse(json['received_date']) 
          : null,
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'product_id': productId.toString(),
      'product_name': productName,
      'sku': sku,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'total_amount': totalAmount,
      'notes': notes,
      'expected_date': expectedDate?.toIso8601String(),
      'received_date': receivedDate?.toIso8601String(),
      'status': status,
    };
  }
}

/// Purchase Order ATUM
class AtumPurchaseOrder {
  final int id;
  final String orderNumber;
  final int? supplierId;
  final String? supplierName;
  final AtumPoStatus status;
  final DateTime orderDate;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final double? totalAmount;
  final double? taxAmount;
  final double? shippingAmount;
  final String? notes;
  final List<AtumPoItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  AtumPurchaseOrder({
    required this.id,
    required this.orderNumber,
    this.supplierId,
    this.supplierName,
    required this.status,
    required this.orderDate,
    this.expectedDate,
    this.receivedDate,
    this.totalAmount,
    this.taxAmount,
    this.shippingAmount,
    this.notes,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory AtumPurchaseOrder.fromJson(Map<String, dynamic> json) {
    return AtumPurchaseOrder(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'],
      status: AtumPoStatus.values.firstWhere(
        (status) => status.name == (json['status'] ?? 'draft'),
        orElse: () => AtumPoStatus.draft,
      ),
      orderDate: DateTime.tryParse(json['order_date']) ?? DateTime.now(),
      expectedDate: json['expected_date'] != null 
          ? DateTime.tryParse(json['expected_date']) 
          : null,
      receivedDate: json['received_date'] != null 
          ? DateTime.tryParse(json['received_date']) 
          : null,
      totalAmount: json['total_amount']?.toDouble(),
      taxAmount: json['tax_amount']?.toDouble(),
      shippingAmount: json['shipping_amount']?.toDouble(),
      notes: json['notes'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => AtumPoItem.fromJson(item))
          .toList() ?? [],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
        'status': status.name,
      'order_date': orderDate.toIso8601String(),
      'expected_date': expectedDate?.toIso8601String(),
      'received_date': receivedDate?.toIso8601String(),
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'shipping_amount': shippingAmount,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Service per gestire i Purchase Orders ATUM
class AtumPurchaseOrderQuery {
  // Singleton
  static final AtumPurchaseOrderQuery _instance = AtumPurchaseOrderQuery._internal();
  factory AtumPurchaseOrderQuery() => _instance;
  AtumPurchaseOrderQuery._internal();

  final AtumConnect _atumConnect = AtumConnect();

  /// Ottiene l'istanza ATUM autenticata
  AtumConnect get _atum => _atumConnect;

  // =======================================================
  // == METODI GESTIONE PURCHASE ORDERS        ==
  // =======================================================

  /// Ottiene lista Purchase Orders
  Future<List<AtumPurchaseOrder>> getPurchaseOrders({
    PoFilters? filters,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM purchase orders...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      final response = await _atum.atumRequest('GET', '/purchase-orders', queryParams: queryParams);
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumPurchaseOrder.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting purchase orders: $e');
      rethrow;
    }
  }

  /// Ottiene singolo Purchase Order
  Future<AtumPurchaseOrder?> getPurchaseOrder(int poId) async {
    try {
      log.d('Getting ATUM purchase order: $poId');
      
      final response = await _atum.atumRequest('GET', '/purchase-orders/$poId');
      
      if (response['success'] == true) {
        return AtumPurchaseOrder.fromJson(response['data']);
      } else {
        log.w('Purchase Order not found: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error getting purchase order: $e');
      rethrow;
    }
  }

  /// Crea nuovo Purchase Order
  Future<AtumPurchaseOrder?> createPurchaseOrder({
    required String orderNumber,
    required int supplierId,
    required List<AtumPoItem> items,
    DateTime? expectedDate,
    String? notes,
    double? taxAmount,
    double? shippingAmount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      log.d('Creating ATUM purchase order: $orderNumber');
      
      final data = {
        'order_number': orderNumber,
        'supplier_id': supplierId,
        'items': items.map((item) => item.toJson()).toList(),
        'expected_date': expectedDate?.toIso8601String(),
        'notes': notes,
        'tax_amount': taxAmount,
        'shipping_amount': shippingAmount,
        'metadata': metadata,
      };

      final response = await _atum.atumRequest('POST', '/purchase-orders', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Purchase Order created successfully: ${response['data']['id']}');
        return AtumPurchaseOrder.fromJson(response['data']);
      } else {
        log.w('⚠️ Purchase Order creation failed: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error creating purchase order: $e');
      rethrow;
    }
  }

  /// Aggiorna Purchase Order esistente
  Future<AtumPurchaseOrder?> updatePurchaseOrder({
    required int poId,
    String? orderNumber,
    int? supplierId,
    AtumPoStatus? status,
    DateTime? expectedDate,
    DateTime? receivedDate,
    String? notes,
    double? taxAmount,
    double? shippingAmount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      log.d('Updating ATUM purchase order: $poId');
      
      final data = <String, dynamic>{
        if (orderNumber != null) 'order_number': orderNumber,
        if (supplierId != null) 'supplier_id': supplierId,
        if (status != null) 'status': status!.name,
        if (expectedDate != null) 'expected_date': expectedDate.toIso8601String(),
        if (receivedDate != null) 'received_date': receivedDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (taxAmount != null) 'tax_amount': taxAmount,
        if (shippingAmount != null) 'shipping_amount': shippingAmount,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await _atum.atumRequest('PUT', '/purchase-orders/$poId', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Purchase Order updated successfully: $poId');
        return AtumPurchaseOrder.fromJson(response['data']);
      } else {
        log.w('⚠️ Purchase Order update failed: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error updating purchase order: $e');
      rethrow;
    }
  }

  /// Aggiunge item a Purchase Order
  Future<bool> addItemToPurchaseOrder({
    required int poId,
    required int productId,
    required double quantity,
    double? purchasePrice,
    String? notes,
    DateTime? expectedDate,
  }) async {
    try {
      log.d('Adding item to ATUM purchase order: po=$poId, product=$productId');
      
      final data = {
        'product_id': productId.toString(),
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'notes': notes,
        'expected_date': expectedDate?.toIso8601String(),
      };

      final response = await _atum.atumRequest('POST', '/purchase-orders/$poId/items', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Item added to purchase order successfully');
        return true;
      } else {
        log.w('⚠️ Item addition failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error adding item to purchase order: $e');
      rethrow;
    }
  }

  /// Aggiorna stato Purchase Order
  Future<bool> updatePurchaseOrderStatus({
    required int poId,
    required AtumPoStatus newStatus,
    String? notes,
  }) async {
    try {
      log.d('Updating ATUM purchase order status: po=$poId, status=${newStatus.name}');
      
      final data = {
        'status': newStatus.name,
        'notes': notes,
      };

      final response = await _atum.atumRequest('PUT', '/purchase-orders/$poId/status', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Purchase Order status updated successfully');
        return true;
      } else {
        log.w('⚠️ Status update failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error updating purchase order status: $e');
      rethrow;
    }
  }

  /// Riceve Purchase Order (segna come ricevuto)
  Future<bool> receivePurchaseOrder({
    required int poId,
    required DateTime receivedDate,
    String? notes,
    List<Map<String, dynamic>>? receivedItems, // items con quantità ricevute
  }) async {
    try {
      log.d('Receiving ATUM purchase order: po=$poId');
      
      final data = {
        'received_date': receivedDate.toIso8601String(),
        'notes': notes,
        if (receivedItems != null) 'received_items': receivedItems,
      };

      final response = await _atum.atumRequest('PUT', '/purchase-orders/$poId/receive', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Purchase Order received successfully');
        return true;
      } else {
        log.w('⚠️ Purchase Order receive failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error receiving purchase order: $e');
      rethrow;
    }
  }

  /// Elimina Purchase Order
  Future<bool> deletePurchaseOrder(int poId) async {
    try {
      log.d('Deleting ATUM purchase order: $poId');
      
      final response = await _atum.atumRequest('DELETE', '/purchase-orders/$poId');
      
      if (response['success'] == true) {
        log.i('✅ Purchase Order deleted successfully: $poId');
        return true;
      } else {
        log.w('⚠️ Purchase Order deletion failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error deleting purchase order: $e');
      rethrow;
    }
  }

  /// Esporta Purchase Order in PDF
  Future<String?> exportPurchaseOrderToPdf(int poId) async {
    try {
      log.d('Exporting ATUM purchase order to PDF: $poId');
      
      final response = await _atum.atumRequest('GET', '/purchase-orders/$poId/pdf');
      
      if (response['success'] == true) {
        log.i('✅ Purchase Order PDF exported successfully');
        return response['pdf_url'];
      } else {
        log.w('⚠️ PDF export failed: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error exporting purchase order to PDF: $e');
      rethrow;
    }
  }

  /// Ottiene stock in arrivo
  Future<List<AtumPurchaseOrder>> getInboundStock({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM inbound stock...');
      
      final response = await _atum.atumRequest('GET', '/purchase-orders/inbound', queryParams: <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      });

      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumPurchaseOrder.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting inbound stock: $e');
      rethrow;
    }
  }

  /// Ottiene statistiche Purchase Orders
  Future<Map<String, dynamic>> getPurchaseOrderStatistics() async {
    try {
      log.d('Getting ATUM purchase order statistics...');
      
      final response = await _atum.atumRequest('GET', '/purchase-orders/statistics');
      
      return response['data'] ?? {};
    } catch (e) {
      log.e('Error getting purchase order statistics: $e');
      rethrow;
    }
  }

  /// Verifica disponibilità servizio Purchase Orders
  Future<bool> isPurchaseOrderServiceAvailable() async {
    try {
      await getPurchaseOrders();
      return true;
    } catch (e) {
      log.w('ATUM Purchase Order service not available: $e');
      return false;
    }
  }
}