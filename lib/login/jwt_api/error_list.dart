/// error_list.dart
/// 
/// Gestione centralizzata delle eccezioni per l'applicazione WooCommerce
/// Contiene tutte le eccezioni personalizzate per:
/// - Errori di connessione e trasporto
/// - Errori specifici di WooCommerce (prodotti, ordini, etc.)
/// - Errori di business logic per ogni servizio
/// - Gestione e parsing degli errori HTTP

import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
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

/// Classe concreta per errori generici non gestiti
class UnhandledApiException extends AppException {
  UnhandledApiException({required int statusCode}) 
    : super('Errore API non gestito.', statusCode: statusCode);
}

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

// === ERRORI PRODOTTI ===
class ProductNotFoundException extends WooCommerceException {
  ProductNotFoundException() : super(code: 'product_invalid_id', message: 'Il prodotto richiesto non esiste.', statusCode: 404);
}

class SkuAlreadyExistsException extends WooCommerceException {
  SkuAlreadyExistsException() : super(code: 'product_sku_already_exists', message: 'Uno SKU deve essere unico.', statusCode: 400);
}

class GenericWooCommerceException extends WooCommerceException {
  GenericWooCommerceException({required super.code, required super.message, super.statusCode});
}

// === ERRORI CATEGORIE ===
abstract class CategoryException extends AppException {
  final String code;
  CategoryException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Categoria: $message (Codice: $code)';
}

class CategoryNotFoundException extends CategoryException {
  CategoryNotFoundException() : super(code: 'category_invalid_id', message: 'La categoria richiesta non esiste.', statusCode: 404);
}

class GenericCategoryException extends CategoryException {
  GenericCategoryException({required super.code, required super.message, super.statusCode});
}

// === ERRORI TAG ===
abstract class TagException extends AppException {
  final String code;
  TagException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Tag: $message (Codice: $code)';
}

class TagNotFoundException extends TagException {
  TagNotFoundException() : super(code: 'tag_invalid_id', message: 'Il tag richiesto non esiste.', statusCode: 404);
}

class TagNameAlreadyExistsException extends TagException {
  TagNameAlreadyExistsException() : super(code: 'tag_name_exists', message: 'Un tag con questo nome esiste già.', statusCode: 400);
}

class TagSlugAlreadyExistsException extends TagException {
  TagSlugAlreadyExistsException() : super(code: 'tag_slug_exists', message: 'Un tag con questo slug esiste già.', statusCode: 400);
}

class GenericTagException extends TagException {
  GenericTagException({required super.code, required super.message, super.statusCode});
}

// === ERRORI ATTRIBUTI ===
abstract class AttributeException extends AppException {
  final String code;
  AttributeException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Attributo: $message (Codice: $code)';
}

class AttributeNotFoundException extends AttributeException {
  AttributeNotFoundException() : super(code: 'attribute_invalid_id', message: 'L\'attributo richiesto non esiste.', statusCode: 404);
}

class AttributeSlugAlreadyExistsException extends AttributeException {
  AttributeSlugAlreadyExistsException() : super(code: 'attribute_slug_exists', message: 'Un attributo con questo slug esiste già.', statusCode: 400);
}

class AttributeTermNotFoundException extends AttributeException {
  AttributeTermNotFoundException() : super(code: 'attribute_term_invalid_id', message: 'Il termine dell\'attributo richiesto non esiste.', statusCode: 404);
}

class GenericAttributeException extends AttributeException {
  GenericAttributeException({required super.code, required super.message, super.statusCode});
}

// === ERRORI VARIANTI ===
abstract class VariationException extends AppException {
  final String code;
  VariationException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Variante: $message (Codice: $code)';
}

class VariationNotFoundException extends VariationException {
  VariationNotFoundException() : super(code: 'variation_invalid_id', message: 'La variante richiesta non esiste.', statusCode: 404);
}

class VariationAttributesRequiredException extends VariationException {
  VariationAttributesRequiredException() : super(code: 'variation_attributes_required', message: 'Gli attributi sono obbligatori per le varianti.', statusCode: 400);
}

class VariationSkuAlreadyExistsException extends VariationException {
  VariationSkuAlreadyExistsException() : super(code: 'variation_sku_exists', message: 'Una variante con questo SKU esiste già.', statusCode: 400);
}

class GenericVariationException extends VariationException {
  GenericVariationException({required super.code, required super.message, super.statusCode});
}

// === ERRORI MEDIA ===
abstract class MediaException extends AppException {
  final String code;
  MediaException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Media: $message (Codice: $code)';
}

