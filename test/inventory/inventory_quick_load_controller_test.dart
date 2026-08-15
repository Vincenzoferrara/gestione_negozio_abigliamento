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
      expect(feedback.message, 'quantità non valida');
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

    test('omits optional location details when they are not set', () async {
      final gateway = FakeMgwsRestockGateway()
        ..quickLoadResponse = MgwsRestockResult.success(_quickLoad());
      final controller = InventoryQuickLoadController(gateway: gateway);
      const plan = InventoryQuickLoadSubmissionPlan(
        lines: <InventoryQuickLoadLineDraft>[
          InventoryQuickLoadLineDraft(
            productId: 7,
            variationId: 0,
            label: 'Prodotto semplice',
            quantity: 1,
            idempotencyKey: 'line-7-0',
          ),
        ],
        reason: 'Carico merce',
      );

      final feedback = await controller.submitPlan(plan);

      expect(feedback.success, isTrue);
      expect(gateway.quickLoadCalls, 1);
      expect(gateway.quickLoadRequest?.warehouseId, isNull);
      expect(gateway.quickLoadRequest?.room, isNull);
      expect(gateway.quickLoadRequest?.rack, isNull);
      expect(gateway.quickLoadRequest?.shelf, isNull);
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
      'submits selected products and variants sequentially with quantities',
      () async {
        final gateway = FakeMgwsRestockGateway()
          ..quickLoadResponse = MgwsRestockResult.success(_quickLoad());
        final controller = InventoryQuickLoadController(gateway: gateway);
        final plan = InventoryQuickLoadSubmissionPlan(
          lines: const <InventoryQuickLoadLineDraft>[
            InventoryQuickLoadLineDraft(
              productId: 7,
              variationId: 0,
              label: 'Prodotto semplice',
              quantity: 2,
              rack: '2',
              shelf: '4',
              idempotencyKey: 'line-7-0',
            ),
            InventoryQuickLoadLineDraft(
              productId: 8,
              variationId: 81,
              label: 'Variante blu',
              quantity: 5,
              rack: '7',
              shelf: '9',
              idempotencyKey: 'line-8-81',
            ),
          ],
          reason: 'Carico merce',
          warehouseId: 3,
          room: 'A',
        );

        final feedback = await controller.submitPlan(plan);

        expect(feedback.success, isTrue);
        expect(gateway.quickLoadRequests, hasLength(2));
        expect(gateway.quickLoadRequests[0].quantityDelta, 2);
        expect(gateway.quickLoadRequests[0].variationId, 0);
        expect(gateway.quickLoadRequests[0].rack, '2');
        expect(gateway.quickLoadRequests[0].shelf, '4');
        expect(gateway.quickLoadRequests[1].quantityDelta, 5);
        expect(gateway.quickLoadRequests[1].variationId, 81);
        expect(gateway.quickLoadRequests[1].rack, '7');
        expect(gateway.quickLoadRequests[1].shelf, '9');
        expect(gateway.quickLoadRequests[1].warehouseId, 3);
        expect(gateway.quickLoadRequests[1].idempotencyKey, 'line-8-81');
      },
    );

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
