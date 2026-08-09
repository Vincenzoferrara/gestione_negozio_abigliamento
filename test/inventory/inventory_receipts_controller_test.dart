import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';

import 'support/fake_mgws_restock_gateway.dart';

void main() {
  group('InventoryReceiptController', () {
    test('does not create a receipt for inconsistent quantities', () async {
      final gateway = FakeMgwsRestockGateway();
      final controller = InventoryReceiptController(gateway: gateway);

      final feedback = await controller.create(_receiptForm(received: '2'));

      expect(feedback.success, isFalse);
      expect(feedback.message, 'quantita ricevimento non coerenti');
      expect(gateway.createReceiptCalls, 0);
    });

    test('blocks over-receive before the gateway', () async {
      final gateway = FakeMgwsRestockGateway();
      final controller = InventoryReceiptController(gateway: gateway);

      final feedback = await controller.create(_receiptForm(received: '4'));

      expect(feedback.success, isFalse);
      expect(
        feedback.message,
        'over-ricezione non consentita senza approvazione MGWS',
      );
      expect(gateway.createReceiptCalls, 0);
    });

    test('requires a QC reason when a line is held', () async {
      final gateway = FakeMgwsRestockGateway();
      final controller = InventoryReceiptController(gateway: gateway);

      final feedback = await controller.create(_receiptForm(qcHold: true));

      expect(feedback.success, isFalse);
      expect(feedback.message, 'motivo QC richiesto');
      expect(gateway.createReceiptCalls, 0);
    });

    test(
      'guards a duplicate receipt submit and preserves the idempotency key',
      () async {
        final gateway = FakeMgwsRestockGateway();
        final pending = Completer<MgwsRestockResult<MgwsReceipt>>();
        gateway.onCreateReceipt = (_) => pending.future;
        final controller = InventoryReceiptController(gateway: gateway);
        final first = controller.create(_receiptForm());
        final duplicate = await controller.create(_receiptForm());

        expect(duplicate.success, isFalse);
        expect(duplicate.message, 'Ricevimento gia in corso');
        expect(gateway.createReceiptCalls, 1);
        expect(gateway.receiptInput?.idempotencyKey, 'receipt-12-2026-01');

        pending.complete(_failure<MgwsReceipt>('backend_receipt_error'));
        await first;
      },
    );

    test('propagates backend receipt errors and details', () async {
      final gateway = FakeMgwsRestockGateway()
        ..receiptResponse = _failure<MgwsReceipt>('mgws_forbidden');
      final controller = InventoryReceiptController(gateway: gateway);

      final feedback = await controller.convalida('18');

      expect(feedback.success, isFalse);
      expect(feedback.message, 'Errore MGWS di prova');
      expect(feedback.details, ['mgws_forbidden']);
      expect(gateway.convalidaReceiptCalls, 1);
    });

    test(
      'guards a duplicate receipt convalida while the first is pending',
      () async {
        final gateway = FakeMgwsRestockGateway();
        final pending = Completer<MgwsRestockResult<MgwsReceipt>>();
        gateway.onConvalidaReceipt = (_) => pending.future;
        final controller = InventoryReceiptController(gateway: gateway);

        final first = controller.convalida('18');
        final duplicate = await controller.convalida('18');

        expect(duplicate.success, isFalse);
        expect(duplicate.message, 'Convalida ricevimento gia in corso');
        expect(gateway.convalidaReceiptCalls, 1);
        expect(gateway.stockWorkflowCalls, 1);

        pending.complete(_failure<MgwsReceipt>('mgws_conflict'));
        await first;
      },
    );
  });
}

InventoryReceiptForm _receiptForm({
  String received = '3',
  bool qcHold = false,
}) {
  return InventoryReceiptForm(
    siteIdText: '2',
    purchaseOrderIdText: '12',
    documentNumberText: 'DDT-2026-01',
    idempotencyKeyText: 'receipt-12-2026-01',
    lines: [
      InventoryReceiptLineForm(
        purchaseOrderLineIdText: '55',
        expectedQuantityText: '3',
        receivedQuantityText: received,
        rejectedQuantityText: '0',
        backorderQuantityText: '0',
        qcHold: qcHold,
      ),
    ],
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
