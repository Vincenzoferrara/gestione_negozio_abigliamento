import 'package:dio/dio.dart';

import '../woo_connect.dart';

/// Query base autenticata per le rotte MGWS.
///
/// Il trasporto viene da `WooConnect`, che e' l'unico owner dei connettori:
/// base URL e credenziali arrivano dal connettore realmente in uso (JWT,
/// WordPress Basic Auth o Consumer Key/Secret). Non esiste un connettore
/// secondario ne un fallback: se non c'e' sessione, la richiesta non parte e
/// l'errore resta in chiaro.
class QueryMgwsBase {
  final WooConnect _woo = WooConnect();

  /// Lettura del contratto di stato di un servizio MGWS.
  ///
  /// Le rotte `inventory/status` e `loyalty/status` rispondono 200 anche quando
  /// il servizio e' spento, per esempio con le tabelle MGWS non installate: in
  /// quel caso `enabled` e `ok` valgono `false`. Guardare solo lo status HTTP
  /// dichiarerebbe MGWS disponibile e ogni chiamata reale fallirebbe sul campo,
  /// quindi la disponibilita' si legge dal corpo della risposta.
  static bool isServiceUsable(Response<dynamic> response) {
    if (response.statusCode != 200) return false;
    final data = response.data;
    if (data is! Map) return true;
    final enabled = data['enabled'];
    if (enabled is bool) return enabled;
    final ok = data['ok'];
    if (ok is bool) return ok;
    return true;
  }

  Future<String> ensureBaseUrl() async {
    final baseUrl = _woo.siteUrl ?? '';
    if (baseUrl.isEmpty) {
      throw Exception('Nessun sito connesso');
    }
    return baseUrl;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final baseUrl = await ensureBaseUrl();
    final dio = _woo.getAuthenticatedDio();
    return dio.get('$baseUrl$endpoint', queryParameters: queryParameters);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? data}) async {
    final baseUrl = await ensureBaseUrl();
    final dio = _woo.getAuthenticatedDio();
    return dio.post('$baseUrl$endpoint', data: data);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? data}) async {
    final baseUrl = await ensureBaseUrl();
    final dio = _woo.getAuthenticatedDio();
    return dio.put('$baseUrl$endpoint', data: data);
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? data}) async {
    final baseUrl = await ensureBaseUrl();
    final dio = _woo.getAuthenticatedDio();
    return dio.patch('$baseUrl$endpoint', data: data);
  }

  Future<dynamic> delete(String endpoint) async {
    final baseUrl = await ensureBaseUrl();
    final dio = _woo.getAuthenticatedDio();
    return dio.delete('$baseUrl$endpoint');
  }
}
