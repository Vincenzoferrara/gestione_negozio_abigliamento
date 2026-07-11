import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/cassa/class_scontrino.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/class_prodotti.dart';

ProdottoGlobal _prodotto({
  required int id,
  required String sku,
  required double prezzo,
}) {
  return ProdottoGlobal(
    id: id,
    nome: 'Prodotto $id',
    sku: sku,
    prezzoNormale: prezzo,
    prezzoScontato: prezzo,
    inStock: true,
    quantitaTotale: 10,
    status: 'publish',
  );
}

void main() {
  test('scontrino vendita calcola totale e operazione effettiva', () {
    final prodotto = _prodotto(id: 1, sku: 'SKU-1', prezzo: 10);
    final riga = RigaScontrino(
      prodotto: prodotto,
      quantita: 2,
      subtotale: 0,
    )..calcolaSubtotale();

    final scontrino = Scontrino(id: '1', data: DateTime(2026, 7, 5));
    scontrino.aggiungiRiga(riga);

    expect(riga.subtotale, 20);
    expect(riga.subtotaleSigned, 20);
    expect(scontrino.subtotale, 20);
    expect(scontrino.totale, 20);
    expect(scontrino.tipoOperazioneEffettiva, TipoOperazioneCassa.vendita);
  });

  test('scontrino misto genera cambio e subtotale reso negativo', () {
    final vendita = RigaScontrino(
      prodotto: _prodotto(id: 1, sku: 'SKU-1', prezzo: 10),
      quantita: 2,
      subtotale: 0,
    )..calcolaSubtotale();
    final reso = RigaScontrino(
      prodotto: _prodotto(id: 2, sku: 'SKU-2', prezzo: 10),
      quantita: 1,
      subtotale: 0,
      tipoMovimento: TipoRigaCassa.reso,
    )..calcolaSubtotale();

    final scontrino = Scontrino(id: '2', data: DateTime(2026, 7, 5));
    scontrino.aggiungiRiga(vendita);
    scontrino.aggiungiRiga(reso);

    expect(vendita.subtotaleSigned, 20);
    expect(reso.subtotaleSigned, -10);
    expect(scontrino.subtotale, 10);
    expect(scontrino.totaleResi, 10);
    expect(scontrino.totale, 10);
    expect(scontrino.tipoOperazioneEffettiva, TipoOperazioneCassa.cambio);
  });
}
