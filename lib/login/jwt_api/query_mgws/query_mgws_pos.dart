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

  /// Apre uno shift (turno cassa) lato server MGWS. Il server è autorevole:
  /// se non conferma l'apertura (es. 409 già aperto, backend giù) l'app nega
  /// il turno locale. La shift_key coincide con `turno.id` e viene riferita
  /// come `shift_id` (root) in ogni checkout per l'enforcement di apertura.
  Future<Map<String, dynamic>> openShift(Map<String, dynamic> payload) async {
    if (!mgwsAvailability.isAvailable) {
      return const <String, dynamic>{
        'success': false,
        'message': 'Backend MGWS non disponibile',
      };
    }

    final response = await _base.post(
      '/wp-json/mgws/v1/pos/shifts',
      data: payload,
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    _log.w('MGWS POS openShift ha restituito una risposta non strutturata');
    return <String, dynamic>{
      'success':
          (response.statusCode ?? 500) >= 200 &&
          (response.statusCode ?? 500) < 300,
      'status_code': response.statusCode,
    };
  }

  /// Chiude uno shift lato server: l'app manda SOLO i conteggi «contato»;
  /// il plugin calcola expected_totals dagli ordini (`_mgws_shift_id`,
  /// HPOS-safe) e restituisce le differenze. Errore server → niente chiusura
  /// locale.
  Future<Map<String, dynamic>> closeShift(
    String shiftIdent,
    Map<String, dynamic> payload,
  ) async {
    if (!mgwsAvailability.isAvailable) {
      return const <String, dynamic>{
        'success': false,
        'message': 'Backend MGWS non disponibile',
      };
    }

    final response = await _base.post(
      '/wp-json/mgws/v1/pos/shifts/$shiftIdent/close',
      data: payload,
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    _log.w('MGWS POS closeShift ha restituito una risposta non strutturata');
    return <String, dynamic>{
      'success':
          (response.statusCode ?? 500) >= 200 &&
          (response.statusCode ?? 500) < 300,
      'status_code': response.statusCode,
    };
  }
}
