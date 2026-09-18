import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Test di integrazione del flusso WordPress auth.
///
/// Verifica l'intero flusso end-to-end:
/// 1. Login via /wp-login.php (cookie-based)
/// 2. Verifica Application Passwords abilitati
/// 3. Estrazione REST nonce da wp-admin
/// 4. Creazione Application Password via REST API
/// 5. Basic Auth con Application Password
/// 6. WooCommerce API con Basic Auth
///
/// Richiede un WordPress Docker su localhost:8080 con:
/// - Utente: testuser / testpassword
/// - Application Passwords abilitati
void main() {
  const siteUrl = 'http://localhost:8080';
  const username = 'testuser';
  const password = 'testpassword';

  group('WordPress Auth Integration', () {
    test('1. Login via /wp-login.php', () async {
      final cookies = await _loginWithCookies(siteUrl, username, password);

      expect(cookies, isNotEmpty);
      expect(
        cookies.keys.any((name) => name.startsWith('wordpress_logged_in_')),
        isTrue,
        reason: 'Cookie wordpress_logged_in_* non trovato',
      );
    });

    test('2. Application Passwords abilitati', () async {
      final cookies = await _loginWithCookies(siteUrl, username, password);
      final cookieHeader = _cookieHeader(cookies);

      final response = await _httpGet('$siteUrl/wp-json/', cookieHeader);
      final body = await response.transform(utf8.decoder).join();

      expect(
        body.contains('application-passwords'),
        isTrue,
        reason: 'application-passwords non trovato nel body /wp-json/',
      );
    });

    test('3. Estrazione REST nonce da wp-admin', () async {
      final cookies = await _loginWithCookies(siteUrl, username, password);
      final cookieHeader = _cookieHeader(cookies);

      final response = await _httpGet(
        '$siteUrl/wp-admin/profile.php',
        cookieHeader,
      );
      final body = await response.transform(utf8.decoder).join();

      final nonceMatch = RegExp(
        r'createNonceMiddleware\(\s*"([a-f0-9]+)"\s*\)',
      ).firstMatch(body);

      expect(
        nonceMatch,
        isNotNull,
        reason: 'createNonceMiddleware nonce non trovato in profile.php',
      );
    });

    test('4. Creazione Application Password via REST API', () async {
      final cookies = await _loginWithCookies(siteUrl, username, password);
      final cookieHeader = _cookieHeader(cookies);
      final nonce = await _extractNonce(siteUrl, cookieHeader);

      final deviceId = 'test-${DateTime.now().millisecondsSinceEpoch}';
      final uri = Uri.parse(
        '$siteUrl/wp-json/wp/v2/users/me/application-passwords',
      );

      final client = HttpClient();
      try {
        final request = await client.postUrl(uri);
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Cookie', cookieHeader);
        request.headers.set('X-WP-Nonce', nonce);
        request.write(jsonEncode({'name': 'test-$deviceId'}));

        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );

        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;

        expect(response.statusCode, equals(201));
        expect(json['password'], isNotNull);
        expect(json['password'], isNotEmpty);
      } finally {
        client.close();
      }
    });

    test('5. Basic Auth funziona con Application Password', () async {
      final cookies = await _loginWithCookies(siteUrl, username, password);
      final cookieHeader = _cookieHeader(cookies);
      final nonce = await _extractNonce(siteUrl, cookieHeader);

      // Crea una Application Password
      final appPassword = await _createAppPassword(
        siteUrl,
        cookieHeader,
        nonce,
      );

      // Test Basic Auth con la password appena creata
      final credentials = '$username:$appPassword';
      final encoded = base64Encode(utf8.encode(credentials));

      final response = await _httpGet(
        '$siteUrl/wp-json/wp/v2/users/me',
        null,
        authHeader: 'Basic $encoded',
      );
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, equals(200));
      expect(json['name'], equals(username));
    });

    test('6. WooCommerce API con WordPress Basic Auth', () async {
      final cookies = await _loginWithCookies(siteUrl, username, password);
      final cookieHeader = _cookieHeader(cookies);
      final nonce = await _extractNonce(siteUrl, cookieHeader);

      // Crea una Application Password
      final appPassword = await _createAppPassword(
        siteUrl,
        cookieHeader,
        nonce,
      );

      // Test WooCommerce REST API con Basic Auth
      final credentials = '$username:$appPassword';
      final encoded = base64Encode(utf8.encode(credentials));

      final response = await _httpGet(
        '$siteUrl/wp-json/wc/v3/products?per_page=1',
        null,
        authHeader: 'Basic $encoded',
      );

      // WooCommerce API restituisce 200 o 401 (se WC non configurato)
      // L'importante è che non sia 403 (nonce invalido)
      expect(
        response.statusCode == 200 || response.statusCode == 401,
        isTrue,
        reason: 'WooCommerce API ha restituito HTTP ${response.statusCode}',
      );
    });
  });
}

// --- Helper functions ---

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
    request.headers.add(
      'Cookie',
      'wordpress_test_cookie=WP%20Cookie%20check',
    );

    final body = Uri(queryParameters: {
      'log': username,
      'pwd': password,
      'wp-submit': 'Accedi',
      'redirect_to': '/wp-admin/',
      'testcookie': '1',
    }).query;

    request.write(body);

    final response = await request.close().timeout(
      const Duration(seconds: 20),
    );

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

Future<HttpClientResponse> _httpGet(
  String url,
  String? cookieHeader, {
  String? authHeader,
}) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    if (cookieHeader != null) {
      request.headers.set('Cookie', cookieHeader);
    }
    if (authHeader != null) {
      request.headers.set('Authorization', authHeader);
    }
    request.headers.set('Accept', 'application/json');
    return await request.close().timeout(const Duration(seconds: 15));
  } catch (e) {
    client.close();
    rethrow;
  }
}

Future<String> _extractNonce(String siteUrl, String cookieHeader) async {
  final response = await _httpGet('$siteUrl/wp-admin/profile.php', cookieHeader);
  final body = await response.transform(utf8.decoder).join();

  final nonceMatch = RegExp(
    r'createNonceMiddleware\(\s*"([a-f0-9]+)"\s*\)',
  ).firstMatch(body);

  if (nonceMatch == null) {
    throw Exception('Nonce non trovato');
  }

  return nonceMatch.group(1)!;
}

Future<String> _createAppPassword(
  String siteUrl,
  String cookieHeader,
  String nonce,
) async {
  final deviceId = 'test-${DateTime.now().millisecondsSinceEpoch}';
  final uri = Uri.parse(
    '$siteUrl/wp-json/wp/v2/users/me/application-passwords',
  );

  final client = HttpClient();
  try {
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Cookie', cookieHeader);
    request.headers.set('X-WP-Nonce', nonce);
    request.write(jsonEncode({'name': 'test-$deviceId'}));

    final response = await request.close().timeout(
      const Duration(seconds: 20),
    );

    final responseBody = await response.transform(utf8.decoder).join();
    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw Exception(
        'HTTP ${response.statusCode}: ${json['message'] ?? 'errore'}',
      );
    }

    return json['password'] as String;
  } finally {
    client.close();
  }
}
