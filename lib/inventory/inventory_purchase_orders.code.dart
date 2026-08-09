import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'inventory_restock_feedback.code.dart';

class InventoryPurchaseOrderForm {
  const InventoryPurchaseOrderForm({
    required this.siteIdText,
    required this.supplierIdText,
    required this.documentNumberText,
    this.warehouseIdText = '',
    this.expectedAtGmtText = '',
    this.currencyText = 'EUR',
    this.notesText = '',
  });

  final String siteIdText;
  final String supplierIdText;
  final String documentNumberText;
  final String warehouseIdText;
  final String expectedAtGmtText;
  final String currencyText;
  final String notesText;

  InventoryFormParse<MgwsPurchaseOrderInput> parse() {
    final siteId = InventoryInputParser.parsePositiveInt(siteIdText);
    if (siteId == null) return const InventoryFormInvalid('site_id non valido');
    final supplierId = InventoryInputParser.parsePositiveInt(supplierIdText);
    if (supplierId == null)
      return const InventoryFormInvalid('supplier_id non valido');
    final documentNumber = documentNumberText.trim();
    if (documentNumber.isEmpty) {
      return const InventoryFormInvalid('numero documento richiesto');
    }
    final warehouseId = InventoryInputParser.parseOptionalNonNegativeInt(
      warehouseIdText,
    );
    if (warehouseId == null) {
      return const InventoryFormInvalid('warehouse_id non valido');
    }
    final expectedAtGmt = _optional(expectedAtGmtText);
    if (expectedAtGmt != null && DateTime.tryParse(expectedAtGmt) == null) {
      return const InventoryFormInvalid('data prevista non valida');
    }
    final currency = currencyText.trim().toUpperCase();
    if (currency.length != 3)
      return const InventoryFormInvalid('valuta non valida');
    return InventoryFormValid(
      MgwsPurchaseOrderInput(
        siteId: siteId,
        supplierId: supplierId,
        documentNumber: documentNumber,
        warehouseId: warehouseId,
        expectedAtGmt: expectedAtGmt,
        currency: currency,
        notes: notesText.trim(),
      ),
    );
  }

  InventoryFormParse<MgwsPurchaseOrderPatch> parsePatch() {
    final supplierId = InventoryInputParser.parsePositiveInt(supplierIdText);
    if (supplierId == null)
      return const InventoryFormInvalid('supplier_id non valido');
    final documentNumber = documentNumberText.trim();
    if (documentNumber.isEmpty) {
      return const InventoryFormInvalid('numero documento richiesto');
    }
    final warehouseId = InventoryInputParser.parseOptionalNonNegativeInt(
      warehouseIdText,
    );
    if (warehouseId == null) {
      return const InventoryFormInvalid('warehouse_id non valido');
    }
    final expectedAtGmt = _optional(expectedAtGmtText);
    if (expectedAtGmt != null && DateTime.tryParse(expectedAtGmt) == null) {
      return const InventoryFormInvalid('data prevista non valida');
    }
    final currency = currencyText.trim().toUpperCase();
    if (currency.length != 3)
      return const InventoryFormInvalid('valuta non valida');
    return InventoryFormValid(
      MgwsPurchaseOrderPatch(
        supplierId: supplierId,
        documentNumber: documentNumber,
        warehouseId: warehouseId,
        expectedAtGmt: expectedAtGmt,
        currency: currency,
        notes: notesText.trim(),
      ),
    );
  }
}

class InventoryPurchaseOrderListForm {
  const InventoryPurchaseOrderListForm({
    this.siteIdText = '',
    this.supplierIdText = '',
    this.statusText = '',
  });

  final String siteIdText;
  final String supplierIdText;
  final String statusText;

