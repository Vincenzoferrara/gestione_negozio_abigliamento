import '../../../log_viewer/app_logger.dart';
import 'mgws_availability.dart';
import 'query_mgws_base.dart';

class QueryMgwsPos {
  QueryMgwsPos();

  final QueryMgwsBase _base = QueryMgwsBase();
  final AppLogger _log = AppLogger();

  Object? checkoutOrderId(Map<String, dynamic> response) {
    return response['order_id'] ?? response['woo_order_id'];
  }

  Future<Map<String, dynamic>> checkout(Map<String, dynamic> payload) async {
    if (!mgwsAvailability.isAvailable) {
      return const <String, dynamic>{
        'success': false,
        'message': 'Backend MGWS non disponibile',
      };
    }

    final response = await _base.post(
      '/wp-json/mgws/v1/pos/checkout',
      data: payload,
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    _log.w('MGWS POS checkout ha restituito una risposta non strutturata');
    return <String, dynamic>{
      'success':
          (response.statusCode ?? 500) >= 200 &&
          (response.statusCode ?? 500) < 300,
      'status_code': response.statusCode,
    };
  }
}
