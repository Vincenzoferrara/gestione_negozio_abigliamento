import 'package:flutter_test/flutter_test.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/class_prodotti.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/prodotto_filters.dart';

void main() {
  group('ProdottoFilterEngine.matchesQuickSearch', () {
    test('finds a product by barcode metadata', () {
      final product = ProdottoGlobal(
        id: 7,
        nome: 'Giacca',
        sku: 'GIACCA-01',
        metadatiCustom: const <String, dynamic>{'barcode': '8051234567890'},
      );

      expect(
        ProdottoFilterEngine.matchesQuickSearch(product, '8051234567890'),
        isTrue,
      );
    });

    test('finds a product by one of its variant barcodes', () {
      final product = ProdottoGlobal(
        id: 8,
        nome: 'Maglia',
        varianti: <VarianteProductGlobal>[
          VarianteProductGlobal(
            id: 81,
            sku: 'MAGLIA-BLU-M',
            metadatiCustom: const <String, dynamic>{'barcode': '8059876543210'},
          ),
        ],
      );

      expect(
        ProdottoFilterEngine.matchesQuickSearch(product, '8059876543210'),
        isTrue,
      );
    });
  });
}
