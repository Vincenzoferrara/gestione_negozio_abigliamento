import 'package:http/http.dart' as http;
import 'dart:convert';

/// Classe base per tutte le eccezioni personalizzate dell'applicazione.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// =========================================================================
// ==                 ECCEZIONI DI TRASPORTO E CONNESSIONE                ==
// =========================================================================
class ConnectionException extends AppException {
  ConnectionException(String details) : super('Errore di rete: $details');
}
class ConnectionTimeoutException extends ConnectionException {
  ConnectionTimeoutException() : super('il server non ha risposto in tempo.');
}
class InvalidCredentialsException extends AppException {
  InvalidCredentialsException(String message) : super(message, statusCode: 403);
}
class UnauthorizedException extends AppException {
  UnauthorizedException() : super('Sessione non valida o scaduta. Effettua nuovamente il login.', statusCode: 401);
}
class ForbiddenException extends AppException {
  ForbiddenException() : super('Permessi insufficienti per eseguire questa operazione.', statusCode: 403);
}
class NotFoundException extends AppException {
  NotFoundException(String resource) : super('La risorsa "$resource" non è stata trovata sul server.', statusCode: 404);
}
class ServerException extends AppException {
  ServerException() : super('Si è verificato un errore interno del server. Riprova più tardi.', statusCode: 500);
}
class InvalidResponseFormatException extends AppException {
  InvalidResponseFormatException() : super('La risposta del server non è in un formato leggibile (JSON).');
}

/// --- NUOVA CLASSE CONCRETA PER ERRORI GENERICI ---
/// Usata come fallback quando lo status code non corrisponde a nessun errore noto.
class UnhandledApiException extends AppException {
  UnhandledApiException({required int statusCode}) 
    : super('Errore API non gestito.', statusCode: statusCode);
}
// --- FINE NOVITÀ ---

// =========================================================================
// ==                 ECCEZIONI DI BUSINESS LOGIC (WOOCOMMERCE)           ==
// =========================================================================
abstract class WooCommerceException extends AppException {
  final String code;
  WooCommerceException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore WooCommerce: $message (Codice: $code)';
}
class ProductNotFoundException extends WooCommerceException {
  ProductNotFoundException() : super(code: 'product_invalid_id', message: 'Il prodotto richiesto non esiste.', statusCode: 404);
}
class SkuAlreadyExistsException extends WooCommerceException {
  SkuAlreadyExistsException() : super(code: 'product_sku_already_exists', message: 'Uno SKU deve essere unico.', statusCode: 400);
}
class GenericWooCommerceException extends WooCommerceException {
  GenericWooCommerceException({required super.code, required super.message, super.statusCode});
}

// =========================================================================
// ==                       GESTORE DEGLI ERRORI                          ==
// =========================================================================
class ErrorHandler {
  static void throwFromResponse(http.Response response) {
    final int statusCode = response.statusCode;

    // Errori di trasporto/autenticazione
    switch (statusCode) {
      case 401: throw UnauthorizedException();
      case 403: throw ForbiddenException();
      case 404: throw NotFoundException(response.request?.url.path ?? 'risorsa');
      case 500: case 502: case 503: case 504:
        throw ServerException();
    }
    
    // Errori di business logic di WooCommerce
    if (statusCode == 400) {
      try {
        final jsonBody = jsonDecode(response.body);
        final String code = jsonBody['code'] ?? '';
        final String message = jsonBody['message'] ?? 'Errore nei dati inviati.';
        switch (code) {
          case 'woocommerce_rest_product_invalid_id': throw ProductNotFoundException();
          case 'woocommerce_rest_product_sku_already_exists': throw SkuAlreadyExistsException();
          default: throw GenericWooCommerceException(code: code, message: message, statusCode: 400);
        }
      } on FormatException {
        throw InvalidResponseFormatException();
      }
    }

    // --- CORREZIONE APPLICATA QUI ---
    // Fallback per errori non previsti, ora usa la nuova classe concreta.
    throw UnhandledApiException(statusCode: statusCode);
    // --- FINE CORREZIONE ---
  }
}