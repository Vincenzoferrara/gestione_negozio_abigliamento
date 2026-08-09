import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/home/home.gui.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

class _InventoryShellGateway implements MgwsInventoryGateway {
  _InventoryShellGateway({required this.available});

  final bool available;

  @override
  Future<List<Map<String, dynamic>>> getAllStock() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getLowStockItems() async => const [];

  @override
  Future<Map<String, dynamic>> getProductStock(int productId) async => const {};

  @override
  Future<Map<String, dynamic>> getStatistics() async => const {};

  @override
  Future<bool> isInventoryServiceAvailable() async => available;

  @override
  Future<MgwsReconcileResult> reconcileStock({
    required int productId,
    required int correctStock,
    required String reason,
  }) async {
    return const MgwsReconcileResult(success: true, message: 'ok', errors: []);
  }

  @override
  Future<MgwsRfidScanResult> resolveRfidScan({
    required List<String> tagIds,
  }) async {
    return const MgwsRfidScanResult(
      success: true,
      message: 'ok',
      errors: [],
      resolved: [],
      unresolved: [],
      stockUpdates: 0,
      movementCount: 0,
      mode: 'resolve_only',
    );
  }

  @override
  Future<MgwsStockSyncResult> syncWooStockToMgws({
    required int productId,
    required int wooStock,
    required String syncType,
  }) async {
    return const MgwsStockSyncResult(success: true, message: 'ok', errors: []);
  }
}

void main() {
  testWidgets('home exposes the Inventario MGWS navigation entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
    );
    await tester.pump();

    expect(find.text('Inventario MGWS'), findsWidgets);
  });

  testWidgets('inventory shell renders every operational section', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: InventoryPage(
          controller: InventoryController(
            gateway: _InventoryShellGateway(available: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('inventory-shell')), findsOneWidget);
    expect(find.text('Quick Load'), findsWidgets);
    expect(find.text('Riordino'), findsWidgets);
    expect(find.text('Ordini Fornitore'), findsWidgets);
    expect(find.text('Ricezione/Convalida'), findsWidgets);
    expect(find.text('Movimenti'), findsWidgets);
    expect(find.text('Inventario fisico'), findsWidgets);
  });

  testWidgets('inventory shell keeps sections visible at small width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: InventoryPage(
          controller: InventoryController(
            gateway: _InventoryShellGateway(available: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('inventory-small-layout')),
      findsOneWidget,
    );
    expect(find.text('Quick Load'), findsWidgets);
    expect(find.text('Inventario fisico'), findsWidgets);
  });

  testWidgets('inventory shell explains disconnected MGWS requirement', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: InventoryPage(
          controller: InventoryController(
            gateway: _InventoryShellGateway(available: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Backend MGWS richiesto'), findsOneWidget);
    expect(
      find.textContaining('Accedi o configura il backend MGWS'),
      findsOneWidget,
    );
  });
}
