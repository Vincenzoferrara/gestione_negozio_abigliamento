abstract class MgwsInventoryGateway {
  Future<bool> isInventoryServiceAvailable();
  Future<Map<String, dynamic>> getProductStock(int productId);
  Future<List<Map<String, dynamic>>> getAllStock();
  Future<Map<String, dynamic>> getStatistics();
  Future<List<Map<String, dynamic>>> getLowStockItems();
  Future<MgwsStockSyncResult> syncWooStockToMgws({
    required int productId,
    required int wooStock,
    required String syncType,
  });
  Future<MgwsReconcileResult> reconcileStock({
    required int productId,
    required int correctStock,
    required String reason,
  });
  Future<MgwsRfidScanResult> resolveRfidScan({required List<String> tagIds});
}

class MgwsStockSyncResult {
  const MgwsStockSyncResult({
    required this.success,
    required this.message,
    required this.errors,
    this.productId,
    this.previousStock,
    this.currentStock,
    this.delta,
  });

  final bool success;
  final String message;
  final List<String> errors;
  final int? productId;
  final int? previousStock;
  final int? currentStock;
  final int? delta;

  factory MgwsStockSyncResult.fromResponse(Object? raw, {int? statusCode}) {
    final data = MgwsInventoryParser.parsePayloadResponse(raw);
    final success = MgwsInventoryParser.parseSuccess(data, statusCode);
    final message = MgwsInventoryParser.parseMessage(
      data,
      success ? 'Sync stock completato' : 'Sync stock non riuscito',
    );
    return MgwsStockSyncResult(
      success: success,
      message: message,
      errors: MgwsInventoryParser.parseErrors(data, message),
      productId: MgwsInventoryParser.parseIntValue(data['product_id']),
      previousStock: MgwsInventoryParser.parseIntValue(data['previous_stock']),
      currentStock: MgwsInventoryParser.parseIntValue(data['current_stock']),
      delta: MgwsInventoryParser.parseIntValue(data['delta']),
    );
  }
}

class MgwsReconcileResult {
  const MgwsReconcileResult({
    required this.success,
    required this.message,
    required this.errors,
    this.productId,
    this.previousStock,
    this.currentStock,
    this.delta,
  });

  final bool success;
  final String message;
  final List<String> errors;
  final int? productId;
  final int? previousStock;
  final int? currentStock;
  final int? delta;

  factory MgwsReconcileResult.fromResponse(Object? raw, {int? statusCode}) {
    final data = MgwsInventoryParser.parsePayloadResponse(raw);
    final success = MgwsInventoryParser.parseSuccess(data, statusCode);
    final message = MgwsInventoryParser.parseMessage(
      data,
      success ? 'Riconciliazione completata' : 'Riconciliazione non riuscita',
    );
    return MgwsReconcileResult(
      success: success,
      message: message,
      errors: MgwsInventoryParser.parseErrors(data, message),
      productId: MgwsInventoryParser.parseIntValue(data['product_id']),
      previousStock: MgwsInventoryParser.parseIntValue(data['previous_stock']),
      currentStock: MgwsInventoryParser.parseIntValue(data['current_stock']),
      delta: MgwsInventoryParser.parseIntValue(data['delta']),
    );
  }
}

class MgwsResolvedTag {
  const MgwsResolvedTag({
    required this.tag,
    this.productId,
    this.sku,
    this.productName,
  });

  final String tag;
  final int? productId;
  final String? sku;
  final String? productName;

  factory MgwsResolvedTag.fromResponse(Object? raw) {
    if (raw is String) return MgwsResolvedTag(tag: raw);
    final data = MgwsInventoryParser.parseMapResponse(raw);
    return MgwsResolvedTag(
      tag: (data['tag'] ?? data['tag_id'] ?? '').toString(),
      productId: MgwsInventoryParser.parseIntValue(data['product_id']),
      sku: data['sku']?.toString(),
      productName: (data['product_name'] ?? data['name'])?.toString(),
    );
  }
}

class MgwsRfidScanResult {
  const MgwsRfidScanResult({
    required this.success,
    required this.message,
    required this.errors,
    required this.resolved,
    required this.unresolved,
    required this.stockUpdates,
    required this.movementCount,
    required this.mode,
  });

  final bool success;
  final String message;
  final List<String> errors;
  final List<MgwsResolvedTag> resolved;
  final List<String> unresolved;
  final int stockUpdates;
  final int movementCount;
  final String mode;

  bool get isResolveOnly => stockUpdates == 0 && movementCount == 0;

  factory MgwsRfidScanResult.fromResponse(Object? raw, {int? statusCode}) {
    final data = MgwsInventoryParser.parsePayloadResponse(raw);
    final summary = MgwsInventoryParser.parseMapResponse(data['summary']);
    final success = MgwsInventoryParser.parseSuccess(data, statusCode);
    final message = MgwsInventoryParser.parseMessage(
      data,
      success ? 'RFID risolto senza aggiornare stock' : 'RFID non risolto',
    );
    return MgwsRfidScanResult(
      success: success,
      message: message,
      errors: MgwsInventoryParser.parseErrors(data, message),
      resolved: MgwsInventoryParser.parseResolvedTags(data['resolved']),
      unresolved: MgwsInventoryParser.parseUnresolvedTags(data['unresolved']),
      stockUpdates:
          MgwsInventoryParser.parseIntValue(data['stock_updates']) ??
          MgwsInventoryParser.parseIntValue(summary['stock_updates']) ??
          0,
      movementCount:
          MgwsInventoryParser.parseIntValue(data['movement_count']) ??
          MgwsInventoryParser.parseIntValue(summary['movement_count']) ??
          0,
      mode: data['mode']?.toString() ?? 'resolve_only',
    );
  }
}

class MgwsInventoryParser {
  static Map<String, dynamic> parseMapResponse(Object? raw) {
    if (raw is! Map) return <String, dynamic>{};
    if (raw.keys.any((key) => key is! String)) return <String, dynamic>{};
    return Map<String, dynamic>.from(raw);
  }

  static Map<String, dynamic> parsePayloadResponse(Object? raw) {
    final map = parseMapResponse(raw);
    final nestedData = map['data'];
    if (nestedData is Map) return {...map, ...parseMapResponse(nestedData)};
    return map;
  }

  static List<Map<String, dynamic>> parseStockListResponse(Object? raw) {
    final source = raw is Map
        ? raw['items'] ?? raw['stock'] ?? raw['data']
        : raw;
    if (source is! List) return <Map<String, dynamic>>[];
    final items = <Map<String, dynamic>>[];
    for (final item in source) {
      final parsed = parseMapResponse(item);
      if (parsed.isEmpty) return <Map<String, dynamic>>[];
      items.add(parsed);
    }
    return items;
  }

  static int? parseIntValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool parseSuccess(Map<String, dynamic> data, int? statusCode) {
    if (data.isEmpty) return false;
    final success = data['success'];
    if (success is bool) return success;
    if (success is String) return success.toLowerCase() == 'true';
    if (statusCode == null) return data['code'] == null;
    return statusCode >= 200 && statusCode < 300;
  }

  static String parseMessage(Map<String, dynamic> data, String fallback) {
    return (data['message'] ?? data['error'] ?? data['code'] ?? fallback)
        .toString();
  }

