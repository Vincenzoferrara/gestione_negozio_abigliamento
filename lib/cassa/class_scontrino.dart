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
  double scontoPercentuale; // Sconto percentuale globale
  double totale;
  String? clienteId;
  String? clienteNome;
  String? clienteEmail;
  String? clienteTelefono;
  String metodoPagamento; // 'contanti', 'carta', 'bancomat'
  String? note;
  String stato; // 'aperto', 'pagato', 'annullato', 'sospeso'

  // Coupon applicato
  String? couponCode;
  double couponSconto;

  // Per calcolo resto
  double importoRicevuto;

  // Aliquota IVA (default 22%)
  double aliquotaIva;

  Scontrino({
    required this.id,
    required this.data,
    List<RigaScontrino>? righe,
    this.subtotale = 0.0,
    this.iva = 0.0,
    this.sconto = 0.0,
    this.scontoPercentuale = 0.0,
    this.totale = 0.0,
    this.clienteId,
    this.clienteNome,
    this.clienteEmail,
    this.clienteTelefono,
    this.metodoPagamento = 'contanti',
    this.note,
    this.stato = 'aperto',
    this.couponCode,
    this.couponSconto = 0.0,
    this.importoRicevuto = 0.0,
    this.aliquotaIva = 22.0,
  }) : righe = righe ?? [];

  /// Calcola il totale dello scontrino
  void calcolaTotale() {
    // Subtotale = somma dei subtotali delle righe (già con sconti riga applicati)
    subtotale = righe.fold(0.0, (sum, riga) => sum + riga.subtotale);

    // Calcola sconto totale (percentuale + fisso + coupon)
    double scontoTotale = sconto + couponSconto;
    if (scontoPercentuale > 0) {
      scontoTotale += subtotale * (scontoPercentuale / 100);
    }

    // Subtotale dopo sconti
    double subtotaleScontato = subtotale - scontoTotale;
    if (subtotaleScontato < 0) subtotaleScontato = 0;

    // Calcola IVA (l'IVA è già inclusa nel prezzo, scorporiamo per mostrare)
    // Formula: IVA = Prezzo - (Prezzo / (1 + aliquota/100))
    iva = subtotaleScontato - (subtotaleScontato / (1 + aliquotaIva / 100));

    // Totale finale
    totale = subtotaleScontato;
  }

  /// Applica uno sconto percentuale globale
  void applicaScontoPercentualeGlobale(double percentuale) {
    scontoPercentuale = percentuale.clamp(0, 100);
    calcolaTotale();
  }

  /// Calcola il resto da dare al cliente
  double get resto => importoRicevuto > totale ? importoRicevuto - totale : 0;

  /// Verifica se l'importo ricevuto è sufficiente
  bool get importoSufficiente => importoRicevuto >= totale;

  /// Totale sconti applicati (righe + globale + coupon)
  double get totaleSconto {
    double scontoRighe = righe.fold(0.0, (sum, riga) => sum + riga.totaleSconto);
    double scontoGlobale = sconto + couponSconto;
    if (scontoPercentuale > 0) {
      scontoGlobale += subtotale * (scontoPercentuale / 100);
    }
    return scontoRighe + scontoGlobale;
  }

  /// Imponibile (totale senza IVA)
  double get imponibile => totale - iva;

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
    scontoPercentuale = 0.0;
    totale = 0.0;
    clienteId = null;
    clienteNome = null;
    clienteEmail = null;
    clienteTelefono = null;
    note = null;
    stato = 'aperto';
    couponCode = null;
    couponSconto = 0.0;
    importoRicevuto = 0.0;
  }

  /// Verifica se lo scontrino è vuoto
  bool get isVuoto => righe.isEmpty;

  /// Numero totale di articoli
  int get numeroArticoli => righe.fold(0, (sum, riga) => sum + riga.quantita);
}

/// Rappresenta una singola riga dello scontrino
class RigaScontrino {
  final ProdottoGlobal prodotto;
  final VarianteProductGlobal? variante;
  int quantita;
  double subtotale;
  double scontoRiga; // Sconto applicato alla singola riga (valore assoluto)
  double scontoPercentuale; // Sconto percentuale sulla riga
  String? note; // Note sulla riga

  RigaScontrino({
    required this.prodotto,
    this.variante,
    required this.quantita,
    required this.subtotale,
    this.scontoRiga = 0.0,
    this.scontoPercentuale = 0.0,
    this.note,
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

  /// Calcola il subtotale della riga (con sconti applicati)
  void calcolaSubtotale() {
    double totaleRiga = quantita * prezzoUnitario;

    // Applica sconto percentuale
    if (scontoPercentuale > 0) {
      totaleRiga -= totaleRiga * (scontoPercentuale / 100);
    }

    // Applica sconto fisso
    totaleRiga -= scontoRiga;

    subtotale = totaleRiga > 0 ? totaleRiga : 0;
  }

  /// Applica uno sconto percentuale alla riga
  void applicaScontoPercentuale(double percentuale) {
    scontoPercentuale = percentuale.clamp(0, 100);
    calcolaSubtotale();
  }

  /// Applica uno sconto fisso alla riga
  void applicaScontoFisso(double sconto) {
    scontoRiga = sconto > 0 ? sconto : 0;
    calcolaSubtotale();
  }

  /// Rimuove tutti gli sconti dalla riga
  void rimuoviSconti() {
    scontoRiga = 0;
    scontoPercentuale = 0;
    calcolaSubtotale();
  }

  /// Totale sconti applicati alla riga
  double get totaleSconto {
    double totaleOriginale = quantita * prezzoUnitario;
    double scontoPerc = scontoPercentuale > 0 ? totaleOriginale * (scontoPercentuale / 100) : 0;
    return scontoPerc + scontoRiga;
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
