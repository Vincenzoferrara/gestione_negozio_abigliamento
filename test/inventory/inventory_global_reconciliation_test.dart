import 'package:flutter_test/flutter_test.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_global.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';

class _MutationRejectingMgwsGateway implements MgwsInventoryGateway {
  var reconcileCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> getAllStock() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getLowStockItems() async => const [];

  @override
  Future<Map<String, dynamic>> getProductStock(int productId) async => const {};

  @override
  Future<Map<String, dynamic>> getStatistics() async => const {};

  @override
  Future<bool> isInventoryServiceAvailable() async => true;

  @override
  Future<MgwsReconcileResult> reconcileStock({
    required int productId,
    required int correctStock,
    required String reason,
  }) async {
    reconcileCalls++;
    throw StateError(
      'MGWS correction must not be called during reconciliation',
    );
  }

  @override
  Future<MgwsRfidScanResult> resolveRfidScan({
    required List<String> tagIds,
  }) async => throw UnimplementedError();

  @override
  Future<MgwsStockSyncResult> syncWooStockToMgws({
    required int productId,
    required int wooStock,
    required String syncType,
  }) async => throw UnimplementedError();
}

class _MutationRejectingWooStockGateway implements WooStockGateway {
  var updateCalls = 0;

  @override
  Future<void> updateProductStock({
    required int productId,
    required int stockQuantity,
    required String stockStatus,
  }) async {
    updateCalls++;
    throw StateError('Woo correction must not be called during reconciliation');
  }
}

UnifiedInventoryItem _discrepancy({
  required int productId,
  required String type,
}) {
  return UnifiedInventoryItem(
    productId: productId,
    productName: 'Product $productId',
    wooStock: type == 'woo_higher' ? 8 : 3,
    mgwsStock: type == 'woo_higher' ? 3 : 8,
    stockStatus: 'instock',
    hasDiscrepancy: true,
    discrepancyType: type,
  );
}

void main() {
  group('InventoryGlobal reconciliation', () {
    test(
      'reports requested corrections as proposals without mutating stock',
      () async {
        final mgwsGateway = _MutationRejectingMgwsGateway();
        final wooGateway = _MutationRejectingWooStockGateway();
        final inventory = InventoryGlobal.withDependencies(
          mgwsInventory: mgwsGateway,
          wooStockGateway: wooGateway,
          unifiedInventoryLoader: () async => [
            _discrepancy(productId: 101, type: 'woo_higher'),
            _discrepancy(productId: 202, type: 'mgws_higher'),
          ],
        );

        final result = await inventory.reconcileInventory(
          fixDiscrepancies: true,
        );

        expect(result.success, isTrue);
        expect(result.syncedProducts, 0);
        expect(result.errors, isEmpty);
        expect(result.message, contains('proposals'));
        expect(result.message, contains('No stock was changed'));
        expect(result.details?['mode'], 'proposal_only');
        expect(result.details?['requested_correction'], isTrue);
        expect(result.details?['proposals'], hasLength(2));
        expect(mgwsGateway.reconcileCalls, 0);
        expect(wooGateway.updateCalls, 0);
      },
    );

    test(
      'reports discrepancies during the normal read-only comparison',
      () async {
        final mgwsGateway = _MutationRejectingMgwsGateway();
        final wooGateway = _MutationRejectingWooStockGateway();
        final inventory = InventoryGlobal.withDependencies(
          mgwsInventory: mgwsGateway,
          wooStockGateway: wooGateway,
          unifiedInventoryLoader: () async => [
            _discrepancy(productId: 101, type: 'woo_higher'),
          ],
        );

        final result = await inventory.reconcileInventory();

        expect(result.success, isTrue);
        expect(result.errors, isEmpty);
        expect(result.message, contains('1 discrepancy found'));
        expect(result.details?['requested_correction'], isFalse);
        expect(result.details?['proposals'], hasLength(1));
        expect(mgwsGateway.reconcileCalls, 0);
        expect(wooGateway.updateCalls, 0);
      },
    );

    test(
      'returns comparison-load errors without attempting corrections',
      () async {
        final mgwsGateway = _MutationRejectingMgwsGateway();
        final wooGateway = _MutationRejectingWooStockGateway();
        final inventory = InventoryGlobal.withDependencies(
          mgwsInventory: mgwsGateway,
          wooStockGateway: wooGateway,
          unifiedInventoryLoader: () async =>
              throw StateError('not authorized'),
        );

        final result = await inventory.reconcileInventory(
          fixDiscrepancies: true,
        );

        expect(result.success, isFalse);
        expect(result.errors.single, contains('not authorized'));
        expect(mgwsGateway.reconcileCalls, 0);
        expect(wooGateway.updateCalls, 0);
      },
    );
  });
}
