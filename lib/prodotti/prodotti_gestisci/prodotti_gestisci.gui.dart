import 'package:flutter/material.dart';
import '../class_prodotti.dart'; // Assicurati di avere il modello separato in questa posizione

class ProdottiGestisciPage extends StatefulWidget {
  @override
  _ProdottiGestisciPageState createState() => _ProdottiGestisciPageState();
}

class _ProdottiGestisciPageState extends State<ProdottiGestisciPage> {
  List<ProdottoWoo> prodotti = [];
  ProdottoWoo? prodottoSelezionato;

  @override
  void initState() {
    super.initState();
    // Dati demo: sostituisci con chiamate reali a WooCommerce
    prodotti = [
      ProdottoWoo(
        id: 1,
        nome: 'Maglietta T-Shirt',
        sku: 'TSHIRT-001',
        prezzoNormale: 20.0,
        prezzoScontato: 15.0,
        descrizioneBreve: 'Maglietta in cotone 100%, disponibile in vari colori.',
        immagineUrl: 'https://example.com/images/tshirt.jpg',
        varianti: [
          VarianteWoo(id: 101,
              nome: 'Rosso - M',
              sku: 'TSHIRT-001-RM',
              prezzo: 15.0,
              quantita: 10),
          VarianteWoo(id: 102,
              nome: 'Blu - L',
              sku: 'TSHIRT-001-BL',
              prezzo: 15.0,
              quantita: 5),
        ],
        categoria: 'Abbigliamento',
        inStock: true,
      ),
      // altri prodotti demo
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestisci Prodotti'),
        backgroundColor: Colors.redAccent,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Prezzo')),
                  DataColumn(label: Text('Categoria')),
                  DataColumn(label: Text('Disponibilità')),
                ],
                rows: prodotti.map((prodotto) {
                  return DataRow(
                    selected: prodottoSelezionato?.id == prodotto.id,
                    onSelectChanged: (_) {
                      setState(() {
                        prodottoSelezionato = prodotto;
                      });
                    },
                    cells: [
                      DataCell(Text(prodotto.id.toString())),
                      DataCell(Text(prodotto.nome)),
                      DataCell(Text(prodotto.sku)),
                      DataCell(Row(
                        children: [
                          if (prodotto.prezzoScontato != null) ...[
                            Text(
                              '€${prodotto.prezzoNormale.toStringAsFixed(2)}',
                              style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey),
                            ),
                            SizedBox(width: 5),
                            Text(
                              '€${prodotto.prezzoScontato!.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.red),
                            ),
                          ] else
                            Text('€${prodotto.prezzoNormale.toStringAsFixed(
                                2)}'),
                        ],
                      )),
                      DataCell(Text(prodotto.categoria)),
                      DataCell(Text(
                          prodotto.inStock ? 'Disponibile' : 'Esaurito')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          VerticalDivider(),
          Expanded(
            flex: 4,
            child: prodottoSelezionato == null
                ? Center(
                child: Text('Seleziona un prodotto per vedere i dettagli'))
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.network(
                      prodottoSelezionato!.immagineUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.image_not_supported, size: 100,
                              color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    prodottoSelezionato!.nome,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(prodottoSelezionato!.descrizioneBreve),
                  SizedBox(height: 16),
                  Text('Varianti:', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: prodottoSelezionato!.varianti.length,
                      itemBuilder: (context, index) {
                        final variante = prodottoSelezionato!.varianti[index];
                        return Card(
                          child: ListTile(
                            title: Text(variante.nome),
                            subtitle: Text('SKU: ${variante.sku}'),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    'Prezzo: €${variante.prezzo.toStringAsFixed(
                                        2)}'),
                                Text('Quantità: ${variante.quantita}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/prodotti/crea');
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.redAccent,
        tooltip: 'Crea Nuovo Prodotto',
      ),
    );
  }
}