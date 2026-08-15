import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestione_negozio_abbigliamento/inventory/inventory_quick_load_catalog.code.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/class_prodotti.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/prodotti_gestisci/prodotti_gestisci.code.dart';

void main() {
  test('finishes an in-flight catalog load safely after disposal', () async {
    final pendingPage = Completer<List<ProdottoGlobal>>();
    final productsController = ProdottiGestioneController(
      productPageLoader:
          ({int page = 1, int perPage = 100, bool includeAllStatus = true}) =>
              pendingPage.future,
    );
    final controller = InventoryQuickLoadCatalogController(
      productsController: productsController,
    );

    final loading = controller.load();
    controller.dispose();
    pendingPage.complete(const <ProdottoGlobal>[]);

    await expectLater(loading, completes);
  });
}
