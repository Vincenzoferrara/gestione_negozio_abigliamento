import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';

class FakeMgwsRestockGateway implements MgwsRestockGateway {
  int quickLoadCalls = 0;
  int createSupplierCalls = 0;
  int updateSupplierCalls = 0;
  int deleteSupplierCalls = 0;
  int listSuppliersCalls = 0;
  int getSupplierCalls = 0;
  int listReorderSuggestionsCalls = 0;
  int listPurchaseOrdersCalls = 0;
  int getPurchaseOrderCalls = 0;
  int updatePurchaseOrderCalls = 0;
  int createPurchaseOrderCalls = 0;
  int savePurchaseOrderLineCalls = 0;
  int updatePurchaseOrderStatusCalls = 0;
  int createReceiptCalls = 0;
  int listReceiptsCalls = 0;
  int getReceiptCalls = 0;
  int convalidaReceiptCalls = 0;
  int listMovementsCalls = 0;
  int createCountSessionCalls = 0;
  int getCountSessionCalls = 0;
  int saveCountLineCalls = 0;
  int approveCountSessionCalls = 0;

  MgwsQuickLoadRequest? quickLoadRequest;
  final List<MgwsQuickLoadRequest> quickLoadRequests = <MgwsQuickLoadRequest>[];
  MgwsSupplierInput? supplierInput;
  MgwsSupplierPatch? supplierPatch;
  int? supplierId;
  MgwsPurchaseOrderInput? purchaseOrderInput;
  MgwsPurchaseOrderLineInput? purchaseOrderLineInput;
  int? purchaseOrderId;
  String? purchaseOrderStatus;
  MgwsPurchaseOrderPatch? purchaseOrderPatch;
  MgwsReceiptInput? receiptInput;
  int? receiptId;
  MgwsMovementFilter? movementFilter;
  MgwsCountSessionInput? countSessionInput;
  MgwsCountLineInput? countLineInput;
  int? countSessionId;

  MgwsRestockResult<MgwsQuickLoad>? quickLoadResponse;
  MgwsRestockResult<List<MgwsSupplier>>? suppliersResponse;
  MgwsRestockResult<MgwsSupplier>? supplierResponse;
  MgwsRestockResult<MgwsDeleteResult>? deleteSupplierResponse;
  MgwsRestockResult<List<MgwsReorderSuggestion>>? reorderSuggestionsResponse;
  MgwsRestockResult<List<MgwsPurchaseOrder>>? purchaseOrdersResponse;
  MgwsRestockResult<MgwsPurchaseOrder>? purchaseOrderResponse;
  MgwsRestockResult<MgwsPurchaseOrderLine>? purchaseOrderLineResponse;
  MgwsRestockResult<List<MgwsReceipt>>? receiptsResponse;
  MgwsRestockResult<MgwsReceipt>? receiptResponse;
  MgwsRestockResult<MgwsMovementPage>? movementsResponse;
  MgwsRestockResult<MgwsCountSession>? countSessionResponse;
  MgwsRestockResult<MgwsCountLine>? countLineResponse;
  Future<MgwsRestockResult<MgwsReceipt>> Function(MgwsReceiptInput)?
  onCreateReceipt;
  Future<MgwsRestockResult<MgwsQuickLoad>> Function(MgwsQuickLoadRequest)?
  onQuickLoad;
  Future<MgwsRestockResult<MgwsReceipt>> Function(int)? onConvalidaReceipt;
  Future<MgwsRestockResult<MgwsCountSession>> Function(int)?
  onApproveCountSession;

  int get stockWorkflowCalls =>
      quickLoadCalls +
      createReceiptCalls +
      convalidaReceiptCalls +
      approveCountSessionCalls;