  static List<String> parseErrors(Map<String, dynamic> data, String message) {
    final errors = data['errors'];
    if (errors is List) return errors.map((error) => error.toString()).toList();
    if (errors is String && errors.isNotEmpty) return [errors];
    if (data['success'] == false || data['code'] != null) return [message];
    return const [];
  }

  static List<MgwsResolvedTag> parseResolvedTags(Object? raw) {
    if (raw is! List) return const [];
    return raw.map(MgwsResolvedTag.fromResponse).toList();
  }

  static List<String> parseUnresolvedTags(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((item) {
      if (item is Map)
        return (item['tag'] ?? item['tag_id'] ?? item).toString();
      return item.toString();
    }).toList();
  }
}

class MgwsInventoryResponse {
  const MgwsInventoryResponse({required this.data, this.statusCode});

  final Object? data;
  final int? statusCode;
}

abstract interface class MgwsInventoryTransport {
  Future<MgwsInventoryResponse> get(
    String path, {
    Map<String, Object?>? queryParameters,
  });
  Future<MgwsInventoryResponse> post(String path, {Map<String, Object?>? data});
  Future<MgwsInventoryResponse> patch(
    String path, {
    Map<String, Object?>? data,
  });
  Future<MgwsInventoryResponse> delete(String path);
}

abstract interface class MgwsRestockGateway {
  Future<MgwsRestockResult<MgwsQuickLoad>> quickLoad(
    MgwsQuickLoadRequest request,
  );
  Future<MgwsRestockResult<List<MgwsSupplier>>> listSuppliers({int? siteId});
  Future<MgwsRestockResult<MgwsSupplier>> createSupplier(
    MgwsSupplierInput input,
  );
  Future<MgwsRestockResult<MgwsSupplier>> getSupplier(int supplierId);
  Future<MgwsRestockResult<MgwsSupplier>> updateSupplier(
    int supplierId,
    MgwsSupplierPatch patch,
  );
  Future<MgwsRestockResult<MgwsDeleteResult>> deleteSupplier(int supplierId);
  Future<MgwsRestockResult<List<MgwsReorderRule>>> listReorderRules({
    int? siteId,
    int? warehouseId,
  });
  Future<MgwsRestockResult<MgwsReorderRule>> createReorderRule(
    MgwsReorderRuleInput input,
  );
  Future<MgwsRestockResult<MgwsReorderRule>> updateReorderRule(
    int ruleId,
    MgwsReorderRulePatch patch,
  );
  Future<MgwsRestockResult<MgwsDeleteResult>> deleteReorderRule(int ruleId);
  Future<MgwsRestockResult<List<MgwsReorderSuggestion>>>
  listReorderSuggestions({int? siteId, int? warehouseId});
  Future<MgwsRestockResult<List<MgwsPurchaseOrder>>> listPurchaseOrders({
    int? siteId,
    int? supplierId,
    String? status,
  });
  Future<MgwsRestockResult<MgwsPurchaseOrder>> createPurchaseOrder(
    MgwsPurchaseOrderInput input,
  );
  Future<MgwsRestockResult<MgwsPurchaseOrder>> getPurchaseOrder(
    int purchaseOrderId,
  );
  Future<MgwsRestockResult<MgwsPurchaseOrder>> updatePurchaseOrder(
    int purchaseOrderId,
    MgwsPurchaseOrderPatch patch,
  );
  Future<MgwsRestockResult<MgwsPurchaseOrderLine>> savePurchaseOrderLine(
    int purchaseOrderId,
    MgwsPurchaseOrderLineInput input,
  );
  Future<MgwsRestockResult<MgwsPurchaseOrder>> updatePurchaseOrderStatus(
    int purchaseOrderId,
    String status,
  );
  Future<MgwsRestockResult<List<MgwsReceipt>>> listReceipts({
    int? siteId,
    int? purchaseOrderId,
    String? status,
  });
  Future<MgwsRestockResult<MgwsReceipt>> createReceipt(MgwsReceiptInput input);
  Future<MgwsRestockResult<MgwsReceipt>> getReceipt(int receiptId);
  Future<MgwsRestockResult<MgwsReceipt>> updateReceipt(
    int receiptId,
    MgwsReceiptPatch patch,
  );
  Future<MgwsRestockResult<MgwsReceipt>> convalidaReceipt(int receiptId);
  Future<MgwsRestockResult<List<MgwsBackorder>>> listBackorders({int? siteId});
  Future<MgwsRestockResult<MgwsMovementPage>> listMovements(
    MgwsMovementFilter filter,
  );
  Future<MgwsRestockResult<MgwsMovement>> getMovement(int movementId);
  Future<MgwsRestockResult<List<MgwsCountSession>>> listCountSessions({
    int? siteId,
    int? warehouseId,
  });
  Future<MgwsRestockResult<MgwsCountSession>> createCountSession(
    MgwsCountSessionInput input,
  );
  Future<MgwsRestockResult<MgwsCountSession>> getCountSession(int sessionId);
  Future<MgwsRestockResult<MgwsCountSession>> updateCountSession(
    int sessionId,
    MgwsCountSessionPatch patch,
  );
  Future<MgwsRestockResult<MgwsCountLine>> saveCountLine(
    int sessionId,
    MgwsCountLineInput input,
  );
  Future<MgwsRestockResult<MgwsCountSession>> approveCountSession(
    int sessionId,
  );
}

class MgwsRestockError {
  const MgwsRestockError({
    required this.code,
    required this.message,
    this.statusCode,
    this.details = const [],
  });

  final String code;
  final String message;
  final int? statusCode;
  final List<String> details;
}

