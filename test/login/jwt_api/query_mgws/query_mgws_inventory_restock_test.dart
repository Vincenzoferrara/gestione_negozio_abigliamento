import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/mgws_availability.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';

class _FakeTransport implements MgwsInventoryTransport {
  _FakeTransport(this.response);

  MgwsInventoryResponse response;
  String? path;
  Map<String, Object?>? query;
  Map<String, Object?>? body;
  String? method;

  @override
  Future<MgwsInventoryResponse> delete(String path) async {
    method = 'DELETE';
    this.path = path;
    return response;
  }

  @override
  Future<MgwsInventoryResponse> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    method = 'GET';
    this.path = path;
    query = queryParameters;
    return response;
  }

  @override
  Future<MgwsInventoryResponse> patch(
    String path, {
    Map<String, Object?>? data,
  }) async {
    method = 'PATCH';
    this.path = path;
    body = data;
    return response;
  }

  @override
  Future<MgwsInventoryResponse> post(
    String path, {
    Map<String, Object?>? data,
  }) async {
    method = 'POST';
    this.path = path;
    body = data;
    return response;
  }
}

MgwsInventoryResponse _failure(int statusCode, String code) {
  return MgwsInventoryResponse(
    statusCode: statusCode,
    data: {'code': code, 'message': 'Operazione negata'},
  );
}

class _StaticMgwsAvailabilityChecker implements MgwsAvailabilityChecker {
  const _StaticMgwsAvailabilityChecker(this.result);

  final bool result;

  @override
  Future<bool> check() async => result;
}

Future<MgwsAvailability> _availableMgws() async {
  final availability = MgwsAvailability(
    checker: const _StaticMgwsAvailabilityChecker(true),
  );
  await availability.refresh();
  return availability;
}