class MediaNotFoundException extends MediaException {
  MediaNotFoundException() : super(code: 'media_invalid_id', message: 'Il media richiesto non esiste.', statusCode: 404);
}

class MediaUploadException extends MediaException {
  MediaUploadException(String details) : super(code: 'media_upload_failed', message: 'Errore durante l\'upload: $details', statusCode: 400);
}

class InvalidMediaTypeException extends MediaException {
  InvalidMediaTypeException(String mimeType) : super(code: 'invalid_media_type', message: 'Tipo di file non supportato: $mimeType', statusCode: 400);
}

class MediaFileTooLargeException extends MediaException {
  MediaFileTooLargeException() : super(code: 'media_file_too_large', message: 'Il file è troppo grande per essere caricato.', statusCode: 413);
}

class GenericMediaException extends MediaException {
  GenericMediaException({required super.code, required super.message, super.statusCode});
}

// === ERRORI ORDINI ===
abstract class OrderException extends AppException {
  final String code;
  OrderException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Ordine: $message (Codice: $code)';
}

class OrderNotFoundException extends OrderException {
  OrderNotFoundException() : super(code: 'order_invalid_id', message: 'L\'ordine richiesto non esiste.', statusCode: 404);
}

class InvalidOrderStatusException extends OrderException {
  InvalidOrderStatusException() : super(code: 'invalid_order_status', message: 'Lo stato dell\'ordine specificato non è valido.', statusCode: 400);
}

class OrderAlreadyPaidException extends OrderException {
  OrderAlreadyPaidException() : super(code: 'order_already_paid', message: 'L\'ordine è già stato pagato.', statusCode: 400);
}

class OrderCannotBeModifiedException extends OrderException {
  OrderCannotBeModifiedException() : super(code: 'order_cannot_be_modified', message: 'L\'ordine non può essere modificato nel suo stato attuale.', statusCode: 400);
}

class GenericOrderException extends OrderException {
  GenericOrderException({required super.code, required super.message, super.statusCode});
}

// =========================================================================
// ==                     ECCEZIONI SPECIFICHE REPORT                     ==
// =========================================================================

abstract class ReportException extends AppException {
  final String code;
  ReportException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Report: $message (Codice: $code)';
}

class GenericReportException extends ReportException {
  GenericReportException({required super.code, required super.message, super.statusCode});
}

// =========================================================================
// ==                     ECCEZIONI SPECIFICHE COUPON                     ==
// =========================================================================

abstract class CouponException extends AppException {
  final String code;
  CouponException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Coupon: $message (Codice: $code)';
}

class CouponNotFoundException extends CouponException {
  CouponNotFoundException() : super(code: 'coupon_invalid_code', message: 'Il coupon richiesto non esiste.', statusCode: 404);
}

class CouponCodeAlreadyExistsException extends CouponException {
  CouponCodeAlreadyExistsException() : super(code: 'coupon_code_exists', message: 'Il codice coupon esiste già.', statusCode: 400);
}

class CouponExpiredException extends CouponException {
  CouponExpiredException() : super(code: 'coupon_expired', message: 'Il coupon è scaduto.', statusCode: 400);
}

class CouponUsageLimitException extends CouponException {
  CouponUsageLimitException() : super(code: 'coupon_usage_limit', message: 'Il coupon ha raggiunto il limite di utilizzi.', statusCode: 400);
}

class GenericCouponException extends CouponException {
  GenericCouponException({required super.code, required super.message, super.statusCode});
}

// =========================================================================
// ==                     ECCEZIONI SPECIFICHE TASSE                      ==
// =========================================================================

abstract class TaxException extends AppException {
  final String code;
  TaxException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Tasse: $message (Codice: $code)';
}

class TaxClassNotFoundException extends TaxException {
  TaxClassNotFoundException() : super(code: 'tax_class_invalid', message: 'La classe di tasse richiesta non esiste.', statusCode: 404);
}

class TaxRateNotFoundException extends TaxException {
  TaxRateNotFoundException() : super(code: 'tax_rate_invalid', message: 'L\'aliquota fiscale richiesta non esiste.', statusCode: 404);
}

class InvalidTaxLocationException extends TaxException {
  InvalidTaxLocationException() : super(code: 'invalid_tax_location', message: 'La zona fiscale specificata non è valida.', statusCode: 400);
}

class GenericTaxException extends TaxException {
  GenericTaxException({required super.code, required super.message, super.statusCode});
}

// =========================================================================
// ==                     ECCEZIONI SPECIFICHE CLIENTI                    ==
// =========================================================================

abstract class CustomerException extends AppException {
  final String code;
  CustomerException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Cliente: $message (Codice: $code)';
}

