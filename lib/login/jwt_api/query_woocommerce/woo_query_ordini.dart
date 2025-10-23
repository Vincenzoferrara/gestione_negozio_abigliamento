/// Query WooCommerce - ORDINI
///
/// Gestisce tutte le operazioni sugli ordini usando woocommerce_flutter_api
/// L'autenticazione è gestita centralmente da JwtConnect

import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../jwt_connect.dart';
import '../error_list.dart';

/// Service per gestire gli ordini WooCommerce
class WooQueryOrdini {
  // Singleton
  static final WooQueryOrdini _instance = WooQueryOrdini._internal();
  factory WooQueryOrdini() => _instance;
  WooQueryOrdini._internal();

  final JwtConnect _auth = JwtConnect();
  WooCommerce? _woo;

  /// Inizializza WooCommerce usando il token JWT di JwtConnect
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

    _woo!.dio = _auth.getAuthenticatedDio();
    return _woo!;
  }

  /// Reset dell'istanza (utile dopo logout)
  void reset() {
    _woo = null;
  }

  // =======================================================
  // == METODI ORDINI                                     ==
  // =======================================================

  /// Ottiene lista ordini con paginazione e filtri
  Future<List<WooOrder>> getOrders({
    int page = 1,
    int perPage = 20,
    List<WooOrderStatus>? status,
    int? customer,
    WooOrderOrderBy? orderBy,
    WooSortOrder? order,
  }) async {
    try {
      final woo = _getWooCommerce();

      return await woo.getOrders(
        page: page,
        perPage: perPage,
        status: status ?? const [WooOrderStatus.any],
        customer: customer,
        orderBy: orderBy ?? WooOrderOrderBy.date,
        order: order ?? WooSortOrder.desc,
      );
    } catch (e) {
      print('❌ Errore getOrders: $e');
      rethrow;
    }
  }

  /// Ottiene un singolo ordine per ID
  Future<WooOrder> getOrderById(int orderId) async {
    try {
      final woo = _getWooCommerce();
      return await woo.getOrder(orderId);
    } catch (e) {
      print('❌ Errore getOrderById: $e');
      rethrow;
    }
  }

  /// Ottiene ordini per stato
  Future<List<WooOrder>> getOrdersByStatus(
    WooOrderStatus status, {
    int limit = 50,
  }) async {
    return await getOrders(
      perPage: limit,
      status: [status],
    );
  }

  /// Ottiene ordini di un cliente specifico
  Future<List<WooOrder>> getOrdersByCustomer(
    int customerId, {
    int limit = 50,
  }) async {
    return await getOrders(
      perPage: limit,
      customer: customerId,
    );
  }

  /// Crea un nuovo ordine (usa Dio diretto)
  Future<WooOrder> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _auth.getAuthenticatedDio().post(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/orders',
        data: orderData,
      );

      return WooOrder.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('❌ Errore createOrder: $e');
      rethrow;
    }
  }

  /// Aggiorna un ordine esistente (usa Dio diretto)
  Future<WooOrder> updateOrder(
    int orderId,
    Map<String, dynamic> orderData,
  ) async {
    try {
      final response = await _auth.getAuthenticatedDio().put(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/orders/$orderId',
        data: orderData,
      );

      return WooOrder.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('❌ Errore updateOrder: $e');
      rethrow;
    }
  }

  /// Aggiorna lo stato di un ordine
  Future<WooOrder> updateOrderStatus(int orderId, String status) async {
    return await updateOrder(orderId, {'status': status});
  }

  /// Elimina un ordine
  Future<bool> deleteOrder(int orderId, {bool force = false}) async {
    try {
      await _auth.getAuthenticatedDio().delete(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/orders/$orderId',
        queryParameters: {'force': force},
      );
      return true;
    } catch (e) {
      print('❌ Errore deleteOrder: $e');
      rethrow;
    }
  }

  /// Ottiene note di un ordine
  Future<List<WooOrderNote>> getOrderNotes(int orderId) async {
    try {
      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/orders/$orderId/notes',
      );

      return (response.data as List)
          .map((item) => WooOrderNote.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Errore getOrderNotes: $e');
      rethrow;
    }
  }

  /// Aggiungi nota a un ordine
  Future<WooOrderNote> addOrderNote(
    int orderId, {
    required String note,
    bool customerNote = false,
  }) async {
    try {
      final response = await _auth.getAuthenticatedDio().post(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/orders/$orderId/notes',
        data: {
          'note': note,
          'customer_note': customerNote,
        },
      );

      return WooOrderNote.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('❌ Errore addOrderNote: $e');
      rethrow;
    }
  }

  /// Ottiene statistiche sugli ordini
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final woo = _getWooCommerce();

      // Stati ordine comuni
      const stati = [
        'pending',
        'processing',
        'on-hold',
        'completed',
        'cancelled',
        'refunded',
        'failed'
      ];

      final futures = stati.map((stato) => _getOrderCountByStatus(woo, stato));
      final conteggi = await Future.wait(futures);

      final result = <String, dynamic>{};
      for (var i = 0; i < stati.length; i++) {
        result[stati[i]] = conteggi[i];
      }

      return result;
    } catch (e) {
      print('❌ Errore getOrderStats: $e');
      return {};
    }
  }

  /// Helper: ottiene il conteggio ordini per stato
  Future<int> _getOrderCountByStatus(
    WooCommerce woo,
    String status,
  ) async {
    try {
      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/orders',
        queryParameters: {
          'per_page': 1,
          'status': status,
        },
      );

      return int.tryParse(response.headers.value('x-wp-total') ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Operazioni batch sugli ordini (usa Dio diretto)
  Future<Map<String, dynamic>> batchUpdateOrders({
    List<Map<String, dynamic>>? create,
    List<Map<String, dynamic>>? update,
    List<int>? delete,
  }) async {
    try {
      final batchData = <String, dynamic>{};
      if (create != null && create.isNotEmpty) batchData['create'] = create;
      if (update != null && update.isNotEmpty) batchData['update'] = update;
      if (delete != null && delete.isNotEmpty) batchData['delete'] = delete;

      if (batchData.isEmpty) {
        throw Exception('Nessuna operazione batch specificata');
      }

      final response = await _auth.getAuthenticatedDio().post(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/orders/batch',
        data: batchData,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Errore batchUpdateOrders: $e');
      rethrow;
    }
  }

  /// Verifica disponibilità del servizio
  Future<bool> isServiceAvailable() async {
    try {
      await getOrders(perPage: 1);
      return true;
    } catch (e) {
      return false;
    }
  }
}
