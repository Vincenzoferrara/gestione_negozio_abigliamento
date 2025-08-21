import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'secure_storage_service.dart';
import 'error_list.dart';

/// Un oggetto di sessione che contiene i dati necessari dopo un login riuscito.
class UserSession {
  final String token;
  final DateTime expiresAt;

  UserSession({required this.token, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token'],
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'expires_at': expiresAt.millisecondsSinceEpoch};
  }
}

/// Servizio centralizzato per l'autenticazione e la gestione della sessione JWT.
class JwtConnect {
  // Pattern Singleton per garantire una sola istanza del servizio nell'app.
  static final JwtConnect _instance = JwtConnect._internal();
  factory JwtConnect() => _instance;
  JwtConnect._internal();

  UserSession? _currentSession;
  String? _currentSiteUrl;

  // --- GETTERS PUBBLICI PER LO STATO ---
  bool get isConnected => _currentSession != null && !_currentSession!.isExpired;
  String? get currentSiteUrl => _currentSiteUrl;
  UserSession? get session => isConnected ? _currentSession : null;

  /// Tenta di caricare una sessione salvata dallo storage sicuro all'avvio dell'app.
  Future<bool> tryAutoConnect() async {
    final storedData = await SecureStorageService.loadSession();
    if (storedData != null) {
      final session = storedData.$1;
      final siteUrl = storedData.$2;
      if (!session.isExpired) {
        _currentSession = session;
        _currentSiteUrl = siteUrl;
        return true;
      } else {
        await disconnect(); // Pulisce i dati se la sessione è scaduta.
      }
    }
    return false;
  }

  /// Esegue il processo di login.
  Future<UserSession> connect({
    required String siteUrl,
    required String username,
    required String password,
    String? customEndpoint,
  }) async {
    // 1. Determina gli endpoint da provare, dando priorità a quelli personalizzati/precedenti.
    final endpointsToTry = await _getEndpointsToTry(customEndpoint);
    String? lastKnownError;

    // 2. Prova ogni endpoint in sequenza.
    for (final endpoint in endpointsToTry) {
      try {
        final uri = buildUri(siteUrl, endpoint);
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({'username': username, 'password': password}),
        ).timeout(const Duration(seconds: 20));

        // Se la richiesta ha successo, analizza la risposta.
        if (response.statusCode == 200) {
          final session = _parseSuccessResponse(response.body);
          await SecureStorageService.saveSession(session, siteUrl);
          await SecureStorageService.saveLastUsedEndpoint(endpoint);
          _currentSession = session;
          _currentSiteUrl = siteUrl;
          return session;
        } 
        // Se l'errore è credenziali/permessi, interrompi subito.
        else if (response.statusCode == 403) {
            final body = jsonDecode(response.body);
            lastKnownError = body['message'] ?? 'Credenziali non valide o permessi insufficienti.';
            break; 
        }

      } on SocketException { throw ConnectionException('di rete');
      } on TimeoutException { throw ConnectionTimeoutException();
      } catch (e) {
        // Ignora gli errori 404 (NotFound) e continua con il prossimo endpoint.
        if (e is! NotFoundException) {
          lastKnownError = e.toString();
        }
      }
    }
    // 3. Se nessun endpoint ha funzionato, lancia un errore.
    throw InvalidCredentialsException(lastKnownError ?? 'Nessun endpoint JWT funzionante trovato.');
  }

  /// Esegue una richiesta HTTP autenticata per conto di altri servizi.
  Future<http.Response> authenticatedRequest(String method, Uri uri, {Map<String, dynamic>? body}) async {
    if (!isConnected) throw UnauthorizedException();

    final headers = {
      'Authorization': 'Bearer ${_currentSession!.token}',
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    
    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET': response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20)); break;
        case 'POST': response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20)); break;
        case 'PUT': response = await http.put(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20)); break;
        case 'DELETE': response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 20)); break;
        default: throw Exception('Metodo HTTP non supportato');
      }
      // Delega la gestione degli errori di risposta a un gestore centralizzato.
      if (response.statusCode >= 400) ErrorHandler.throwFromResponse(response);
      return response;
    } on SocketException {
      throw ConnectionException('di rete');
    } on TimeoutException {
      throw ConnectionTimeoutException();
    }
  }

  /// Costruisce un Uri sicuro, centralizzando la logica di formattazione.
  Uri buildUri(String siteUrl, String endpoint, {Map<String, String>? queryParams}) {
    final cleanUrl = siteUrl.endsWith('/') ? siteUrl.substring(0, siteUrl.length - 1) : siteUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final routeWithParams = Uri(path: cleanEndpoint, queryParameters: queryParams).toString();
    return Uri.parse('$cleanUrl/?rest_route=/$routeWithParams');
  }

  /// Esegue il logout e pulisce tutti i dati di sessione.
  Future<void> disconnect() async {
    await SecureStorageService.clearAll();
    _currentSession = null;
    _currentSiteUrl = null;
  }
  
  // --- Metodi Helper Privati ---

  Future<List<String>> _getEndpointsToTry(String? customEndpoint) async {
    const commonEndpoints = ['simple-jwt-login/v1/auth', 'jwt-auth/v1/token'];
    final lastUsedEndpoint = await SecureStorageService.getLastUsedEndpoint();
    // La logica toSet().toList() rimuove eventuali duplicati.
    return [
      if (customEndpoint != null && customEndpoint.isNotEmpty) customEndpoint,
      if (lastUsedEndpoint != null) lastUsedEndpoint,
      ...commonEndpoints
    ].toSet().toList();
  }

  UserSession _parseSuccessResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) throw InvalidResponseFormatException();
      
      final tokenData = decoded['data'];
      final String? token = tokenData?['jwt'] ?? tokenData?['token'];
      if (token == null) throw InvalidResponseFormatException();
      
      final int expiresIn = tokenData?['expires_in'] ?? 86400; // Default a 24 ore
      return UserSession(token: token, expiresAt: DateTime.now().add(Duration(seconds: expiresIn)));
    } catch (_) {
      throw InvalidResponseFormatException();
    }
  }
}