void main() {
  group('MGWS inventory restock parsers', () {
    test('parses a complete quick load success response', () async {
      final transport = _FakeTransport(
        const MgwsInventoryResponse(
          statusCode: 200,
          data: {
            'ok': true,
            'operation': 'quick_load',
            'product_id': 7,
            'variation_id': 0,
            'quantity_delta': 3,
            'previous_stock': 4,
            'current_stock': 7,
            'reason': 'Carico fornitore',
            'movement_id': 88,
            'location': {
              'site_id': 2,
              'warehouse_id': 5,
              'room': 'A',
              'rack': '1',
              'shelf': '2',
            },
          },
        ),
      );
      final client = QueryMgwsInventory(
        transport: transport,
        availability: await _availableMgws(),
      );

      final result = await client.quickLoad(
        const MgwsQuickLoadRequest(
          productId: 7,
          quantityDelta: 3,
          reason: 'Carico fornitore',
          warehouseId: 5,
        ),
      );

      expect(result.success, isTrue);
      expect(result.data?.currentStock, 7);
      expect(transport.path, '/wp-json/mgws/v1/inventory/quick-load');
      expect(transport.body?['warehouse_id'], 5);
    });

    test(
      'returns typed backend and permission failures without throwing',
      () async {
        final transport = _FakeTransport(_failure(401, 'rest_not_logged_in'));
        final client = QueryMgwsInventory(
          transport: transport,
          availability: await _availableMgws(),
        );

        final unauthorized = await client.getSupplier(9);
        transport.response = _failure(403, 'mgws_forbidden');
        final forbidden = await client.deleteSupplier(9);

        expect(unauthorized.success, isFalse);
        expect(unauthorized.error?.code, 'rest_not_logged_in');
        expect(forbidden.success, isFalse);
        expect(forbidden.error?.code, 'mgws_forbidden');
      },
    );

    test('does not call a restock endpoint when MGWS is unavailable', () async {
      final transport = _FakeTransport(
        const MgwsInventoryResponse(statusCode: 200, data: {'ok': true}),
      );
      final availability = MgwsAvailability(
        checker: const _StaticMgwsAvailabilityChecker(false),
      );
      await availability.refresh();
      final client = QueryMgwsInventory(
        transport: transport,
        availability: availability,
      );

      final result = await client.quickLoad(
        const MgwsQuickLoadRequest(
          productId: 7,
          quantityDelta: 3,
          reason: 'Carico fornitore',
        ),
      );

      expect(result.success, isFalse);
      expect(result.error?.code, 'mgws_unavailable');
      expect(transport.method, isNull);
    });

    test(
      'fails closed for malformed data and success responses with errors',
      () {
        final malformed = MgwsRestockParser.object<MgwsQuickLoad>(
          {'ok': true, 'product_id': 'bad'},
          200,
          MgwsQuickLoad.fromMap,
        );
        final partial = MgwsRestockParser.object<MgwsQuickLoad>(
          {
            'ok': true,
            'errors': ['audit warning'],
            'product_id': 7,
          },
          200,
          MgwsQuickLoad.fromMap,
        );

        expect(malformed.success, isFalse);
        expect(malformed.data, isNull);
        expect(partial.success, isFalse);
        expect(partial.details, ['audit warning']);
      },
    );

    test('does not throw for legacy malformed nested maps or stock lists', () {
      expect(
        QueryMgwsInventory.parsePayloadResponse({
          'data': {1: 'invalid key'},
        }),
        isNotEmpty,
      );
      expect(
        QueryMgwsInventory.parseStockListResponse([
          {1: 'invalid key'},
        ]),
        isEmpty,
      );
    });
  });

  group('MGWS inventory restock endpoint encoding', () {
    test('encodes all dynamic endpoint group paths', () {
      expect(
        QueryMgwsInventory.supplierPath(7),
        '/wp-json/mgws/v1/inventory/suppliers/7',
      );
      expect(
        QueryMgwsInventory.reorderRulePath(8),
        '/wp-json/mgws/v1/inventory/reorder-rules/8',
      );
      expect(
        QueryMgwsInventory.purchaseOrderPath(9),
        '/wp-json/mgws/v1/inventory/purchase-orders/9',
      );
      expect(
        QueryMgwsInventory.receiptPath(10),
        '/wp-json/mgws/v1/inventory/receipts/10',
      );
      expect(
        QueryMgwsInventory.movementPath(11),
        '/wp-json/mgws/v1/inventory/movements/11',
      );
      expect(
        QueryMgwsInventory.countSessionPath(12),
        '/wp-json/mgws/v1/inventory/count-sessions/12',
      );
    });

    test(
      'preserves movement pagination, dates, source, operator, and reason filters',
      () {
        const filter = MgwsMovementFilter(
          productId: 7,
          variationId: 0,
          dateFrom: '2026-08-01T00:00:00Z',
          dateTo: '2026-08-02T23:59:59Z',
          sourceType: 'receipt/load',
          operatorUserId: 42,
          reasonCode: 'stock count',
          stockEffect: 'adjustment',
          page: 2,
          perPage: 100,
        );

        final encoded = QueryMgwsInventory.encodedQueryPath(
          '/wp-json/mgws/v1/inventory/movements',
          filter.toQuery(),
        );

        expect(encoded, contains('product_id=7'));
        expect(encoded, contains('date_from=2026-08-01T00%3A00%3A00Z'));
        expect(encoded, contains('source_type=receipt%2Fload'));
        expect(encoded, contains('user_id=42'));
        expect(encoded, contains('reason_code=stock+count'));
        expect(encoded, contains('page=2'));
        expect(encoded, contains('per_page=100'));
      },
    );

    test(
      'uses typed queries and paths for every restock endpoint group',
      () async {
        final transport = _FakeTransport(_failure(403, 'mgws_forbidden'));
        final client = QueryMgwsInventory(
          transport: transport,
          availability: await _availableMgws(),
        );

        await client.listReorderRules(siteId: 2, warehouseId: 5);
        expect(transport.path, '/wp-json/mgws/v1/inventory/reorder-rules');
        expect(transport.query, {'site_id': 2, 'warehouse_id': 5});

        await client.updatePurchaseOrderStatus(9, 'ordered');
        expect(
          transport.path,
          '/wp-json/mgws/v1/inventory/purchase-orders/9/status',
        );
        expect(transport.body, {'status': 'ordered'});

        await client.convalidaReceipt(10);
        expect(
          transport.path,
          '/wp-json/mgws/v1/inventory/receipts/10/convalida',
        );

        await client.listBackorders(siteId: 2);
        expect(transport.query, {'site_id': 2});

        await client.approveCountSession(12);
        expect(
          transport.path,
          '/wp-json/mgws/v1/inventory/count-sessions/12/approve',
        );
      },
    );
  });
}
