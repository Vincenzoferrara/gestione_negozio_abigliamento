import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'inventory_restock_feedback.code.dart';

class InventoryMovementFilterForm {
  const InventoryMovementFilterForm({
    this.productIdText = '',
    this.variationIdText = '',
    this.dateFromText = '',
    this.dateToText = '',
    this.sourceTypeText = '',
    this.operatorUserIdText = '',
    this.reasonCodeText = '',
    this.stockEffectText = '',
    this.pageText = '1',
    this.perPageText = '50',
  });

  final String productIdText;
  final String variationIdText;
  final String dateFromText;
  final String dateToText;
  final String sourceTypeText;
  final String operatorUserIdText;
  final String reasonCodeText;
  final String stockEffectText;
  final String pageText;
  final String perPageText;

  InventoryFormParse<MgwsMovementFilter> parse() {
    final productId = _optionalPositiveInt(productIdText);
    if (productIdText.trim().isNotEmpty && productId == null) {
      return const InventoryFormInvalid('product_id non valido');
    }
    final variationId = _optionalNonNegativeInt(variationIdText);
    if (variationIdText.trim().isNotEmpty && variationId == null) {
      return const InventoryFormInvalid('variation_id non valido');
    }
    final dateFrom = _parseDate(dateFromText, 'data iniziale non valida');
    if (dateFrom is InventoryFormInvalid<String?>) {
      return InventoryFormInvalid(dateFrom.message);
    }
    final dateTo = _parseDate(dateToText, 'data finale non valida');
    if (dateTo is InventoryFormInvalid<String?>) {
      return InventoryFormInvalid(dateTo.message);
    }
    final page = InventoryInputParser.parsePositiveInt(pageText);
    if (page == null) return const InventoryFormInvalid('pagina non valida');
    final perPage = InventoryInputParser.parsePositiveInt(perPageText);
    if (perPage == null || perPage > 100) {
      return const InventoryFormInvalid('righe per pagina non valide');
    }
    final from = (dateFrom as InventoryFormValid<String?>).value;
    final to = (dateTo as InventoryFormValid<String?>).value;
    if (from != null &&
        to != null &&
        DateTime.parse(from).isAfter(DateTime.parse(to))) {
      return const InventoryFormInvalid('intervallo date non valido');
    }
    final operatorUserId = _optionalPositiveInt(operatorUserIdText);
    if (operatorUserIdText.trim().isNotEmpty && operatorUserId == null) {
      return const InventoryFormInvalid('operatore non valido');
    }
    return InventoryFormValid(
      MgwsMovementFilter(
        productId: productId,
        variationId: variationId,
        dateFrom: from,
        dateTo: to,
        sourceType: _optional(sourceTypeText),
        operatorUserId: operatorUserId,
        reasonCode: _optional(reasonCodeText),
        stockEffect: _optional(stockEffectText),
        page: page,
        perPage: perPage,
      ),
    );
  }
}

class InventoryMovementController with InventoryFeedbackController {
  InventoryMovementController({MgwsRestockGateway? gateway})
    : gateway = gateway ?? QueryMgwsInventory();

  final MgwsRestockGateway gateway;
  MgwsMovementFilter? lastFilter;
  MgwsMovementPage? movementPage;
  bool isLoading = false;

  List<MgwsMovement> get movements => movementPage?.items ?? const [];

  Future<InventoryActionFeedback> load(InventoryMovementFilterForm form) async {
    final parsed = form.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        isLoading = true;
        try {
          final result = await gateway.listMovements(value);
          if (result.success) {
            lastFilter = value;
            movementPage = result.data;
          }
          return remember(
            InventoryActionFeedback(
              success: result.success,
              message: result.message,
              details: result.details,
            ),
          );
        } finally {
          isLoading = false;
        }
    }
  }
}

InventoryFormParse<String?> _parseDate(String value, String message) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return const InventoryFormValid(null);
  final parsed = DateTime.tryParse(trimmed);
  return parsed == null
      ? InventoryFormInvalid(message)
      : InventoryFormValid(parsed.toUtc().toIso8601String());
}

int? _optionalPositiveInt(String value) {
  return value.trim().isEmpty
      ? null
      : InventoryInputParser.parsePositiveInt(value);
}

int? _optionalNonNegativeInt(String value) {
  return value.trim().isEmpty
      ? null
      : InventoryInputParser.parseNonNegativeInt(value);
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
