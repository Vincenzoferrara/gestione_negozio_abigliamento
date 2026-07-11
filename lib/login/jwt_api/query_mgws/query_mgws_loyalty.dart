import '../../../log_viewer/app_logger.dart';
import 'query_mgws_base.dart';

class QueryMgwsLoyalty {
  QueryMgwsLoyalty();

  final QueryMgwsBase _base = QueryMgwsBase();
  final AppLogger _log = AppLogger();

  Future<int> getCustomerPoints(int customerId) async {
    final response = await _base.get(
      '/wp-json/mgws/v1/loyalty/customers/$customerId',
    );
    final data = response.data as Map<String, dynamic>? ?? <String, dynamic>{};
    return int.tryParse(data['points']?.toString() ?? '0') ?? 0;
  }

  Future<bool> addPointsToCustomer({
    required int customerId,
    required int points,
    String? reference,
    String? note,
  }) async {
    final response = await _base.post(
      '/wp-json/mgws/v1/loyalty/customers/$customerId/points/add',
      data: {'points': points, 'reference': reference, 'note': note},
    );
    return (response.statusCode ?? 500) >= 200 &&
        (response.statusCode ?? 500) < 300;
  }

  Future<bool> deductPointsFromCustomer({
    required int customerId,
    required int points,
    String? reference,
    String? note,
  }) async {
    final response = await _base.post(
      '/wp-json/mgws/v1/loyalty/customers/$customerId/points/deduct',
      data: {'points': points, 'reference': reference, 'note': note},
    );
    return (response.statusCode ?? 500) >= 200 &&
        (response.statusCode ?? 500) < 300;
  }

  Future<Map<String, dynamic>?> getCustomerLoyaltyCard(int customerId) async {
    final response = await _base.get(
      '/wp-json/mgws/v1/loyalty/customers/$customerId',
    );
    if (response.data is! Map<String, dynamic>) return null;
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> findCustomerByCardNumber(
    String cardNumber,
  ) async {
    final response = await _base.get(
      '/wp-json/mgws/v1/loyalty/lookup/card/$cardNumber',
    );
    if (response.data is! Map<String, dynamic>) return null;
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> findCustomerByEmail(String email) async {
    final response = await _base.get(
      '/wp-json/mgws/v1/loyalty/lookup/email/$email',
    );
    if (response.data is! Map<String, dynamic>) return null;
    return response.data as Map<String, dynamic>;
  }

  Future<bool> createOrUpdateLoyaltyCard({
    required int customerId,
    required String cardNumber,
    String tier = 'bronze',
  }) async {
    final response = await _base.put(
      '/wp-json/mgws/v1/loyalty/customers/$customerId/card',
      data: {'card_number': cardNumber, 'tier': tier},
    );
    return (response.statusCode ?? 500) >= 200 &&
        (response.statusCode ?? 500) < 300;
  }

  Future<bool> removeLoyaltyCard(int customerId) async {
    final response = await _base.delete(
      '/wp-json/mgws/v1/loyalty/customers/$customerId/card',
    );
    return (response.statusCode ?? 500) >= 200 &&
        (response.statusCode ?? 500) < 300;
  }

  Future<List<Map<String, dynamic>>> getPointsHistory(
    int customerId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _base.get(
      '/wp-json/mgws/v1/loyalty/customers/$customerId/history',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final raw = response.data;
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> getLoyaltyStats() async {
    final response = await _base.get('/wp-json/mgws/v1/loyalty/stats');
    if (response.data is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }
    return response.data as Map<String, dynamic>;
  }

  Future<bool> isLoyaltyAvailable() async {
    try {
      final response = await _base.get('/wp-json/mgws/v1/loyalty/status');
      return response.statusCode == 200;
    } catch (e) {
      _log.w('MGWS loyalty non disponibile: $e');
      return false;
    }
  }
}
