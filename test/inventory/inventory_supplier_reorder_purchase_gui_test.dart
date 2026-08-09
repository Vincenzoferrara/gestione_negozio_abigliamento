import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_purchase_orders.gui.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_reorder.gui.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_suppliers.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/reuse_class/datagridview/datagridview.gui.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

import 'support/fake_mgws_restock_gateway.dart';

void main() {
  group('InventorySupplierPanel', () {
    testWidgets(
      'lists suppliers, validates create, edits, and surfaces protected delete',
      (tester) async {
        final supplier = _supplier();
        final gateway = FakeMgwsRestockGateway()
          ..suppliersResponse = MgwsRestockResult.success([supplier])
          ..supplierResponse = MgwsRestockResult.success(supplier)
          ..deleteSupplierResponse = MgwsRestockResult.failure(
            const MgwsRestockError(
              code: 'supplier_protected',
              message: 'Fornitore protetto da ordini collegati',
              details: ['Disattiva il fornitore invece di eliminarlo.'],
            ),
          );
        final controller = InventorySupplierController(gateway: gateway);

        await _pump(tester, InventorySupplierPanel(controller: controller));

        expect(find.byType(DataGridView<MgwsSupplier>), findsOneWidget);
        expect(find.text('Fornitore Uno'), findsWidgets);

        await tester.tap(find.byKey(const ValueKey('inventory-supplier-new')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('inventory-supplier-site-field')),
          '0',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('inventory-supplier-save')),
        );
        await tester.tap(find.byKey(const ValueKey('inventory-supplier-save')));
        await tester.pumpAndSettle();
        expect(find.text('site_id non valido'), findsOneWidget);
        expect(gateway.createSupplierCalls, 0);

        await tester.enterText(
          find.byKey(const ValueKey('inventory-supplier-site-field')),
          '2',
        );
        await tester.enterText(
          find.byKey(const ValueKey('inventory-supplier-code-field')),
          'SUP-2',
        );
        await tester.enterText(
          find.byKey(const ValueKey('inventory-supplier-name-field')),
          'Nuovo fornitore',
        );
        await tester.tap(find.byKey(const ValueKey('inventory-supplier-save')));
        await tester.pumpAndSettle();

        expect(gateway.createSupplierCalls, 1);
        expect(gateway.stockWorkflowCalls, 0);

        await tester.ensureVisible(find.text('Fornitore Uno').first);
        await tester.tap(find.text('Fornitore Uno').first);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('inventory-supplier-name-field')),
              )
              .controller
              ?.text,
          'Fornitore Uno',
        );

        await tester.enterText(
          find.byKey(const ValueKey('inventory-supplier-name-field')),
          'Fornitore Uno aggiornato',
        );
        await tester.tap(find.byKey(const ValueKey('inventory-supplier-save')));
        await tester.pumpAndSettle();
        expect(gateway.updateSupplierCalls, 1);
        expect(gateway.supplierPatch?.name, 'Fornitore Uno aggiornato');

        await tester.tap(
          find.byKey(const ValueKey('inventory-supplier-delete')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('inventory-supplier-delete-confirm')),
        );
        await tester.pumpAndSettle();

        expect(gateway.deleteSupplierCalls, 1);
        expect(
          find.text('Fornitore protetto da ordini collegati'),
          findsOneWidget,
        );
        expect(
          find.text('Disattiva il fornitore invece di eliminarlo.'),
          findsOneWidget,
        );
        expect(gateway.stockWorkflowCalls, 0);
      },
    );
  });

  group('InventoryReorderPanel', () {
    testWidgets('renders suggestions and creates a draft purchase order', (
      tester,
    ) async {
      final order = _purchaseOrder(lines: const []);
      final gateway = FakeMgwsRestockGateway()
        ..reorderSuggestionsResponse = MgwsRestockResult.success([
          _suggestion(),
        ])
        ..purchaseOrderResponse = MgwsRestockResult.success(order)
        ..purchaseOrderLineResponse = MgwsRestockResult.success(_line());
      final controller = InventoryReorderController(gateway: gateway);

      await _pump(tester, InventoryReorderPanel(controller: controller));

      expect(find.byType(DataGridView<MgwsReorderSuggestion>), findsOneWidget);
      expect(find.textContaining('Prodotto #101'), findsOneWidget);
      expect(find.textContaining('Variante 202'), findsOneWidget);

      await tester.tap(find.textContaining('Prodotto #101'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('inventory-reorder-create-draft')),
      );
      await tester.pumpAndSettle();

      expect(gateway.createPurchaseOrderCalls, 1);
      expect(gateway.savePurchaseOrderLineCalls, 1);
      expect(gateway.purchaseOrderInput?.supplierId, 77);
      expect(gateway.purchaseOrderLineInput?.variationId, 202);
      expect(gateway.purchaseOrderLineInput?.orderedQuantity, 12);
      expect(gateway.stockWorkflowCalls, 0);
    });

    testWidgets('shows malformed backend payload errors without mutations', (
      tester,
    ) async {
      final gateway = FakeMgwsRestockGateway()
        ..reorderSuggestionsResponse = MgwsRestockResult.failure(
          const MgwsRestockError(
            code: 'mgws_malformed_payload',
            message: 'Payload riordino non valido',
            details: ['Campo suggested_qty mancante.'],
          ),
        );
      final controller = InventoryReorderController(gateway: gateway);

      await _pump(tester, InventoryReorderPanel(controller: controller));

      expect(find.text('Payload riordino non valido'), findsOneWidget);
      expect(find.text('Campo suggested_qty mancante.'), findsOneWidget);
      expect(gateway.createPurchaseOrderCalls, 0);
      expect(gateway.stockWorkflowCalls, 0);
    });
  });

  group('InventoryPurchaseOrderPanel', () {
    testWidgets('loads orders, edits draft header, line, and cancel status', (
      tester,
    ) async {
      final order = _purchaseOrder(lines: [_line()]);
      final gateway = FakeMgwsRestockGateway()
        ..purchaseOrdersResponse = MgwsRestockResult.success([order])
        ..purchaseOrderResponse = MgwsRestockResult.success(order)
        ..purchaseOrderLineResponse = MgwsRestockResult.success(_line());
      final controller = InventoryPurchaseOrderController(gateway: gateway);

      await _pump(tester, InventoryPurchaseOrderPanel(controller: controller));

      expect(find.byType(DataGridView<MgwsPurchaseOrder>), findsOneWidget);
      expect(find.text('PO-1'), findsWidgets);
      expect(find.text('draft'), findsWidgets);
      expect(find.text('Prodotto #101 / Variante 202'), findsOneWidget);

      await tester.tap(find.text('PO-1').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('inventory-po-document-field')),
        'PO-2',
      );
      await tester.tap(find.byKey(const ValueKey('inventory-po-update-save')));
      await tester.pumpAndSettle();
      expect(gateway.updatePurchaseOrderCalls, 1);
      expect(gateway.purchaseOrderPatch?.documentNumber, 'PO-2');

      await tester.enterText(
        find.byKey(const ValueKey('inventory-po-line-quantity-field')),
        '6',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('inventory-po-line-save')),
      );
      await tester.tap(find.byKey(const ValueKey('inventory-po-line-save')));
      await tester.pumpAndSettle();
      expect(gateway.savePurchaseOrderLineCalls, 1);
      expect(gateway.purchaseOrderLineInput?.orderedQuantity, 6);

      await tester.tap(
        find.byKey(const ValueKey('inventory-po-status-cancel')),
      );
      await tester.pumpAndSettle();
      expect(gateway.updatePurchaseOrderStatusCalls, 1);
      expect(gateway.purchaseOrderStatus, 'cancelled');
      expect(gateway.stockWorkflowCalls, 0);
    });
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
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

