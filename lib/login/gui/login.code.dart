import 'package:flutter/material.dart';
import '../jwt_api/jwt_connect.dart';
import '../jwt_api/product_service.dart';

class LoginCode {
  final AuthService _authService = AuthService();

  Future<bool> tryAutoLogin() async {
    return await _authService.tryLoadSessionFromStorage();
  }

  /// Esegue il login e, se ha successo, esegue un'azione di test.
  /// Ora accetta una callback 'onSuccess' invece di gestire la navigazione.
  Future<void> performLoginAndTestCreation({
    required BuildContext context,
    required String siteUrl,
    required String username,
    required String password,
    String? customJwtEndpoint,
    required VoidCallback onSuccess, // <-- NUOVA CALLBACK
  }) async {
    final userSession = await _authService.login(
      siteUrl: siteUrl,
      username: username,
      password: password,
      customEndpoint: customJwtEndpoint,
    );

    final productService = ProductService(
      siteUrl: siteUrl,
      session: userSession,
    );
      
    final testProduct = NewProductData(
      name: 'Prodotto Test Centralizzato',
      price: '42.00',
      sku: 'APP-TEST-${DateTime.now().millisecondsSinceEpoch}',
      description: 'Creato con la nuova architettura centralizzata ApiClient.'
    );

    await productService.createProduct(testProduct);

    // Se tutte le operazioni precedenti hanno successo, chiama la callback.
    onSuccess();
  }

  Future<void> logout() async {
    await _authService.logout();
  }
  
  String? get cachedSiteUrl => _authService.currentSiteUrl;
}

final loginCode = LoginCode();