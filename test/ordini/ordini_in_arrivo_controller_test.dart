import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/ordini/class_ordini.dart';
import 'package:gestione_negozio_abbigliamento/ordini/ordini_in_arrivo/ordini_in_arrivo.code.dart';

void main() {
  group('OrdiniInArrivoController', () {
    late OrdiniInArrivoController controller;

    OrdiniGlobal ordineSu(
      List<ProdottoOrdine> lineItems, {
      int id = 1,
      String? number = '123',
    }) {
      return OrdiniGlobal(id: id, number: number, lineItems: lineItems);
    }

    setUp(() {
      controller = OrdiniInArrivoController();
    });

    test('nessun ordine selezionato: verifica fallisce', () {
      final risultato = controller.verificaCodiceProdotto('ABC-1');

      expect(risultato.trovato, isFalse);
      expect(risultato.prodotto, isNull);
    });

    test('filtro status di default è processing', () {
      expect(controller.filtroStatus, OrdineStatus.processing);
    });

    test('verifica prodotto presente: trovato e registrato', () {
      controller.selezionaOrdine(ordineSu([
        ProdottoOrdine(id: 10, name: 'Maglione', sku: 'magl-01'),
        ProdottoOrdine(id: 11, name: 'Pantalone', sku: 'pant-02'),
      ]));

      final risultato = controller.verificaCodiceProdotto('magl-01');

      expect(risultato.trovato, isTrue);
      expect(risultato.prodotto?.id, 10);
      expect(controller.isSkuVerificato('magl-01'), isTrue);
      expect(controller.numeroProdottiVerificati, 1);
      expect(controller.numeroProdottiTotali, 2);
      expect(controller.verificaCompleta, isFalse);
    });

    test('la verifica SKU è case-insensitive e ignora spazi', () {
      controller.selezionaOrdine(ordineSu([
        ProdottoOrdine(sku: 'MAGL-01'),
      ]));

      final risultato = controller.verificaCodiceProdotto('  magl-01 ');

      expect(risultato.trovato, isTrue);
      expect(controller.isSkuVerificato('magl-01'), isTrue);
    });

    test('verifica completa quando tutti gli SKU distinti sono controllati', () {
      controller.selezionaOrdine(ordineSu([
        ProdottoOrdine(sku: 'SKU-A'),
        ProdottoOrdine(sku: 'SKU-B'),
      ]));

      controller.verificaCodiceProdotto('SKU-A');
      controller.verificaCodiceProdotto('SKU-B');

      expect(controller.numeroProdottiVerificati, 2);
      expect(controller.verificaCompleta, isTrue);
    });

    test('SKU duplicati nell ordine contano una sola volta', () {
      controller.selezionaOrdine(ordineSu([
        ProdottoOrdine(sku: 'SKU-A'),
        ProdottoOrdine(sku: 'SKU-A'),
        ProdottoOrdine(sku: 'SKU-B'),
      ]));

      controller.verificaCodiceProdotto('SKU-A');

      expect(controller.numeroProdottiTotali, 2);
      expect(controller.numeroProdottiVerificati, 1);
    });

    test('cambio ordine selezionato azzera le verifiche', () {
      controller.selezionaOrdine(ordineSu([
        ProdottoOrdine(sku: 'SKU-A'),
      ]));
      controller.verificaCodiceProdotto('SKU-A');
      expect(controller.numeroProdottiVerificati, 1);

      controller.selezionaOrdine(ordineSu(
        [ProdottoOrdine(sku: 'SKU-B')],
        id: 2,
        number: '124',
      ));

      expect(controller.numeroProdottiVerificati, 0);
      expect(controller.verificaCompleta, isFalse);
    });

    test('resetVerifiche azzera verifiche e deseleziona', () {
      controller.selezionaOrdine(ordineSu([
        ProdottoOrdine(sku: 'SKU-A'),
      ]));
      controller.verificaCodiceProdotto('SKU-A');

      controller.resetVerifiche();

      expect(controller.hasOrdineSelezionato, isFalse);
      expect(controller.numeroProdottiVerificati, 0);
    });

    test('ordine senza SKU: totale di fallback = righe, verifiche a zero', () {
      controller.selezionaOrdine(ordineSu([
        ProdottoOrdine(id: 1, sku: null),
        ProdottoOrdine(id: 2, sku: ''),
      ]));

      // Senza SKU il controller conta le righe come totale ma nulla è verificabile.
      expect(controller.numeroProdottiTotali, 2);
      expect(controller.numeroProdottiVerificati, 0);
      expect(controller.verificaCompleta, isFalse);
    });
  });
}