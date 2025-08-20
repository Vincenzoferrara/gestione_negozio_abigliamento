import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'jwt_connect.dart';
import 'error_list.dart';

/// Classe centralizzata per tutte le comunicazioni API.
class ApiClient {
  final String _siteUrl;
  final UserSession? _session;

  ApiClient({required String siteUrl, UserSession? session})
      : _siteUrl = siteUrl,
        _session = session;

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) {
    return _makeRequest('POST', endpoint, body: body);
  }

  Future<http.Response> get(String endpoint) {
    return _makeRequest('GET', endpoint);
  }

  Future<http.Response> _makeRequest(String method, String endpoint, {Map<String, dynamic>? body}) async {
    final cleanUrl = _siteUrl.endsWith('/') ? _siteUrl.substring(0, _siteUrl.length - 1) : _siteUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final requestUrl = Uri.parse('$cleanUrl/?rest_route=/$cleanEndpoint');
    
    debugPrint('API Request -> $method $requestUrl');
    
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'User-Agent': 'GestioneNegozio/1.0',
    };
    if (_session != null) {
      if (_session!.isExpired) throw UnauthorizedException();
      headers['Authorization'] = 'Bearer ${_session!.token}';
    }

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(requestUrl, headers: headers).timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          response = await http.post(requestUrl, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
          break;
        default:
          throw Exception('Metodo HTTP non supportato: $method');
      }
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutException();
    } on http.ClientException {
      throw NetworkException();
    }
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    
    Map<String, dynamic>? errorBody;
    try {
      errorBody = jsonDecode(response.body);
    } catch(e) {/* ignore */}
    
    final serverMessage = errorBody?['data']?['message'] ?? errorBody?['message'] ?? 'Nessun dettaglio.';

    switch (response.statusCode) {
      case 401: throw UnauthorizedException();
      case 403: throw ForbiddenException();
      case 404: throw NotFoundException(response.request?.url.path ?? 'endpoint');
      case 500: case 502: case 503: case 504:
        throw ServerException();
      default:
        throw ApiException(serverMessage, statusCode: response.statusCode);
    }
  }
}