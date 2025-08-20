import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import 'api_client.dart';
import 'error_list.dart';

/// Un oggetto sicuro per contenere i dati della sessione dopo un login riuscito.
/// Include la logica per la scadenza del token.
class UserSession {
  final String token;
  final DateTime expiresAt;

  UserSession({required this.token, required this.expiresAt});

  /// Controlla se il token è scaduto.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Metodi per la serializzazione da/per JSON per lo storage sicuro.
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

/// Servizio dedicato all'autenticazione e alla gestione della sessione.
/// Questo è l'UNICO file che sa come fare un login.
class AuthService {
  // Unica istanza (Singleton) per garantire un solo gestore di sessione.
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserSession? _currentSession;
  String? _currentSiteUrl;

  /// Tenta di caricare una sessione valida dallo storage sicuro all'avvio dell'app.
  Future<bool> tryLoadSessionFromStorage() async {
    final storedData = await SecureStorageService.loadSession();
    if (storedData != null) {
      final session = storedData.$1;
      final siteUrl = storedData.$2;
      if (!session.isExpired) {
        _currentSession = session;
        _currentSiteUrl = siteUrl;
        debugPrint('Sessione valida caricata dallo storage per: $siteUrl');
        return true;
      } else {
        debugPrint('Sessione trovata ma scaduta. Pulizia in corso.');
        await logout();
      }
    }
    return false;
  }

  /// Esegue il login con una logica diretta e robusta.
  Future<UserSession> login({
    required String siteUrl,
    required String username,
    required String password,
    String? customEndpoint,
  }) async {
    // Scegliamo l'endpoint da usare: quello personalizzato ha la priorità.
    final endpoint = (customEndpoint != null && customEndpoint.isNotEmpty)
        ? customEndpoint
        : 'simple-jwt-login/v1/auth';

    // Creiamo un ApiClient per questa singola operazione di login.
    // Non gli passiamo una sessione perché non ne abbiamo ancora una.
    final apiClient = ApiClient(siteUrl: siteUrl);

    debugPrint('Tentativo di login con endpoint: $endpoint');

    try {
      // Facciamo una sola chiamata mirata all'endpoint scelto.
      final response = await apiClient.post(endpoint, body: {
        'username': username,
        'password': password,
      });

      // Se la chiamata ha successo (ApiClient non ha lanciato eccezioni),
      // analizziamo la risposta per creare la sessione.
      final session = _parseSuccessResponse(response.body);
      
      // Se il parsing ha successo, salviamo tutto per il futuro.
      await SecureStorageService.saveSession(session, siteUrl);
      // Non salviamo più "l'ultimo endpoint usato" perché la logica di auto-discovery è stata rimossa.
      
      _currentSession = session;
      _currentSiteUrl = siteUrl;

      debugPrint('Login riuscito!');
      return session;

    } catch (e) {
      // Se ApiClient lancia un'eccezione (403, 404, rete, etc.),
      // la intercettiamo, la logghiamo e la rilanciamo alla UI.
      debugPrint('Login fallito: ${e.toString()}');
      rethrow;
    }
  }

  /// Analizza la risposta di successo per estrarre il token e la data di scadenza.
  UserSession _parseSuccessResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is! Map<String, dynamic>) {
        throw InvalidResponseException();
      }
      
      String? token;
      // La risposta che hai mostrato è: {"success":true,"data":{"jwt":"..."}}
      // Questa logica cerca il token in quel formato.
      if (decoded.containsKey('data') && decoded['data'] is Map) {
        final dataMap = decoded['data'] as Map<String, dynamic>;
        // Simple JWT Login a volte lo mette in 'jwt', a volte direttamente in 'token'
        if (dataMap.containsKey('jwt') && (dataMap['jwt'] is String)) {
          token = dataMap['jwt'];
        } else if (dataMap.containsKey('token')) {
          token = dataMap['token'];
        }
      }
      
      // Fallback per altri formati comuni
      if (token == null && decoded.containsKey('token')) {
        token = decoded['token'];
      }

      if (token == null || token.isEmpty) {
        debugPrint('Risposta di successo ricevuta, ma il token JWT non è stato trovato nel corpo: $responseBody');
        throw InvalidResponseException();
      }

      // Per la scadenza, usiamo un default sicuro se non specificato.
      int expiresInSeconds = 86400; // 24 ore
      if (decoded.containsKey('data') && decoded['data'] is Map) {
         final dataMap = decoded['data'] as Map<String, dynamic>;
         if (dataMap.containsKey('expires_in')) {
           expiresInSeconds = dataMap['expires_in'] ?? expiresInSeconds;
         }
      }

      return UserSession(
        token: token,
        expiresAt: DateTime.now().add(Duration(seconds: expiresInSeconds)),
      );

    } catch (e) {
      debugPrint('Errore durante il parsing della risposta di successo: $e');
      throw InvalidResponseException();
    }
  }

  /// Esegue il logout e pulisce tutti i dati salvati.
  Future<void> logout() async {
    await SecureStorageService.clearAll();
    _currentSession = null;
    _currentSiteUrl = null;
    debugPrint('Sessione e dati sicuri cancellati.');
  }

  // Getters pubblici per accedere allo stato della sessione dall'esterno.
  UserSession? get currentSession => _currentSession;
  String? get currentSiteUrl => _currentSiteUrl;
  bool get hasActiveSession => _currentSession != null && !_currentSession!.isExpired;
}