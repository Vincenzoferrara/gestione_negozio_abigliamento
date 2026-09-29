import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'inventory_restock_feedback.code.dart';

class InventorySupplierForm {
  const InventorySupplierForm({
    required this.nameText,
    this.taxIdText = '',
    this.emailText = '',
    this.phoneText = '',
    this.notesText = '',
    this.paymentTermsDaysText = '',
    this.ibanText = '',
    this.leadTimeDaysText = '',
    this.active = true,
  });

  final String nameText;
  final String taxIdText;
  final String emailText;
  final String phoneText;
  final String notesText;
  final String paymentTermsDaysText;
  final String ibanText;
  final String leadTimeDaysText;
  final bool active;

  InventoryFormParse<MgwsSupplierInput> parseCreate() {
    final paymentTermsDays = _optionalNonNegativeInt(
      paymentTermsDaysText,
      'termini pagamento',
    );
    if (paymentTermsDays case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    final leadTimeDays = _optionalNonNegativeInt(leadTimeDaysText, 'lead time');
    if (leadTimeDays case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    final name = nameText.trim();
    if (name.isEmpty)
      return const InventoryFormInvalid('nome fornitore richiesto');
    final email = _optionalEmail(emailText);
    if (email case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    return InventoryFormValid(
      MgwsSupplierInput(
        name: name,
        taxId: _optional(taxIdText),
        email: (email as InventoryFormValid<String?>).value,
        phone: _optional(phoneText),
        notes: _optional(notesText),
        paymentTermsDays: (paymentTermsDays as InventoryFormValid<int?>).value,
        iban: _optional(ibanText),
        leadTimeDays: (leadTimeDays as InventoryFormValid<int?>).value,
        active: active,
      ),
    );
  }

  InventoryFormParse<MgwsSupplierPatch> parsePatch() {
    final name = nameText.trim();
    if (name.isEmpty)
      return const InventoryFormInvalid('nome fornitore richiesto');
    final paymentTermsDays = _optionalNonNegativeInt(
      paymentTermsDaysText,
      'termini pagamento',
    );
    if (paymentTermsDays case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    final leadTimeDays = _optionalNonNegativeInt(leadTimeDaysText, 'lead time');
    if (leadTimeDays case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    final email = _optionalEmail(emailText);
    if (email case InventoryFormInvalid(:final message)) {
      return InventoryFormInvalid(message);
    }
    return InventoryFormValid(
      MgwsSupplierPatch(
        name: name,
        taxId: _optional(taxIdText),
        email: (email as InventoryFormValid<String?>).value,
        phone: _optional(phoneText),
        notes: _optional(notesText),
        paymentTermsDays: (paymentTermsDays as InventoryFormValid<int?>).value,
        iban: _optional(ibanText),
        leadTimeDays: (leadTimeDays as InventoryFormValid<int?>).value,
        active: active,
      ),
    );
  }
}

InventoryFormParse<int?> _optionalNonNegativeInt(String value, String label) {
  if (value.trim().isEmpty) return const InventoryFormValid(null);
  final parsed = InventoryInputParser.parseNonNegativeInt(value);
  if (parsed == null) return InventoryFormInvalid('$label non valido');
  return InventoryFormValid(parsed);
}

/// Controlla l'email solo se e' stata scritta.
///
/// Il backend rifiuta comunque un indirizzo malformato, ma arriva come errore
/// di server: dirlo qui dice all'operatore cosa correggere senza aspettare
/// un giro di rete.
InventoryFormParse<String?> _optionalEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return const InventoryFormValid(null);
  if (!_emailShape.hasMatch(email)) {
    return const InventoryFormInvalid('email non valida');
  }
  return InventoryFormValid(email);
}

/// Dominio obbligatorio, TLD almeno di due lettere, niente spazi.
///
/// Non prova a replicare `is_email` di WordPress: serve solo a scartare il
/// refuso, non a fare da arbitro. Chi scrive bene passa, chi sbaglia viene
/// fermato qui invece che dal server.
final RegExp _emailShape = RegExp(
  r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)*\.[A-Za-z]{2,}$',
);

class InventorySupplierController with InventoryFeedbackController {
  InventorySupplierController({MgwsRestockGateway? gateway})
    : gateway = gateway ?? QueryMgwsInventory();

  final MgwsRestockGateway gateway;
  List<MgwsSupplier> suppliers = const [];
  MgwsSupplier? lastSupplier;

  /// I fornitori sono globali: il caricamento non ha bisogno di una sede.
  Future<InventoryActionFeedback> load() async {
    final result = await gateway.listSuppliers();
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
