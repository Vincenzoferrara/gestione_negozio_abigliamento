import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/mgws_availability.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/class_prodotti.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/prodotti_crea/prodotti_crea.code.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/prodotti_crea/prodotti_crea.gui.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

class _FakeMgwsInventoryGateway implements MgwsInventoryGateway {
  _FakeMgwsInventoryGateway({this.reconcileResult, this.reconcileError});

  final MgwsReconcileResult? reconcileResult;
  final Object? reconcileError;
  var reconcileCalls = 0;
  var successfulReconcileCalls = 0;
  int? productId;
  int? correctStock;
  String? reason;

  @override
  Future<List<Map<String, dynamic>>> getAllStock() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getLowStockItems() async => const [];

  @override
  Future<Map<String, dynamic>> getProductStock(int productId) async => const {};

  @override
  Future<Map<String, dynamic>> getStatistics() async => const {};

  @override
  Future<bool> isInventoryServiceAvailable() async => true;

  @override
  Future<MgwsReconcileResult> reconcileStock({
    required int productId,
    required int correctStock,
    required String reason,
  }) async {
    reconcileCalls++;
    this.productId = productId;
    this.correctStock = correctStock;
    this.reason = reason;
    if (reconcileError != null) {
      throw reconcileError!;
    }
    final result =
        reconcileResult ??
        MgwsReconcileResult(
          success: true,
          message: 'Rettifica registrata',
          errors: const [],
          productId: productId,
          previousStock: 2,
          currentStock: correctStock,
          delta: correctStock - 2,
        );
    if (result.success && result.errors.isEmpty) {
      successfulReconcileCalls++;
    }
    return result;
  }

  @override
  Future<MgwsRfidScanResult> resolveRfidScan({
    required List<String> tagIds,
  }) async {
    return MgwsRfidScanResult.fromResponse({'success': true});
  }

  @override
  Future<MgwsStockSyncResult> syncWooStockToMgws({
    required int productId,
    required int wooStock,
    required String syncType,
  }) async {
    return MgwsStockSyncResult.fromResponse({'success': true});
  }
}

class _StaticMgwsAvailabilityChecker implements MgwsAvailabilityChecker {
  const _StaticMgwsAvailabilityChecker(this.result);

  final bool result;

  @override
  Future<bool> check() async => result;
}

Future<MgwsAvailability> _mgwsAvailability(bool isAvailable) async {
  final availability = MgwsAvailability(
    checker: _StaticMgwsAvailabilityChecker(isAvailable),
  );
  await availability.refresh();
  return availability;
}

class _FakeProdottiCreaController extends ProdottiCreaController {
  _FakeProdottiCreaController(_FakeMgwsInventoryGateway gateway)
    : super(inventoryGateway: gateway);

  @override
  Future<List<dynamic>> getAttributes({bool forceRefresh = false}) async {
    return const [];
  }

