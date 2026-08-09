import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';

import 'support/fake_mgws_restock_gateway.dart';

void main() {
  group('InventoryQuickLoadController', () {
    test('does not call MGWS for an invalid product', () async {
      final gateway = FakeMgwsRestockGateway();
      final controller = InventoryQuickLoadController(gateway: gateway);

      final feedback = await controller.submit(
        const InventoryQuickLoadForm(
          productIdText: 'invalid',
          quantityText: '3',
          reasonText: 'Carico scaffale',
        ),
      );

      expect(feedback.success, isFalse);
      expect(feedback.message, 'product_id non valido');
      expect(gateway.quickLoadCalls, 0);
    });

    test('does not call MGWS for an invalid quantity', () async {
      final gateway = FakeMgwsRestockGateway();
      final controller = InventoryQuickLoadController(gateway: gateway);

      final feedback = await controller.submit(
        const InventoryQuickLoadForm(
          productIdText: '7',
          quantityText: '0',
          reasonText: 'Carico scaffale',
        ),
      );

      expect(feedback.success, isFalse);
      expect(feedback.message, 'quantita non valida');
      expect(gateway.quickLoadCalls, 0);
    });

    test('does not call MGWS for a blank reason', () async {
      final gateway = FakeMgwsRestockGateway();
      final controller = InventoryQuickLoadController(gateway: gateway);

      final feedback = await controller.submit(
        const InventoryQuickLoadForm(
          productIdText: '7',
          quantityText: '3',
          reasonText: ' ',
        ),
      );

      expect(feedback.success, isFalse);
      expect(feedback.message, 'reason richiesto');
      expect(gateway.quickLoadCalls, 0);
    });

    test('constructs a typed request and calls quickLoad once', () async {
      final gateway = FakeMgwsRestockGateway()
        ..quickLoadResponse = MgwsRestockResult.success(_quickLoad());
      final controller = InventoryQuickLoadController(gateway: gateway);

      final feedback = await controller.submit(
        const InventoryQuickLoadForm(
          productIdText: '7',
          variationIdText: '4',
          quantityText: '3',
          reasonText: 'Carico fornitore',
          noteText: 'DDT 12',
          warehouseIdText: '5',
        ),
      );

      expect(feedback.success, isTrue);
      expect(gateway.quickLoadCalls, 1);
      expect(gateway.quickLoadRequest?.productId, 7);
      expect(gateway.quickLoadRequest?.variationId, 4);
      expect(gateway.quickLoadRequest?.quantityDelta, 3);
      expect(gateway.quickLoadRequest?.reason, 'Carico fornitore');
      expect(gateway.quickLoadRequest?.warehouseId, 5);
      expect(controller.lastQuickLoad?.movementId, 88);
    });

    test(
      'blocks a duplicate quick-load submit while the first is pending',
      () async {
        final gateway = FakeMgwsRestockGateway();
        final pending = Completer<MgwsRestockResult<MgwsQuickLoad>>();
        gateway.onQuickLoad = (_) => pending.future;
        final controller = InventoryQuickLoadController(gateway: gateway);
        const form = InventoryQuickLoadForm(
          productIdText: '7',
          quantityText: '3',
          reasonText: 'Carico scaffale',
        );

        final first = controller.submit(form);
        final duplicate = await controller.submit(form);

        expect(duplicate.success, isFalse);
        expect(duplicate.message, 'Carico rapido gia in corso');
        expect(gateway.quickLoadCalls, 1);
        expect(gateway.stockWorkflowCalls, 1);

        pending.complete(MgwsRestockResult.success(_quickLoad()));
        await first;
      },
    );

    test(
      'surfaces quick-load conflict details without a second mutation call',
      () async {
        final gateway = FakeMgwsRestockGateway()
          ..quickLoadResponse = MgwsRestockResult.failure(
            const MgwsRestockError(
              code: 'mgws_conflict',
              message: 'Operazione rifiutata',
              details: ['stock changed'],
            ),
          );
        final controller = InventoryQuickLoadController(gateway: gateway);

        final feedback = await controller.submit(
          const InventoryQuickLoadForm(
            productIdText: '7',
            quantityText: '3',
            reasonText: 'Carico scaffale',
          ),
        );

        expect(feedback.success, isFalse);
        expect(feedback.details, ['stock changed']);
        expect(gateway.quickLoadCalls, 1);
        expect(gateway.stockWorkflowCalls, 1);
      },
    );
  });
}

MgwsQuickLoad _quickLoad() {
  return const MgwsQuickLoad(
    productId: 7,
    variationId: 4,
    quantityDelta: 3,
    previousStock: 4,
    currentStock: 7,
    reason: 'Carico fornitore',
    movementId: 88,
    location: MgwsLocation(
      siteId: 2,
      warehouseId: 5,
      room: 'A',
      rack: '1',
      shelf: '2',
    ),
  );
}
