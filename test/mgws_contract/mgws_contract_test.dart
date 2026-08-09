import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/cassa/checkout_payload.dart';
import 'package:gestione_negozio_abbigliamento/cassa/class_scontrino.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/adapter/loyalty_gateway.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/adapter/platform_manager.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_loyalty.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_pos.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/class_prodotti.dart';

ProdottoGlobal _product() {
  return ProdottoGlobal(
    id: 101,
    nome: 'Maglia MGWS',
    sku: 'MGWS-101',
    prezzoNormale: 12.5,
    prezzoScontato: 12.5,
    inStock: true,
    quantitaTotale: 7,
    status: 'publish',
  );
}

void main() {
  group('MGWS first backend contract', () {
    test('POS checkout accepts order_id and woo_order_id responses', () {
      final pos = QueryMgwsPos();

      expect(pos.checkoutOrderId({'order_id': 701}), 701);
      expect(pos.checkoutOrderId({'woo_order_id': 702}), 702);
    });

    test('checkout payload has a stable local receipt identity fallback', () {
      final scontrino = Scontrino(
        id: 'receipt-7',
        data: DateTime.utc(2026, 7, 18, 12),
      );
      final line = RigaScontrino(
        prodotto: _product(),
        quantita: 2,
        subtotale: 0,
      )..calcolaSubtotale();
      scontrino.aggiungiRiga(line);

      final payload = buildMgwsCheckoutPayload(scontrino: scontrino);
      final metadata = (payload['meta_data'] as List<Map<String, dynamic>>);
      final hasLocalReceiptId = metadata.any(
        (entry) => entry['key'] == '_id_scontrino_locale',
      );

      expect(
        payload.containsKey('idempotency_key') || hasLocalReceiptId,
        isTrue,
      );
      expect(
        metadata.singleWhere(
          (entry) => entry['key'] == '_id_scontrino_locale',
        )['value'],
        'receipt-7',
      );
    });

    test('inventory fixtures preserve expected map and list values', () {
      final productStock = QueryMgwsInventory.parseMapResponse({
        'product_id': 101,
        'variation_id': 0,
        'current_stock': 7,
      });
      final allStock = QueryMgwsInventory.parseStockListResponse([
        {'product_id': 101, 'variation_id': 0, 'current_stock': 7},
      ]);

      expect(productStock['product_id'], 101);
      expect(productStock['current_stock'], 7);
      expect(allStock, hasLength(1));
      expect(allStock.single['variation_id'], 0);
      expect(allStock.single['current_stock'], 7);
    });

    test('malformedInventoryFixtureFailsSafely', () {
      final malformedFixture = <String, Object?>{
        'stock/all': <String, Object?>{'product_id': 101, 'current_stock': 7},
      };

      final parsed = QueryMgwsInventory.parseStockListResponse(
        malformedFixture['stock/all'],
      );

      expect(parsed, isEmpty);
    });

    test('loyalty paths encode special card and email lookups', () {
      expect(
        QueryMgwsLoyalty.cardLookupPath('CARD:201 / ?'),
        '/wp-json/mgws/v1/loyalty/lookup/card/CARD%3A201%20%2F%20%3F',
      );
      expect(
        QueryMgwsLoyalty.emailLookupPath('ada+vip@example.test'),
        '/wp-json/mgws/v1/loyalty/lookup/email/ada%2Bvip%40example.test',
      );
    });

    test('loyalty customer response preserves MGWS contract fields', () {
      final customer = QueryMgwsLoyalty.customerFromResponse({
        'user_id': 201,
        'customer_id': 201,
        'card_number': 'CARD-201',
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'email': 'ada+vip@example.test',
        'points': '7',
      });

      expect(customer?['user_id'], 201);
      expect(customer?['card_number'], 'CARD-201');
      expect(QueryMgwsLoyalty.customerPointsFromResponse(customer), 7);
    });

    test('PlatformManager exposes WooCommerce and MGWS accessors only', () {
      expect(PlatformType.values, equals([PlatformType.woocommerce]));
      expect(PlatformManager.currentPlatform, PlatformType.woocommerce);
      expect(PlatformManager.pos, isA<QueryMgwsPos>());
      expect(PlatformManager.cartaFedelta, isA<LoyaltyGateway>());
    });
  });
}
