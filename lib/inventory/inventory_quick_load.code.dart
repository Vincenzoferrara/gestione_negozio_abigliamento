import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'inventory_restock_feedback.code.dart';

class InventoryQuickLoadLineDraft {
  const InventoryQuickLoadLineDraft({
    required this.productId,
    required this.variationId,
    required this.label,
    required this.quantity,
    required this.idempotencyKey,
    this.sku,
    this.barcode,
    this.imageUrl,
    this.rack,
    this.shelf,
  });

  final int productId;
  final int variationId;
  final String label;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final String? rack;
  final String? shelf;
  final int quantity;
  final String idempotencyKey;

  String get key => '$productId:$variationId';
  bool get isVariant => variationId > 0;

  InventoryQuickLoadLineDraft copyWith({
    int? quantity,
    String? idempotencyKey,
    String? rack,
    String? shelf,
  }) {
    return InventoryQuickLoadLineDraft(
      productId: productId,
      variationId: variationId,
      label: label,
      sku: sku,
      barcode: barcode,
      imageUrl: imageUrl,
      rack: rack ?? this.rack,
      shelf: shelf ?? this.shelf,
      quantity: quantity ?? this.quantity,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}

class InventoryQuickLoadSubmissionPlan {
  const InventoryQuickLoadSubmissionPlan({
    required this.lines,
    required this.reason,
    this.note,
    this.warehouseId,
    this.room,
  });

  final List<InventoryQuickLoadLineDraft> lines;
  final String reason;
  final String? note;
  final int? warehouseId;
  final String? room;

  int get totalQuantity =>
      lines.fold<int>(0, (sum, line) => sum + line.quantity);

  InventoryFormParse<List<MgwsQuickLoadRequest>> parse() {
    if (lines.isEmpty) {
      return const InventoryFormInvalid(
        'Seleziona almeno un prodotto o variante',
      );
    }
    if (reason.trim().isEmpty) {
      return const InventoryFormInvalid('reason richiesto');
    }
    if (warehouseId != null && warehouseId! <= 0) {
      return const InventoryFormInvalid('warehouse_id non valido');
    }
    for (final line in lines) {
      if (line.productId <= 0) {
        return const InventoryFormInvalid('product_id non valido');
      }
      if (line.variationId < 0) {
        return const InventoryFormInvalid('variation_id non valido');
      }
      if (line.quantity <= 0) {
        return InventoryFormInvalid('Quantità non valida per ${line.label}');
      }
    }
    return InventoryFormValid(
      lines
          .map(
            (line) => MgwsQuickLoadRequest(
              productId: line.productId,
              variationId: line.variationId,
              quantityDelta: line.quantity,
              reason: reason.trim(),
              note: _optional(note ?? ''),
              barcode: _optional(line.barcode ?? ''),
              warehouseId: warehouseId,
              room: _optional(room ?? ''),
              rack: _optional(line.rack ?? ''),
              shelf: _optional(line.shelf ?? ''),
              idempotencyKey: line.idempotencyKey,
            ),
          )
          .toList(growable: false),
    );
  }
}

class InventoryQuickLoadLineResult {
  const InventoryQuickLoadLineResult({
    required this.line,
    required this.success,
    required this.message,
    this.details = const <String>[],
    this.data,
  });

  final InventoryQuickLoadLineDraft line;
  final bool success;
  final String message;
  final List<String> details;
  final MgwsQuickLoad? data;
}

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
      return const InventoryFormInvalid('quantità non valida');
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
  List<InventoryQuickLoadLineResult> lastQuickLoadResults = const [];
  bool isSubmitting = false;

  List<InventoryQuickLoadLineDraft> get retryableLines => lastQuickLoadResults
      .where((result) => !result.success)
      .map((result) => result.line)
      .toList(growable: false);

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

  Future<InventoryActionFeedback> submitPlan(
    InventoryQuickLoadSubmissionPlan plan,
  ) async {
    final parsed = plan.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        if (isSubmitting) return invalid('Carico rapido gia in corso');
        isSubmitting = true;
        final results = <InventoryQuickLoadLineResult>[];
        try {
          for (int index = 0; index < value.length; index++) {
            final request = value[index];
            final line = plan.lines[index];
            try {
              final result = await gateway.quickLoad(request);
              final success = result.success && result.data != null;
              if (success) lastQuickLoad = result.data;
              results.add(
                InventoryQuickLoadLineResult(
                  line: line,
                  success: success,
                  message: success
                      ? result.message
                      : result.success
                      ? 'Risposta MGWS senza dati'
                      : result.message,
                  details: result.details,
                  data: result.data,
                ),
              );
            } catch (error) {
              results.add(
                InventoryQuickLoadLineResult(
                  line: line,
                  success: false,
                  message: error.toString(),
                ),
              );
            }
          }
          lastQuickLoadResults =
              List<InventoryQuickLoadLineResult>.unmodifiable(results);
          final succeeded = results.where((result) => result.success).length;
          final failed = results.length - succeeded;
          return remember(
            InventoryActionFeedback(
              success: failed == 0,
              message: failed == 0
                  ? 'Completati $succeeded/${results.length} carichi'
                  : 'Completati $succeeded/${results.length} carichi; $failed da riprovare',
              details: [
                for (final result in results.where((item) => !item.success))
                  '${result.line.label}: ${result.message}',
                for (final result in results.where((item) => !item.success))
                  for (final detail in result.details)
                    '${result.line.label}: $detail',
              ],
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
