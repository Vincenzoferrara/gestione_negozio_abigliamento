import '../../../log_viewer/app_logger.dart';
import 'query_mgws_base.dart';

class QueryMgwsInventory {
  QueryMgwsInventory();

  final QueryMgwsBase _base = QueryMgwsBase();
  final AppLogger _log = AppLogger();

  Future<bool> isInventoryServiceAvailable() async {
    try {
      final response = await _base.get('/wp-json/mgws/v1/inventory/status');
      return response.statusCode == 200;
    } catch (e) {
      _log.w('MGWS inventory non disponibile: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getProductStock(int productId) async {
    final response = await _base.get('/wp-json/mgws/v1/inventory/stock/product/$productId');
    if (response.data is! Map<String, dynamic>) return <String, dynamic>{};
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAllStock() async {
    final response = await _base.get('/wp-json/mgws/v1/inventory/stock/all');
    final raw = response.data;
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final response = await _base.get('/wp-json/mgws/v1/inventory/statistics');
    if (response.data is! Map<String, dynamic>) return <String, dynamic>{};
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final response = await _base.get('/wp-json/mgws/v1/inventory/low-stock');
    final raw = response.data;
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<bool> syncWooStockToMgws({
    required int productId,
    required int wooStock,
    required String syncType,
  }) async {
    final response = await _base.post(
      '/wp-json/mgws/v1/inventory/stock/sync',
      data: {
        'product_id': productId,
        'woo_stock': wooStock,
        'sync_type': syncType,
      },
    );
    return (response.statusCode ?? 500) >= 200 &&
        (response.statusCode ?? 500) < 300;
  }

  Future<bool> reconcileStock({
    required int productId,
    required int correctStock,
    required String reason,
  }) async {
    final response = await _base.put(
      '/wp-json/mgws/v1/inventory/stock/reconcile',
      data: {
        'product_id': productId,
        'correct_stock': correctStock,
        'reason': reason,
      },
    );
    return (response.statusCode ?? 500) >= 200 &&
        (response.statusCode ?? 500) < 300;
  }

  Future<bool> updateStockFromTags({required List<String> tagIds}) async {
    final response = await _base.post(
      '/wp-json/mgws/v1/inventory/rfid/scan',
      data: {'tags': tagIds},
    );
    return (response.statusCode ?? 500) >= 200 &&
        (response.statusCode ?? 500) < 300;
  }
}
