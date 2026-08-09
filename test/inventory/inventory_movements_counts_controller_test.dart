import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';

import 'support/fake_mgws_restock_gateway.dart';

void main() {
  group('InventoryMovementController', () {
    test('parses filters and remains read-only', () async {
      final gateway = FakeMgwsRestockGateway();
      final controller = InventoryMovementController(gateway: gateway);

      await controller.load(
        const InventoryMovementFilterForm(
          productIdText: '7',
          dateFromText: '2026-08-01T00:00:00Z',
          dateToText: '2026-08-02T23:59:59Z',
          sourceTypeText: 'receipt',
          operatorUserIdText: '42',
          reasonCodeText: 'count',
          pageText: '2',
          perPageText: '100',
        ),
      );

      expect(gateway.listMovementsCalls, 1);
      expect(gateway.movementFilter?.productId, 7);
      expect(gateway.movementFilter?.sourceType, 'receipt');
      expect(gateway.movementFilter?.operatorUserId, 42);
      expect(gateway.movementFilter?.reasonCode, 'count');
      expect(gateway.movementFilter?.page, 2);
      expect(gateway.stockWorkflowCalls, 0);
    });

    test('does not query movements for an invalid date', () async {
      final gateway = FakeMgwsRestockGateway();
      final controller = InventoryMovementController(gateway: gateway);

      final feedback = await controller.load(
        const InventoryMovementFilterForm(dateFromText: 'not-a-date'),
      );

      expect(feedback.success, isFalse);
      expect(gateway.listMovementsCalls, 0);
    });
  });

  group('InventoryCountSessionController', () {
    test('saves a draft count line and approves through MGWS only', () async {
      final gateway = FakeMgwsRestockGateway()
        ..countSessionResponse = MgwsRestockResult.success(_session('draft'));
      final controller = InventoryCountSessionController(gateway: gateway);

      await controller.load('31');
      await controller.saveLine(
        const InventoryCountLineForm(
          sessionIdText: '31',
          productIdText: '7',
          physicalQuantityText: '4',
        ),
      );
      await controller.approve('31');

      expect(gateway.saveCountLineCalls, 1);
      expect(gateway.countLineInput?.physicalQuantity, 4);
      expect(gateway.approveCountSessionCalls, 1);
      expect(gateway.quickLoadCalls, 0);
      expect(gateway.convalidaReceiptCalls, 0);
    });

    test('keeps posted sessions read-only without calling MGWS', () async {
      final gateway = FakeMgwsRestockGateway()
        ..countSessionResponse = MgwsRestockResult.success(_session('posted'));
      final controller = InventoryCountSessionController(gateway: gateway);
      await controller.load('31');

      final feedback = await controller.saveLine(
        const InventoryCountLineForm(
          sessionIdText: '31',
          productIdText: '7',
          physicalQuantityText: '4',
        ),
      );

      expect(feedback.success, isFalse);
      expect(gateway.saveCountLineCalls, 0);
    });

    test('propagates unknown barcode or tag backend errors', () async {
      final gateway = FakeMgwsRestockGateway()
        ..countSessionResponse = MgwsRestockResult.success(_session('draft'))
        ..countLineResponse = _failure<MgwsCountLine>('mgws_unknown_tag');
      final controller = InventoryCountSessionController(gateway: gateway);
      await controller.load('31');

      final feedback = await controller.saveLine(
        const InventoryCountLineForm(
          sessionIdText: '31',
          tagText: 'UNKNOWN-TAG',
          physicalQuantityText: '1',
        ),
      );

      expect(feedback.success, isFalse);
      expect(feedback.details, ['mgws_unknown_tag']);
      expect(gateway.saveCountLineCalls, 1);
    });

    test(
      'guards duplicate count approval while the first is pending',
      () async {
        final gateway = FakeMgwsRestockGateway()
          ..countSessionResponse = MgwsRestockResult.success(_session('draft'));
        final pending = Completer<MgwsRestockResult<MgwsCountSession>>();
        gateway.onApproveCountSession = (_) => pending.future;
        final controller = InventoryCountSessionController(gateway: gateway);
        await controller.load('31');

        final first = controller.approve('31');
        final duplicate = await controller.approve('31');

        expect(duplicate.success, isFalse);
        expect(duplicate.message, 'Approvazione inventario gia in corso');
        expect(gateway.approveCountSessionCalls, 1);
        expect(gateway.stockWorkflowCalls, 1);

        pending.complete(MgwsRestockResult.success(_session('posted')));
        await first;
      },
    );

    test(
      'surfaces count approval conflict details without local stock mutation',
      () async {
        final gateway = FakeMgwsRestockGateway()
          ..countSessionResponse = MgwsRestockResult.success(_session('draft'));
        final controller = InventoryCountSessionController(gateway: gateway);
        await controller.load('31');
        gateway.countSessionResponse = _failure<MgwsCountSession>(
          'mgws_conflict',
        );

        final feedback = await controller.approve('31');

        expect(feedback.success, isFalse);
        expect(feedback.details, ['mgws_conflict']);
        expect(gateway.approveCountSessionCalls, 1);
        expect(gateway.quickLoadCalls, 0);
        expect(gateway.convalidaReceiptCalls, 0);
      },
    );
  });
}

MgwsCountSession _session(String status) {
  return MgwsCountSession(
    id: 31,
    siteId: 2,
    warehouseId: 5,
    documentNumber: 'COUNT-31',
    status: status,
    startedByUserId: 4,
    approvedByUserId: 0,
    startedAtGmt: '2026-08-01T00:00:00Z',
    approvedAtGmt: null,
    postedAtGmt: status == 'posted' ? '2026-08-02T00:00:00Z' : null,
    notes: '',
    createdAtGmt: '2026-08-01T00:00:00Z',
    updatedAtGmt: '2026-08-01T00:00:00Z',
    lines: const [],
  );
}

MgwsRestockResult<T> _failure<T>(String code) {
  return MgwsRestockResult.failure(
    MgwsRestockError(
      code: code,
      message: 'Errore MGWS di prova',
      details: [code],
    ),
  );
}