class MgwsRestockResult<T> {
  const MgwsRestockResult._({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  final bool success;
  final String message;
  final T? data;
  final MgwsRestockError? error;

  List<String> get details => error?.details ?? const [];

  factory MgwsRestockResult.success(
    T data, {
    String message = 'Operazione MGWS completata',
  }) {
    return MgwsRestockResult._(success: true, message: message, data: data);
  }

  factory MgwsRestockResult.failure(MgwsRestockError error) {
    return MgwsRestockResult._(
      success: false,
      message: error.message,
      error: error,
    );
  }
}

class MgwsRestockParser {
  static Map<String, Object?> map(Object? raw) {
    if (raw is! Map || raw.keys.any((key) => key is! String)) return const {};
    return Map<String, Object?>.from(raw);
  }

  static Map<String, Object?> payload(Object? raw) {
    final response = map(raw);
    final nested = map(response['data']);
    return nested.isEmpty ? response : {...response, ...nested};
  }

  static List<Map<String, Object?>> list(Object? raw) {
    final source = raw is List ? raw : map(raw)['items'] ?? map(raw)['data'];
    if (source is! List) return const [];
    final values = <Map<String, Object?>>[];
    for (final item in source) {
      final parsed = map(item);
      if (parsed.isEmpty) return const [];
      values.add(parsed);
    }
    return values;
  }

  static int? integer(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble())
      return value.toInt();
    return null;
  }

  static String? string(Object? value) => value is String ? value : null;
  static bool? boolean(Object? value) => value is bool ? value : null;
  static String? nullableString(Object? value) =>
      value == null || value is String ? value as String? : null;

  static MgwsRestockError error(
    Object? raw,
    int? statusCode, {
    String fallback = 'Risposta MGWS non valida',
  }) {
    final data = payload(raw);
    final message =
        string(data['message']) ?? string(data['error']) ?? fallback;
    final code =
        string(data['code']) ??
        (statusCode == 401
            ? 'mgws_unauthorized'
            : statusCode == 403
            ? 'mgws_forbidden'
            : 'mgws_invalid_response');
    final errors = data['errors'];
    final details = errors is List
        ? errors.whereType<String>().toList(growable: false)
        : errors is String
        ? [errors]
        : <String>[];
    return MgwsRestockError(
      code: code,
      message: message,
      statusCode: statusCode,
      details: details,
    );
  }

  static bool isOk(Map<String, Object?> data, int? statusCode) {
    if (data.isEmpty ||
        (statusCode != null && (statusCode < 200 || statusCode >= 300)))
      return false;
    return data['ok'] == true || data['success'] == true || statusCode != null;
  }

  static MgwsRestockResult<T> object<T>(
    Object? raw,
    int? statusCode,
    T? Function(Map<String, Object?> value) parse, {
    String successMessage = 'Operazione MGWS completata',
  }) {
    final data = payload(raw);
    final parsed = parse(data);
    final apiError = error(raw, statusCode);
    if (!isOk(data, statusCode) ||
        parsed == null ||
        apiError.details.isNotEmpty) {
      return MgwsRestockResult.failure(apiError);
    }
    return MgwsRestockResult.success(
      parsed,
      message: string(data['message']) ?? successMessage,
    );
  }

  static MgwsRestockResult<List<T>> objects<T>(
    Object? raw,
    int? statusCode,
    T? Function(Map<String, Object?> value) parse, {
    String successMessage = 'Elenco MGWS caricato',
  }) {
    final response = map(raw);
    if ((statusCode != null && (statusCode < 200 || statusCode >= 300)) ||
        response.containsKey('code')) {
      return MgwsRestockResult.failure(error(raw, statusCode));
    }
    final values = list(raw);
    if (raw is! List &&
        !response.containsKey('items') &&
        !response.containsKey('data')) {
      return MgwsRestockResult.failure(error(raw, statusCode));
    }
    final parsed = <T>[];
    for (final value in values) {
      final item = parse(value);
      if (item == null)
        return MgwsRestockResult.failure(error(raw, statusCode));
      parsed.add(item);
    }
    return MgwsRestockResult.success(parsed, message: successMessage);
  }
}

class MgwsLocation {
  const MgwsLocation({
    required this.siteId,
    required this.warehouseId,
    required this.room,
    required this.rack,
    required this.shelf,
  });
  final int siteId;
  final int warehouseId;
  final String room;
  final String rack;
  final String shelf;

  static MgwsLocation? fromMap(Map<String, Object?> value) {
    final siteId = MgwsRestockParser.integer(value['site_id']);
    final warehouseId = MgwsRestockParser.integer(value['warehouse_id']);
    final room = MgwsRestockParser.string(value['room']);
    final rack = MgwsRestockParser.string(value['rack']);
    final shelf = MgwsRestockParser.string(value['shelf']);
    return siteId == null ||
            warehouseId == null ||
            room == null ||
            rack == null ||
            shelf == null
        ? null
        : MgwsLocation(
            siteId: siteId,
            warehouseId: warehouseId,
            room: room,
            rack: rack,
            shelf: shelf,
          );
  }
}

class MgwsQuickLoadRequest {
  const MgwsQuickLoadRequest({
    required this.productId,
    required this.quantityDelta,
    required this.reason,
    this.variationId = 0,
    this.note,
    this.barcode,
    this.warehouseId,
    this.room,
    this.rack,
    this.shelf,
    this.idempotencyKey,
  });
  final int productId;
  final int quantityDelta;
  final String reason;
  final int variationId;
  final String? note;
  final String? barcode;
  final int? warehouseId;
  final String? room;
  final String? rack;
  final String? shelf;
  final String? idempotencyKey;
  Map<String, Object?> toJson() => _compact({
    'product_id': productId,
    'quantity_delta': quantityDelta,
    'reason': reason,
    'variation_id': variationId,
    'note': note,
    'barcode': barcode,
    'warehouse_id': warehouseId,
    'room': room,
    'rack': rack,
    'shelf': shelf,
    'idempotency_key': idempotencyKey,
  });
}

class MgwsQuickLoad {
  const MgwsQuickLoad({
    required this.productId,
    required this.variationId,
    required this.quantityDelta,
    required this.previousStock,
    required this.currentStock,
    required this.reason,
    required this.movementId,
    required this.location,
  });
  final int productId;
  final int variationId;
  final int quantityDelta;
  final int previousStock;
  final int currentStock;
  final String reason;
  final int movementId;
  final MgwsLocation location;
  static MgwsQuickLoad? fromMap(Map<String, Object?> value) {
    final productId = MgwsRestockParser.integer(value['product_id']);
    final variationId = MgwsRestockParser.integer(value['variation_id']);
    final quantityDelta = MgwsRestockParser.integer(value['quantity_delta']);
    final previousStock = MgwsRestockParser.integer(value['previous_stock']);
    final currentStock = MgwsRestockParser.integer(value['current_stock']);
    final reason = MgwsRestockParser.string(value['reason']);
    final movementId = MgwsRestockParser.integer(value['movement_id']);
    final location = MgwsLocation.fromMap(
      MgwsRestockParser.map(value['location']),
    );
    return productId == null ||
            variationId == null ||
            quantityDelta == null ||
            previousStock == null ||
            currentStock == null ||
            reason == null ||
            movementId == null ||
            location == null
        ? null
        : MgwsQuickLoad(
            productId: productId,
            variationId: variationId,
            quantityDelta: quantityDelta,
            previousStock: previousStock,
            currentStock: currentStock,
            reason: reason,
            movementId: movementId,
            location: location,
          );
  }
}

class MgwsSupplierInput {
  const MgwsSupplierInput({
    required this.siteId,
    required this.supplierCode,
    required this.name,
    this.taxId,
    this.email,
    this.phone,
    this.active = true,
    this.notes,
  });
  final int siteId;
  final String supplierCode;
  final String name;
  final String? taxId;
  final String? email;
  final String? phone;
  final bool active;
  final String? notes;
  Map<String, Object?> toJson() => _compact({
    'site_id': siteId,
    'supplier_code': supplierCode,
    'name': name,
    'tax_id': taxId,
    'email': email,
    'phone': phone,
    'active': active,
    'notes': notes,
  });
}

class MgwsSupplierPatch {
  const MgwsSupplierPatch({
    this.supplierCode,
    this.name,
    this.taxId,
    this.email,
    this.phone,
    this.active,
    this.notes,
  });
  final String? supplierCode;
  final String? name;
  final String? taxId;
  final String? email;
  final String? phone;
  final bool? active;
  final String? notes;
  Map<String, Object?> toJson() => _compact({
    'supplier_code': supplierCode,
    'name': name,
    'tax_id': taxId,
    'email': email,
    'phone': phone,
    'active': active,
    'notes': notes,
  });
}

class MgwsSupplier {
  const MgwsSupplier({
    required this.id,
    required this.siteId,
    required this.supplierCode,
    required this.name,
    required this.taxId,
    required this.email,
    required this.phone,
    required this.active,
    required this.notes,
    required this.createdAtGmt,
    required this.updatedAtGmt,
  });
  final int id;
  final int siteId;
  final String supplierCode;
  final String name;
  final String taxId;
  final String email;
  final String phone;
  final bool active;
  final String notes;
  final String createdAtGmt;
  final String updatedAtGmt;
  static MgwsSupplier? fromMap(Map<String, Object?> value) {
    final id = MgwsRestockParser.integer(value['id']);
    final siteId = MgwsRestockParser.integer(value['site_id']);
    final supplierCode = MgwsRestockParser.string(value['supplier_code']);
    final name = MgwsRestockParser.string(value['name']);
    final taxId = MgwsRestockParser.string(value['tax_id']);
    final email = MgwsRestockParser.string(value['email']);
    final phone = MgwsRestockParser.string(value['phone']);
    final active = MgwsRestockParser.boolean(value['active']);
    final notes = MgwsRestockParser.string(value['notes']);
    final createdAtGmt = MgwsRestockParser.string(value['created_at_gmt']);
    final updatedAtGmt = MgwsRestockParser.string(value['updated_at_gmt']);
    return id == null ||
            siteId == null ||
            supplierCode == null ||
            name == null ||
            taxId == null ||
            email == null ||
            phone == null ||
            active == null ||
            notes == null ||
            createdAtGmt == null ||
            updatedAtGmt == null
        ? null
        : MgwsSupplier(
            id: id,
            siteId: siteId,
            supplierCode: supplierCode,
            name: name,
            taxId: taxId,
            email: email,
            phone: phone,
            active: active,
            notes: notes,
            createdAtGmt: createdAtGmt,
            updatedAtGmt: updatedAtGmt,
          );
  }
}

class MgwsDeleteResult {
  const MgwsDeleteResult({required this.id});
  final int id;
  static MgwsDeleteResult? supplier(Map<String, Object?> value) {
    final id = MgwsRestockParser.integer(value['supplier_id']);
    return value['deleted'] == true && id != null
        ? MgwsDeleteResult(id: id)
        : null;
  }

