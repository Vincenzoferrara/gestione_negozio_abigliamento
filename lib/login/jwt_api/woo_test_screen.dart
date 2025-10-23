// WooCommerce Test Screen
//
// SCHERMATA TEMPORANEA SOLO PER TESTING
// DA ELIMINARE dopo aver verificato il funzionamento

import 'package:flutter/material.dart';
import 'package:gestione_negozio_abigliamento/log_viewer/app_logger.dart';
import 'woo_test_product_loader.dart';
import 'woocommerce_service.dart';
import 'jwt_connect.dart';

class WooTestScreen extends StatefulWidget {
  const WooTestScreen({super.key});

  @override
  State<WooTestScreen> createState() => _WooTestScreenState();
}

class _WooTestScreenState extends State<WooTestScreen> {
  final WooTestProductLoader _tester = WooTestProductLoader();
  final WooCommerceService _wooService = WooCommerceService();

  bool _isLoading = false;
  String _result = '';
  List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test WooCommerce'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ SCHERMATA DI TEST',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _wooService.isReady
                      ? '✅ Connesso a: ${_wooService.siteUrl}'
                      : '❌ Non connesso',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          // Test buttons
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTestButton(
                    'Test Rapido',
                    'Carica 1 prodotto',
                    Icons.flash_on,
                    Colors.green,
                    _runQuickTest,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    'Test Completo',
                    'Esegue tutti i test',
                    Icons.checklist,
                    Colors.blue,
                    _runFullTest,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    'Carica Prodotto (Dio Diretto)',
                    'Test API diretta con JWT',
                    Icons.api,
                    Colors.deepOrange,
                    _testProductWithDio,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    'Carica Singolo Prodotto',
                    'Test caricamento 1 prodotto',
                    Icons.shopping_bag,
                    Colors.orange,
                    _testSingleProduct,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    'Carica 5 Prodotti',
                    'Test caricamento multiplo',
                    Icons.inventory,
                    Colors.purple,
                    _testMultipleProducts,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    'Conta Prodotti',
                    'Conta totale prodotti negozio',
                    Icons.calculate,
                    Colors.teal,
                    _testCountProducts,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    'Test JWT Token',
                    'Verifica autenticazione JWT',
                    Icons.vpn_key,
                    Colors.cyan,
                    _testJwtToken,
                  ),
                  const SizedBox(height: 12),
                  _buildTestButton(
                    'Test Connessione',
                    'Verifica accesso API',
                    Icons.wifi,
                    Colors.indigo,
                    _testConnection,
                  ),

