import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'inventory_restock_feedback.code.dart';

class InventorySupplierForm {
  const InventorySupplierForm({
    required this.siteIdText,
    required this.supplierCodeText,
    required this.nameText,
    this.taxIdText = '',
    this.emailText = '',
    this.phoneText = '',
    this.notesText = '',
    this.active = true,
  });

  final String siteIdText;
  final String supplierCodeText;
  final String nameText;
  final String taxIdText;
  final String emailText;
  final String phoneText;
  final String notesText;
  final bool active;

  InventoryFormParse<MgwsSupplierInput> parseCreate() {
    final siteId = InventoryInputParser.parsePositiveInt(siteIdText);
    if (siteId == null) return const InventoryFormInvalid('site_id non valido');
    final code = supplierCodeText.trim();
    if (code.isEmpty)
      return const InventoryFormInvalid('codice fornitore richiesto');
    final name = nameText.trim();
    if (name.isEmpty)
      return const InventoryFormInvalid('nome fornitore richiesto');
    return InventoryFormValid(
      MgwsSupplierInput(
        siteId: siteId,
        supplierCode: code,
        name: name,
        taxId: _optional(taxIdText),
        email: _optional(emailText),
        phone: _optional(phoneText),
        notes: _optional(notesText),
        active: active,
      ),
    );
  }

  InventoryFormParse<MgwsSupplierPatch> parsePatch() {
    final code = supplierCodeText.trim();
    if (code.isEmpty)
      return const InventoryFormInvalid('codice fornitore richiesto');
    final name = nameText.trim();
    if (name.isEmpty)
      return const InventoryFormInvalid('nome fornitore richiesto');
    return InventoryFormValid(
      MgwsSupplierPatch(
        supplierCode: code,
        name: name,
        taxId: _optional(taxIdText),
        email: _optional(emailText),
        phone: _optional(phoneText),
        notes: _optional(notesText),
        active: active,
      ),
    );
  }
}

class InventorySupplierController with InventoryFeedbackController {
  InventorySupplierController({MgwsRestockGateway? gateway})
    : gateway = gateway ?? QueryMgwsInventory();

  final MgwsRestockGateway gateway;
  List<MgwsSupplier> suppliers = const [];
  MgwsSupplier? lastSupplier;

  Future<InventoryActionFeedback> load(String siteIdText) async {
    final siteId = siteIdText.trim().isEmpty
        ? null
        : InventoryInputParser.parsePositiveInt(siteIdText);
    if (siteIdText.trim().isNotEmpty && siteId == null) {
      return invalid('site_id non valido');
    }
    final result = await gateway.listSuppliers(siteId: siteId);
    if (result.success && result.data != null) suppliers = result.data!;
    return _feedback(result);
  }

  Future<InventoryActionFeedback> get(String supplierIdText) async {
    final parsed = InventoryIdentifierForm(
      supplierIdText,
      label: 'supplier_id',
    ).parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        final result = await gateway.getSupplier(value);
        lastSupplier = result.data;
        return _feedback(result);
    }
  }

  Future<InventoryActionFeedback> create(InventorySupplierForm form) async {
    final parsed = form.parseCreate();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        final result = await gateway.createSupplier(value);
        lastSupplier = result.data;
        return _feedback(result);
    }
  }

  Future<InventoryActionFeedback> update({
    required String supplierIdText,
    required InventorySupplierForm form,
  }) async {
    final identifier = InventoryIdentifierForm(
      supplierIdText,
      label: 'supplier_id',
    ).parse();
    final patch = form.parsePatch();
    switch (identifier) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(value: final supplierId):
        switch (patch) {
          case InventoryFormInvalid(:final message):
            return invalid(message);
          case InventoryFormValid(value: final supplierPatch):
            final result = await gateway.updateSupplier(
              supplierId,
              supplierPatch,
            );
            lastSupplier = result.data;
            return _feedback(result);
        }
    }
  }

  Future<InventoryActionFeedback> delete(String supplierIdText) async {
    final parsed = InventoryIdentifierForm(
      supplierIdText,
      label: 'supplier_id',
    ).parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        return invalid(message);
      case InventoryFormValid(:final value):
        return _feedback(await gateway.deleteSupplier(value));
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