  static MgwsDeleteResult? reorderRule(Map<String, Object?> value) {
    final id = MgwsRestockParser.integer(value['rule_id']);
    return value['deleted'] == true && id != null
        ? MgwsDeleteResult(id: id)
        : null;
  }
}

Map<String, Object?> _compact(Map<String, Object?> value) {
  return Map<String, Object?>.fromEntries(
    value.entries.where((entry) => entry.value != null),
  );
}

class MgwsReorderRuleInput {
  const MgwsReorderRuleInput({
    required this.siteId,
    required this.warehouseId,
    required this.productId,
    required this.reorderPoint,
    required this.targetStock,
    required this.reorderQuantity,
    required this.leadTimeDays,
    required this.safetyDays,
    this.variationId = 0,
    this.supplierId = 0,
    this.active = true,
  });
  final int siteId;
  final int warehouseId;
  final int productId;
  final int variationId;
  final int supplierId;
  final int reorderPoint;
  final int targetStock;
  final int reorderQuantity;
  final int leadTimeDays;
  final int safetyDays;
  final bool active;
  Map<String, Object?> toJson() => {
    'site_id': siteId,
    'warehouse_id': warehouseId,
    'product_id': productId,
    'variation_id': variationId,
    'supplier_id': supplierId,
    'reorder_point': reorderPoint,
    'target_stock': targetStock,
    'reorder_quantity': reorderQuantity,
    'lead_time_days': leadTimeDays,
    'safety_days': safetyDays,
    'active': active,
  };
}

class MgwsReorderRulePatch {
  const MgwsReorderRulePatch({
    this.warehouseId,
    this.productId,
    this.variationId,
    this.supplierId,
    this.reorderPoint,
    this.targetStock,
    this.reorderQuantity,
    this.leadTimeDays,
    this.safetyDays,
    this.active,
  });
  final int? warehouseId;
  final int? productId;
  final int? variationId;
  final int? supplierId;
  final int? reorderPoint;
  final int? targetStock;
  final int? reorderQuantity;
  final int? leadTimeDays;
  final int? safetyDays;
  final bool? active;
  Map<String, Object?> toJson() => _compact({
    'warehouse_id': warehouseId,
    'product_id': productId,
    'variation_id': variationId,
    'supplier_id': supplierId,
    'reorder_point': reorderPoint,
    'target_stock': targetStock,
    'reorder_quantity': reorderQuantity,
    'lead_time_days': leadTimeDays,
    'safety_days': safetyDays,
    'active': active,
  });
}

class MgwsReorderRule {
  const MgwsReorderRule({
    required this.id,
    required this.siteId,
    required this.warehouseId,
    required this.productId,
    required this.variationId,
    required this.supplierId,
    required this.reorderPoint,
    required this.targetStock,
    required this.reorderQuantity,
    required this.leadTimeDays,
    required this.safetyDays,
    required this.active,
    required this.createdAtGmt,
    required this.updatedAtGmt,
  });
  final int id;
  final int siteId;
  final int warehouseId;
  final int productId;
  final int variationId;
  final int supplierId;
  final int reorderPoint;
  final int targetStock;
  final int reorderQuantity;
  final int leadTimeDays;
  final int safetyDays;
  final bool active;
  final String createdAtGmt;
  final String updatedAtGmt;
  static MgwsReorderRule? fromMap(Map<String, Object?> value) {
    final values = [
      'id',
      'site_id',
      'warehouse_id',
      'product_id',
      'variation_id',
      'supplier_id',
      'reorder_point',
      'target_stock',
      'reorder_quantity',
      'lead_time_days',
      'safety_days',
    ].map((key) => MgwsRestockParser.integer(value[key])).toList();
    final active = MgwsRestockParser.boolean(value['active']);
    final created = MgwsRestockParser.string(value['created_at_gmt']);
    final updated = MgwsRestockParser.string(value['updated_at_gmt']);
    if (values.any((item) => item == null) ||
        active == null ||
        created == null ||
        updated == null)
      return null;
    return MgwsReorderRule(
      id: values[0]!,
      siteId: values[1]!,
      warehouseId: values[2]!,
      productId: values[3]!,
      variationId: values[4]!,
      supplierId: values[5]!,
      reorderPoint: values[6]!,
      targetStock: values[7]!,
      reorderQuantity: values[8]!,
      leadTimeDays: values[9]!,
      safetyDays: values[10]!,
      active: active,
      createdAtGmt: created,
      updatedAtGmt: updated,
    );
  }
}

class MgwsReorderSuggestion {
  const MgwsReorderSuggestion({
    required this.ruleId,
    required this.siteId,
    required this.warehouseId,
    required this.supplierId,
    required this.productId,
    required this.variationId,
    required this.currentStock,
    required this.reorderPoint,
    required this.targetStock,
    required this.reorderQuantity,
    required this.suggestedQuantity,
    required this.leadTimeDays,
    required this.safetyDays,
  });
  final int ruleId;
  final int siteId;
  final int warehouseId;
  final int supplierId;
  final int productId;
  final int variationId;
  final int currentStock;
  final int reorderPoint;
  final int targetStock;
  final int reorderQuantity;
  final int suggestedQuantity;
  final int leadTimeDays;
  final int safetyDays;
  static MgwsReorderSuggestion? fromMap(Map<String, Object?> value) {
    final keys = [
      'rule_id',
      'site_id',
      'warehouse_id',
      'supplier_id',
      'product_id',
      'variation_id',
      'current_stock',
      'reorder_point',
      'target_stock',
      'reorder_quantity',
      'suggested_qty',
      'lead_time_days',
      'safety_days',
    ];
    final values = keys
        .map((key) => MgwsRestockParser.integer(value[key]))
        .toList();
    if (values.any((item) => item == null)) return null;
    return MgwsReorderSuggestion(
      ruleId: values[0]!,
      siteId: values[1]!,
      warehouseId: values[2]!,
      supplierId: values[3]!,
      productId: values[4]!,
      variationId: values[5]!,
      currentStock: values[6]!,
      reorderPoint: values[7]!,
      targetStock: values[8]!,
      reorderQuantity: values[9]!,
      suggestedQuantity: values[10]!,
      leadTimeDays: values[11]!,
      safetyDays: values[12]!,
    );
  }
}

class MgwsPurchaseOrderInput {
  const MgwsPurchaseOrderInput({
    required this.siteId,
    required this.supplierId,
    required this.documentNumber,
    this.warehouseId = 0,
    this.expectedAtGmt,
    this.currency = 'EUR',
    this.notes = '',
  });
  final int siteId;
  final int supplierId;
  final String documentNumber;
  final int warehouseId;
  final String? expectedAtGmt;
  final String currency;
  final String notes;
  Map<String, Object?> toJson() => _compact({
    'site_id': siteId,
    'supplier_id': supplierId,
    'document_number': documentNumber,
    'warehouse_id': warehouseId,
    'expected_at_gmt': expectedAtGmt,
    'currency': currency,
    'notes': notes,
  });
}

class MgwsPurchaseOrderPatch {
  const MgwsPurchaseOrderPatch({
    this.supplierId,
    this.documentNumber,
    this.warehouseId,
    this.expectedAtGmt,
    this.currency,
    this.notes,
  });
  final int? supplierId;
  final String? documentNumber;
  final int? warehouseId;
  final String? expectedAtGmt;
  final String? currency;
  final String? notes;
  Map<String, Object?> toJson() => _compact({
    'supplier_id': supplierId,
    'document_number': documentNumber,
    'warehouse_id': warehouseId,
    'expected_at_gmt': expectedAtGmt,
    'currency': currency,
    'notes': notes,
  });
}

class MgwsPurchaseOrderLineInput {
  const MgwsPurchaseOrderLineInput({
    this.lineId,
    this.action,
    this.productId,
    this.variationId,
    this.orderedQuantity,
    this.unitCost,
    this.supplierSku,
    this.barcode,
    this.expectedAtGmt,
  });
  final int? lineId;
  final String? action;
  final int? productId;
  final int? variationId;
  final int? orderedQuantity;
  final String? unitCost;
  final String? supplierSku;
  final String? barcode;
  final String? expectedAtGmt;
  Map<String, Object?> toJson() => _compact({
    'line_id': lineId,
    'action': action,
    'product_id': productId,
    'variation_id': variationId,
    'ordered_qty': orderedQuantity,
    'unit_cost': unitCost,
    'supplier_sku': supplierSku,
    'barcode': barcode,
    'expected_at_gmt': expectedAtGmt,
  });
}

class MgwsPurchaseOrderLine {
  const MgwsPurchaseOrderLine({
    required this.id,
    required this.purchaseOrderId,
    required this.lineNumber,
    required this.productId,
    required this.variationId,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.cancelledQuantity,
    required this.unitCost,
    required this.supplierSku,
    required this.barcode,
    required this.expectedAtGmt,
    required this.stockEffect,
    required this.createdAtGmt,
    required this.updatedAtGmt,
  });
  final int id;
  final int purchaseOrderId;
  final int lineNumber;
  final int productId;
  final int variationId;
  final int orderedQuantity;
  final int receivedQuantity;
  final int cancelledQuantity;
  final String unitCost;
  final String supplierSku;
  final String barcode;
  final String? expectedAtGmt;
  final String stockEffect;
  final String createdAtGmt;
  final String updatedAtGmt;
  static MgwsPurchaseOrderLine? fromMap(Map<String, Object?> value) {
    final keys = [
      'id',
      'purchase_order_id',
      'line_number',
      'product_id',
      'variation_id',
      'ordered_qty',
      'received_qty',
      'cancelled_qty',
    ];
    final values = keys
        .map((key) => MgwsRestockParser.integer(value[key]))
        .toList();
    final unitCost = MgwsRestockParser.string(value['unit_cost']);
    final supplierSku = MgwsRestockParser.string(value['supplier_sku']);
    final barcode = MgwsRestockParser.string(value['barcode']);
    final expected = MgwsRestockParser.nullableString(value['expected_at_gmt']);
    final effect = MgwsRestockParser.string(value['stock_effect']);
    final created = MgwsRestockParser.string(value['created_at_gmt']);
    final updated = MgwsRestockParser.string(value['updated_at_gmt']);
    if (values.any((item) => item == null) ||
        unitCost == null ||
        supplierSku == null ||
        barcode == null ||
        effect == null ||
        created == null ||
        updated == null ||
        (value['expected_at_gmt'] != null && expected == null))
      return null;
    return MgwsPurchaseOrderLine(
      id: values[0]!,
      purchaseOrderId: values[1]!,
      lineNumber: values[2]!,
      productId: values[3]!,
      variationId: values[4]!,
      orderedQuantity: values[5]!,
      receivedQuantity: values[6]!,
      cancelledQuantity: values[7]!,
      unitCost: unitCost,
      supplierSku: supplierSku,
      barcode: barcode,
      expectedAtGmt: expected,
      stockEffect: effect,
      createdAtGmt: created,
      updatedAtGmt: updated,
    );
  }
}

class MgwsPurchaseOrder {
  const MgwsPurchaseOrder({
    required this.id,
    required this.siteId,
    required this.warehouseId,
    required this.supplierId,
    required this.documentNumber,
    required this.status,
    required this.orderedAtGmt,
    required this.expectedAtGmt,
    required this.currency,
    required this.notes,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.createdAtGmt,
    required this.updatedAtGmt,
    required this.lines,
  });
  final int id;
  final int siteId;
  final int warehouseId;
  final int supplierId;
  final String documentNumber;
  final String status;
  final String? orderedAtGmt;
  final String? expectedAtGmt;
  final String currency;
  final String notes;
  final int createdByUserId;
  final int updatedByUserId;
  final String createdAtGmt;
  final String updatedAtGmt;
  final List<MgwsPurchaseOrderLine> lines;
  static MgwsPurchaseOrder? fromMap(Map<String, Object?> value) {
    final keys = [
      'id',
      'site_id',
      'warehouse_id',
      'supplier_id',
      'created_by_user_id',
      'updated_by_user_id',
    ];
    final ints = keys
        .map((key) => MgwsRestockParser.integer(value[key]))
        .toList();
    final strings = [
      'document_number',
      'status',
      'currency',
      'notes',
      'created_at_gmt',
      'updated_at_gmt',
    ].map((key) => MgwsRestockParser.string(value[key])).toList();
    final ordered = MgwsRestockParser.nullableString(value['ordered_at_gmt']);
    final expected = MgwsRestockParser.nullableString(value['expected_at_gmt']);
    final rawLines = value['lines'];
    final lines = rawLines == null
        ? const <MgwsPurchaseOrderLine>[]
        : MgwsRestockParser.list(
            rawLines,
          ).map(MgwsPurchaseOrderLine.fromMap).toList();
    if (ints.any((item) => item == null) ||
        strings.any((item) => item == null) ||
        (value['ordered_at_gmt'] != null && ordered == null) ||
        (value['expected_at_gmt'] != null && expected == null) ||
        lines.any((item) => item == null))
      return null;
    return MgwsPurchaseOrder(
      id: ints[0]!,
      siteId: ints[1]!,
      warehouseId: ints[2]!,
      supplierId: ints[3]!,
      documentNumber: strings[0]!,
      status: strings[1]!,
      orderedAtGmt: ordered,
      expectedAtGmt: expected,
      currency: strings[2]!,
      notes: strings[3]!,
      createdByUserId: ints[4]!,
      updatedByUserId: ints[5]!,
      createdAtGmt: strings[4]!,
      updatedAtGmt: strings[5]!,
      lines: lines.cast<MgwsPurchaseOrderLine>(),
    );
  }
}

class MgwsReceiptLineInput {
  const MgwsReceiptLineInput({
    required this.purchaseOrderLineId,
    required this.expectedQuantity,
    required this.receivedQuantity,
    required this.rejectedQuantity,
    required this.backorderQuantity,
    this.reasonCode = '',
  });
  final int purchaseOrderLineId;
  final int expectedQuantity;
  final int receivedQuantity;
  final int rejectedQuantity;
  final int backorderQuantity;
  final String reasonCode;
  Map<String, Object?> toJson() => {
    'purchase_order_line_id': purchaseOrderLineId,
    'expected_qty': expectedQuantity,
    'received_qty': receivedQuantity,
    'rejected_qty': rejectedQuantity,
    'backorder_qty': backorderQuantity,
    'reason_code': reasonCode,
  };
}

class MgwsReceiptInput {
  const MgwsReceiptInput({
    required this.siteId,
    required this.purchaseOrderId,
    required this.documentNumber,
    required this.lines,
    this.idempotencyKey,
    this.notes,
  });
  final int siteId;
  final int purchaseOrderId;
  final String documentNumber;
  final List<MgwsReceiptLineInput> lines;
  final String? idempotencyKey;
  final String? notes;
  Map<String, Object?> toJson() => _compact({
    'site_id': siteId,
    'purchase_order_id': purchaseOrderId,
    'document_number': documentNumber,
    'lines': lines.map((line) => line.toJson()).toList(growable: false),
    'idempotency_key': idempotencyKey,
    'notes': notes,
  });
}

class MgwsReceiptPatch {
  const MgwsReceiptPatch({this.status, this.notes});
  final String? status;
  final String? notes;
  Map<String, Object?> toJson() => _compact({'status': status, 'notes': notes});
}

class MgwsReceiptLine {
  const MgwsReceiptLine({
    required this.id,
    required this.receiptId,
    required this.lineNumber,
    required this.purchaseOrderLineId,
    required this.productId,
    required this.variationId,
    required this.expectedQuantity,
    required this.receivedQuantity,
    required this.rejectedQuantity,
    required this.backorderQuantity,
    required this.unitCost,
    required this.stockEffect,
    required this.reasonCode,
    required this.createdAtGmt,
    required this.updatedAtGmt,
  });
  final int id;
  final int receiptId;
  final int lineNumber;
  final int purchaseOrderLineId;
  final int productId;
  final int variationId;
  final int expectedQuantity;
  final int receivedQuantity;
  final int rejectedQuantity;
  final int backorderQuantity;
  final String unitCost;
  final String stockEffect;
  final String reasonCode;
  final String createdAtGmt;
  final String updatedAtGmt;
  static MgwsReceiptLine? fromMap(Map<String, Object?> value) {
    final keys = [
      'id',
      'receipt_id',
      'line_number',
      'purchase_order_line_id',
      'product_id',
      'variation_id',
      'expected_qty',
      'received_qty',
      'rejected_qty',
      'backorder_qty',
    ];
    final ints = keys
        .map((key) => MgwsRestockParser.integer(value[key]))
        .toList();
    final strings = [
      'unit_cost',
      'stock_effect',
      'reason_code',
      'created_at_gmt',
      'updated_at_gmt',
    ].map((key) => MgwsRestockParser.string(value[key])).toList();
    if (ints.any((item) => item == null) || strings.any((item) => item == null))
      return null;
    return MgwsReceiptLine(
      id: ints[0]!,
      receiptId: ints[1]!,
      lineNumber: ints[2]!,
      purchaseOrderLineId: ints[3]!,
      productId: ints[4]!,
      variationId: ints[5]!,
      expectedQuantity: ints[6]!,
      receivedQuantity: ints[7]!,
      rejectedQuantity: ints[8]!,
      backorderQuantity: ints[9]!,
      unitCost: strings[0]!,
      stockEffect: strings[1]!,
      reasonCode: strings[2]!,
      createdAtGmt: strings[3]!,
      updatedAtGmt: strings[4]!,
    );
  }
}

class MgwsReceipt {
  const MgwsReceipt({
    required this.id,
    required this.siteId,
    required this.warehouseId,
    required this.purchaseOrderId,
    required this.supplierId,
    required this.documentNumber,
    required this.status,
    required this.receivedAtGmt,
    required this.validatedAtGmt,
    required this.postedAtGmt,
    required this.validatedByUserId,
    required this.postedByUserId,
    required this.notes,
    required this.createdAtGmt,
    required this.updatedAtGmt,
    required this.lines,
  });
  final int id;
  final int siteId;
  final int warehouseId;
  final int purchaseOrderId;
  final int supplierId;
  final String documentNumber;
  final String status;
  final String? receivedAtGmt;
  final String? validatedAtGmt;
  final String? postedAtGmt;
  final int validatedByUserId;
  final int postedByUserId;
  final String notes;
  final String createdAtGmt;
  final String updatedAtGmt;
  final List<MgwsReceiptLine> lines;
  static MgwsReceipt? fromMap(Map<String, Object?> value) {
    final keys = [
      'id',
      'site_id',
      'warehouse_id',
      'purchase_order_id',
      'supplier_id',
      'validated_by_user_id',
      'posted_by_user_id',
    ];
    final ints = keys
        .map((key) => MgwsRestockParser.integer(value[key]))
        .toList();
    final strings = [
      'document_number',
      'status',
      'notes',
      'created_at_gmt',
      'updated_at_gmt',
    ].map((key) => MgwsRestockParser.string(value[key])).toList();
    final received = MgwsRestockParser.nullableString(value['received_at_gmt']);
    final validated = MgwsRestockParser.nullableString(
      value['validated_at_gmt'],
    );
    final posted = MgwsRestockParser.nullableString(value['posted_at_gmt']);
    final rawLines = value['lines'];
    final lines = rawLines == null
        ? const <MgwsReceiptLine>[]
        : MgwsRestockParser.list(
            rawLines,
          ).map(MgwsReceiptLine.fromMap).toList();
    if (ints.any((item) => item == null) ||
        strings.any((item) => item == null) ||
        (value['received_at_gmt'] != null && received == null) ||
        (value['validated_at_gmt'] != null && validated == null) ||
        (value['posted_at_gmt'] != null && posted == null) ||
        lines.any((item) => item == null))
      return null;
    return MgwsReceipt(
      id: ints[0]!,
      siteId: ints[1]!,
      warehouseId: ints[2]!,
      purchaseOrderId: ints[3]!,
      supplierId: ints[4]!,
      documentNumber: strings[0]!,
      status: strings[1]!,
      receivedAtGmt: received,
      validatedAtGmt: validated,
      postedAtGmt: posted,
      validatedByUserId: ints[5]!,
      postedByUserId: ints[6]!,
      notes: strings[2]!,
      createdAtGmt: strings[3]!,
      updatedAtGmt: strings[4]!,
      lines: lines.cast<MgwsReceiptLine>(),
    );
  }
}

class MgwsBackorder {
  const MgwsBackorder({
    required this.id,
    required this.receiptLineId,
    required this.purchaseOrderLineId,
    required this.productId,
    required this.variationId,
    required this.remainingQuantity,
    required this.status,
    required this.expectedAtGmt,
    required this.resolvedAtGmt,
    required this.createdAtGmt,
    required this.updatedAtGmt,
  });
  final int id;
  final int receiptLineId;
  final int purchaseOrderLineId;
  final int productId;
  final int variationId;
  final int remainingQuantity;
  final String status;
  final String? expectedAtGmt;
  final String? resolvedAtGmt;
  final String createdAtGmt;
  final String updatedAtGmt;
  static MgwsBackorder? fromMap(Map<String, Object?> value) {
    final keys = [
      'id',
      'receipt_line_id',
      'purchase_order_line_id',
      'product_id',
      'variation_id',
      'remaining_qty',
    ];
    final ints = keys
        .map((key) => MgwsRestockParser.integer(value[key]))
        .toList();
    final status = MgwsRestockParser.string(value['status']);
    final expected = MgwsRestockParser.nullableString(value['expected_at_gmt']);
    final resolved = MgwsRestockParser.nullableString(value['resolved_at_gmt']);
    final created = MgwsRestockParser.string(value['created_at_gmt']);
    final updated = MgwsRestockParser.string(value['updated_at_gmt']);
    if (ints.any((item) => item == null) ||
        status == null ||
        created == null ||
        updated == null ||
        (value['expected_at_gmt'] != null && expected == null) ||
        (value['resolved_at_gmt'] != null && resolved == null))
      return null;
    return MgwsBackorder(
      id: ints[0]!,
      receiptLineId: ints[1]!,
      purchaseOrderLineId: ints[2]!,
      productId: ints[3]!,
      variationId: ints[4]!,
      remainingQuantity: ints[5]!,
      status: status,
      expectedAtGmt: expected,
      resolvedAtGmt: resolved,
      createdAtGmt: created,
      updatedAtGmt: updated,
    );
  }
}

class MgwsMovementFilter {
  const MgwsMovementFilter({
    this.productId,
    this.variationId,
    this.dateFrom,
    this.dateTo,
    this.sourceType,
    this.operatorUserId,
    this.reasonCode,
    this.stockEffect,
    this.page = 1,
    this.perPage = 50,
  });
  final int? productId;
  final int? variationId;
  final String? dateFrom;
  final String? dateTo;
  final String? sourceType;
  final int? operatorUserId;
  final String? reasonCode;
  final String? stockEffect;
  final int page;
  final int perPage;
  Map<String, Object?> toQuery() => _compact({
    'product_id': productId,
    'variation_id': variationId,
    'date_from': dateFrom,
    'date_to': dateTo,
    'source_type': sourceType,
    'user_id': operatorUserId,
    'reason_code': reasonCode,
    'stock_effect': stockEffect,
    'page': page,
    'per_page': perPage,
  });
}

class MgwsMovement {
  const MgwsMovement({
    required this.id,
    required this.occurredAtGmt,
    required this.type,
    required this.stockEffect,
    required this.productId,
    required this.variationId,
    required this.quantityDelta,
    required this.stockBefore,
    required this.stockAfter,
    required this.location,
    required this.operatorUserId,
    required this.reasonCode,
    required this.note,
    required this.sourceType,
    required this.sourceId,
    required this.sourceLineId,
    required this.sourceLinks,
  });
  final int id;
  final String occurredAtGmt;
  final String type;
  final String stockEffect;
  final int productId;
  final int variationId;
  final int quantityDelta;
  final int? stockBefore;
  final int? stockAfter;
  final MgwsLocation location;
  final int operatorUserId;
  final String reasonCode;
  final String note;
  final String sourceType;
  final int sourceId;
  final int sourceLineId;
  final Map<String, int> sourceLinks;
  static MgwsMovement? fromMap(Map<String, Object?> value) {
    final keys = [
      'id',
      'product_id',
      'variation_id',
      'quantity_delta',
      'operator_user_id',
    ];
    final ints = keys
        .map((key) => MgwsRestockParser.integer(value[key]))
        .toList();
    final strings = [
      'occurred_at_gmt',
      'type',
      'stock_effect',
      'reason_code',
      'note',
    ].map((key) => MgwsRestockParser.string(value[key])).toList();
    final location = MgwsLocation.fromMap(
      MgwsRestockParser.map(value['location']),
    );
    final source = MgwsRestockParser.map(value['source']);
    final sourceType = MgwsRestockParser.string(source['type']);
    final sourceId = MgwsRestockParser.integer(source['id']);
    final sourceLineId = MgwsRestockParser.integer(source['line_id']);
    final links = <String, int>{};
    for (final entry in MgwsRestockParser.map(source['links']).entries) {
      final item = MgwsRestockParser.integer(entry.value);
      if (item == null) return null;
      links[entry.key] = item;
    }
    final before = value['stock_before'] == null
        ? null
        : MgwsRestockParser.integer(value['stock_before']);
    final after = value['stock_after'] == null
        ? null
        : MgwsRestockParser.integer(value['stock_after']);
    if (ints.any((item) => item == null) ||
        strings.any((item) => item == null) ||
        location == null ||
        sourceType == null ||
        sourceId == null ||
        sourceLineId == null ||
        (value['stock_before'] != null && before == null) ||
        (value['stock_after'] != null && after == null))
      return null;
    return MgwsMovement(
      id: ints[0]!,
      occurredAtGmt: strings[0]!,
      type: strings[1]!,
      stockEffect: strings[2]!,
      productId: ints[1]!,
      variationId: ints[2]!,
      quantityDelta: ints[3]!,
      stockBefore: before,
      stockAfter: after,
      location: location,
      operatorUserId: ints[4]!,
      reasonCode: strings[3]!,
      note: strings[4]!,
      sourceType: sourceType,
      sourceId: sourceId,
      sourceLineId: sourceLineId,
      sourceLinks: Map.unmodifiable(links),
    );
  }
}

class MgwsMovementPage {
  const MgwsMovementPage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });
  final List<MgwsMovement> items;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  static MgwsMovementPage? fromMap(Map<String, Object?> value) {
    final page = MgwsRestockParser.integer(value['page']);
    final perPage = MgwsRestockParser.integer(value['per_page']);
    final total = MgwsRestockParser.integer(value['total']);
    final totalPages = MgwsRestockParser.integer(value['total_pages']);
    final raw = MgwsRestockParser.list(value['items']);
    final items = raw.map(MgwsMovement.fromMap).toList();
    return page == null ||
            perPage == null ||
            total == null ||
            totalPages == null ||
            items.any((item) => item == null)
        ? null
        : MgwsMovementPage(
            items: items.cast<MgwsMovement>(),
            page: page,
            perPage: perPage,
            total: total,
            totalPages: totalPages,
          );
  }
}

