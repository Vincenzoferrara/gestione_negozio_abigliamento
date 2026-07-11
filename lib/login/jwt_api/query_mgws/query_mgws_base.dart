import '../jwt_connect.dart';

class QueryMgwsBase {
  Future<String> ensureBaseUrl() async {
    final jwtConnect = JwtConnect();
    String baseUrl = jwtConnect.currentSiteUrl ?? '';
    if (baseUrl.isEmpty) {
      await jwtConnect.tryAutoConnect();
      baseUrl = jwtConnect.currentSiteUrl ?? '';
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
    final jwtConnect = JwtConnect();
    final baseUrl = await ensureBaseUrl();
    final dio = jwtConnect.getAuthenticatedDio();
    return dio.get('$baseUrl$endpoint', queryParameters: queryParameters);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? data}) async {
    final jwtConnect = JwtConnect();
    final baseUrl = await ensureBaseUrl();
    final dio = jwtConnect.getAuthenticatedDio();
    return dio.post('$baseUrl$endpoint', data: data);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? data}) async {
    final jwtConnect = JwtConnect();
    final baseUrl = await ensureBaseUrl();
    final dio = jwtConnect.getAuthenticatedDio();
    return dio.put('$baseUrl$endpoint', data: data);
  }

  Future<dynamic> delete(String endpoint) async {
    final jwtConnect = JwtConnect();
    final baseUrl = await ensureBaseUrl();
    final dio = jwtConnect.getAuthenticatedDio();
    return dio.delete('$baseUrl$endpoint');
  }
}
