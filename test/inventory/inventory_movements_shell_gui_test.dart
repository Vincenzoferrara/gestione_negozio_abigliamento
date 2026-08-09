import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/reuse_class/datagridview/datagridview.gui.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

import 'inventory_movements_gui_test.dart' as movement_gui;
import 'support/fake_mgws_restock_gateway.dart';

void main() {
  testWidgets('mounts as the real Movimenti shell tab', (tester) async {
    final gateway = movement_gui.configuredMovementGateway([
      movement_gui.movement(sourceType: 'quick_load'),
    ]);

    await _pumpShell(tester, gateway: gateway);
    await tester.drag(find.byType(TabBar), const Offset(-360, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Movimenti'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('inventory-movements-panel')),
      findsOneWidget,
    );
    expect(find.text('Movimenti stock MGWS'), findsOneWidget);
    expect(find.byType(DataGridView<MgwsMovement>), findsOneWidget);
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required FakeMgwsRestockGateway gateway,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: InventoryPage(
        controller: InventoryController(gateway: _ReadinessGateway()),
        movementController: InventoryMovementController(gateway: gateway),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ReadinessGateway implements MgwsInventoryGateway {
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
  }) async =>
      const MgwsReconcileResult(success: true, message: 'ok', errors: []);

  @override
  Future<MgwsRfidScanResult> resolveRfidScan({
    required List<String> tagIds,
  }) async {
    return const MgwsRfidScanResult(
      success: true,
      message: 'ok',
      errors: [],
      resolved: [],
      unresolved: [],
      stockUpdates: 0,
      movementCount: 0,
      mode: 'resolve_only',
    );
  }

  @override
  Future<MgwsStockSyncResult> syncWooStockToMgws({
    required int productId,
    required int wooStock,
    required String syncType,
  }) async =>
      const MgwsStockSyncResult(success: true, message: 'ok', errors: []);
}