class MgwsCountSessionInput {
  const MgwsCountSessionInput({
    required this.siteId,
    required this.warehouseId,
    required this.documentNumber,
    this.notes = '',
  });
  final int siteId;
  final int warehouseId;
  final String documentNumber;
  final String notes;
  Map<String, Object?> toJson() => {
    'site_id': siteId,
    'warehouse_id': warehouseId,
    'document_number': documentNumber,
    'notes': notes,
  };
}

class MgwsCountSessionPatch {
  const MgwsCountSessionPatch({this.documentNumber, this.notes});
  final String? documentNumber;
  final String? notes;
  Map<String, Object?> toJson() =>
      _compact({'document_number': documentNumber, 'notes': notes});
}

class MgwsCountLineInput {
  const MgwsCountLineInput({
    required this.physicalQuantity,
    this.productId,
    this.variationId,
    this.barcode,
    this.tag,
    this.warehouseId,
    this.room = '',
    this.rack = '',
    this.shelf = '',
    this.reasonCode = '',
  });
  final int physicalQuantity;
  final int? productId;
  final int? variationId;
  final String? barcode;
  final String? tag;
  final int? warehouseId;
  final String room;
  final String rack;
  final String shelf;
  final String reasonCode;
  Map<String, Object?> toJson() => _compact({
    'physical_qty': physicalQuantity,
    'product_id': productId,
    'variation_id': variationId,
    'barcode': barcode,
    'tag': tag,
    'warehouse_id': warehouseId,
    'room': room,
    'rack': rack,
    'shelf': shelf,
    'reason_code': reasonCode,
  });
}

