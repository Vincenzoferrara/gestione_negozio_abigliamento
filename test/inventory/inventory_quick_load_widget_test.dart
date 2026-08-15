import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_quick_load.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/query_mgws_inventory.dart';
import 'package:gestione_negozio_abbigliamento/settings/inventory_quick_load_settings.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

import 'support/fake_mgws_restock_gateway.dart';

void main() {
  group('InventoryQuickLoadPanel', () {
    testWidgets(
      'uses configured defaults and submits selected lines sequentially',
      (tester) async {
        final gateway = FakeMgwsRestockGateway()
          ..quickLoadResponse = MgwsRestockResult.success(_quickLoad());
        final settings = await _configuredSettings();

        await _pumpQuickLoad(
          tester,
          gateway: gateway,
          settings: settings,
          lines: _selectedLines(),
        );

        expect(find.text('Magazzino'), findsWidgets);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('Carico scaffale'), findsOneWidget);

        final picker = find.byKey(
          const ValueKey('inventory-quick-load-open-picker'),
        );
        await tester.ensureVisible(picker);
        await tester.pump();
        await tester.tap(picker);
        await tester.pumpAndSettle();

        expect(find.text('Maglia blu'), findsOneWidget);
        expect(find.text('Maglia rossa · M'), findsOneWidget);
        expect(find.text('2 righe · 5 pezzi'), findsWidgets);
        expect(
          find.byKey(
            const ValueKey('inventory-quick-load-selected-image-8:81'),
          ),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const ValueKey('inventory-quick-load-rack-7:0')),
          'R1',
        );
        await tester.enterText(
          find.byKey(const ValueKey('inventory-quick-load-shelf-7:0')),
          'P1',
        );
        await tester.enterText(
          find.byKey(const ValueKey('inventory-quick-load-rack-8:81')),
          'R2',
        );
        await tester.enterText(
          find.byKey(const ValueKey('inventory-quick-load-shelf-8:81')),
          'P2',
        );
        await tester.pump();

        await _tapSubmit(tester);
        await tester.pumpAndSettle();

        expect(find.text('Conferma carico rapido'), findsOneWidget);
        expect(find.text('2 righe · 5 pezzi'), findsWidgets);
        expect(
          find.textContaining('MGWS riceverà un carico per ogni riga'),
          findsOneWidget,
        );
        expect(gateway.quickLoadCalls, 0);

        await tester.tap(
          find.byKey(const ValueKey('inventory-quick-load-confirm')),
        );
        await tester.pumpAndSettle();

        expect(gateway.quickLoadCalls, 2);
        expect(gateway.quickLoadRequests[0].productId, 7);
        expect(gateway.quickLoadRequests[0].variationId, 0);
        expect(gateway.quickLoadRequests[0].quantityDelta, 3);
        expect(gateway.quickLoadRequests[0].rack, 'R1');
        expect(gateway.quickLoadRequests[0].shelf, 'P1');
        expect(gateway.quickLoadRequests[0].barcode, '8051111111111');
        expect(gateway.quickLoadRequests[1].productId, 8);
        expect(gateway.quickLoadRequests[1].variationId, 81);
        expect(gateway.quickLoadRequests[1].quantityDelta, 2);
        expect(gateway.quickLoadRequests[1].warehouseId, 5);
        expect(gateway.quickLoadRequests[1].room, 'A');
        expect(gateway.quickLoadRequests[1].rack, 'R2');
        expect(gateway.quickLoadRequests[1].shelf, 'P2');
        expect(gateway.quickLoadRequests[1].barcode, '8052222222222');
        expect(gateway.quickLoadRequests[1].reason, 'Carico scaffale');
        expect(find.text('Completati 2/2 carichi'), findsWidgets);
      },
    );

    testWidgets('blocks submit until at least one catalog line is selected', (
      tester,
    ) async {
      final gateway = FakeMgwsRestockGateway();
      await _pumpQuickLoad(
        tester,
        gateway: gateway,
        settings: await _configuredSettings(),
      );

      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Seleziona almeno un prodotto o variante'),
        findsWidgets,
      );
      expect(find.text('Conferma carico rapido'), findsNothing);
      expect(gateway.quickLoadCalls, 0);
    });

    testWidgets(
      'allows confirmation when optional location is not configured',
      (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final settings = InventoryQuickLoadSettings();
        await settings.init();
        final gateway = FakeMgwsRestockGateway();
        await _pumpQuickLoad(
          tester,
          gateway: gateway,
          settings: settings,
          lines: _selectedLines(),
        );
        await tester.tap(
          find.byKey(const ValueKey('inventory-quick-load-open-picker')),
        );
        await tester.pumpAndSettle();

        await _tapSubmit(tester);
        await tester.pumpAndSettle();

        expect(find.text('Conferma carico rapido'), findsOneWidget);
        expect(gateway.quickLoadCalls, 0);
      },
    );

    testWidgets('hides location levels disabled in settings', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final settings = InventoryQuickLoadSettings();
      await settings.init();
      await settings.setRoomOptions(['A']);
      await settings.setShelfOptions(['P1']);
      await settings.setDefaults(room: 'A', shelf: 'P1');
      final gateway = FakeMgwsRestockGateway()
        ..quickLoadResponse = MgwsRestockResult.success(_quickLoad());
      final line = _selectedLines().first.copyWith(
        rack: 'SCONTO DISATTIVATO',
        shelf: 'P1',
      );

      await _pumpQuickLoad(
        tester,
        gateway: gateway,
        settings: settings,
        lines: [line],
      );

      expect(find.text('Magazzino'), findsNothing);
      expect(find.text('Stanza'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('inventory-quick-load-open-picker')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('inventory-quick-load-rack-7:0')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('inventory-quick-load-shelf-7:0')),
        findsOneWidget,
      );

      await _confirmQuickLoad(tester);

      expect(gateway.quickLoadRequests.single.warehouseId, isNull);
      expect(gateway.quickLoadRequests.single.room, 'A');
      expect(gateway.quickLoadRequests.single.rack, isNull);
      expect(gateway.quickLoadRequests.single.shelf, 'P1');
    });

    testWidgets('keeps only failed lines ready for retry', (tester) async {
      final gateway = FakeMgwsRestockGateway();
      gateway.onQuickLoad = (request) async {
        if (gateway.quickLoadCalls == 2) {
          return MgwsRestockResult.failure(
            const MgwsRestockError(
              code: 'mgws_conflict',
              message: 'Riga in conflitto',
            ),
          );
        }
        return MgwsRestockResult.success(_quickLoad());
      };
      await _pumpQuickLoad(
        tester,
        gateway: gateway,
        settings: await _configuredSettings(),
        lines: _selectedLines(),
      );
      await tester.tap(
        find.byKey(const ValueKey('inventory-quick-load-open-picker')),
      );
      await tester.pumpAndSettle();

      await _confirmQuickLoad(tester);

      expect(find.text('Completati 1/2 carichi; 1 da riprovare'), findsWidgets);
      expect(
        find.byKey(const ValueKey('inventory-quick-load-selected-7:0')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('inventory-quick-load-selected-8:81')),
        findsOneWidget,
      );
      expect(find.text('Riprova 1 righe'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _confirmQuickLoad(tester);

      expect(gateway.quickLoadCalls, 3);
      expect(find.text('Completati 1/1 carichi'), findsWidgets);
      expect(find.text('Nessun prodotto selezionato'), findsOneWidget);
    });

    testWidgets('keeps the operational note after a backend failure', (
      tester,
    ) async {
      final gateway = FakeMgwsRestockGateway()
        ..quickLoadResponse = MgwsRestockResult.failure(
          const MgwsRestockError(
            code: 'mgws_forbidden',
            message: 'Operazione negata',
            details: ['Capacita MGWS mancante'],
          ),
        );
      await _pumpQuickLoad(
        tester,
        gateway: gateway,
        settings: await _configuredSettings(),
        lines: [_selectedLines().first],
      );
      await tester.tap(
        find.byKey(const ValueKey('inventory-quick-load-open-picker')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('inventory-quick-load-note-field')),
        'Mantieni nota',
      );

      await _confirmQuickLoad(tester);

      expect(find.textContaining('Operazione negata'), findsWidgets);
      expect(find.textContaining('Capacita MGWS mancante'), findsWidgets);
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
      await _pumpQuickLoad(
        tester,
        gateway: FakeMgwsRestockGateway(),
        settings: await _configuredSettings(),
      );

      expect(find.textContaining('Fornitore'), findsNothing);
      expect(find.textContaining('Ordine'), findsNothing);
      expect(find.textContaining('Fattura'), findsNothing);
      expect(find.textContaining('DDT'), findsNothing);
    });

    testWidgets('renders without overflow on narrow and wide workspaces', (
      tester,
    ) async {
      final settings = await _configuredSettings();
      for (final size in const [Size(390, 780), Size(1280, 820)]) {
        await tester.binding.setSurfaceSize(size);
        await _pumpQuickLoad(
          tester,
          gateway: FakeMgwsRestockGateway(),
          settings: settings,
          lines: [_selectedLines().first],
        );
        await tester.tap(
          find.byKey(const ValueKey('inventory-quick-load-open-picker')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.binding.setSurfaceSize(null);
    });
  });
}

Future<InventoryQuickLoadSettings> _configuredSettings() async {
  SharedPreferences.setMockInitialValues({});
  final settings = InventoryQuickLoadSettings();
  await settings.init();
  await settings.setWarehouseOptions(['5']);
  await settings.setRoomOptions(['A']);
  await settings.setRackOptions(['1']);
  await settings.setShelfOptions(['2']);
  await settings.setReasonOptions(['Carico scaffale']);
  await settings.setDefaults(
    warehouse: '5',
    room: 'A',
    rack: '1',
    shelf: '2',
    reason: 'Carico scaffale',
  );
  return settings;
}

List<InventoryQuickLoadLineDraft> _selectedLines() {
  return const [
    InventoryQuickLoadLineDraft(
      productId: 7,
      variationId: 0,
      label: 'Maglia blu',
      sku: 'MAG-BLU',
      barcode: '8051111111111',
      imageUrl: 'https://example.test/maglia-blu.jpg',
      quantity: 3,
      idempotencyKey: 'line-7',
    ),
    InventoryQuickLoadLineDraft(
      productId: 8,
      variationId: 81,
      label: 'Maglia rossa · M',
      sku: 'MAG-ROSSA-M',
      barcode: '8052222222222',
      imageUrl: 'https://example.test/maglia-rossa.jpg',
      quantity: 2,
      idempotencyKey: 'line-8-81',
    ),
  ];
}

Future<void> _pumpQuickLoad(
  WidgetTester tester, {
  required FakeMgwsRestockGateway gateway,
  required InventoryQuickLoadSettings settings,
  List<InventoryQuickLoadLineDraft> lines = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: InventoryQuickLoadPanel(
            controller: InventoryQuickLoadController(gateway: gateway),
            settings: settings,
            pickerLauncher: (_, _) async => lines,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _confirmQuickLoad(WidgetTester tester) async {
  await _tapSubmit(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('inventory-quick-load-confirm')));
  await tester.pumpAndSettle();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final submit = find.byKey(const ValueKey('inventory-quick-load-submit'));
  await tester.ensureVisible(submit);
  await tester.pump();
  await tester.tap(submit);
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
