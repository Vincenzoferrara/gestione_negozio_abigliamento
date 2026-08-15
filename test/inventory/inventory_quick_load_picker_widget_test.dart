import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/inventory/inventory.code.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_quick_load_picker.gui.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/class_prodotti.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/prodotti_gestisci/prodotti_gestisci.code.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

void main() {
  testWidgets(
    'picker searches catalog and selects simple products and concrete variants',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final productsController = ProdottiGestioneController(
        productPageLoader:
            ({
              int page = 1,
              int perPage = 100,
              bool includeAllStatus = true,
            }) async => page == 1 ? _products() : const <ProdottoGlobal>[],
      );
      final catalog = InventoryQuickLoadCatalogController(
        productsController: productsController,
      );
      addTearDown(catalog.dispose);
      await catalog.load(forceRefresh: true);
      List<InventoryQuickLoadLineDraft>? picked;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    picked = await showInventoryQuickLoadPicker(
                      context,
                      controller: catalog,
                    );
                  },
                  child: const Text('Apri selettore'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apri selettore'));
      await tester.pumpAndSettle();

      expect(find.text('T-shirt semplice'), findsOneWidget);
      expect(find.text('Felpa variabile'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('quick-load-product-image-11')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('quick-load-product-search')),
        'felpa',
      );
      await tester.pump();
      expect(find.text('T-shirt semplice'), findsNothing);
      expect(find.text('Felpa variabile'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('quick-load-product-search')),
        '8059876543210',
      );
      await tester.pump();
      expect(find.text('T-shirt semplice'), findsNothing);
      expect(find.text('Felpa variabile'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('quick-load-product-search')),
        '',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('quick-load-product-11')));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('quick-load-variable-product-12')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('quick-load-variant-121')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('quick-load-variant-image-121')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('quick-load-variant-121')));
      await tester.pump();

      expect(find.text('2 righe · 2 pezzi'), findsOneWidget);
      final quantityFields = find.byType(TextFormField);
      expect(quantityFields, findsNWidgets(2));
      await tester.enterText(quantityFields.first, '7');
      await tester.pump();
      expect(find.text('2 righe · 8 pezzi'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('quick-load-confirm-products')),
      );
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked, hasLength(2));
      expect(picked!.map((line) => line.quantity), containsAll(<int>[1, 7]));
      expect(
        picked!.map((line) => line.variationId),
        containsAll(<int>[0, 121]),
      );
      expect(
        picked!.firstWhere((line) => line.variationId == 121).label,
        'Felpa variabile · Rosso / M',
      );
      expect(
        picked!.firstWhere((line) => line.variationId == 121).barcode,
        '8059876543210',
      );
      expect(
        picked!.firstWhere((line) => line.variationId == 121).imageUrl,
        'https://example.test/felpa-rossa.jpg',
      );
    },
  );
}

List<ProdottoGlobal> _products() {
  return [
    ProdottoGlobal(
      id: 11,
      nome: 'T-shirt semplice',
      sku: 'TS-11',
      immagineUrl: 'https://example.test/tshirt.jpg',
      metadatiCustom: const <String, dynamic>{'barcode': '8051111111111'},
      quantitaTotale: 4,
    ),
    ProdottoGlobal(
      id: 12,
      nome: 'Felpa variabile',
      sku: 'FL-12',
      immagineUrl: 'https://example.test/felpa.jpg',
      variations: const [121],
      varianti: [
        VarianteProductGlobal(
          id: 121,
          nome: 'Felpa rossa M',
          sku: 'FL-ROSSA-M',
          immagineUrl: 'https://example.test/felpa-rossa.jpg',
          metadatiCustom: const <String, dynamic>{'barcode': '8059876543210'},
          quantita: 2,
          attributi: [
            AttributoVariante(nome: 'Colore', opzione: 'Rosso'),
            AttributoVariante(nome: 'Taglia', opzione: 'M'),
          ],
        ),
      ],
    ),
  ];
}