MgwsSupplier _supplier() {
  return const MgwsSupplier(
    id: 9,
    siteId: 2,
    supplierCode: 'SUP-1',
    name: 'Fornitore Uno',
    taxId: 'IT123',
    email: 'supplier@example.test',
    phone: '011',
    active: true,
    notes: 'Preferito',
    createdAtGmt: '2026-01-01T00:00:00Z',
    updatedAtGmt: '2026-01-02T00:00:00Z',
  );
}

MgwsReorderSuggestion _suggestion() {
  return const MgwsReorderSuggestion(
    ruleId: 5,
    siteId: 2,
    warehouseId: 3,
    supplierId: 77,
    productId: 101,
    variationId: 202,
    currentStock: 1,
    reorderPoint: 4,
    targetStock: 13,
    reorderQuantity: 12,
    suggestedQuantity: 12,
    leadTimeDays: 7,
    safetyDays: 2,
  );
}

MgwsPurchaseOrder _purchaseOrder({required List<MgwsPurchaseOrderLine> lines}) {
  return MgwsPurchaseOrder(
    id: 44,
    siteId: 2,
    warehouseId: 3,
    supplierId: 77,
    documentNumber: 'PO-1',
    status: 'draft',
    orderedAtGmt: null,
    expectedAtGmt: '2026-02-01T00:00:00Z',
    currency: 'EUR',
    notes: 'Bozza',
    createdByUserId: 1,
    updatedByUserId: 1,
    createdAtGmt: '2026-01-01T00:00:00Z',
    updatedAtGmt: '2026-01-02T00:00:00Z',
    lines: lines,
  );
}

MgwsPurchaseOrderLine _line() {
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
