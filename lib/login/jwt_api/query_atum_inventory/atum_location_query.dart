// ATUM Location Query - Gestione locations ATUM
//
// Gestisce tutte le operazioni sulle locations di magazzino
// Include: creazione, lettura, aggiornamento locations

import 'dart:async';

import './atum_connect.dart';
import '../../../log_viewer/app_logger.dart';

/// Tipi location ATUM
enum AtumLocationType {
  warehouse,
  shelf,
  room,
  area,
  zone,
  custom,
}

/// Filtri per ricerca locations
class LocationFilters {
  final String? search;
  final AtumLocationType? type;
  final String? parent;
  final bool? activeOnly;
  final String? orderBy;
  final String? order;
  final int? page;
  final int? perPage;

  LocationFilters({
    this.search,
    this.type,
    this.parent,
    this.activeOnly,
    this.orderBy,
    this.order,
    this.page,
    this.perPage,
  });
}

/// Location ATUM
class AtumLocation {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final AtumLocationType type;
  final int? parentId;
  final String? parentName;
  final bool active;
  final int? productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  AtumLocation({
    required this.id,
    required this.name,
    this.code,
    this.description,
    required this.type,
    this.parentId,
    this.parentName,
    this.active = true,
    this.productCount,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory AtumLocation.fromJson(Map<String, dynamic> json) {
    return AtumLocation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
      description: json['description'],
      type: AtumLocationType.values.firstWhere(
        (type) => type.name == (json['type'] ?? 'custom'),
        orElse: () => AtumLocationType.custom,
      ),
      parentId: json['parent_id'],
      parentName: json['parent_name'],
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
      'description': description,
      'type': type.name,
      'parent_id': parentId,
      'parent_name': parentName,
      'active': active,
      'product_count': productCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Stock per location
class LocationStock {
  final int locationId;
  final String locationName;
  final int productId;
  final String productName;
  final String? sku;
  final double currentStock;
  final double? reservedStock;
  final double availableStock;
  final String stockStatus;
  final DateTime? lastUpdated;

  LocationStock({
    required this.locationId,
    required this.locationName,
    required this.productId,
    required this.productName,
    this.sku,
    required this.currentStock,
    this.reservedStock,
    this.availableStock = 0.0,
    required this.stockStatus,
    this.lastUpdated,
  });

  factory LocationStock.fromJson(Map<String, dynamic> json) {
    return LocationStock(
      locationId: json['location_id'] ?? 0,
      locationName: json['location_name'] ?? '',
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      sku: json['sku'],
      currentStock: (json['current_stock'] ?? 0).toDouble(),
      reservedStock: json['reserved_stock']?.toDouble(),
      availableStock: (json['available_stock'] ?? 0).toDouble(),
      stockStatus: json['stock_status'] ?? 'unknown',
      lastUpdated: json['last_updated'] != null 
          ? DateTime.tryParse(json['last_updated']) 
          : null,
    );
  }
}

/// Service per gestire le locations ATUM
class AtumLocationQuery {
  // Singleton
  static final AtumLocationQuery _instance = AtumLocationQuery._internal();
  factory AtumLocationQuery() => _instance;
  AtumLocationQuery._internal();

  final AtumConnect _atumConnect = AtumConnect();

  /// Ottiene l'istanza ATUM autenticata
  AtumConnect get _atum => _atumConnect;

  // =======================================================
  // == METODI GESTIONE LOCATIONS                   ==
  // =======================================================

  /// Ottiene lista locations
  Future<List<AtumLocation>> getLocations({
    LocationFilters? filters,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      log.d('Getting ATUM locations...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (filters?.search != null) 'search': filters!.search!,
        if (filters?.type != null) 'type': filters!.type!.name,
        if (filters?.parent != null) 'parent': filters!.parent!,
        if (filters?.activeOnly == true) 'active_only': 'true',
        if (filters?.orderBy != null) 'orderby': filters!.orderBy!,
        if (filters?.order != null) 'order': filters!.order!,
      };

      final response = await _atum.atumRequest('GET', '/locations', queryParams: queryParams);
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumLocation.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting locations: $e');
      rethrow;
    }
  }

  /// Ottiene singola location
  Future<AtumLocation?> getLocation(int locationId) async {
    try {
      log.d('Getting ATUM location: $locationId');
      
      final response = await _atum.atumRequest('GET', '/locations/$locationId');
      
      if (response['success'] == true) {
        return AtumLocation.fromJson(response['data']);
      } else {
        log.w('Location not found: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error getting location: $e');
      rethrow;
    }
  }

  /// Crea nuova location
  Future<AtumLocation?> createLocation({
    required String name,
    String? code,
    String? description,
    AtumLocationType type = AtumLocationType.custom,
    int? parentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      log.d('Creating ATUM location: $name');
      
      final data = {
        'name': name,
        'code': code,
        'description': description,
        'type': type.name,
        'parent_id': parentId,
        'metadata': metadata,
      };

      final response = await _atum.atumRequest('POST', '/locations', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Location created successfully: ${response['data']['id']}');
        return AtumLocation.fromJson(response['data']);
      } else {
        log.w('⚠️ Location creation failed: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error creating location: $e');
      rethrow;
    }
  }

  /// Aggiorna location esistente
  Future<AtumLocation?> updateLocation({
    required int locationId,
    required String name,
    String? code,
    String? description,
    AtumLocationType? type,
    int? parentId,
    bool? active,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      log.d('Updating ATUM location: $locationId');
      
      final data = {
        'name': name,
        'code': code,
        'description': description,
        if (type != null) 'type': type!.toString(),
        if (parentId != null) 'parent_id': parentId,
        if (active != null) 'active': active,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await _atum.atumRequest('PUT', '/locations/$locationId', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Location updated successfully: $locationId');
        return AtumLocation.fromJson(response['data']);
      } else {
        log.w('⚠️ Location update failed: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error updating location: $e');
      rethrow;
    }
  }

  /// Elimina location
  Future<bool> deleteLocation(int locationId) async {
    try {
      log.d('Deleting ATUM location: $locationId');
      
      final response = await _atum.atumRequest('DELETE', '/locations/$locationId');
      
      if (response['success'] == true) {
        log.i('✅ Location deleted successfully: $locationId');
        return true;
      } else {
        log.w('⚠️ Location deletion failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error deleting location: $e');
      rethrow;
    }
  }

  /// Ottiene gerarchia locations
  Future<List<AtumLocation>> getLocationHierarchy() async {
    try {
      log.d('Getting ATUM location hierarchy...');
      
      final response = await _atum.atumRequest('GET', '/locations/hierarchy');
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumLocation.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting location hierarchy: $e');
      rethrow;
    }
  }

  /// Ottiene stock per location
  Future<List<LocationStock>> getLocationStock(int locationId) async {
    try {
      log.d('Getting ATUM location stock: $locationId');
      
      final response = await _atum.atumRequest('GET', '/locations/$locationId/stock');
      
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => LocationStock.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting location stock: $e');
      rethrow;
    }
  }

  /// Aggiorna stock location
  Future<bool> updateLocationStock({
    required int locationId,
    required int productId,
    required double newStock,
    String? reason,
  }) async {
    try {
      log.d('Updating ATUM location stock: location=$locationId, product=$productId, new_stock=$newStock');
      
      final data = {
        'product_id': productId.toString(),
        'new_stock': newStock,
        'reason': reason ?? 'Stock adjustment via Flutter app',
      };

      final response = await _atum.atumRequest('PUT', '/locations/$locationId/stock', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Location stock updated successfully');
        return true;
      } else {
        log.w('⚠️ Location stock update failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error updating location stock: $e');
      rethrow;
    }
  }

  /// Assegna prodotto a location
  Future<bool> assignProductToLocation({
    required int productId,
    required int locationId,
    double? quantity,
  }) async {
    try {
      log.d('Assigning product to location: product=$productId, location=$locationId');
      
      final data = {
        'product_id': productId.toString(),
        'location_id': locationId,
        'quantity': quantity ?? 0,
      };

      final response = await _atum.atumRequest('POST', '/locations/assign-product', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Product assigned to location successfully');
        return true;
      } else {
        log.w('⚠️ Product assignment failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      log.e('Error assigning product to location: $e');
      rethrow;
    }
  }

  /// Ottiene locations per tipo
  Future<List<AtumLocation>> getLocationsByType(AtumLocationType type) async {
    try {
      log.d('Getting ATUM locations by type: ${type.name}');
      
      final response = await _atum.atumRequest('GET', '/locations/by-type', queryParams: <String, String>{
      'type': type.name,
      });

      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => AtumLocation.fromJson(item)).toList();
    } catch (e) {
      log.e('Error getting locations by type: $e');
      rethrow;
    }
  }

  /// Verifica disponibilità servizio locations
  Future<bool> isLocationServiceAvailable() async {
    try {
      await getLocations();
      return true;
    } catch (e) {
      log.w('ATUM Location service not available: $e');
      return false;
    }
  }
}