  @override
  Future<List<CategoriaProdotto>> getCategories({
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<List<MarcaProdotto>> getBrands({bool forceRefresh = false}) async {
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProdottiCrea MGWS inventory reconcile', () {
    test('does not call MGWS when saved product has no valid id', () async {
      final gateway = _FakeMgwsInventoryGateway();
      final controller = ProdottiCreaController(inventoryGateway: gateway);

      final feedback = await controller.reconcileMgwsStockAfterSave(
        savedProduct: ProdottoGlobal(id: 0),
        input: const ProductMgwsStockInput(
          stockText: '7',
          reasonText: 'Stock iniziale prodotto da app Flutter',
        ),
      );

      expect(feedback.success, isFalse);
      expect(feedback.message, contains('product_id'));
      expect(gateway.reconcileCalls, 0);
    });

    test('validates stock and reason before calling MGWS', () async {
      final gateway = _FakeMgwsInventoryGateway();
      final controller = ProdottiCreaController(inventoryGateway: gateway);

      final invalidStock = await controller.reconcileMgwsStockAfterSave(
        savedProduct: ProdottoGlobal(id: 42),
        input: const ProductMgwsStockInput(
          stockText: '-1',
          reasonText: 'Stock iniziale prodotto da app Flutter',
        ),
      );
      final missingReason = await controller.reconcileMgwsStockAfterSave(
        savedProduct: ProdottoGlobal(id: 42),
        input: const ProductMgwsStockInput(stockText: '7', reasonText: ' '),
      );

      expect(invalidStock.success, isFalse);
      expect(invalidStock.message, contains('stock'));
      expect(missingReason.success, isFalse);
      expect(missingReason.message, contains('motivo'));
      expect(gateway.reconcileCalls, 0);
    });

    test('calls reconcile after product save returns a valid id', () async {
      final gateway = _FakeMgwsInventoryGateway();
      final controller = ProdottiCreaController(
        inventoryGateway: gateway,
        availability: await _mgwsAvailability(true),
      );

      final feedback = await controller.reconcileMgwsStockAfterSave(
        savedProduct: ProdottoGlobal(id: 42),
        input: const ProductMgwsStockInput(
          stockText: '9',
          reasonText: 'Rettifica inventario fisico',
        ),
      );

      expect(feedback.success, isTrue);
      expect(feedback.message, contains('Rettifica registrata'));
      expect(gateway.reconcileCalls, 1);
      expect(gateway.successfulReconcileCalls, 1);
      expect(gateway.productId, 42);
      expect(gateway.correctStock, 9);
      expect(gateway.reason, 'Rettifica inventario fisico');
    });

    test('returns partial feedback when MGWS rejects reconciliation', () async {
      final gateway = _FakeMgwsInventoryGateway(
        reconcileResult: const MgwsReconcileResult(
          success: false,
          message: 'Stock MGWS non aggiornato',
          errors: ['Movimento non registrato'],
        ),
      );
      final controller = ProdottiCreaController(
        inventoryGateway: gateway,
        availability: await _mgwsAvailability(true),
      );

      final feedback = await controller.reconcileMgwsStockAfterSave(
        savedProduct: ProdottoGlobal(id: 42),
        input: const ProductMgwsStockInput(
          stockText: '9',
          reasonText: 'Rettifica inventario fisico',
        ),
      );

      expect(feedback.success, isFalse);
      expect(feedback.message, contains('Stock MGWS non aggiornato'));
      expect(feedback.details, ['Movimento non registrato']);
      expect(gateway.reconcileCalls, 1);
      expect(gateway.successfulReconcileCalls, 0);
    });

    test('returns failure feedback when MGWS reconciliation throws', () async {
      final gateway = _FakeMgwsInventoryGateway(
        reconcileError: StateError('MGWS non raggiungibile'),
      );
      final controller = ProdottiCreaController(
        inventoryGateway: gateway,
        availability: await _mgwsAvailability(true),
      );

      final feedback = await controller.reconcileMgwsStockAfterSave(
        savedProduct: ProdottoGlobal(id: 42),
        input: const ProductMgwsStockInput(
          stockText: '9',
          reasonText: 'Rettifica inventario fisico',
        ),
      );

      expect(feedback.success, isFalse);
      expect(feedback.message, contains('MGWS non raggiungibile'));
      expect(gateway.reconcileCalls, 1);
      expect(gateway.successfulReconcileCalls, 0);
    });

    test('treats MGWS success responses with errors as unsuccessful', () async {
      final gateway = _FakeMgwsInventoryGateway(
        reconcileResult: const MgwsReconcileResult(
          success: true,
          message: 'Rettifica registrata con avvisi',
          errors: ['Audit non completo'],
        ),
      );
      final controller = ProdottiCreaController(
        inventoryGateway: gateway,
        availability: await _mgwsAvailability(true),
      );

      final feedback = await controller.reconcileMgwsStockAfterSave(
        savedProduct: ProdottoGlobal(id: 42),
        input: const ProductMgwsStockInput(
          stockText: '9',
          reasonText: 'Rettifica inventario fisico',
        ),
      );

      expect(feedback.success, isFalse);
      expect(feedback.message, contains('Rettifica registrata con avvisi'));
      expect(feedback.details, ['Audit non completo']);
      expect(gateway.reconcileCalls, 1);
      expect(gateway.successfulReconcileCalls, 0);
    });

    test('does not call MGWS stock reconciliation when unavailable', () async {
      final gateway = _FakeMgwsInventoryGateway();
      final controller = ProdottiCreaController(
        inventoryGateway: gateway,
        availability: await _mgwsAvailability(false),
      );

      final feedback = await controller.reconcileMgwsStockAfterSave(
        savedProduct: ProdottoGlobal(id: 42),
        input: const ProductMgwsStockInput(
          stockText: '9',
          reasonText: 'Rettifica inventario fisico',
        ),
      );

      expect(feedback.success, isFalse);
      expect(feedback.message, contains('backend non disponibile'));
      expect(gateway.reconcileCalls, 0);
    });
  });

  group('ProdottiCrea MGWS form validation', () {
    test('skips stock and reason validation when MGWS is disabled', () {
      expect(validateProductMgwsStock(enabled: false, value: ''), isNull);
      expect(validateProductMgwsReason(enabled: false, value: ' '), isNull);
    });

    test('rejects empty, non-numeric, and negative enabled stock', () {
      expect(
        validateProductMgwsStock(enabled: true, value: ''),
        'Stock MGWS obbligatorio',
      );
      expect(
        validateProductMgwsStock(enabled: true, value: 'abc'),
        'Inserisci un intero non negativo',
      );
      expect(
        validateProductMgwsStock(enabled: true, value: '-1'),
        'Inserisci un intero non negativo',
      );
      expect(validateProductMgwsStock(enabled: true, value: '0'), isNull);
    });

    test('requires a non-blank enabled reason', () {
      expect(
        validateProductMgwsReason(enabled: true, value: ' '),
        'Motivo obbligatorio',
      );
      expect(
        validateProductMgwsReason(enabled: true, value: 'Audit fisico'),
        isNull,
      );
    });
  });

  testWidgets('shows MGWS fields only when enabled and validates them', (
    tester,
  ) async {
    final gateway = _FakeMgwsInventoryGateway();
    final controller = _FakeProdottiCreaController(gateway);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProdottiCreaPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avanti').first);
    await tester.pump();

    final switchFinder = find.byKey(
      const ValueKey('productMgwsInventoryEnabledSwitch'),
    );
    final stockFinder = find.byKey(const ValueKey('productMgwsStockField'));
    final reasonFinder = find.byKey(const ValueKey('productMgwsReasonField'));

    expect(switchFinder, findsOneWidget);
    expect(stockFinder, findsNothing);
    expect(reasonFinder, findsNothing);
    expect(gateway.reconcileCalls, 0);

    tester.widget<SwitchListTile>(switchFinder).onChanged?.call(true);
    await tester.pump();
    expect(stockFinder, findsOneWidget);
    expect(reasonFinder, findsOneWidget);

    await tester.enterText(stockFinder, '');
    await tester.enterText(reasonFinder, '');
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    expect(
      tester.widget<TextFormField>(stockFinder).validator?.call(''),
      'Stock MGWS obbligatorio',
    );
    expect(
      tester.widget<TextFormField>(reasonFinder).validator?.call(''),
      'Motivo obbligatorio',
    );

    tester.widget<SwitchListTile>(switchFinder).onChanged?.call(false);
    await tester.pump();
    expect(stockFinder, findsNothing);
    expect(reasonFinder, findsNothing);
    expect(gateway.reconcileCalls, 0);
  });
}
