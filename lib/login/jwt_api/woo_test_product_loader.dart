// WooCommerce Test Product Loader
//
// CLASSE TEMPORANEA SOLO PER TESTING
// Questa classe serve solo per testare il caricamento di prodotti base
// DA ELIMINARE dopo aver verificato il funzionamento

import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import 'package:gestione_negozio_abigliamento/log_viewer/app_logger.dart';
import 'woocommerce_service.dart';

/// Classe di test per verificare il caricamento prodotti
///
/// ATTENZIONE: Questa è una classe temporanea solo per testing!
/// Eliminarla una volta verificato che tutto funziona
class WooTestProductLoader {
  final WooCommerceService _wooService = WooCommerceService();

  /// Test base: carica un singolo prodotto
  Future<void> testLoadSingleProduct() async {
    log.i('🧪 [TEST] Inizio test caricamento singolo prodotto');

    try {
      final woo = _wooService.getWooCommerce();
      log.d('📦 Richiesta lista prodotti (limit 1)...');

      final products = await woo.getProducts(
        perPage: 1,
        page: 1,
      );

      if (products.isEmpty) {
        log.w('⚠️ Nessun prodotto trovato nel negozio');
        return;
      }

      final product = products.first;
      log.i('✅ Prodotto caricato con successo!');
      log.d('📋 ID: ${product.id}');
      log.d('📋 Nome: ${product.name}');
      log.d('📋 Prezzo: ${product.price}');
      log.d('📋 SKU: ${product.sku ?? "N/A"}');
      log.d('📋 Tipo: ${product.type}');
      log.d('📋 Status: ${product.status}');

    } catch (e, stack) {
      log.e('❌ [TEST] Errore caricamento prodotto', e, stack);
      rethrow;
    }
  }

  /// Test: carica i primi 5 prodotti
  Future<void> testLoadMultipleProducts() async {
    log.i('🧪 [TEST] Inizio test caricamento multipli prodotti');

    try {
      final woo = _wooService.getWooCommerce();
      log.d('📦 Richiesta lista prodotti (limit 5)...');

      final products = await woo.getProducts(
        perPage: 5,
        page: 1,
      );

      log.i('✅ Caricati ${products.length} prodotti');

      for (int i = 0; i < products.length; i++) {
        final p = products[i];
        log.d('  ${i + 1}. [${p.id}] ${p.name} - €${p.price ?? "N/A"}');
      }

    } catch (e, stack) {
      log.e('❌ [TEST] Errore caricamento prodotti', e, stack);
      rethrow;
    }
  }

  /// Test: ottiene un prodotto specifico per ID
  Future<void> testLoadProductById(int productId) async {
    log.i('🧪 [TEST] Caricamento prodotto ID: $productId');

    try {
      final woo = _wooService.getWooCommerce();
      log.d('📦 Richiesta prodotto con ID $productId...');

      final product = await woo.getProduct(productId);

      log.i('✅ Prodotto caricato con successo!');
      log.d('📋 ID: ${product.id}');
      log.d('📋 Nome: ${product.name}');
      log.d('📋 Descrizione: ${product.description ?? "N/A"}');
      log.d('📋 Descrizione breve: ${product.shortDescription ?? "N/A"}');
      log.d('📋 Prezzo: ${product.price}');
      log.d('📋 Prezzo normale: ${product.regularPrice}');
      log.d('📋 Prezzo scontato: ${product.salePrice ?? "N/A"}');
      log.d('📋 SKU: ${product.sku ?? "N/A"}');
      log.d('📋 Stock: ${product.stockQuantity ?? "N/A"}');
      log.d('📋 Gestione stock: ${product.manageStock}');
      log.d('📋 Categorie: ${product.categories.length}');
      log.d('📋 Tags: ${product.tags.length}');
      log.d('📋 Immagini: ${product.images.length}');

      if (product.categories.isNotEmpty) {
        log.d('   Categorie:');
        for (final cat in product.categories) {
          log.d('   - [${cat.id}] ${cat.name}');
        }
      }

    } catch (e, stack) {
      log.e('❌ [TEST] Errore caricamento prodotto ID $productId', e, stack);
      rethrow;
    }
  }

  /// Test: cerca prodotti per nome
  Future<void> testSearchProducts(String searchTerm) async {
    log.i('🧪 [TEST] Ricerca prodotti: "$searchTerm"');

    try {
      final woo = _wooService.getWooCommerce();
      log.d('🔍 Ricerca prodotti con termine: $searchTerm...');

      final products = await woo.getProducts(
        search: searchTerm,
        perPage: 10,
      );

      log.i('✅ Trovati ${products.length} prodotti');

      if (products.isEmpty) {
        log.w('⚠️ Nessun prodotto trovato per "$searchTerm"');
        return;
      }

      for (int i = 0; i < products.length; i++) {
        final p = products[i];
        log.d('  ${i + 1}. [${p.id}] ${p.name} - €${p.price ?? "N/A"}');
      }

    } catch (e, stack) {
      log.e('❌ [TEST] Errore ricerca prodotti', e, stack);
      rethrow;
    }
  }

  /// Test: conta totale prodotti
  Future<void> testCountProducts() async {
    log.i('🧪 [TEST] Conteggio totale prodotti');

    try {
      final woo = _wooService.getWooCommerce();
      log.d('📊 Richiesta conteggio prodotti...');

      // Faccio una richiesta con limit 1 e leggo l'header X-WP-Total
      final response = await woo.dio.get(
        '${_wooService.siteUrl}/wp-json/wc/v3/products',
        queryParameters: {'per_page': 1, 'page': 1},
      );

      final totalProducts = int.tryParse(
        response.headers.value('x-wp-total') ?? '0'
      ) ?? 0;

      log.i('✅ Totale prodotti nel negozio: $totalProducts');

    } catch (e, stack) {
      log.e('❌ [TEST] Errore conteggio prodotti', e, stack);
      rethrow;
    }
  }

  /// Test completo - esegue tutti i test in sequenza
  Future<void> runAllTests() async {
    log.i('🚀 [TEST] Avvio test completo WooCommerce Products');
    log.i('════════════════════════════════════════════════════');

    try {
      // Test 1: Verifica connessione
      log.i('\n📡 TEST 1: Verifica connessione');
      final isConnected = await _wooService.testConnection();
      if (!isConnected) {
        log.e('❌ Connessione fallita, interrompo i test');
        return;
      }

      // Test 2: Conta prodotti
      log.i('\n📊 TEST 2: Conteggio prodotti');
      await testCountProducts();

      // Test 3: Singolo prodotto
      log.i('\n📦 TEST 3: Caricamento singolo prodotto');
      await testLoadSingleProduct();

      // Test 4: Multipli prodotti
      log.i('\n📦 TEST 4: Caricamento multipli prodotti');
      await testLoadMultipleProducts();

      log.i('\n════════════════════════════════════════════════════');
      log.i('✅ [TEST] Tutti i test completati con successo!');

    } catch (e, stack) {
      log.e('❌ [TEST] Test fallito', e, stack);
      log.i('════════════════════════════════════════════════════');
    }
  }

  /// Test rapido - solo verifica base
  Future<bool> quickTest() async {
    log.i('⚡ [TEST RAPIDO] Verifica rapida WooCommerce');

    try {
      await testLoadSingleProduct();
      log.i('✅ [TEST RAPIDO] OK');
      return true;
    } catch (e) {
      log.e('❌ [TEST RAPIDO] FAILED', e);
      return false;
    }
  }
}
