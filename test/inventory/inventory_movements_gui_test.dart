import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_movements.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

import 'support/fake_mgws_restock_gateway.dart';

void main() {
  testWidgets('filters ledger rows and keeps the panel read-only', (
    tester,
  ) async {
    final gateway = configuredMovementGateway([
      movement(sourceType: 'receipt'),
    ]);
    final controller = InventoryMovementController(gateway: gateway);

    await _pumpLedger(tester, controller: controller);
    await tester.enterText(
      find.byKey(const ValueKey('inventory-movement-product-field')),
      '101',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-movement-variation-field')),
      '202',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-movement-from-field')),
      '2026-08-01',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-movement-source-field')),
      'receipt',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-movement-operator-field')),
      '42',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-movement-reason-field')),
      'receiving',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-movement-effect-field')),
      'increase',
    );
    await tester.tap(find.byKey(const ValueKey('inventory-movement-refresh')));
    await tester.pumpAndSettle();

    expect(gateway.listMovementsCalls, 2);
    expect(gateway.movementFilter?.productId, 101);
    expect(gateway.movementFilter?.variationId, 202);
    expect(gateway.movementFilter?.sourceType, 'receipt');
    expect(gateway.movementFilter?.operatorUserId, 42);
    expect(gateway.movementFilter?.reasonCode, 'receiving');
    expect(gateway.movementFilter?.stockEffect, 'increase');
    expect(gateway.stockWorkflowCalls, 0);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('shows detail audit fields and source document links', (
    tester,
  ) async {
    final gateway = configuredMovementGateway([
      movement(
        sourceType: 'count_session',
        sourceLinks: const {'count_session_id': 31, 'source_session_id': 7001},
      ),
    ]);

    await _pumpLedger(
      tester,
      controller: InventoryMovementController(gateway: gateway),
    );
    await tester.tap(find.textContaining('Prodotto #101').first);
    await tester.pumpAndSettle();

    expect(find.text('Dettaglio movimento #501'), findsOneWidget);
    expect(find.text('Before 8'), findsOneWidget);
    expect(find.text('After 13'), findsOneWidget);
    expect(find.text('Delta +5'), findsOneWidget);
    expect(find.text('Origine count_session #88'), findsOneWidget);
    expect(find.text('Riga origine #90'), findsOneWidget);
    expect(find.text('count_session_id #31'), findsOneWidget);
    expect(find.text('source_session_id #7001'), findsOneWidget);
    expect(find.text('Motivo: receiving'), findsOneWidget);
  });

  testWidgets('shows loading and empty states', (tester) async {
    final gateway = configuredMovementGateway([]);

    await _pumpLedger(
      tester,
      controller: InventoryMovementController(gateway: gateway),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(
      find.text('Nessun movimento stock MGWS trovato per i filtri.'),
      findsOneWidget,
    );
  });

  testWidgets('surfaces malformed movement payload and backend errors', (
    tester,
  ) async {
    final gateway = FakeMgwsRestockGateway()
      ..movementsResponse = MgwsRestockResult.failure(
        const MgwsRestockError(
          code: 'mgws_malformed_payload',
          message: 'Payload movimenti non valido',
          details: ['Campo source.links non valido'],
        ),
      );

    await _pumpLedger(
      tester,
      controller: InventoryMovementController(gateway: gateway),
    );

    expect(find.text('Payload movimenti non valido'), findsOneWidget);
    expect(find.text('Campo source.links non valido'), findsOneWidget);
    expect(gateway.stockWorkflowCalls, 0);
  });
}

Future<void> _pumpLedger(
  WidgetTester tester, {
  required InventoryMovementController controller,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 900,
          child: InventoryMovementLedgerPanel(controller: controller),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

FakeMgwsRestockGateway configuredMovementGateway(List<MgwsMovement> movements) {
  return FakeMgwsRestockGateway()
    ..movementsResponse = MgwsRestockResult.success(
      MgwsMovementPage(
        items: movements,
        page: 1,
        perPage: 50,
        total: movements.length,
        totalPages: movements.isEmpty ? 0 : 1,
      ),
    );
}

MgwsMovement movement({
  required String sourceType,
  Map<String, int> sourceLinks = const {'receipt_id': 88, 'document_id': 44},
}) {
  return MgwsMovement(
    id: 501,
    occurredAtGmt: '2026-08-02T10:15:00Z',
    type: 'stock_movement',
    stockEffect: 'increase',
    productId: 101,
    variationId: 202,
    quantityDelta: 5,
    stockBefore: 8,
    stockAfter: 13,
    location: const MgwsLocation(
      siteId: 2,
      warehouseId: 3,
      room: 'A',
      rack: 'R1',
      shelf: 'S2',
    ),
    operatorUserId: 42,
    reasonCode: 'receiving',
    note: 'DDT convalidato',
    sourceType: sourceType,
    sourceId: 88,
    sourceLineId: 90,
    sourceLinks: sourceLinks,
  );
}
