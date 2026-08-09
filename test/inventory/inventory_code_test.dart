import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

class _FakeInventoryGateway implements MgwsInventoryGateway {
  var syncCalls = 0;
  var reconcileCalls = 0;
  var rfidCalls = 0;
  var stockMutationCalls = 0;
  var availabilityCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> getAllStock() async {
    return [
      {'product_id': 101, 'current_stock': 7, 'stock_status': 'instock'},
    ];
  }

  @override
  Future<Map<String, dynamic>> getProductStock(int productId) async {
    return {'product_id': productId, 'current_stock': 7};
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    return {'total_products': 1};
  }

  @override
  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    return const [];
  }

  @override
  Future<bool> isInventoryServiceAvailable() async {
    availabilityCalls++;
    return true;
  }

  @override
  Future<MgwsReconcileResult> reconcileStock({
    required int productId,
    required int correctStock,
    required String reason,
  }) async {
    reconcileCalls++;
    return MgwsReconcileResult.fromResponse({
      'success': true,
      'product_id': productId,
      'previous_stock': 4,
      'current_stock': correctStock,
      'delta': correctStock - 4,
      'message': reason,
    });
  }

  @override
  Future<MgwsRfidScanResult> resolveRfidScan({
    required List<String> tagIds,
  }) async {
    rfidCalls++;
    return MgwsRfidScanResult.fromResponse({
      'success': true,
      'mode': 'resolve_only',
      'resolved': [
        {'tag': tagIds.first, 'product_id': 101, 'sku': 'MGWS-101'},
      ],
      'unresolved': tagIds.skip(1).toList(),
      'stock_updates': 0,
      'movement_count': 0,
    });
  }

  @override
  Future<MgwsStockSyncResult> syncWooStockToMgws({
    required int productId,
    required int wooStock,
    required String syncType,
  }) async {
    syncCalls++;
    stockMutationCalls++;
    return MgwsStockSyncResult.fromResponse({
      'success': true,
      'product_id': productId,
      'previous_stock': 5,
      'current_stock': wooStock,
      'delta': wooStock - 5,
      'message': syncType,
    });
  }
}

void main() {
  group('MGWS inventory controller', () {
    test('validates numeric sync inputs before calling MGWS', () async {
      final gateway = _FakeInventoryGateway();
      final controller = InventoryController(gateway: gateway);

      final feedback = await controller.syncWooToMgws(
        productIdText: 'abc',
        wooStockText: '7',
      );

      expect(feedback.success, isFalse);
      expect(feedback.message, contains('product_id'));
      expect(gateway.syncCalls, 0);
    });

    test('requires reconcile reason and exposes stock delta', () async {
      final gateway = _FakeInventoryGateway();
      final controller = InventoryController(gateway: gateway);

      final missingReason = await controller.reconcileStock(
        productIdText: '101',
        correctStockText: '9',
        reasonText: ' ',
      );
      final reconciled = await controller.reconcileStock(
        productIdText: '101',
        correctStockText: '9',
        reasonText: 'Rettifica conta fisica',
      );

      expect(missingReason.success, isFalse);
      expect(gateway.reconcileCalls, 1);
      expect(reconciled.success, isTrue);
      expect(controller.lastReconcileResult?.previousStock, 4);
      expect(controller.lastReconcileResult?.currentStock, 9);
      expect(controller.lastReconcileResult?.delta, 5);
    });

    test('resolves RFID tags without triggering stock sync mutation', () async {
      final gateway = _FakeInventoryGateway();
      final controller = InventoryController(gateway: gateway);

      final feedback = await controller.resolveRfidScan('TAG-1\nMISSING');

      expect(feedback.success, isTrue);
      expect(gateway.rfidCalls, 1);
      expect(gateway.stockMutationCalls, 0);
      expect(controller.lastRfidResult?.isResolveOnly, isTrue);
      expect(controller.lastRfidResult?.resolved.single.productId, 101);
      expect(controller.lastRfidResult?.unresolved, ['MISSING']);
    });

    test('parses RFID summary counters from nested MGWS payload', () {
      final result = MgwsRfidScanResult.fromResponse({
        'success': true,
        'mode': 'resolve_only',
        'resolved': [
          {'tag': 'TAG-1', 'product_id': 101},
        ],
        'unresolved': ['MISSING'],
        'summary': {
          'submitted': 2,
          'resolved': 1,
          'unresolved': 1,
          'stock_updates': 0,
          'movement_count': 0,
        },
      });

      expect(result.stockUpdates, 0);
      expect(result.movementCount, 0);
      expect(result.isResolveOnly, isTrue);
      expect(result.resolved.single.productId, 101);
      expect(result.unresolved, ['MISSING']);
    });

    testWidgets('inventory page opens the shell without workflow mutations', (
      tester,
    ) async {
      final gateway = _FakeInventoryGateway();
      final controller = InventoryController(gateway: gateway);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: InventoryPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('inventory-shell')), findsOneWidget);
      expect(find.text('Inventario MGWS'), findsOneWidget);
      expect(find.text('Quick Load'), findsWidgets);
      expect(find.text('Movimenti'), findsWidgets);
      expect(gateway.availabilityCalls, 1);
      expect(gateway.syncCalls, 0);
      expect(gateway.reconcileCalls, 0);
      expect(gateway.rfidCalls, 0);
    });
  });
}
