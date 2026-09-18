import '../../auth_service.dart';

/// Query base autenticata che funziona con qualsiasi connector
/// (JWT, WooCommerce API, o WordPress Application Passwords).
///
/// Usa AuthService per ottenere il Dio autenticato corretto,
/// eliminando la dipendenza diretta da JwtConnect.
class QueryMgwsBase {
  final AuthService _auth = AuthService();

  Future<String> ensureBaseUrl() async {
    String baseUrl = _auth.currentSiteUrl ?? '';
    if (baseUrl.isEmpty) {
      await _auth.checkAuthentication();
      baseUrl = _auth.currentSiteUrl ?? '';
    }
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
    final dio = _auth.getAuthenticatedDio();
    return dio.get('$baseUrl$endpoint', queryParameters: queryParameters);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? data}) async {
    final baseUrl = await ensureBaseUrl();
    final dio = _auth.getAuthenticatedDio();
    return dio.post('$baseUrl$endpoint', data: data);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? data}) async {
    final baseUrl = await ensureBaseUrl();
    final dio = _auth.getAuthenticatedDio();
    return dio.put('$baseUrl$endpoint', data: data);
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? data}) async {
    final baseUrl = await ensureBaseUrl();
    final dio = _auth.getAuthenticatedDio();
    return dio.patch('$baseUrl$endpoint', data: data);
  }

  Future<dynamic> delete(String endpoint) async {
    final baseUrl = await ensureBaseUrl();
    final dio = _auth.getAuthenticatedDio();
    return dio.delete('$baseUrl$endpoint');
  }
}
