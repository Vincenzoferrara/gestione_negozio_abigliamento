import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

import 'fake_mgws_restock_gateway.dart';

class CountGateway extends FakeMgwsRestockGateway {
  MgwsRestockResult<List<MgwsCountSession>>? countSessionsResponse;
  int listCountSessionsCalls = 0;

  @override
  Future<MgwsRestockResult<List<MgwsCountSession>>> listCountSessions({
    int? siteId,
    int? warehouseId,
  }) {
    listCountSessionsCalls++;
    return Future.value(countSessionsResponse ?? super.listCountSessions());
  }
}

class CountReadinessGateway implements MgwsInventoryGateway {
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

Future<void> pumpInventoryChild(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: SizedBox(width: 1200, height: 900, child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpCountShell(WidgetTester tester, CountGateway gateway) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: InventoryPage(
        controller: InventoryController(gateway: CountReadinessGateway()),
        countController: InventoryCountSessionController(gateway: gateway),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MgwsCountSession countSession(
  String status, {
  List<MgwsCountLine> lines = const [],
}) {
  return MgwsCountSession(
    id: 31,
    siteId: 2,
    warehouseId: 5,
    documentNumber: 'COUNT-31',
    status: status,
    startedByUserId: 4,
    approvedByUserId: status == 'posted' ? 5 : 0,
    startedAtGmt: '2026-08-01T00:00:00Z',
    approvedAtGmt: status == 'posted' ? '2026-08-02T00:00:00Z' : null,
    postedAtGmt: status == 'posted' ? '2026-08-02T00:00:00Z' : null,
    notes: 'Conta agosto',
    createdAtGmt: '2026-08-01T00:00:00Z',
    updatedAtGmt: '2026-08-01T00:00:00Z',
    lines: lines,
  );
}

MgwsCountLine countLine({int stockMoveId = 0}) {
  return MgwsCountLine(
    id: 77,
    countSessionId: 31,
    warehouseId: 5,
    productId: 101,
    variationId: 202,
    room: 'A',
    rack: 'R1',
    shelf: 'S2',
    bookQuantity: 8,
    physicalQuantity: 6,
    discrepancyQuantity: -2,
    reasonCode: 'physical_count',
    stockMoveId: stockMoveId,
    countedByUserId: 4,
    countedAtGmt: '2026-08-01T10:00:00Z',
    createdAtGmt: '2026-08-01T10:00:00Z',
    updatedAtGmt: '2026-08-01T10:00:00Z',
  );
}
