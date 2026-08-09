import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'inventory_restock_feedback.code.dart';

export 'inventory_counts.code.dart';
export 'inventory_movements.code.dart';
export 'inventory_purchase_orders.code.dart';
export 'inventory_quick_load.code.dart';
export 'inventory_receipts.code.dart';
export 'inventory_reorder.code.dart';
export 'inventory_restock_feedback.code.dart';
export 'inventory_suppliers.code.dart';

class InventoryController {
  InventoryController({MgwsInventoryGateway? gateway})
    : gateway = gateway ?? QueryMgwsInventory();

  final MgwsInventoryGateway gateway;

  List<Map<String, dynamic>> stockRows = const [];
  InventoryActionFeedback? lastFeedback;
  MgwsStockSyncResult? lastSyncResult;
  MgwsReconcileResult? lastReconcileResult;
  MgwsRfidScanResult? lastRfidResult;
  bool? isMgwsAvailable;
  bool isCheckingAvailability = false;
  bool isLoadingStock = false;
  bool isSyncing = false;
  bool isReconciling = false;
  bool isResolvingRfid = false;

  Future<InventoryActionFeedback> checkMgwsReadiness() async {
    isCheckingAvailability = true;
    try {
      final available = await gateway.isInventoryServiceAvailable();
      isMgwsAvailable = available;
      return _remember(
        InventoryActionFeedback(
          success: available,
          message: available
              ? 'Backend MGWS disponibile'
              : 'Backend MGWS richiesto: accedi o configura il backend MGWS',
        ),
      );
    } finally {
      isCheckingAvailability = false;
    }
  }

  Future<InventoryActionFeedback> loadStock({String? productIdText}) async {
    isLoadingStock = true;
    try {
      final productId = _optionalProductId(productIdText ?? '');
      stockRows = productId == null
          ? await gateway.getAllStock()
          : [await gateway.getProductStock(productId)];
      return _remember(
        InventoryActionFeedback(
          success: true,
          message: stockRows.isEmpty
              ? 'Nessuna riga stock disponibile'
              : 'Stock caricato: ${stockRows.length} righe',
        ),
      );
    } catch (e) {
      return _remember(
        InventoryActionFeedback(
          success: false,
          message: 'Errore caricamento stock MGWS: $e',
        ),
      );
    } finally {
      isLoadingStock = false;
    }
  }

  Future<InventoryActionFeedback> syncWooToMgws({
    required String productIdText,
    required String wooStockText,
  }) async {
    final productId = InventoryInputParser.parseProductId(productIdText);
    if (productId == null) return _validationError('product_id non valido');
    final wooStock = InventoryInputParser.parseStock(wooStockText);
    if (wooStock == null) return _validationError('woo_stock non valido');

    isSyncing = true;
    try {
      final result = await gateway.syncWooStockToMgws(
        productId: productId,
        wooStock: wooStock,
        syncType: 'manual',
      );
      lastSyncResult = result;
      return _remember(
        InventoryActionFeedback(
          success: result.success,
          message: _stockMessage(
            'Sync Woo -> MGWS',
            result.message,
            result.delta,
          ),
          details: result.errors,
        ),
      );
    } catch (e) {
      return _remember(
        InventoryActionFeedback(
          success: false,
          message: 'Errore sync MGWS: $e',
        ),
      );
    } finally {
      isSyncing = false;
    }
  }

  Future<InventoryActionFeedback> reconcileStock({
    required String productIdText,
    required String correctStockText,
    required String reasonText,
  }) async {
    final productId = InventoryInputParser.parseProductId(productIdText);
    if (productId == null) return _validationError('product_id non valido');
    final correctStock = InventoryInputParser.parseStock(correctStockText);
    if (correctStock == null)
      return _validationError('correct_stock non valido');
    final reason = reasonText.trim();
    if (reason.isEmpty) return _validationError('reason richiesto');

    isReconciling = true;
    try {
      final result = await gateway.reconcileStock(
        productId: productId,
        correctStock: correctStock,
        reason: reason,
      );
      lastReconcileResult = result;
      return _remember(
        InventoryActionFeedback(
          success: result.success,
          message: _stockMessage(
            'Reconcile stock',
            result.message,
            result.delta,
          ),
          details: result.errors,
        ),
      );
    } catch (e) {
      return _remember(
        InventoryActionFeedback(
          success: false,
          message: 'Errore reconcile MGWS: $e',
        ),
      );
    } finally {
      isReconciling = false;
    }
  }

  Future<InventoryActionFeedback> resolveRfidScan(String rawTags) async {
    final tags = InventoryInputParser.parseTags(rawTags);
    if (tags.isEmpty) return _validationError('Inserisci almeno un tag RFID');

    isResolvingRfid = true;
    try {
      final result = await gateway.resolveRfidScan(tagIds: tags);
      lastRfidResult = result;
      final suffix = result.isResolveOnly ? 'Nessuna quantita aggiornata.' : '';
      return _remember(
        InventoryActionFeedback(
          success: result.success,
          message:
              'RFID resolve-only: ${result.resolved.length} risolti, '
              '${result.unresolved.length} non risolti. $suffix',
          details: [...result.errors, ...result.unresolved],
        ),
      );
    } catch (e) {
      return _remember(
        InventoryActionFeedback(
          success: false,
          message: 'Errore RFID MGWS: $e',
        ),
      );
    } finally {
      isResolvingRfid = false;
    }
  }

  int? _optionalProductId(String value) {
    if (value.trim().isEmpty) return null;
    return InventoryInputParser.parseProductId(value);
  }

  InventoryActionFeedback _validationError(String message) {
    return _remember(InventoryActionFeedback(success: false, message: message));
  }

  InventoryActionFeedback _remember(InventoryActionFeedback feedback) {
    lastFeedback = feedback;
    return feedback;
  }

  String _stockMessage(String action, String message, int? delta) {
    if (delta == null) return '$action: $message';
    final sign = delta > 0 ? '+' : '';
    return '$action: $message (delta $sign$delta)';
  }
}