class CustomerNotFoundException extends CustomerException {
  CustomerNotFoundException() : super(code: 'customer_invalid_id', message: 'Il cliente richiesto non esiste.', statusCode: 404);
}

class InvalidCustomerEmailException extends CustomerException {
  InvalidCustomerEmailException() : super(code: 'invalid_email', message: 'L\'indirizzo email non è valido.', statusCode: 400);
}

class CustomerEmailAlreadyExistsException extends CustomerException {
  CustomerEmailAlreadyExistsException() : super(code: 'email_exists', message: 'L\'indirizzo email è già in uso.', statusCode: 400);
}

class InvalidCustomerUsernameException extends CustomerException {
  InvalidCustomerUsernameException() : super(code: 'invalid_username', message: 'Il nome utente non è valido.', statusCode: 400);
}

class CustomerUsernameAlreadyExistsException extends CustomerException {
  CustomerUsernameAlreadyExistsException() : super(code: 'username_exists', message: 'Il nome utente è già in uso.', statusCode: 400);
}

class GenericCustomerException extends CustomerException {
  GenericCustomerException({required super.code, required super.message, super.statusCode});
}

// =========================================================================
// ==                     ECCEZIONI SPECIFICHE SPEDIZIONI                 ==
// =========================================================================

abstract class ShippingException extends AppException {
  final String code;
  ShippingException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Spedizione: $message (Codice: $code)';
}

class ShippingZoneNotFoundException extends ShippingException {
  ShippingZoneNotFoundException() : super(code: 'shipping_zone_invalid', message: 'La zona di spedizione richiesta non esiste.', statusCode: 404);
}

class ShippingMethodNotFoundException extends ShippingException {
  ShippingMethodNotFoundException() : super(code: 'shipping_method_invalid', message: 'Il metodo di spedizione richiesto non esiste.', statusCode: 404);
}

class ShippingClassNotFoundException extends ShippingException {
  ShippingClassNotFoundException() : super(code: 'shipping_class_invalid', message: 'La classe di spedizione richiesta non esiste.', statusCode: 404);
}

class InvalidShippingLocationException extends ShippingException {
  InvalidShippingLocationException() : super(code: 'invalid_shipping_location', message: 'La zona di spedizione specificata non è valida.', statusCode: 400);
}

class GenericShippingException extends ShippingException {
  GenericShippingException({required super.code, required super.message, super.statusCode});
}

// =========================================================================
// ==                     ECCEZIONI SPECIFICHE BATCH                      ==
// =========================================================================

abstract class BatchException extends AppException {
  final String code;
  BatchException({required this.code, required String message, int? statusCode}) 
    : super(message, statusCode: statusCode);
  @override
  String toString() => 'Errore Operazione Batch: $message (Codice: $code)';
}

class InvalidBatchDataException extends BatchException {
  InvalidBatchDataException([String? details]) : super(
    code: 'invalid_batch_data', 
    message: details != null ? 'I dati per l\'operazione batch non sono validi: $details' : 'I dati per l\'operazione batch non sono validi.', 
    statusCode: 400
  );
}

class BatchLimitExceededException extends BatchException {
  BatchLimitExceededException() : super(code: 'batch_limit_exceeded', message: 'È stato superato il limite massimo per le operazioni batch.', statusCode: 400);
}

class BatchOperationFailedException extends BatchException {
  BatchOperationFailedException([String? details]) : super(
    code: 'batch_operation_failed', 
    message: details != null ? 'L\'operazione batch è fallita: $details' : 'L\'operazione batch è fallita.', 
    statusCode: 500
  );
}

class GenericBatchException extends BatchException {
  GenericBatchException({required super.code, required super.message, super.statusCode});
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
        
