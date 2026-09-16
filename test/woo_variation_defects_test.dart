import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';

/// Test diagnostico: quante e quali varianti hanno il difetto di parsing.
///
/// Difetto = campi prezzo (`price`, `regular_price`, `sale_price`) che NON
/// sono stringhe (numeri JSON o null). Il codice originale del plugin
/// (`double.tryParse(json['price'])`) accetta solo String e lancia TypeError
/// negli altri casi; siccome la lista è parsata con un `.map()` senza
/// tolleranza per-item, UNA sola variante così abbatte l'intero caricamento.
///
/// Il test gira in due modalità:
///  1. Fixture offline (`test/fixtures/variations_*.json`): conta le varianti
///     che avrebbero crashato col codice originale e verifica che la patch
///     (`_parsePrice`) le parsi tutte.
///  2. Store live (WordPress Docker su localhost:8080): scansiona TUTTI i
///     prodotti variabili e TUTTE le loro varianti, parsandole una a una con
///     try/catch, e stampa il report completo.
///
/// Richiede per la parte live: WordPress su localhost:8080
/// (testuser/testpassword) con Application Passwords e WooCommerce attivi.
void main() {
  group('difetto prezzi varianti (report diagnostico)', () {    test('fixture: conta le varianti che crashavano col codice originale',
        () {
      const fixtures = [
        'test/fixtures/variations_5869.json',
        'test/fixtures/variations_5735.json',
        'test/fixtures/variations_5733.json',
      ];

      var total = 0;
      final defective = <String>[];

      for (final path in fixtures) {
        final raw = File(path).readAsStringSync();
        final json = jsonDecode(raw) as List<dynamic>;
        for (final item in json) {
          final m = item as Map<String, dynamic>;
          total++;
          final badFields = _nonStringPriceFields(m);
          if (badFields.isNotEmpty) {
            defective.add(
                '${_label(m)} [${badFields.join(', ')}] <- $path');
          }
          // La patch deve parsare comunque tutto senza throw.
          WooProductVariation.fromJson(m);
        }
      }

      // ignore: avoid_print
      print('FIXTURE SCAN: $total varianti totali, '
          '${defective.length} avrebbero crashato col codice originale:');
      for (final d in defective) {
        // ignore: avoid_print
        print('  - $d');
      }
      if (defective.isEmpty) {
        // ignore: avoid_print
        print('  (nessuna: tutte le fixture usano prezzi stringa)');
      }
    });

    test(
      'live: scansiona tutte le varianti dello store',
      () async {      final auth = await _basicAuthHeader(
        'http://localhost:8080',
        'testuser',
        'testpassword',
      );
      const siteUrl = 'http://localhost:8080';

      // 1. Tutti i prodotti (paginati).
      final products = <Map<String, dynamic>>[];
      var page = 1;
      while (true) {
        final chunk = await _getJson(
          '$siteUrl/wp-json/wc/v3/products?per_page=100&page=$page',
          auth,
        );
        if (chunk.isEmpty) break;
        products.addAll(chunk);
        if (chunk.length < 100) break;
        page++;
      }

      final variable =
          products.where((p) => p['type'] == 'variable').toList();

      // 2. Tutte le varianti di ogni prodotto variabile, parse una a una.
      var total = 0;
      var ok = 0;
      final defective = <String>[];

      for (final p in variable) {
        final productId = p['id'];
        var vpage = 1;
        while (true) {
          final chunk = await _getJson(
            '$siteUrl/wp-json/wc/v3/products/$productId/variations'
            '?per_page=100&page=$vpage',
            auth,
          );
          if (chunk.isEmpty) break;
          for (final item in chunk) {
            final m = item;
            total++;
            final badFields = _nonStringPriceFields(m);
            try {
              WooProductVariation.fromJson(m);
              ok++;
              if (badFields.isNotEmpty) {
                defective.add(
                    '${_label(m)} prodotto=$productId '
                    '[prezzi non-stringa: ${badFields.join(', ')}] '
                    '-> OK solo grazie alla patch _parsePrice');
              }
            } catch (e) {
              defective.add(
                  '${_label(m)} prodotto=$productId '
                  '[CRASH anche con patch: $e]');
            }
          }
          if (chunk.length < 100) break;
          vpage++;
        }
      }

      // ignore: avoid_print
      print('LIVE SCAN: ${products.length} prodotti '
          '(${variable.length} variabili), $total varianti totali, '
          '$ok parsate OK, ${defective.length} con difetto:');
      for (final d in defective) {
        // ignore: avoid_print
        print('  - $d');
      }
      if (defective.isEmpty) {
        // ignore: avoid_print
        print('  (nessuna: zero difetti nello store)');
      }

      expect(total, greaterThan(0),
          reason: 'Lo store non ha varianti da scansionare');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

/// Ritorna i nomi dei campi prezzo che NON sono stringhe (quelli che il
/// codice originale `double.tryParse(...)` non digeriva).
List<String> _nonStringPriceFields(Map<String, dynamic> m) {
  final bad = <String>[];
  for (final f in const ['price', 'regular_price', 'sale_price']) {
    final v = m[f];
    if (v is! String) bad.add('$f=${v == null ? 'null' : '${v.runtimeType}($v)'}');
  }
  return bad;
}

String _label(Map<String, dynamic> m) =>
    'var-id=${m['id']} sku=${m['sku']}';

// --- Helper auth/HTTP (stesso flusso degli altri test e2e) ---

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
    request.write(Uri(queryParameters: {
      'log': username,
      'pwd': password,
      'wp-submit': 'Accedi',
      'redirect_to': '/wp-admin/',
      'testcookie': '1',
    }).query);
    final response =
        await request.close().timeout(const Duration(seconds: 20));
    // ignore: avoid_print
    print('login HTTP ${response.statusCode}');
    final cookies = <String, String>{};
    for (final cookie in response.cookies) {
      cookies[cookie.name] = Uri.decodeComponent(cookie.value);
    }
    return cookies;
  } finally {
    client.close();
  }
}

Future<String> _basicAuthHeader(
  String siteUrl,
  String username,
  String password,
) async {
  final cookies = await _loginWithCookies(siteUrl, username, password);
  final cookieHeader =
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  final client = HttpClient();
  try {
    var request = await client.getUrl(
        Uri.parse('$siteUrl/wp-admin/profile.php'));
    request.headers.set('Cookie', cookieHeader);
    var response =
        await request.close().timeout(const Duration(seconds: 15));
    final body = await response.transform(utf8.decoder).join();
    final nonceMatch =
        RegExp(r'createNonceMiddleware\(\s*"([a-f0-9]+)"\s*\)')
            .firstMatch(body);
    if (nonceMatch == null) throw Exception('Nonce non trovato');
    request = await client.postUrl(Uri.parse(
        '$siteUrl/wp-json/wp/v2/users/me/application-passwords'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Cookie', cookieHeader);
    request.headers.set('X-WP-Nonce', nonceMatch.group(1)!);
    request.write(jsonEncode({
      'name': 'defects-${DateTime.now().millisecondsSinceEpoch}',
    }));
    response = await request.close().timeout(const Duration(seconds: 20));
    final respBody = await response.transform(utf8.decoder).join();
    final json = jsonDecode(respBody) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}: ${json['message']}');
    }
    final appPassword = json['password'] as String;
    final basic = base64Encode(utf8.encode('$username:$appPassword'));
    return 'Basic $basic';
  } finally {
    client.close();
  }
}

Future<List<Map<String, dynamic>>> _getJson(String url, String auth) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('Authorization', auth);
    final response =
        await request.close().timeout(const Duration(seconds: 20));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw Exception('GET $url -> HTTP ${response.statusCode}: $body');
    }
    return (jsonDecode(body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  } finally {
    client.close();
  }
}
