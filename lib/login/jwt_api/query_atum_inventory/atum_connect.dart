// ATUM Connect - Connessione ATUM con autenticazione JWT
//
// Estende JwtConnect per aggiungere endpoint specifici ATUM
// Mantiene la stessa autenticazione JWT usata per WooCommerce

import 'dart:async';

import 'package:dio/dio.dart';
import '../jwt_connect.dart';
import '../../../log_viewer/app_logger.dart';

/// Configurazione ATUM
class AtumConfig {
  final String baseUrl;
  final String? apiVersion;

  AtumConfig({
    required this.baseUrl,
    this.apiVersion = 'v1',
  });

  /// Endpoint base per API ATUM
  String get atumApiBase => '/wp-json/atum/$apiVersion';
}

/// Eccezioni specifiche ATUM
class AtumException implements Exception {
  final String message;
  final int? statusCode;
  
  AtumException(this.message, {this.statusCode});
  
  @override
  String toString() => 'AtumException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Servizio di connessione ATUM che usa JwtConnect
class AtumConnect {
  // Singleton
  static final AtumConnect _instance = AtumConnect._internal();
  factory AtumConnect() => _instance;
  AtumConnect._internal();

  final JwtConnect _jwtConnect = JwtConnect();

  AtumConfig? _atumConfig;
  Dio? _atumDio;



  /// Configura la connessione ATUM
  void configureAtum(String siteUrl) {
    _atumConfig = AtumConfig(baseUrl: siteUrl);
    log.d('ATUM configured for: $siteUrl');
  }

  /// Getter per verificare se ATUM è configurato
  bool get isAtumConfigured => _atumConfig != null;

  /// Getter per verificare se JWT è connesso
  bool get isConnected => _jwtConnect.isConnected;

  /// Getter per l'istanza Dio configurata per ATUM
  Dio get atumDio {
    if (!_jwtConnect.isConnected) {
      throw AtumException('JWT non autenticato. Effettuare prima il login.');
    }

    if (_atumDio == null) {
      final cleanBaseUrl = _atumConfig!.baseUrl.endsWith('/') 
          ? _atumConfig!.baseUrl.substring(0, _atumConfig!.baseUrl.length - 1)
          : _atumConfig!.baseUrl;

      _atumDio = Dio(BaseOptions(
        baseUrl: '$cleanBaseUrl${_atumConfig!.atumApiBase}',
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-ATUM-Version': _atumConfig!.apiVersion,
        },
      ));

      // Interceptor per aggiungere headers ATUM specifici
      _atumDio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Aggiungi headers ATUM a tutte le richieste
            if (_jwtConnect.session != null) {
              options.headers['Authorization'] = 'Bearer ${_jwtConnect.session!.token}';
              options.headers['X-ATUM-Source'] = 'flutter-app';
            }
            return handler.next(options);
          },
          onResponse: (response, handler) {
            log.d('ATUM Response ${response.statusCode} from ${response.requestOptions.uri}');
            return handler.next(response);
          },
          onError: (error, handler) async {
            log.e('ATUM Error ${error.response?.statusCode} on ${error.requestOptions.uri}');
            
            // Gestione errori specifici ATUM
            if (error.response?.statusCode == 404) {
              // Endpoint ATUM non trovato
              return handler.next(error);
            } else if (error.response?.statusCode == 403) {
              // Permessi ATUM insufficienti
              throw AtumException('Permessi ATUM insufficienti', statusCode: 403);
            } else if (error.response?.statusCode == 422) {
              // Errori di validazione ATUM
              final responseData = error.response?.data;
              if (responseData is Map && responseData.containsKey('message')) {
                throw AtumException(responseData['message'], statusCode: 422);
              }
            }
            
            return handler.next(error);
          },
        ),
      );

      log.d('ATUM Dio initialized with baseUrl: $cleanBaseUrl${_atumConfig!.atumApiBase}');
    }

    return _atumDio!;
  }

  /// Esegue una richiesta autenticata alle API ATUM
  Future<Map<String, dynamic>> atumRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? queryParams,
  }) async {
    if (!isAtumConfigured) {
      throw AtumException('ATUM non configurato. Usare configureAtum() prima.');
    }

    try {
      final dio = atumDio;
      
      late Response<Map<String, dynamic>> response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await dio.get(
            endpoint,
            queryParameters: queryParams,
          );
          break;
        case 'POST':
          response = await dio.post(
            endpoint,
            data: data,
            queryParameters: queryParams,
          );
          break;
        case 'PUT':
          response = await dio.put(
            endpoint,
            data: data,
            queryParameters: queryParams,
          );
          break;
        case 'DELETE':
          response = await dio.delete(
            endpoint,
            queryParameters: queryParams,
          );
          break;
        default:
          throw AtumException('Metodo HTTP non supportato: $method');
      }

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data ?? {};
      } else {
        throw AtumException(
          'Errore richiesta ATUM: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw AtumException(
        'Errore di rete ATUM: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AtumException('Errore generico ATUM: $e');
    }
  }

  /// Verifica se le API ATUM sono disponibili
  Future<bool> isAtumAvailable() async {
    try {
      if (!isAtumConfigured) return false;
      
      final response = await atumRequest('GET', '/health');
      return response['status'] == 'ok';
    } catch (e) {
      log.w('ATUM non disponibile: $e');
      return false;
    }
  }

  /// Ottiene la versione delle API ATUM
  Future<String?> getAtumVersion() async {
    try {
      final response = await atumRequest('GET', '/version');
      return response['version'];
    } catch (e) {
      log.w('Impossibile ottenere versione ATUM: $e');
      return null;
    }
  }

  /// Resetta la connessione ATUM (mantenendo JWT)
  void resetAtumConnection() {
    _atumDio = null;
    _atumConfig = null;
    log.d('ATUM connection reset');
  }

  /// Logout completo
  Future<void> disconnect() async {
    resetAtumConnection();
    await _jwtConnect.disconnect();
  }
}