        // Mappa errori specifici alle eccezioni tipizzate
        switch (code) {
          // === ERRORI PRODOTTI ===
          case 'woocommerce_rest_product_invalid_id': throw ProductNotFoundException();
          case 'woocommerce_rest_product_sku_already_exists': throw SkuAlreadyExistsException();
            
          // === ERRORI CATEGORIE ===
          case 'woocommerce_rest_product_category_invalid_id': throw CategoryNotFoundException();
            
          // === ERRORI TAG ===
          case 'woocommerce_rest_product_tag_invalid_id': throw TagNotFoundException();
            
          // === ERRORI ATTRIBUTI ===
          case 'woocommerce_rest_product_attribute_invalid_id': throw AttributeNotFoundException();
          case 'woocommerce_rest_product_attribute_term_invalid_id': throw AttributeTermNotFoundException();
            
          // === ERRORI VARIANTI ===
          case 'woocommerce_rest_product_variation_invalid_id': throw VariationNotFoundException();
            
          // === ERRORI MEDIA ===
          case 'woocommerce_rest_attachment_invalid_id': throw MediaNotFoundException();
            
          // === ERRORI ORDINI ===
          case 'woocommerce_rest_shop_order_invalid_id': throw OrderNotFoundException();
          case 'woocommerce_rest_invalid_order_status': throw InvalidOrderStatusException();
            
          // === ERRORI CLIENTI ===
          case 'woocommerce_rest_customer_invalid_id': throw CustomerNotFoundException();
          case 'woocommerce_rest_customer_invalid_email': throw InvalidCustomerEmailException();
          case 'registration-error-email-exists': throw CustomerEmailAlreadyExistsException();
          case 'registration-error-username-exists': throw CustomerUsernameAlreadyExistsException();
          case 'woocommerce_rest_invalid_username': throw InvalidCustomerUsernameException();
            
          // === ERRORI COUPON ===
          case 'woocommerce_rest_shop_coupon_invalid_id': throw CouponNotFoundException();
          case 'woocommerce_rest_coupon_code_already_exists': throw CouponCodeAlreadyExistsException();
          case 'woocommerce_rest_coupon_expired': throw CouponExpiredException();
          case 'woocommerce_rest_coupon_usage_limit_reached': throw CouponUsageLimitException();
            
          // === ERRORI TASSE ===
          case 'woocommerce_rest_tax_class_invalid': throw TaxClassNotFoundException();
          case 'woocommerce_rest_tax_rate_invalid_id': throw TaxRateNotFoundException();
          case 'woocommerce_rest_invalid_tax_location': throw InvalidTaxLocationException();
            
          // === ERRORI SPEDIZIONI ===
          case 'woocommerce_rest_shipping_zone_invalid_id': throw ShippingZoneNotFoundException();
          case 'woocommerce_rest_shipping_zone_method_invalid_id': throw ShippingMethodNotFoundException();
          case 'woocommerce_rest_shipping_class_invalid_id': throw ShippingClassNotFoundException();
          case 'woocommerce_rest_invalid_shipping_location': throw InvalidShippingLocationException();
            
          // === ERRORI BATCH ===
          case 'woocommerce_rest_invalid_batch_data': throw InvalidBatchDataException();
          case 'woocommerce_rest_batch_limit_exceeded': throw BatchLimitExceededException();
          case 'woocommerce_rest_batch_operation_failed': throw BatchOperationFailedException();
            
          // === ERRORI GENERICI ===
          default:
            // Determina il tipo di eccezione generica in base al contesto
            if (code.startsWith('woocommerce_rest_product')) {
              throw GenericWooCommerceException(code: code, message: message, statusCode: statusCode);
            } else if (code.contains('coupon')) {
              throw GenericCouponException(code: code, message: message, statusCode: statusCode);
            } else if (code.contains('customer')) {
              throw GenericCustomerException(code: code, message: message, statusCode: statusCode);
            } else if (code.contains('tax')) {
              throw GenericTaxException(code: code, message: message, statusCode: statusCode);
            } else if (code.contains('shipping')) {
              throw GenericShippingException(code: code, message: message, statusCode: statusCode);
            } else if (code.contains('batch')) {
              throw GenericBatchException(code: code, message: message, statusCode: statusCode);
            } else {
              // Fallback per errori completamente sconosciuti
              throw GenericWooCommerceException(code: code, message: message, statusCode: statusCode);
            }
        }
      } on FormatException {
        throw InvalidResponseFormatException();
      }
    }

    // Fallback per errori non previsti
    throw UnhandledApiException(statusCode: statusCode);
  }

  /// Gestisce gli errori da DioException
  static Never throwFromDioException(DioException e) {
    if (e.response != null) {
      final response = e.response!;
      final statusCode = response.statusCode ?? 0;

      // Errori di trasporto/autenticazione
      switch (statusCode) {
        case 401: throw UnauthorizedException();
        case 403: throw ForbiddenException();
        case 404: throw NotFoundException(e.requestOptions.path);
        case 500: case 502: case 503: case 504:
          throw ServerException();
      }

      // Errori di business logic di WooCommerce
      if (statusCode == 400 && response.data != null) {
        try {
          final jsonBody = response.data is Map ? response.data : jsonDecode(response.data.toString());
          final String code = jsonBody['code'] ?? '';
          final String message = jsonBody['message'] ?? 'Errore nei dati inviati.';

          // Mappa errori specifici alle eccezioni tipizzate
          switch (code) {
            // === ERRORI PRODOTTI ===
            case 'woocommerce_rest_product_invalid_id': throw ProductNotFoundException();
            case 'woocommerce_rest_product_sku_already_exists': throw SkuAlreadyExistsException();

            // === ERRORI CATEGORIE ===
            case 'woocommerce_rest_product_category_invalid_id': throw CategoryNotFoundException();

            // === ERRORI TAG ===
            case 'woocommerce_rest_product_tag_invalid_id': throw TagNotFoundException();

            // === ERRORI ATTRIBUTI ===
            case 'woocommerce_rest_product_attribute_invalid_id': throw AttributeNotFoundException();
            case 'woocommerce_rest_product_attribute_term_invalid_id': throw AttributeTermNotFoundException();

            // === ERRORI VARIANTI ===
            case 'woocommerce_rest_product_variation_invalid_id': throw VariationNotFoundException();

            // === ERRORI MEDIA ===
            case 'woocommerce_rest_attachment_invalid_id': throw MediaNotFoundException();

            // === ERRORI ORDINI ===
            case 'woocommerce_rest_shop_order_invalid_id': throw OrderNotFoundException();
            case 'woocommerce_rest_invalid_order_status': throw InvalidOrderStatusException();

            // === ERRORI CLIENTI ===
            case 'woocommerce_rest_customer_invalid_id': throw CustomerNotFoundException();
            case 'woocommerce_rest_customer_invalid_email': throw InvalidCustomerEmailException();
            case 'registration-error-email-exists': throw CustomerEmailAlreadyExistsException();
            case 'registration-error-username-exists': throw CustomerUsernameAlreadyExistsException();
            case 'woocommerce_rest_invalid_username': throw InvalidCustomerUsernameException();

            // === ERRORI COUPON ===
            case 'woocommerce_rest_shop_coupon_invalid_id': throw CouponNotFoundException();
            case 'woocommerce_rest_coupon_code_already_exists': throw CouponCodeAlreadyExistsException();
            case 'woocommerce_rest_coupon_expired': throw CouponExpiredException();
            case 'woocommerce_rest_coupon_usage_limit_reached': throw CouponUsageLimitException();

            // === ERRORI TASSE ===
            case 'woocommerce_rest_tax_class_invalid': throw TaxClassNotFoundException();
            case 'woocommerce_rest_tax_rate_invalid_id': throw TaxRateNotFoundException();
            case 'woocommerce_rest_invalid_tax_location': throw InvalidTaxLocationException();

            // === ERRORI SPEDIZIONI ===
            case 'woocommerce_rest_shipping_zone_invalid_id': throw ShippingZoneNotFoundException();
            case 'woocommerce_rest_shipping_zone_method_invalid_id': throw ShippingMethodNotFoundException();
            case 'woocommerce_rest_shipping_class_invalid_id': throw ShippingClassNotFoundException();
            case 'woocommerce_rest_invalid_shipping_location': throw InvalidShippingLocationException();

            // === ERRORI BATCH ===
            case 'woocommerce_rest_invalid_batch_data': throw InvalidBatchDataException();
            case 'woocommerce_rest_batch_limit_exceeded': throw BatchLimitExceededException();
            case 'woocommerce_rest_batch_operation_failed': throw BatchOperationFailedException();

            // === ERRORI GENERICI ===
            default:
              // Determina il tipo di eccezione generica in base al contesto
              if (code.startsWith('woocommerce_rest_product')) {
                throw GenericWooCommerceException(code: code, message: message, statusCode: statusCode);
              } else if (code.contains('coupon')) {
                throw GenericCouponException(code: code, message: message, statusCode: statusCode);
              } else if (code.contains('customer')) {
                throw GenericCustomerException(code: code, message: message, statusCode: statusCode);
              } else if (code.contains('tax')) {
                throw GenericTaxException(code: code, message: message, statusCode: statusCode);
              } else if (code.contains('shipping')) {
                throw GenericShippingException(code: code, message: message, statusCode: statusCode);
              } else if (code.contains('batch')) {
                throw GenericBatchException(code: code, message: message, statusCode: statusCode);
              } else {
                // Fallback per errori completamente sconosciuti
                throw GenericWooCommerceException(code: code, message: message, statusCode: statusCode);
              }
          }
        } on FormatException {
          throw InvalidResponseFormatException();
        }
      }

      // Fallback per errori non previsti
      throw UnhandledApiException(statusCode: statusCode);
    } else {
      // Errori di connessione senza risposta
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw ConnectionTimeoutException();
        case DioExceptionType.connectionError:
          throw ConnectionException('di rete');
        case DioExceptionType.cancel:
          throw ConnectionException('richiesta annullata');
        default:
          throw ConnectionException(e.message ?? 'errore sconosciuto');
      }
    }
  }
}