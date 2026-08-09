import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_quick_load.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

import 'support/fake_mgws_restock_gateway.dart';

void main() {
  group('InventoryQuickLoadPanel', () {
    testWidgets(
      'collects product, barcode, quantity and reason before submit',
      (tester) async {
        final gateway = FakeMgwsRestockGateway()
          ..quickLoadResponse = MgwsRestockResult.success(_quickLoad());

        await _pumpQuickLoad(tester, gateway: gateway);

        await _fillRequiredQuickLoadFields(tester, barcode: 'SKU-7-RED');
        await tester.enterText(
          find.byKey(const ValueKey('inventory-quick-load-variation-field')),
          '4',
        );
        await tester.tap(
          find.byKey(const ValueKey('inventory-quick-load-submit')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Conferma carico rapido'), findsOneWidget);
        expect(find.textContaining('Prodotto: 7'), findsOneWidget);
        expect(find.textContaining('Variante: 4'), findsOneWidget);
        expect(find.textContaining('Barcode: SKU-7-RED'), findsOneWidget);
        expect(gateway.quickLoadCalls, 0);

        await tester.tap(
          find.byKey(const ValueKey('inventory-quick-load-confirm')),
        );
        await tester.pumpAndSettle();

        expect(gateway.quickLoadCalls, 1);
        expect(gateway.quickLoadRequest?.productId, 7);
        expect(gateway.quickLoadRequest?.variationId, 4);
        expect(gateway.quickLoadRequest?.barcode, 'SKU-7-RED');
        expect(gateway.quickLoadRequest?.quantityDelta, 3);
        expect(gateway.quickLoadRequest?.reason, 'Carico scaffale');
      },
    );

    testWidgets('blocks zero quantity before confirmation and gateway call', (
      tester,
    ) async {
      final gateway = FakeMgwsRestockGateway();

      await _pumpQuickLoad(tester, gateway: gateway);
      await tester.enterText(
        find.byKey(const ValueKey('inventory-quick-load-product-field')),
        '7',
      );
      await tester.enterText(
        find.byKey(const ValueKey('inventory-quick-load-quantity-field')),
        '0',
      );
      await tester.enterText(
        find.byKey(const ValueKey('inventory-quick-load-reason-field')),
        'Carico scaffale',
      );

      await tester.tap(
        find.byKey(const ValueKey('inventory-quick-load-submit')),
      );
      await tester.pumpAndSettle();

      expect(find.text('quantita non valida'), findsWidgets);
      expect(find.text('Conferma carico rapido'), findsNothing);
      expect(gateway.quickLoadCalls, 0);
    });

    testWidgets('blocks blank reason before confirmation and gateway call', (
      tester,
    ) async {
      final gateway = FakeMgwsRestockGateway();

      await _pumpQuickLoad(tester, gateway: gateway);
      await tester.enterText(
        find.byKey(const ValueKey('inventory-quick-load-product-field')),
        '7',
      );
      await tester.enterText(
        find.byKey(const ValueKey('inventory-quick-load-quantity-field')),
        '3',
      );

      await tester.tap(
        find.byKey(const ValueKey('inventory-quick-load-submit')),
      );
      await tester.pumpAndSettle();

      expect(find.text('reason richiesto'), findsWidgets);
      expect(find.text('Conferma carico rapido'), findsNothing);
      expect(gateway.quickLoadCalls, 0);
    });

    testWidgets('shows success feedback with movement id', (tester) async {
      final gateway = FakeMgwsRestockGateway()
        ..quickLoadResponse = MgwsRestockResult.success(_quickLoad());

      await _pumpQuickLoad(tester, gateway: gateway);
      await _fillRequiredQuickLoadFields(tester);
      await _confirmQuickLoad(tester);

      expect(find.text('Operazione MGWS completata'), findsWidgets);
      expect(find.text('Movimento MGWS #88'), findsOneWidget);
      expect(find.textContaining('Stock: 4 -> 7'), findsOneWidget);
    });

    testWidgets('shows backend error and keeps user input', (tester) async {
      final gateway = FakeMgwsRestockGateway()
        ..quickLoadResponse = MgwsRestockResult.failure(
          const MgwsRestockError(
            code: 'mgws_forbidden',
            message: 'Operazione negata',
            details: ['Capacita MGWS mancante'],
          ),
        );

      await _pumpQuickLoad(tester, gateway: gateway);
      await _fillRequiredQuickLoadFields(tester, note: 'Mantieni nota');
      await _confirmQuickLoad(tester);

      expect(find.text('Operazione negata'), findsWidgets);
      expect(find.text('Capacita MGWS mancante'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('inventory-quick-load-note-field')),
            )
            .controller
            ?.text,
        'Mantieni nota',
      );
    });

    testWidgets('does not display supplier or document fields', (tester) async {
      await _pumpQuickLoad(tester, gateway: FakeMgwsRestockGateway());

      expect(find.textContaining('Fornitore'), findsNothing);
      expect(find.textContaining('Ordine'), findsNothing);
      expect(find.textContaining('Fattura'), findsNothing);
      expect(find.textContaining('DDT'), findsNothing);
    });
  });
}

Future<void> _pumpQuickLoad(
  WidgetTester tester, {
  required FakeMgwsRestockGateway gateway,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: InventoryQuickLoadPanel(
            controller: InventoryQuickLoadController(gateway: gateway),
          ),
        ),
      ),
    ),
  );
}

Future<void> _fillRequiredQuickLoadFields(
  WidgetTester tester, {
  String barcode = '',
  String note = '',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('inventory-quick-load-product-field')),
    '7',
  );
  await tester.enterText(
    find.byKey(const ValueKey('inventory-quick-load-barcode-field')),
    barcode,
  );
  await tester.enterText(
    find.byKey(const ValueKey('inventory-quick-load-quantity-field')),
    '3',
  );
  await tester.enterText(
    find.byKey(const ValueKey('inventory-quick-load-reason-field')),
    'Carico scaffale',
  );
  await tester.enterText(
    find.byKey(const ValueKey('inventory-quick-load-note-field')),
    note,
  );
}

Future<void> _confirmQuickLoad(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('inventory-quick-load-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('inventory-quick-load-confirm')));
  await tester.pumpAndSettle();
}

MgwsQuickLoad _quickLoad() {
  return const MgwsQuickLoad(
    productId: 7,
    variationId: 0,
    quantityDelta: 3,
    previousStock: 4,
    currentStock: 7,
    reason: 'Carico scaffale',
    movementId: 88,
    location: MgwsLocation(
      siteId: 2,
      warehouseId: 5,
      room: 'A',
      rack: '1',
      shelf: '2',
    ),
  );
}