class MgwsCountLine {
  const MgwsCountLine({
    required this.id,
    required this.countSessionId,
    required this.warehouseId,
    required this.productId,
    required this.variationId,
    required this.room,
    required this.rack,
    required this.shelf,
    required this.bookQuantity,
    required this.physicalQuantity,
    required this.discrepancyQuantity,
    required this.reasonCode,
    required this.stockMoveId,
    required this.countedByUserId,
    required this.countedAtGmt,
    required this.createdAtGmt,
    required this.updatedAtGmt,
  });
  final int id;
  final int countSessionId;
  final int warehouseId;
  final int productId;
  final int variationId;
  final String room;
  final String rack;
  final String shelf;
  final int bookQuantity;
  final int physicalQuantity;
  final int discrepancyQuantity;
  final String reasonCode;
  final int stockMoveId;
  final int countedByUserId;
  final String? countedAtGmt;
  final String createdAtGmt;
  final String updatedAtGmt;
  static MgwsCountLine? fromMap(Map<String, Object?> value) {
    final keys = [
      'id',
      'count_session_id',
      'warehouse_id',
      'product_id',
      'variation_id',
      'book_qty',
      'physical_qty',
      'discrepancy_qty',
      'stock_move_id',
      'counted_by_user_id',
    ];
    final ints = keys
        .map((key) => MgwsRestockParser.integer(value[key]))
        .toList();
    final strings = [
      'room',
      'rack',
      'shelf',
      'reason_code',
      'created_at_gmt',
      'updated_at_gmt',
    ].map((key) => MgwsRestockParser.string(value[key])).toList();
    final counted = MgwsRestockParser.nullableString(value['counted_at_gmt']);
    if (ints.any((item) => item == null) ||
        strings.any((item) => item == null) ||
        (value['counted_at_gmt'] != null && counted == null))
      return null;
    return MgwsCountLine(
      id: ints[0]!,
      countSessionId: ints[1]!,
      warehouseId: ints[2]!,
      productId: ints[3]!,
      variationId: ints[4]!,
      room: strings[0]!,
      rack: strings[1]!,
      shelf: strings[2]!,
      bookQuantity: ints[5]!,
      physicalQuantity: ints[6]!,
      discrepancyQuantity: ints[7]!,
      reasonCode: strings[3]!,
      stockMoveId: ints[8]!,
      countedByUserId: ints[9]!,
      countedAtGmt: counted,
      createdAtGmt: strings[4]!,
      updatedAtGmt: strings[5]!,
    );
  }
}

