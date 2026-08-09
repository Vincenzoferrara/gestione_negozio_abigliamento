class InventoryActionFeedback {
  const InventoryActionFeedback({
    required this.success,
    required this.message,
    this.details = const [],
  });

  final bool success;
  final String message;
  final List<String> details;
}

sealed class InventoryFormParse<T> {
  const InventoryFormParse();
}

class InventoryFormValid<T> extends InventoryFormParse<T> {
  const InventoryFormValid(this.value);

  final T value;
}

class InventoryFormInvalid<T> extends InventoryFormParse<T> {
  const InventoryFormInvalid(this.message);

  final String message;
}

class InventoryInputParser {
  static int? parseProductId(String value) => parsePositiveInt(value);

  static int? parseStock(String value) => parseNonNegativeInt(value);

  static int? parsePositiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed == null || parsed <= 0 ? null : parsed;
  }

  static int? parseNonNegativeInt(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed == null || parsed < 0 ? null : parsed;
  }

  static int? parseOptionalNonNegativeInt(String value) {
    if (value.trim().isEmpty) return 0;
    return parseNonNegativeInt(value);
  }

  static List<String> parseTags(String value) {
    return value
        .split(RegExp(r'[\s,;]+'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }
}

class InventoryIdentifierForm {
  const InventoryIdentifierForm(this.idText, {this.label = 'id'});

  final String idText;
  final String label;

  InventoryFormParse<int> parse() {
    final id = InventoryInputParser.parsePositiveInt(idText);
    return id == null
        ? InventoryFormInvalid('$label non valido')
        : InventoryFormValid(id);
  }
}

mixin InventoryFeedbackController {
  InventoryActionFeedback? lastFeedback;

  InventoryActionFeedback remember(InventoryActionFeedback feedback) {
    lastFeedback = feedback;
    return feedback;
  }

  InventoryActionFeedback invalid(String message) {
    return remember(InventoryActionFeedback(success: false, message: message));
  }
}
