import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory.gui.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_receipts.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

import 'support/fake_mgws_restock_gateway.dart';

void main() {
  group('InventoryReceiptPanel', () {
    testWidgets('mounts as the real Ricezione/Convalida shell tab', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = _configuredGateway();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: InventoryPage(
            controller: InventoryController(
              gateway: _InventoryReadinessGateway(),
            ),
            purchaseOrderController: InventoryPurchaseOrderController(
              gateway: gateway,
            ),
            receiptController: InventoryReceiptController(gateway: gateway),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Ricezione/Convalida'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('inventory-receipt-panel')),
        findsOneWidget,
      );
      expect(find.text('Ricezione / Convalida'), findsOneWidget);
    });

    testWidgets('shows loading then empty states without stock mutation', (
      tester,
    ) async {
      final gateway = FakeMgwsRestockGateway()
        ..purchaseOrdersResponse = MgwsRestockResult.success([])
        ..receiptsResponse = MgwsRestockResult.success([]);

      await _pumpReceipt(tester, gateway: gateway, settle: false);

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle();

      expect(
        find.text('Nessun ordine fornitore disponibile per ricezione.'),
        findsOneWidget,
      );
      expect(find.text('Nessuna ricezione MGWS trovata.'), findsOneWidget);
      expect(gateway.createReceiptCalls, 0);
      expect(gateway.convalidaReceiptCalls, 0);
    });

    testWidgets('resolves a line from scan before creating a full receipt', (
      tester,
    ) async {
      final gateway = _configuredGateway();

      await _pumpReceipt(tester, gateway: gateway);
      await tester.enterText(
        find.byKey(const ValueKey('inventory-receipt-scan-field')),
        'BAR-101',
      );
      await tester.tap(
        find.byKey(const ValueKey('inventory-receipt-scan-resolve')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Riga ordine risolta da scan'), findsOneWidget);
      expect(gateway.createReceiptCalls, 0);
      expect(gateway.convalidaReceiptCalls, 0);

      await tester.ensureVisible(
        find.byKey(const ValueKey('inventory-receipt-create')),
      );
      await tester.tap(find.byKey(const ValueKey('inventory-receipt-create')));
      await tester.pumpAndSettle();

      expect(gateway.createReceiptCalls, 1);
      expect(gateway.convalidaReceiptCalls, 0);
      expect(gateway.receiptInput?.lines.single.receivedQuantity, 12);
      expect(gateway.receiptInput?.idempotencyKey, 'receipt-44-PO-1');
      expect(find.textContaining('Convalida/post summary'), findsWidgets);
    });

    testWidgets('records partial receive with backorder and reason', (
      tester,
    ) async {
      final gateway = _configuredGateway();
      await _pumpReceipt(tester, gateway: gateway);

      await tester.enterText(
        find.byKey(const ValueKey('inventory-receipt-received-field')),
        '8',
      );
      await tester.enterText(
        find.byKey(const ValueKey('inventory-receipt-backorder-field')),
        '4',
      );
      await tester.enterText(
        find.byKey(const ValueKey('inventory-receipt-reason-field')),
        'Consegna parziale fornitore',
      );
      await tester.tap(find.byKey(const ValueKey('inventory-receipt-create')));
      await tester.pumpAndSettle();

      final line = gateway.receiptInput?.lines.single;
      expect(line?.expectedQuantity, 12);
      expect(line?.receivedQuantity, 8);
      expect(line?.backorderQuantity, 4);
      expect(line?.reasonCode, 'Consegna parziale fornitore');
      expect(gateway.convalidaReceiptCalls, 0);
    });

    testWidgets('sends QC hold reason through the receipt line', (
      tester,
    ) async {
      final gateway = _configuredGateway();
      await _pumpReceipt(tester, gateway: gateway);

      await tester.tap(
        find.byKey(const ValueKey('inventory-receipt-qc-hold-field')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('inventory-receipt-reason-field')),
        'QC: cuciture da controllare',
      );
      await tester.tap(find.byKey(const ValueKey('inventory-receipt-create')));
      await tester.pumpAndSettle();

      expect(
        gateway.receiptInput?.lines.single.reasonCode,
        'QC: cuciture da controllare',
      );
      expect(gateway.createReceiptCalls, 1);
    });

    testWidgets('blocks over-receive without calling MGWS', (tester) async {
      final gateway = _configuredGateway();
      await _pumpReceipt(tester, gateway: gateway);

      await tester.enterText(
        find.byKey(const ValueKey('inventory-receipt-received-field')),
        '13',
      );
      await tester.tap(find.byKey(const ValueKey('inventory-receipt-create')));
      await tester.pumpAndSettle();

      expect(
        find.text('over-ricezione non consentita senza approvazione MGWS'),
        findsOneWidget,
      );
      expect(gateway.createReceiptCalls, 0);
      expect(gateway.convalidaReceiptCalls, 0);
    });

    testWidgets('surfaces duplicate idempotency responses', (tester) async {
      final gateway = _configuredGateway(
        receiptMessage: 'Ricezione gia registrata da idempotency key',
      );
      await _pumpReceipt(tester, gateway: gateway);

      await tester.enterText(
        find.byKey(const ValueKey('inventory-receipt-idempotency-field')),
        'same-idempotency-key',
      );
      await tester.tap(find.byKey(const ValueKey('inventory-receipt-create')));
      await tester.pumpAndSettle();

      expect(
        find.text('Ricezione gia registrata da idempotency key'),
        findsOneWidget,
      );
      expect(gateway.receiptInput?.idempotencyKey, 'same-idempotency-key');
      expect(gateway.createReceiptCalls, 1);
    });

    testWidgets(
      'surfaces backend permission errors and malformed load payloads',
      (tester) async {
        final gateway = _configuredGateway(
          receiptResponse: MgwsRestockResult.failure(
            const MgwsRestockError(
              code: 'mgws_forbidden',
              message: 'Permesso MGWS mancante',
              details: ['Capability manage_mgws_inventory richiesta'],
            ),
          ),
          receiptsResponse: MgwsRestockResult.failure(
            const MgwsRestockError(
              code: 'mgws_malformed_payload',
              message: 'Payload ricezioni non valido',
              details: ['Campo lines non valido'],
            ),
          ),
        );
        await _pumpReceipt(tester, gateway: gateway);

        expect(find.text('Payload ricezioni non valido'), findsOneWidget);
        expect(find.text('Campo lines non valido'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('inventory-receipt-create')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Permesso MGWS mancante'), findsOneWidget);
        expect(
          find.text('Capability manage_mgws_inventory richiesta'),
          findsOneWidget,
        );
        expect(gateway.convalidaReceiptCalls, 0);
      },
    );

    testWidgets('posts stock only through convalida after receipt creation', (
      tester,
    ) async {
      final gateway = _configuredGateway();
      await _pumpReceipt(tester, gateway: gateway);

      await tester.tap(find.byKey(const ValueKey('inventory-receipt-create')));
      await tester.pumpAndSettle();

      expect(gateway.createReceiptCalls, 1);
      expect(gateway.convalidaReceiptCalls, 0);

      await tester.tap(
        find.byKey(const ValueKey('inventory-receipt-convalida')),
      );
      await tester.pumpAndSettle();

      expect(gateway.convalidaReceiptCalls, 1);
      expect(gateway.receiptId, 88);
    });
  });
}

Future<void> _pumpReceipt(
  WidgetTester tester, {
  required FakeMgwsRestockGateway gateway,
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
          child: InventoryReceiptPanel(
            controller: InventoryReceiptController(gateway: gateway),
            purchaseOrderController: InventoryPurchaseOrderController(
              gateway: gateway,
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

FakeMgwsRestockGateway _configuredGateway({
  String receiptMessage = 'Operazione MGWS completata',
  MgwsRestockResult<MgwsReceipt>? receiptResponse,
  MgwsRestockResult<List<MgwsReceipt>>? receiptsResponse,
}) {
  final receipt = _receipt(status: 'draft');
  return FakeMgwsRestockGateway()
    ..purchaseOrdersResponse = MgwsRestockResult.success([
      _purchaseOrder(lines: [_purchaseOrderLine()]),
    ])
    ..receiptsResponse = receiptsResponse ?? MgwsRestockResult.success([])
    ..receiptResponse =
        receiptResponse ??
        MgwsRestockResult.success(receipt, message: receiptMessage);
}

MgwsPurchaseOrder _purchaseOrder({required List<MgwsPurchaseOrderLine> lines}) {
  return MgwsPurchaseOrder(
    id: 44,
    siteId: 2,
    warehouseId: 3,
    supplierId: 77,
    documentNumber: 'PO-1',
    status: 'ordered',
    orderedAtGmt: '2026-01-03T00:00:00Z',
    expectedAtGmt: '2026-02-01T00:00:00Z',
    currency: 'EUR',
    notes: 'Ordine pronto',
    createdByUserId: 1,
    updatedByUserId: 1,
    createdAtGmt: '2026-01-01T00:00:00Z',
    updatedAtGmt: '2026-01-02T00:00:00Z',
    lines: lines,
  );
}

MgwsPurchaseOrderLine _purchaseOrderLine() {
  return const MgwsPurchaseOrderLine(
    id: 45,
    purchaseOrderId: 44,
    lineNumber: 1,
    productId: 101,
    variationId: 202,
    orderedQuantity: 12,
    receivedQuantity: 0,
    cancelledQuantity: 0,
    unitCost: '9.90',
    supplierSku: 'SUP-SKU',
    barcode: 'BAR-101',
    expectedAtGmt: '2026-02-01T00:00:00Z',
    stockEffect: 'none_until_receipt',
    createdAtGmt: '2026-01-01T00:00:00Z',
    updatedAtGmt: '2026-01-02T00:00:00Z',
  );
}

MgwsReceipt _receipt({required String status}) {
  return MgwsReceipt(
    id: 88,
    siteId: 2,
    warehouseId: 3,
    purchaseOrderId: 44,
    supplierId: 77,
    documentNumber: 'DDT-PO-1',
    status: status,
    receivedAtGmt: '2026-02-01T08:00:00Z',
    validatedAtGmt: status == 'posted' ? '2026-02-01T09:00:00Z' : null,
    postedAtGmt: status == 'posted' ? '2026-02-01T09:00:00Z' : null,
    validatedByUserId: status == 'posted' ? 1 : 0,
    postedByUserId: status == 'posted' ? 1 : 0,
    notes: 'Ricezione test',
    createdAtGmt: '2026-02-01T08:00:00Z',
    updatedAtGmt: '2026-02-01T08:00:00Z',
    lines: [_receiptLine()],
  );
}

MgwsReceiptLine _receiptLine() {
  return const MgwsReceiptLine(
    id: 90,
    receiptId: 88,
    lineNumber: 1,
    purchaseOrderLineId: 45,
    productId: 101,
    variationId: 202,
    expectedQuantity: 12,
    receivedQuantity: 12,
    rejectedQuantity: 0,
    backorderQuantity: 0,
    unitCost: '9.90',
    stockEffect: 'pending_until_convalida',
    reasonCode: '',
    createdAtGmt: '2026-02-01T08:00:00Z',
    updatedAtGmt: '2026-02-01T08:00:00Z',
  );
}

class _InventoryReadinessGateway implements MgwsInventoryGateway {
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
