import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';

/// Test end-to-end del percorso REALE delle varianti:
/// API della libreria (getProductVariations) → WooProductVariation.fromJson
/// (fork patchato) contro il WordPress Docker.
///
/// Richiede WordPress su localhost:8080 (testuser/testpassword) con
/// Application Passwords abilitati e WooCommerce REST attivo.
void main() {
  const siteUrl = 'http://localhost:8080';
  const username = 'testuser';
  const password = 'testpassword';

  test('getProductVariations parsa le varianti reali (end-to-end)', () async {
    // 1. Login + Application Password (come fa l'app)
    final cookies = await _loginWithCookies(siteUrl, username, password);
    final cookieHeader = _cookieHeader(cookies);
    final appPassword = await _createAppPassword(siteUrl, cookieHeader);

    // 2. Istanza WooCommerce con Basic Auth (Application Password),
    //    stesso costruttore usato da WooConnect per WordPress.
    final woo = WooCommerce(
      baseUrl: siteUrl,
      consumerKey: username,
      consumerSecret: appPassword,
      useFaker: false,
      isDebug: false,
    );

    // 3. Chiamata reale al plugin per il prodotto 5869 (quello della log)
    final variations = await woo.getProductVariations(
      5869,
      page: 1,
      perPage: 100,
      status: WooProductStatus.publish,
    );

    expect(variations, isNotEmpty,
        reason: 'Il prodotto 5869 dovrebbe avere varianti');
    for (final v in variations.items) {
      expect(v.status, WooProductStatus.publish,
          reason: 'SKU ${v.sku}: status non decodificato (fork patchato)');
      expect(v.id, isNotNull);
      expect(v.sku, isNotNull);
      expect(v.stockStatus, isNotNull);
      expect(v.attributes, isNotEmpty,
          reason: 'SKU ${v.sku}: attributi mancanti (formato option)');
      for (final attr in v.attributes ?? []) {
        expect(attr.options, isNotEmpty,
            reason: 'SKU ${v.sku}: attributo ${attr.name} senza opzioni');
      }
    }
  });
}

// --- Helper (stesso flusso del test di integrazione WP auth) ---

Future<Map<String, String>> _loginWithCookies(
  String siteUrl,
  String username,
  String password,
) async {
  final uri = Uri.parse('$siteUrl/wp-login.php');
  final client = HttpClient();
  try {
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
    request.headers.add('Cookie', 'wordpress_test_cookie=WP%20Cookie%20check');
    final body = Uri(queryParameters: {
      'log': username,
      'pwd': password,
      'wp-submit': 'Accedi',
      'redirect_to': '/wp-admin/',
      'testcookie': '1',
    }).query;
    request.write(body);
    final response =
        await request.close().timeout(const Duration(seconds: 20));
    final cookies = <String, String>{};
    for (final cookie in response.cookies) {
      cookies[cookie.name] = Uri.decodeComponent(cookie.value);
    }
    return cookies;
  } finally {
    client.close();
  }
}

String _cookieHeader(Map<String, String> cookies) {
  return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
}

Future<String> _extractNonce(String siteUrl, String cookieHeader) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse('$siteUrl/wp-admin/profile.php'));
    request.headers.set('Cookie', cookieHeader);
    final response =
        await request.close().timeout(const Duration(seconds: 15));
    final body = await response.transform(utf8.decoder).join();
    final nonceMatch =
        RegExp(r'createNonceMiddleware\(\s*"([a-f0-9]+)"\s*\)').firstMatch(body);
    if (nonceMatch == null) throw Exception('Nonce non trovato');
    return nonceMatch.group(1)!;
  } finally {
    client.close();
  }
}

Future<String> _createAppPassword(String siteUrl, String cookieHeader) async {
  final nonce = await _extractNonce(siteUrl, cookieHeader);
  final uri = Uri.parse(
    '$siteUrl/wp-json/wp/v2/users/me/application-passwords',
  );
  final client = HttpClient();
  try {
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Cookie', cookieHeader);
    request.headers.set('X-WP-Nonce', nonce);
    request.write(jsonEncode({
      'name': 'e2e-${DateTime.now().millisecondsSinceEpoch}',
    }));
    final response =
        await request.close().timeout(const Duration(seconds: 20));
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}: ${json['message']}');
    }
    return json['password'] as String;
  } finally {
    client.close();
  }
}