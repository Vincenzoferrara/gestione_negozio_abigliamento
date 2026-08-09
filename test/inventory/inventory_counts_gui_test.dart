import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_counts.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/reuse_class/datagridview/datagridview.gui.dart';

import 'support/count_fixtures.dart';

void main() {
  testWidgets('creates a count session and saves draft count lines only', (
    tester,
  ) async {
    final draft = countSession('draft', lines: [countLine()]);
    final gateway = CountGateway()
      ..countSessionsResponse = MgwsRestockResult.success([draft])
      ..countSessionResponse = MgwsRestockResult.success(draft)
      ..countLineResponse = MgwsRestockResult.success(countLine());
    final controller = InventoryCountSessionController(gateway: gateway);

    await pumpInventoryChild(
      tester,
      InventoryCountPanel(controller: controller),
    );

    expect(find.byType(DataGridView<MgwsCountSession>), findsOneWidget);
    expect(find.byType(DataGridView<MgwsCountLine>), findsNWidgets(2));
    expect(find.text('COUNT-31'), findsWidgets);
    expect(find.text('-2'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('inventory-count-site-field')),
      '2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-count-warehouse-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-count-document-field')),
      'COUNT-32',
    );
    await tester.tap(find.byKey(const ValueKey('inventory-count-create')));
    await tester.pumpAndSettle();

    expect(gateway.createCountSessionCalls, 1);
    expect(gateway.countSessionInput?.documentNumber, 'COUNT-32');

    await tester.enterText(
      find.byKey(const ValueKey('inventory-count-product-field')),
      '101',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-count-quantity-field')),
      '6',
    );
    await tester.tap(find.byKey(const ValueKey('inventory-count-line-save')));
    await tester.pumpAndSettle();

    expect(gateway.saveCountLineCalls, 1);
    expect(gateway.countLineInput?.productId, 101);
    expect(gateway.countLineInput?.physicalQuantity, 6);
    expect(gateway.stockWorkflowCalls, 0);
  });

  testWidgets('surfaces unknown scan errors without creating movements', (
    tester,
  ) async {
    final draft = countSession('draft');
    final gateway = CountGateway()
      ..countSessionsResponse = MgwsRestockResult.success([draft])
      ..countSessionResponse = MgwsRestockResult.success(draft)
      ..countLineResponse = MgwsRestockResult.failure(
        const MgwsRestockError(
          code: 'mgws_unknown_barcode',
          message: 'Barcode non risolto da MGWS',
          details: ['UNKNOWN-BAR'],
        ),
      );

    await pumpInventoryChild(
      tester,
      InventoryCountPanel(
        controller: InventoryCountSessionController(gateway: gateway),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('inventory-count-barcode-field')),
      'UNKNOWN-BAR',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-count-quantity-field')),
      '1',
    );
    await tester.tap(find.byKey(const ValueKey('inventory-count-line-save')));
    await tester.pumpAndSettle();

    expect(find.text('Barcode non risolto da MGWS'), findsOneWidget);
    expect(find.text('UNKNOWN-BAR'), findsWidgets);
    expect(gateway.saveCountLineCalls, 1);
    expect(gateway.stockWorkflowCalls, 0);
  });

  testWidgets('approval posts stock once and posted sessions are read-only', (
    tester,
  ) async {
    final draft = countSession('draft', lines: [countLine()]);
    final posted = countSession('posted', lines: [countLine(stockMoveId: 88)]);
    final gateway = CountGateway()
      ..countSessionsResponse = MgwsRestockResult.success([draft])
      ..countSessionResponse = MgwsRestockResult.success(draft);
    final controller = InventoryCountSessionController(gateway: gateway);

    await pumpInventoryChild(
      tester,
      InventoryCountPanel(controller: controller),
    );

    gateway.countSessionResponse = MgwsRestockResult.success(posted);
    await tester.tap(find.byKey(const ValueKey('inventory-count-approve')));
    await tester.pumpAndSettle();

    expect(gateway.approveCountSessionCalls, 1);
    expect(gateway.stockWorkflowCalls, 1);
    expect(
      find.text('Sessione registrata: righe in sola lettura'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('inventory-count-product-field')),
      '101',
    );
    await tester.enterText(
      find.byKey(const ValueKey('inventory-count-quantity-field')),
      '8',
    );
    await tester.tap(find.byKey(const ValueKey('inventory-count-line-save')));
    await tester.pumpAndSettle();

    expect(gateway.saveCountLineCalls, 0);
    expect(find.text('Sessione di conteggio gia registrata'), findsOneWidget);
  });

  testWidgets('backend list errors remain visible', (tester) async {
    final gateway = CountGateway()
      ..countSessionsResponse = MgwsRestockResult.failure(
        const MgwsRestockError(
          code: 'mgws_counts_unavailable',
          message: 'Conte MGWS non disponibili',
          details: ['Permesso mancante'],
        ),
      );

    await pumpInventoryChild(
      tester,
      InventoryCountPanel(
        controller: InventoryCountSessionController(gateway: gateway),
      ),
    );

    expect(find.text('Conte MGWS non disponibili'), findsOneWidget);
    expect(find.text('Permesso mancante'), findsOneWidget);
  });

  testWidgets('mounts as the real Inventario fisico shell tab', (tester) async {
    final gateway = CountGateway()
      ..countSessionsResponse = MgwsRestockResult.success([
        countSession('draft'),
      ]);

    await pumpCountShell(tester, gateway);
    await tester.drag(find.byType(TabBar), const Offset(-520, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Inventario fisico'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('inventory-count-panel')), findsOneWidget);
    expect(find.text('Inventario fisico MGWS'), findsOneWidget);
    expect(find.byType(DataGridView<MgwsCountSession>), findsOneWidget);
  });
}
