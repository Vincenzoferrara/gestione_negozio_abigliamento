import 'package:dio/dio.dart';

/// Interfaccia di un connettore di autenticazione verso WordPress.
///
/// Ogni connettore sa produrre un [Dio] gia' autenticato con le proprie
/// credenziali: JWT Bearer, WordPress Basic Auth con Application Password o
/// Basic Auth con Consumer Key/Secret WooCommerce.
///
/// `WooConnect` e' l'unico owner dei connettori attivi e decide quale
/// connettore e' vivo: nessun altro punto dell'app deve istanziare un
/// connettore per autenticarsi, perche' un connettore secondario risulterebbe
/// disallineato dalla sessione realmente in uso.
abstract class AuthConnector {
  bool get isConnected;
  String? get currentSiteUrl;
  Future<bool> tryAutoConnect();
  Future<void> connect({
    required String siteUrl,
    required String username,
    required String password,
    String? customEndpoint,
  });
  Future<void> disconnect();
  Future<bool> refreshToken();
  Dio getAuthenticatedDio();
}