class MgwsCountSession {
  const MgwsCountSession({
    required this.id,
    required this.siteId,
    required this.warehouseId,
    required this.documentNumber,
    required this.status,
    required this.startedByUserId,
    required this.approvedByUserId,
    required this.startedAtGmt,
    required this.approvedAtGmt,
    required this.postedAtGmt,
    required this.notes,
    required this.createdAtGmt,
    required this.updatedAtGmt,
    required this.lines,
  });
  final int id;
  final int siteId;
  final int warehouseId;
  final String documentNumber;
  final String status;
  final int startedByUserId;
  final int approvedByUserId;
  final String? startedAtGmt;
  final String? approvedAtGmt;
  final String? postedAtGmt;
  final String notes;
  final String createdAtGmt;
  final String updatedAtGmt;
  final List<MgwsCountLine> lines;
  static MgwsCountSession? fromMap(Map<String, Object?> value) {
    final keys = [
      'id',
      'site_id',
      'warehouse_id',
      'started_by_user_id',
      'approved_by_user_id',
    ];
    final ints = keys
        .map((key) => MgwsRestockParser.integer(value[key]))
        .toList();
    final strings = [
      'document_number',
      'status',
      'notes',
      'created_at_gmt',
      'updated_at_gmt',
    ].map((key) => MgwsRestockParser.string(value[key])).toList();
    final started = MgwsRestockParser.nullableString(value['started_at_gmt']);
    final approved = MgwsRestockParser.nullableString(value['approved_at_gmt']);
    final posted = MgwsRestockParser.nullableString(value['posted_at_gmt']);
    final rawLines = value['lines'];
    final lines = rawLines == null
        ? const <MgwsCountLine>[]
        : MgwsRestockParser.list(rawLines).map(MgwsCountLine.fromMap).toList();
    if (ints.any((item) => item == null) ||
        strings.any((item) => item == null) ||
        (value['started_at_gmt'] != null && started == null) ||
        (value['approved_at_gmt'] != null && approved == null) ||
        (value['posted_at_gmt'] != null && posted == null) ||
        lines.any((item) => item == null))
      return null;
    return MgwsCountSession(
      id: ints[0]!,
      siteId: ints[1]!,
      warehouseId: ints[2]!,
      documentNumber: strings[0]!,
      status: strings[1]!,
      startedByUserId: ints[3]!,
      approvedByUserId: ints[4]!,
      startedAtGmt: started,
      approvedAtGmt: approved,
      postedAtGmt: posted,
      notes: strings[2]!,
      createdAtGmt: strings[3]!,
      updatedAtGmt: strings[4]!,
      lines: lines.cast<MgwsCountLine>(),
    );
  }
}
