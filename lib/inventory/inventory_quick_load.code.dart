import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'inventory_restock_feedback.code.dart';

class InventoryQuickLoadForm {
  const InventoryQuickLoadForm({
    required this.productIdText,
    required this.quantityText,
    required this.reasonText,
    this.variationIdText = '',
    this.noteText = '',
    this.barcodeText = '',
    this.warehouseIdText = '',
    this.roomText = '',
    this.rackText = '',
    this.shelfText = '',
    this.idempotencyKeyText = '',
  });

  final String productIdText;
  final String quantityText;
  final String reasonText;
  final String variationIdText;
  final String noteText;
  final String barcodeText;
  final String warehouseIdText;
  final String roomText;
  final String rackText;
  final String shelfText;
  final String idempotencyKeyText;

  InventoryFormParse<MgwsQuickLoadRequest> parse() {
    final productId = InventoryInputParser.parseProductId(productIdText);
    if (productId == null)
      return const InventoryFormInvalid('product_id non valido');
    final quantity = InventoryInputParser.parsePositiveInt(quantityText);
    if (quantity == null)
      return const InventoryFormInvalid('quantita non valida');
    final reason = reasonText.trim();
    if (reason.isEmpty) return const InventoryFormInvalid('reason richiesto');
    final variationId = InventoryInputParser.parseOptionalNonNegativeInt(
      variationIdText,
    );
    if (variationId == null) {
      return const InventoryFormInvalid('variation_id non valido');
    }
    final warehouseId = warehouseIdText.trim().isEmpty
        ? null
        : InventoryInputParser.parsePositiveInt(warehouseIdText);
    if (warehouseIdText.trim().isNotEmpty && warehouseId == null) {
      return const InventoryFormInvalid('warehouse_id non valido');
    }
    return InventoryFormValid(
      MgwsQuickLoadRequest(
        productId: productId,
        quantityDelta: quantity,
        reason: reason,
        variationId: variationId,
        note: _optional(noteText),
        barcode: _optional(barcodeText),
        warehouseId: warehouseId,
        room: _optional(roomText),
        rack: _optional(rackText),
        shelf: _optional(shelfText),
        idempotencyKey: _optional(idempotencyKeyText),
      ),
    );
  }
}

class InventoryQuickLoadController with InventoryFeedbackController {
  InventoryQuickLoadController({MgwsRestockGateway? gateway})
    : gateway = gateway ?? QueryMgwsInventory();

  final MgwsRestockGateway gateway;
  MgwsQuickLoad? lastQuickLoad;
  bool isSubmitting = false;

  Future<InventoryActionFeedback> submit(InventoryQuickLoadForm form) async {
    final parsed = form.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        if (isSubmitting) return invalid('Carico rapido gia in corso');
        isSubmitting = true;
        try {
          final result = await gateway.quickLoad(value);
          lastQuickLoad = result.data;
          return remember(
            InventoryActionFeedback(
              success: result.success,
              message: result.message,
              details: result.details,
            ),
          );
        } finally {
          isSubmitting = false;
        }
    }
  }
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
