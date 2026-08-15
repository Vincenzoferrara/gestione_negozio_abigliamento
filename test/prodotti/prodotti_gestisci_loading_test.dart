import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/class_prodotti.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/prodotti_gestisci/prodotti_gestisci.code.dart';
import 'package:gestione_negozio_abbigliamento/reuse_class/datagridview/datagridview_cache.dart';

void main() {
  setUp(DataGridViewCache.clearAll);
  tearDown(DataGridViewCache.clearAll);

  test(
    'pubblica la prima pagina mentre le successive caricano in background',
    () async {
      final secondPage = Completer<List<ProdottoGlobal>>();
      final firstPageVisible = Completer<void>();
      final progressCounts = <int>[];
      var loadCompleted = false;

      final firstChunk = List<ProdottoGlobal>.generate(
        100,
        (index) => ProdottoGlobal(id: index + 1, nome: 'Prodotto ${index + 1}'),
      );
      final controller = ProdottiGestioneController(
        productPageLoader:
            ({int page = 1, int perPage = 100, bool includeAllStatus = true}) {
              if (page == 1) return Future.value(firstChunk);
              if (page == 2) return secondPage.future;
              return Future.value(<ProdottoGlobal>[]);
            },
      );
      addTearDown(controller.dispose);

      final load = controller
          .caricaProdotti(
            onProgress: (products) {
              progressCounts.add(products.length);
              if (products.length == 100 && !firstPageVisible.isCompleted) {
                firstPageVisible.complete();
              }
            },
          )
          .whenComplete(() => loadCompleted = true);

      await firstPageVisible.future.timeout(const Duration(seconds: 1));

      expect(controller.prodotti, hasLength(100));
      expect(progressCounts, <int>[100]);
      expect(loadCompleted, isFalse);

      secondPage.complete(<ProdottoGlobal>[
        ProdottoGlobal(id: 101, nome: 'Prodotto 101'),
      ]);
      await load;

      expect(controller.prodotti, hasLength(101));
      expect(progressCounts, <int>[100, 101]);
    },
  );
}
