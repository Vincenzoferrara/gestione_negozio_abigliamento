// class_scontrino.dart

import '../prodotti/class_prodotti.dart';

/// Rappresenta uno scontrino completo
class Scontrino {
  String id;
  DateTime data;
  List<RigaScontrino> righe;
  double subtotale;
  double iva;
  double sconto;
  double totale;
  String? clienteId;
  String? clienteNome;
  String? clienteEmail;
  String? clienteTelefono;
  String metodoPagamento; // 'contanti', 'carta', 'bancomat'
  String? note;
  String stato; // 'aperto', 'pagato', 'annullato'

  Scontrino({
    required this.id,
    required this.data,
    List<RigaScontrino>? righe,
    this.subtotale = 0.0,
    this.iva = 0.0,
    this.sconto = 0.0,
    this.totale = 0.0,
    this.clienteId,
    this.clienteNome,
    this.clienteEmail,
    this.clienteTelefono,
    this.metodoPagamento = 'contanti',
    this.note,
    this.stato = 'aperto',
  }) : righe = righe ?? [];

  /// Calcola il totale dello scontrino
  void calcolaTotale() {
    subtotale = righe.fold(0.0, (sum, riga) => sum + riga.subtotale);
    totale = subtotale - sconto + iva;
  }

  /// Aggiunge una riga allo scontrino
  void aggiungiRiga(RigaScontrino riga) {
    righe.add(riga);
    calcolaTotale();
  }

  /// Rimuove una riga dallo scontrino
  void rimuoviRiga(int index) {
    if (index >= 0 && index < righe.length) {
      righe.removeAt(index);
      calcolaTotale();
    }
  }

  /// Svuota lo scontrino
  void reset() {
    righe.clear();
    subtotale = 0.0;
    iva = 0.0;
    sconto = 0.0;
    totale = 0.0;
    clienteId = null;
    clienteNome = null;
    clienteEmail = null;
    clienteTelefono = null;
    note = null;
    stato = 'aperto';
  }

  /// Verifica se lo scontrino è vuoto
  bool get isVuoto => righe.isEmpty;

  /// Numero totale di articoli
  int get numeroArticoli => righe.fold(0, (sum, riga) => sum + riga.quantita);
}

/// Rappresenta una singola riga dello scontrino
class RigaScontrino {
  final Prodotto_global prodotto;
  final Variante_product_global? variante;
  int quantita;
  double subtotale;

  RigaScontrino({
    required this.prodotto,
    this.variante,
    required this.quantita,
    required this.subtotale,
  });

  /// Ottiene il prezzo unitario effettivo (variante o prodotto)
  double get prezzoUnitario {
    if (variante != null) {
      return variante!.prezzoEffettivo;
    }
    return prodotto.prezzoEffettivo;
  }

  /// Ottiene il nome visualizzabile
  String get nomeCompleto {
    if (variante != null) {
      return '${prodotto.nome ?? ''} - ${variante!.nomeVisualizzabile}';
    }
    return prodotto.nome ?? '';
  }

  /// Ottiene l'immagine URL
  String? get immagineUrl {
    if (variante != null && variante!.immagineUrl != null) {
      return variante!.immagineUrl;
    }
    return prodotto.immagineUrl;
  }

  /// Ottiene lo SKU
  String get sku {
    if (variante != null) {
      return variante!.sku;
    }
    return prodotto.sku ?? '';
  }

  /// Calcola il subtotale della riga
  void calcolaSubtotale() {
    subtotale = quantita * prezzoUnitario;
  }

  /// Aggiorna la quantità e ricalcola
  void aggiornaQuantita(int nuovaQuantita) {
    quantita = nuovaQuantita;
    calcolaSubtotale();
  }

  /// Incrementa la quantità di 1
  void incrementaQuantita() {
    quantita++;
    calcolaSubtotale();
  }

  /// Decrementa la quantità di 1 (minimo 1)
  void decrementaQuantita() {
    if (quantita > 1) {
      quantita--;
      calcolaSubtotale();
    }
  }
}