                  // Result area
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),

                  if (_isLoading)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Test in corso...'),
                        ],
                      ),
                    )
                  else if (_result.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _result.contains('❌')
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _result.contains('❌')
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _result.contains('❌')
                                    ? Icons.error
                                    : Icons.check_circle,
                                color: _result.contains('❌')
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Risultato:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_result),
                        ],
                      ),
                    ),

                  // Logs area
                  if (_logs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Log:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _logs.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Pulisci'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final logText = _logs[index];
                          Color textColor = Colors.white;
                          Color? backgroundColor;

                          if (logText.contains('✅')) {
                            textColor = Colors.green.shade900;
                            backgroundColor = Colors.green.shade300;
                          } else if (logText.contains('❌')) {
                            textColor = Colors.white;
                            backgroundColor = Colors.red.shade700;
                          } else if (logText.contains('⚠️')) {
                            textColor = Colors.orange.shade900;
                            backgroundColor = Colors.orange.shade300;
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 1),
                            padding: backgroundColor != null
                                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                                : EdgeInsets.zero,
                            decoration: backgroundColor != null
                                ? BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              logText,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontFamily: 'monospace',
                                fontWeight: backgroundColor != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Future<void> Function() onPressed,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        onTap: _isLoading ? null : () => _runTest(onPressed, title),
      ),
    );
  }

  Future<void> _runTest(Future<void> Function() testFunction, String testName) async {
    setState(() {
      _isLoading = true;
      _result = '';
      _logs = [];
    });

    _addLog('🚀 Avvio test: $testName');

    try {
      await testFunction();
      _addLog('✅ Test completato con successo');
      setState(() {
        _result = '✅ Test "$testName" completato con successo!';
      });
    } catch (e) {
      _addLog('❌ Test fallito: $e');
      setState(() {
        _result = '❌ Errore:\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    log.d(message);
  }

  // Test methods
  Future<void> _runQuickTest() async {
    _addLog('⚡ Esecuzione test rapido...');
    final success = await _tester.quickTest();
    if (!success) {
      throw Exception('Test rapido fallito');
    }
  }

  Future<void> _runFullTest() async {
    _addLog('📋 Esecuzione test completo...');
    await _tester.runAllTests();
  }

  Future<void> _testSingleProduct() async {
    _addLog('📦 Caricamento singolo prodotto...');
    await _tester.testLoadSingleProduct();
  }

  Future<void> _testMultipleProducts() async {
    _addLog('📦 Caricamento multipli prodotti...');
    await _tester.testLoadMultipleProducts();
  }

  Future<void> _testCountProducts() async {
    _addLog('📊 Conteggio prodotti...');
    await _tester.testCountProducts();
  }

  Future<void> _testProductWithDio() async {
    _addLog('🔍 Test caricamento prodotti con Dio diretto...');

    final jwt = JwtConnect();

    if (!jwt.isConnected) {
      _addLog('❌ Non autenticato');
      throw Exception('Nessuna sessione JWT attiva');
    }

    _addLog('✅ JWT Token attivo');
    _addLog('📍 Base URL: ${jwt.currentSiteUrl}');

    try {
      // Test con endpoint WooCommerce diretto
      final url = '${jwt.currentSiteUrl}/wp-json/wc/v3/products';
      _addLog('🌐 GET: $url');

      final response = await jwt.getAuthenticatedDio().get(
        url,
        queryParameters: {
          'per_page': 5,
          'page': 1,
        },
      );

      _addLog('✅ Status: ${response.statusCode}');
      _addLog('📦 Prodotti ricevuti: ${(response.data as List).length}');

      final products = response.data as List;
      for (int i = 0; i < products.length; i++) {
        final p = products[i];
        _addLog('  ${i + 1}. [${p['id']}] ${p['name']} - €${p['price'] ?? "N/A"}');
      }

      if (products.isEmpty) {
        _addLog('⚠️ Nessun prodotto trovato nel negozio');
      }
    } catch (e) {
      _addLog('❌ Errore: $e');
      rethrow;
    }
  }

  Future<void> _testJwtToken() async {
    _addLog('🔑 Verifica JWT Token...');

    final jwt = JwtConnect();

    if (!jwt.isConnected) {
      _addLog('❌ Non autenticato');
      throw Exception('Nessuna sessione JWT attiva');
    }

    _addLog('✅ Sessione JWT attiva');
    _addLog('📍 URL: ${jwt.currentSiteUrl}');

    final token = jwt.session?.token;
    if (token != null) {
      _addLog('🔐 Token: ${token.substring(0, 30)}...');
      _addLog('⏰ Scadenza: ${jwt.session?.expiresAt}');
      _addLog('⏱️ Ancora valido: ${!jwt.session!.isExpired}');
    }

    // Test chiamata autenticata diretta
    _addLog('🧪 Test chiamata API autenticata...');
    try {
      final response = await jwt.getAuthenticatedDio().get(
        '${jwt.currentSiteUrl}/wp-json/wp/v2/users/me',
      );

      _addLog('✅ Risposta API: ${response.statusCode}');
      _addLog('👤 Utente: ${response.data['name']}');
      _addLog('📧 Email: ${response.data['email']}');
    } catch (e) {
      _addLog('❌ Errore chiamata API: $e');
      rethrow;
    }
  }

  Future<void> _testConnection() async {
    _addLog('🔌 Test connessione API...');
    final connected = await _wooService.testConnection();
    if (!connected) {
      throw Exception('Connessione fallita');
    }
    _addLog('✅ Connessione OK');
  }
}
