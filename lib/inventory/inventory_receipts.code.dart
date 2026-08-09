import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'inventory_restock_feedback.code.dart';

class InventoryReceiptLineForm {
  const InventoryReceiptLineForm({
    required this.purchaseOrderLineIdText,
    required this.expectedQuantityText,
    required this.receivedQuantityText,
    required this.rejectedQuantityText,
    required this.backorderQuantityText,
    this.reasonCodeText = '',
    this.qcHold = false,
  });

  final String purchaseOrderLineIdText;
  final String expectedQuantityText;
  final String receivedQuantityText;
  final String rejectedQuantityText;
  final String backorderQuantityText;
  final String reasonCodeText;
  final bool qcHold;

  InventoryFormParse<MgwsReceiptLineInput> parse() {
    final purchaseOrderLineId = InventoryInputParser.parsePositiveInt(
      purchaseOrderLineIdText,
    );
    if (purchaseOrderLineId == null) {
      return const InventoryFormInvalid('riga ordine non valida');
    }
    final expected = InventoryInputParser.parsePositiveInt(
      expectedQuantityText,
    );
    final received = InventoryInputParser.parseNonNegativeInt(
      receivedQuantityText,
    );
    final rejected = InventoryInputParser.parseNonNegativeInt(
      rejectedQuantityText,
    );
    final backorder = InventoryInputParser.parseNonNegativeInt(
      backorderQuantityText,
    );
    if (expected == null ||
        received == null ||
        rejected == null ||
        backorder == null) {
      return const InventoryFormInvalid('quantita ricevimento non valide');
    }
    if (received > expected) {
      return const InventoryFormInvalid(
        'over-ricezione non consentita senza approvazione MGWS',
      );
    }
    final reason = reasonCodeText.trim();
    if (qcHold && reason.isEmpty) {
      return const InventoryFormInvalid('motivo QC richiesto');
    }
    if ((rejected > 0 || backorder > 0) && reason.isEmpty) {
      return const InventoryFormInvalid('motivo scarto/backorder richiesto');
    }
    if (received + rejected + backorder != expected) {
      return const InventoryFormInvalid('quantita ricevimento non coerenti');
    }
    return InventoryFormValid(
      MgwsReceiptLineInput(
        purchaseOrderLineId: purchaseOrderLineId,
        expectedQuantity: expected,
        receivedQuantity: received,
        rejectedQuantity: rejected,
        backorderQuantity: backorder,
        reasonCode: reason,
      ),
    );
  }
}

class InventoryReceiptListForm {
  const InventoryReceiptListForm({
    this.siteIdText = '',
    this.purchaseOrderIdText = '',
    this.statusText = '',
  });

  final String siteIdText;
  final String purchaseOrderIdText;
  final String statusText;

