import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';

import 'support/fake_mgws_restock_gateway.dart';

void main() {
  group('InventorySupplierController', () {
    test('validates supplier CRUD inputs before gateway calls', () async {
      final gateway = FakeMgwsRestockGateway();
      final controller = InventorySupplierController(gateway: gateway);

      final invalidCreate = await controller.create(
        const InventorySupplierForm(
          siteIdText: '0',
          supplierCodeText: 'SUP-1',
          nameText: 'Fornitore',
        ),
      );
      final invalidUpdate = await controller.update(
        supplierIdText: 'invalid',
        form: const InventorySupplierForm(
          siteIdText: '1',
          supplierCodeText: 'SUP-1',
          nameText: 'Fornitore',
        ),
      );
      final invalidDelete = await controller.delete(' ');

      expect(invalidCreate.success, isFalse);
      expect(invalidUpdate.success, isFalse);
      expect(invalidDelete.success, isFalse);
      expect(gateway.createSupplierCalls, 0);
      expect(gateway.updateSupplierCalls, 0);
      expect(gateway.deleteSupplierCalls, 0);
    });

    test(
      'sends valid supplier CRUD actions without stock workflow calls',
      () async {
        final gateway = FakeMgwsRestockGateway();
        final controller = InventorySupplierController(gateway: gateway);
        const form = InventorySupplierForm(
          siteIdText: '2',
          supplierCodeText: 'SUP-1',
          nameText: 'Fornitore Uno',
        );

        await controller.create(form);
        await controller.update(supplierIdText: '9', form: form);
        await controller.delete('9');

        expect(gateway.createSupplierCalls, 1);
        expect(gateway.updateSupplierCalls, 1);
        expect(gateway.deleteSupplierCalls, 1);
        expect(gateway.supplierInput?.siteId, 2);
        expect(gateway.supplierPatch?.name, 'Fornitore Uno');
        expect(gateway.stockWorkflowCalls, 0);
      },
    );
  });

  group('InventoryPurchaseOrderController', () {
    test(
      'calls draft, line, and status endpoints without stock mutation',
      () async {
        final gateway = FakeMgwsRestockGateway();
        final controller = InventoryPurchaseOrderController(gateway: gateway);

        await controller.createDraft(
          const InventoryPurchaseOrderForm(
            siteIdText: '2',
            supplierIdText: '9',
            documentNumberText: 'PO-2026-01',
            warehouseIdText: '5',
          ),
        );
        await controller.saveLine(
          const InventoryPurchaseOrderLineForm(
            purchaseOrderIdText: '12',
            productIdText: '7',
            orderedQuantityText: '3',
            unitCostText: '12.50',
          ),
        );
        await controller.updateStatus(
          const InventoryPurchaseOrderStatusForm(
            purchaseOrderIdText: '12',
            statusText: 'ordered',
          ),
        );

        expect(gateway.createPurchaseOrderCalls, 1);
        expect(gateway.savePurchaseOrderLineCalls, 1);
        expect(gateway.updatePurchaseOrderStatusCalls, 1);
        expect(gateway.purchaseOrderInput?.documentNumber, 'PO-2026-01');
        expect(gateway.purchaseOrderLineInput?.orderedQuantity, 3);
        expect(gateway.purchaseOrderStatus, 'ordered');
        expect(gateway.stockWorkflowCalls, 0);
      },
    );
  });
}