  InventoryFormParse<InventoryPurchaseOrderListFilter> parse() {
    final siteId = _optionalPositive(siteIdText, 'site_id');
    if (siteId case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    final supplierId = _optionalPositive(supplierIdText, 'supplier_id');
    if (supplierId case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    return InventoryFormValid(
      InventoryPurchaseOrderListFilter(
        siteId: (siteId as InventoryFormValid<int?>).value,
        supplierId: (supplierId as InventoryFormValid<int?>).value,
        status: _optional(statusText),
      ),
    );
  }
}

class InventoryPurchaseOrderListFilter {
  const InventoryPurchaseOrderListFilter({
    required this.siteId,
    required this.supplierId,
    required this.status,
  });

  final int? siteId;
  final int? supplierId;
  final String? status;
}

class InventoryPurchaseOrderLineForm {
  const InventoryPurchaseOrderLineForm({
    required this.purchaseOrderIdText,
    required this.productIdText,
    required this.orderedQuantityText,
    required this.unitCostText,
    this.variationIdText = '',
    this.supplierSkuText = '',
    this.barcodeText = '',
    this.expectedAtGmtText = '',
  });

  final String purchaseOrderIdText;
  final String productIdText;
  final String orderedQuantityText;
  final String unitCostText;
  final String variationIdText;
  final String supplierSkuText;
  final String barcodeText;
  final String expectedAtGmtText;

  InventoryFormParse<InventoryPurchaseOrderLineCommand> parse() {
    final purchaseOrderId = InventoryInputParser.parsePositiveInt(
      purchaseOrderIdText,
    );
    if (purchaseOrderId == null) {
      return const InventoryFormInvalid('purchase_order_id non valido');
    }
    final productId = InventoryInputParser.parseProductId(productIdText);
    if (productId == null)
      return const InventoryFormInvalid('product_id non valido');
    final quantity = InventoryInputParser.parsePositiveInt(orderedQuantityText);
    if (quantity == null)
      return const InventoryFormInvalid('quantita ordinata non valida');
    final cost = double.tryParse(unitCostText.trim());
    if (cost == null || cost < 0)
      return const InventoryFormInvalid('costo non valido');
    final variationId = InventoryInputParser.parseOptionalNonNegativeInt(
      variationIdText,
    );
    if (variationId == null) {
      return const InventoryFormInvalid('variation_id non valido');
    }
    final expectedAtGmt = _optional(expectedAtGmtText);
    if (expectedAtGmt != null && DateTime.tryParse(expectedAtGmt) == null) {
      return const InventoryFormInvalid('data prevista non valida');
    }
    return InventoryFormValid(
      InventoryPurchaseOrderLineCommand(
        purchaseOrderId: purchaseOrderId,
        input: MgwsPurchaseOrderLineInput(
          productId: productId,
          variationId: variationId,
          orderedQuantity: quantity,
          unitCost: unitCostText.trim(),
          supplierSku: _optional(supplierSkuText),
          barcode: _optional(barcodeText),
          expectedAtGmt: expectedAtGmt,
        ),
      ),
    );
  }
}

class InventoryPurchaseOrderLineCommand {
  const InventoryPurchaseOrderLineCommand({
    required this.purchaseOrderId,
    required this.input,
  });

  final int purchaseOrderId;
  final MgwsPurchaseOrderLineInput input;
}

class InventoryPurchaseOrderStatusForm {
  const InventoryPurchaseOrderStatusForm({
    required this.purchaseOrderIdText,
    required this.statusText,
  });

  final String purchaseOrderIdText;
  final String statusText;

  InventoryFormParse<InventoryPurchaseOrderStatusCommand> parse() {
    final purchaseOrderId = InventoryInputParser.parsePositiveInt(
      purchaseOrderIdText,
    );
    if (purchaseOrderId == null) {
      return const InventoryFormInvalid('purchase_order_id non valido');
    }
    final status = statusText.trim();
    if (status.isEmpty)
      return const InventoryFormInvalid('stato ordine richiesto');
    return InventoryFormValid(
      InventoryPurchaseOrderStatusCommand(
        purchaseOrderId: purchaseOrderId,
        status: status,
      ),
    );
  }
}

class InventoryPurchaseOrderStatusCommand {
  const InventoryPurchaseOrderStatusCommand({
    required this.purchaseOrderId,
    required this.status,
  });

  final int purchaseOrderId;
  final String status;
}

class InventoryPurchaseOrderController with InventoryFeedbackController {
  InventoryPurchaseOrderController({MgwsRestockGateway? gateway})
    : gateway = gateway ?? QueryMgwsInventory();

  final MgwsRestockGateway gateway;
  List<MgwsPurchaseOrder> purchaseOrders = const [];
  MgwsPurchaseOrder? lastPurchaseOrder;
  MgwsPurchaseOrderLine? lastPurchaseOrderLine;

  Future<InventoryActionFeedback> load(
    InventoryPurchaseOrderListForm form,
  ) async {
    final parsed = form.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        final result = await gateway.listPurchaseOrders(
          siteId: value.siteId,
          supplierId: value.supplierId,
          status: value.status,
        );
        if (result.success && result.data != null)
          purchaseOrders = result.data!;
        return _feedback(result);
    }
  }

  Future<InventoryActionFeedback> get(String purchaseOrderIdText) async {
    final parsed = InventoryIdentifierForm(
      purchaseOrderIdText,
      label: 'purchase_order_id',
    ).parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        final result = await gateway.getPurchaseOrder(value);
        lastPurchaseOrder = result.data;
        return _feedback(result);
    }
  }

  Future<InventoryActionFeedback> createDraft(
    InventoryPurchaseOrderForm form,
  ) async {
    final parsed = form.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        final result = await gateway.createPurchaseOrder(value);
        lastPurchaseOrder = result.data;
        return _feedback(result);
    }
  }

  Future<InventoryActionFeedback> saveLine(
    InventoryPurchaseOrderLineForm form,
  ) async {
    final parsed = form.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        final result = await gateway.savePurchaseOrderLine(
          value.purchaseOrderId,
          value.input,
        );
        lastPurchaseOrderLine = result.data;
        return _feedback(result);
    }
  }

  Future<InventoryActionFeedback> updateDraft({
    required String purchaseOrderIdText,
    required InventoryPurchaseOrderForm form,
  }) async {
    final identifier = InventoryIdentifierForm(
      purchaseOrderIdText,
      label: 'purchase_order_id',
    ).parse();
    final patch = form.parsePatch();
    switch (identifier) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(value: final purchaseOrderId):
        switch (patch) {
          case InventoryFormInvalid(:final message):
            return invalid(message);
          case InventoryFormValid(value: final value):
            final result = await gateway.updatePurchaseOrder(
              purchaseOrderId,
              value,
            );
            lastPurchaseOrder = result.data;
            return _feedback(result);
        }
    }
  }

  Future<InventoryActionFeedback> updateStatus(
    InventoryPurchaseOrderStatusForm form,
  ) async {
    final parsed = form.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        final result = await gateway.updatePurchaseOrderStatus(
          value.purchaseOrderId,
          value.status,
        );
        lastPurchaseOrder = result.data;
        return _feedback(result);
    }
  }

  Future<InventoryActionFeedback> cancel(String purchaseOrderIdText) {
    return updateStatus(
      InventoryPurchaseOrderStatusForm(
        purchaseOrderIdText: purchaseOrderIdText,
        statusText: 'cancelled',
      ),
    );
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