  @override
  Future<MgwsRestockResult<MgwsQuickLoad>> quickLoad(
    MgwsQuickLoadRequest request,
  ) {
    quickLoadCalls++;
    quickLoadRequest = request;
    quickLoadRequests.add(request);
    return onQuickLoad?.call(request) ??
        Future.value(quickLoadResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<List<MgwsSupplier>>> listSuppliers({int? siteId}) {
    listSuppliersCalls++;
    return Future.value(suppliersResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsSupplier>> createSupplier(
    MgwsSupplierInput input,
  ) {
    createSupplierCalls++;
    supplierInput = input;
    return Future.value(supplierResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsSupplier>> getSupplier(int supplierId) {
    getSupplierCalls++;
    this.supplierId = supplierId;
    return Future.value(supplierResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsSupplier>> updateSupplier(
    int supplierId,
    MgwsSupplierPatch patch,
  ) {
    updateSupplierCalls++;
    this.supplierId = supplierId;
    supplierPatch = patch;
    return Future.value(supplierResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsDeleteResult>> deleteSupplier(int supplierId) {
    deleteSupplierCalls++;
    this.supplierId = supplierId;
    return Future.value(deleteSupplierResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<List<MgwsReorderRule>>> listReorderRules({
    int? siteId,
    int? warehouseId,
  }) => Future.value(_failure());

  @override
  Future<MgwsRestockResult<MgwsReorderRule>> createReorderRule(
    MgwsReorderRuleInput input,
  ) => Future.value(_failure());

  @override
  Future<MgwsRestockResult<MgwsReorderRule>> updateReorderRule(
    int ruleId,
    MgwsReorderRulePatch patch,
  ) => Future.value(_failure());

  @override
  Future<MgwsRestockResult<MgwsDeleteResult>> deleteReorderRule(int ruleId) =>
      Future.value(_failure());

  @override
  Future<MgwsRestockResult<List<MgwsReorderSuggestion>>>
  listReorderSuggestions({int? siteId, int? warehouseId}) {
    listReorderSuggestionsCalls++;
    return Future.value(reorderSuggestionsResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<List<MgwsPurchaseOrder>>> listPurchaseOrders({
    int? siteId,
    int? supplierId,
    String? status,
  }) {
    listPurchaseOrdersCalls++;
    return Future.value(purchaseOrdersResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsPurchaseOrder>> createPurchaseOrder(
    MgwsPurchaseOrderInput input,
  ) {
    createPurchaseOrderCalls++;
    purchaseOrderInput = input;
    return Future.value(purchaseOrderResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsPurchaseOrder>> getPurchaseOrder(
    int purchaseOrderId,
  ) {
    getPurchaseOrderCalls++;
    this.purchaseOrderId = purchaseOrderId;
    return Future.value(purchaseOrderResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsPurchaseOrder>> updatePurchaseOrder(
    int purchaseOrderId,
    MgwsPurchaseOrderPatch patch,
  ) {
    updatePurchaseOrderCalls++;
    this.purchaseOrderId = purchaseOrderId;
    purchaseOrderPatch = patch;
    return Future.value(purchaseOrderResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsPurchaseOrderLine>> savePurchaseOrderLine(
    int purchaseOrderId,
    MgwsPurchaseOrderLineInput input,
  ) {
    savePurchaseOrderLineCalls++;
    this.purchaseOrderId = purchaseOrderId;
    purchaseOrderLineInput = input;
    return Future.value(purchaseOrderLineResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsPurchaseOrder>> updatePurchaseOrderStatus(
    int purchaseOrderId,
    String status,
  ) {
    updatePurchaseOrderStatusCalls++;
    this.purchaseOrderId = purchaseOrderId;
    purchaseOrderStatus = status;
    return Future.value(purchaseOrderResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<List<MgwsReceipt>>> listReceipts({
    int? siteId,
    int? purchaseOrderId,
    String? status,
  }) {
    listReceiptsCalls++;
    this.purchaseOrderId = purchaseOrderId;
    purchaseOrderStatus = status;
    return Future.value(receiptsResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsReceipt>> createReceipt(MgwsReceiptInput input) {
    createReceiptCalls++;
    receiptInput = input;
    return onCreateReceipt?.call(input) ??
        Future.value(receiptResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsReceipt>> getReceipt(int receiptId) {
    getReceiptCalls++;
    this.receiptId = receiptId;
    return Future.value(receiptResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsReceipt>> updateReceipt(
    int receiptId,
    MgwsReceiptPatch patch,
  ) => Future.value(_failure());

  @override
  Future<MgwsRestockResult<MgwsReceipt>> convalidaReceipt(int receiptId) {
    convalidaReceiptCalls++;
    this.receiptId = receiptId;
    return onConvalidaReceipt?.call(receiptId) ??
        Future.value(receiptResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<List<MgwsBackorder>>> listBackorders({
    int? siteId,
  }) => Future.value(_failure());

  @override
  Future<MgwsRestockResult<MgwsMovementPage>> listMovements(
    MgwsMovementFilter filter,
  ) {
    listMovementsCalls++;
    movementFilter = filter;
    return Future.value(movementsResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsMovement>> getMovement(int movementId) =>
      Future.value(_failure());

  @override
  Future<MgwsRestockResult<List<MgwsCountSession>>> listCountSessions({
    int? siteId,
    int? warehouseId,
  }) => Future.value(_failure());

  @override
  Future<MgwsRestockResult<MgwsCountSession>> createCountSession(
    MgwsCountSessionInput input,
  ) {
    createCountSessionCalls++;
    countSessionInput = input;
    return Future.value(countSessionResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsCountSession>> getCountSession(int sessionId) {
    getCountSessionCalls++;
    countSessionId = sessionId;
    return Future.value(countSessionResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsCountSession>> updateCountSession(
    int sessionId,
    MgwsCountSessionPatch patch,
  ) => Future.value(_failure());

  @override
  Future<MgwsRestockResult<MgwsCountLine>> saveCountLine(
    int sessionId,
    MgwsCountLineInput input,
  ) {
    saveCountLineCalls++;
    countSessionId = sessionId;
    countLineInput = input;
    return Future.value(countLineResponse ?? _failure());
  }

  @override
  Future<MgwsRestockResult<MgwsCountSession>> approveCountSession(
    int sessionId,
  ) {
    approveCountSessionCalls++;
    countSessionId = sessionId;
    return onApproveCountSession?.call(sessionId) ??
        Future.value(countSessionResponse ?? _failure());
  }

  MgwsRestockResult<T> _failure<T>() {
    return MgwsRestockResult.failure(
      const MgwsRestockError(
        code: 'fake_unconfigured',
        message: 'Fake gateway non configurato',
      ),
    );
  }
}
