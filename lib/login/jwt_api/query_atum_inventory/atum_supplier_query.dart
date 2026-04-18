// ATUM Supplier Query - Gestione fornitori ATUM
//
// Gestisce tutte le operazioni sui fornitori
// Include: creazione, lettura, aggiornamento, assegnazione prodotti

import 'dart:async';

import './atum_connect.dart';
import '../../../log_viewer/app_logger.dart';

/// Filtri per ricerca fornitori
class SupplierFilters {
  final String? search;
  final String? category;
  final bool? activeOnly;
  final String? country;
  final String? city;
  final String? orderBy;
  final String? order;
  final int? page;
  final int? perPage;

  SupplierFilters({
    this.search,
    this.category,
    this.activeOnly,
    this.country,
    this.city,
    this.orderBy,
    this.order,
    this.page,
    this.perPage,
  });
}

/// Fornitore ATUM
class AtumSupplier {
  final int id;
  final String name;
  final String? code;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final String? city;
  final String? country;
  final String? vatNumber;
  final String? taxNumber;
  final String? description;
  final bool active;
  final int? productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  AtumSupplier({
    required this.id,
    required this.name,
    this.code,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.city,
    this.country,
    this.vatNumber,
    this.taxNumber,
    this.description,
    this.active = true,
    this.productCount,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory AtumSupplier.fromJson(Map<String, dynamic> json) {
    return AtumSupplier(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      vatNumber: json['vat_number'],
      taxNumber: json['tax_number'],
      description: json['description'],
      active: json['active'] ?? true,
      productCount: json['product_count'],
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
      'name': name,
      'code': code,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address,
      'city': city,
      'country': country,
      'vat_number': vatNumber,
      'tax_number': taxNumber,
      'description': description,
      'active': active,
      'product_count': productCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Prodotto fornitore
class SupplierProduct {
  final int productId;
  final String productName;
  final String? sku;
  final double? purchasePrice;
  final String? supplierSku;
  final String? supplierProductName;
  final DateTime? lastSupplyDate;
  final double? averageSupplyTime;

  SupplierProduct({
    required this.productId,
    required this.productName,
    this.sku,
    this.purchasePrice,
    this.supplierSku,
    this.supplierProductName,
    this.lastSupplyDate,
    this.averageSupplyTime,
  });

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    return SupplierProduct(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      sku: json['sku'],
      purchasePrice: json['purchase_price']?.toDouble(),
      supplierSku: json['supplier_sku'],
      supplierProductName: json['supplier_product_name'],
      lastSupplyDate: json['last_supply_date'] != null 
          ? DateTime.tryParse(json['last_supply_date']) 
          : null,
      averageSupplyTime: json['average_supply_time']?.toDouble(),
    );
  }
}

/// Service per gestire i fornitori ATUM
class AtumSupplierQuery {
  // Singleton
  static final AtumSupplierQuery _instance = AtumSupplierQuery._internal();
  factory AtumSupplierQuery() => _instance;
  AtumSupplierQuery._internal();

  final AtumConnect _atumConnect = AtumConnect();

  /// Ottiene l'istanza ATUM autenticata
  AtumConnect get _atum => _atumConnect;

  // =======================================================
  // == METODI GESTIONE FORNITORI                 ==
  // =======================================================

  /// Ottiene lista fornitori
  Future<List<AtumSupplier>> getSuppliers({
    SupplierFilters? filters,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM suppliers...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (filters?.search != null) 'search': filters!.search!,
        if (filters?.category != null) 'category': filters!.category!,
        if (filters?.activeOnly == true) 'active_only': 'true',
        if (filters?.country != null) 'country': filters!.country!,
        if (filters?.city != null) 'city': filters!.city!,
        if (filters?.orderBy != null) 'orderby': filters!.orderBy!,
        if (filters?.order != null) 'order': filters!.order!,
      };

      final response = await _atum.atumRequest('GET', '/suppliers', queryParams: queryParams);
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumSupplier.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting suppliers: $e');
      rethrow;
    }
  }

  /// Ottiene singolo fornitore
  Future<AtumSupplier?> getSupplier(int supplierId) async {
    try {
      log.d('Getting ATUM supplier: $supplierId');
      
      final response = await _atum.atumRequest('GET', '/suppliers/$supplierId');
      
      if (response['success'] == true) {
        return AtumSupplier.fromJson(response['data']);
      } else {
        log.w('Supplier not found: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error getting supplier: $e');
      rethrow;
    }
  }

  /// Crea nuovo fornitore
  Future<AtumSupplier?> createSupplier({
    required String name,
    String? code,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? city,
    String? country,
    String? vatNumber,
    String? taxNumber,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      log.d('Creating ATUM supplier: $name');
      
      final data = {
        'name': name,
        'code': code,
        'email': email,
        'phone': phone,
        'website': website,
        'address': address,
        'city': city,
        'country': country,
        'vat_number': vatNumber,
        'tax_number': taxNumber,
        'description': description,
        'metadata': metadata,
      };

      final response = await _atum.atumRequest('POST', '/suppliers', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Supplier created successfully: ${response['data']['id']}');
        return AtumSupplier.fromJson(response['data']);
      } else {
        log.w('⚠️ Supplier creation failed: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error creating supplier: $e');
      rethrow;
    }
  }

  /// Aggiorna fornitore esistente
  Future<AtumSupplier?> updateSupplier({
    required int supplierId,
    required String name,
    String? code,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? city,
    String? country,
    String? vatNumber,
    String? taxNumber,
    String? description,
    bool? active,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      log.d('Updating ATUM supplier: $supplierId');
      
      final data = {
        'name': name,
        'code': code,
        'email': email,
        'phone': phone,
        'website': website,
        'address': address,
        'city': city,
        'country': country,
        'vat_number': vatNumber,
        'tax_number': taxNumber,
        'description': description,
        if (active != null) 'active': active,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await _atum.atumRequest('PUT', '/suppliers/$supplierId', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Supplier updated successfully: $supplierId');
        return AtumSupplier.fromJson(response['data']);
      } else {
        log.w('⚠️ Supplier update failed: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error updating supplier: $e');
      rethrow;
    }
  }

  /// Elimina fornitore
  Future<bool> deleteSupplier(int supplierId) async {
    try {
      log.d('Deleting ATUM supplier: $supplierId');
      
      final response = await _atum.atumRequest('DELETE', '/suppliers/$supplierId');
      
      if (response['success'] == true) {
        log.i('✅ Supplier deleted successfully: $supplierId');
        return true;
      } else {
        log.w('⚠️ Supplier deletion failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error deleting supplier: $e');
      rethrow;
    }
  }

  /// Ottiene prodotti fornitore
  Future<List<SupplierProduct>> getSupplierProducts(int supplierId) async {
    try {
      log.d('Getting ATUM supplier products: $supplierId');
      
      final response = await _atum.atumRequest('GET', '/suppliers/$supplierId/products');
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => SupplierProduct.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting supplier products: $e');
      rethrow;
    }
  }

  /// Assegna prodotto a fornitore
  Future<bool> assignProductToSupplier({
    required int productId,
    required int supplierId,
    double? purchasePrice,
    String? supplierSku,
  }) async {
    try {
      log.d('Assigning product to supplier: product=$productId, supplier=$supplierId');
      
      final data = {
        'product_id': productId.toString(),
        'supplier_id': supplierId,
        'purchase_price': purchasePrice,
        'supplier_sku': supplierSku,
      };

      final response = await _atum.atumRequest('POST', '/suppliers/assign-product', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Product assigned to supplier successfully');
        return true;
      } else {
        log.w('⚠️ Product assignment failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error assigning product to supplier: $e');
      rethrow;
    }
  }

  /// Rimuovi assegnazione prodotto fornitore
  Future<bool> removeProductFromSupplier({
    required int productId,
    required int supplierId,
  }) async {
    try {
      log.d('Removing product from supplier: product=$productId, supplier=$supplierId');
      
      final data = {
        'product_id': productId.toString(),
        'supplier_id': supplierId,
      };

      final response = await _atum.atumRequest('DELETE', '/suppliers/remove-product', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Product removed from supplier successfully');
        return true;
      } else {
        log.w('⚠️ Product removal failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error removing product from supplier: $e');
      rethrow;
    }
  }

  /// Ottiene fornitori per categoria
  Future<List<AtumSupplier>> getSuppliersByCategory(String category) async {
    try {
      log.d('Getting ATUM suppliers by category: $category');
      
      final response = await _atum.atumRequest('GET', '/suppliers/by-category', queryParams: <String, String>{
        'category': category,
      });

      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumSupplier.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting suppliers by category: $e');
      rethrow;
    }
  }

  /// Ottiene statistiche fornitori
  Future<Map<String, dynamic>> getSupplierStatistics() async {
    try {
      log.d('Getting ATUM supplier statistics...');
      
      final response = await _atum.atumRequest('GET', '/suppliers/statistics');
      
      return response['data'] ?? {};
    } catch (e) {
      log.e('Error getting supplier statistics: $e');
      rethrow;
    }
  }

  /// Verifica disponibilità servizio fornitori
  Future<bool> isSupplierServiceAvailable() async {
    try {
      await getSuppliers();
      return true;
    } catch (e) {
      log.w('ATUM Supplier service not available: $e');
      return false;
    }
  }
}