  InventoryFormParse<InventoryReceiptListFilter> parse() {
    final siteId = _optionalPositive(siteIdText, 'site_id');
    if (siteId case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    final purchaseOrderId = _optionalPositive(
      purchaseOrderIdText,
      'purchase_order_id',
    );
    if (purchaseOrderId case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    return InventoryFormValid(
      InventoryReceiptListFilter(
        siteId: (siteId as InventoryFormValid<int?>).value,
        purchaseOrderId: (purchaseOrderId as InventoryFormValid<int?>).value,
        status: _optional(statusText),
      ),
    );
  }
}

class InventoryReceiptListFilter {
  const InventoryReceiptListFilter({
    required this.siteId,
    required this.purchaseOrderId,
    required this.status,
  });

  final int? siteId;
  final int? purchaseOrderId;
  final String? status;
}

class InventoryReceiptForm {
  const InventoryReceiptForm({
    required this.siteIdText,
    required this.purchaseOrderIdText,
    required this.documentNumberText,
    required this.lines,
    this.idempotencyKeyText = '',
    this.notesText = '',
  });

  final String siteIdText;
  final String purchaseOrderIdText;
  final String documentNumberText;
  final List<InventoryReceiptLineForm> lines;
  final String idempotencyKeyText;
  final String notesText;

  InventoryFormParse<MgwsReceiptInput> parse() {
    final siteId = InventoryInputParser.parsePositiveInt(siteIdText);
    if (siteId == null) return const InventoryFormInvalid('site_id non valido');
    final purchaseOrderId = InventoryInputParser.parsePositiveInt(
      purchaseOrderIdText,
    );
    if (purchaseOrderId == null) {
      return const InventoryFormInvalid('purchase_order_id non valido');
    }
    final documentNumber = documentNumberText.trim();
    if (documentNumber.isEmpty) {
      return const InventoryFormInvalid('numero documento richiesto');
    }
    if (lines.isEmpty)
      return const InventoryFormInvalid('almeno una riga richiesta');
    final parsedLines = <MgwsReceiptLineInput>[];
    for (final line in lines) {
      switch (line.parse()) {
        case InventoryFormInvalid(:final message):
          return InventoryFormInvalid(message);
        case InventoryFormValid(:final value):
          parsedLines.add(value);
      }
    }
    return InventoryFormValid(
      MgwsReceiptInput(
        siteId: siteId,
        purchaseOrderId: purchaseOrderId,
        documentNumber: documentNumber,
        lines: parsedLines,
        idempotencyKey: _optional(idempotencyKeyText),
        notes: _optional(notesText),
      ),
    );
  }
}

class InventoryReceiptController with InventoryFeedbackController {
  InventoryReceiptController({MgwsRestockGateway? gateway})
    : gateway = gateway ?? QueryMgwsInventory();

  final MgwsRestockGateway gateway;
  List<MgwsReceipt> receipts = const [];
  MgwsReceipt? lastReceipt;
  bool isSubmitting = false;
  bool isValidating = false;

  Future<InventoryActionFeedback> load(InventoryReceiptListForm form) async {
    final parsed = form.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        final result = await gateway.listReceipts(
          siteId: value.siteId,
          purchaseOrderId: value.purchaseOrderId,
          status: value.status,
        );
        if (result.success && result.data != null) receipts = result.data!;
        return _feedback(result);
    }
  }

  Future<InventoryActionFeedback> get(String receiptIdText) async {
    final parsed = InventoryIdentifierForm(
      receiptIdText,
      label: 'receipt_id',
    ).parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        final result = await gateway.getReceipt(value);
        lastReceipt = result.data;
        return _feedback(result);
    }
  }

  Future<InventoryActionFeedback> create(InventoryReceiptForm form) async {
    final parsed = form.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        if (isSubmitting) return invalid('Ricevimento gia in corso');
        isSubmitting = true;
        try {
          final result = await gateway.createReceipt(value);
          lastReceipt = result.data;
          return _feedback(result);
        } finally {
          isSubmitting = false;
        }
    }
  }

  Future<InventoryActionFeedback> convalida(String receiptIdText) async {
    final parsed = InventoryIdentifierForm(
      receiptIdText,
      label: 'receipt_id',
    ).parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        if (isValidating) return invalid('Convalida ricevimento gia in corso');
        isValidating = true;
        try {
          final result = await gateway.convalidaReceipt(value);
          lastReceipt = result.data;
          return _feedback(result);
        } finally {
          isValidating = false;
        }
    }
  }

  InventoryActionFeedback _feedback<T>(MgwsRestockResult<T> result) {
    return remember(
      InventoryActionFeedback(
        success: result.success,
        message: result.message,
        details: result.details,
      ),
    );
  }
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

InventoryFormParse<int?> _optionalPositive(String value, String label) {
  if (value.trim().isEmpty) return const InventoryFormValid(null);
  final parsed = InventoryInputParser.parsePositiveInt(value);
  if (parsed == null) return InventoryFormInvalid('$label non valido');
  return InventoryFormValid(parsed);
}
