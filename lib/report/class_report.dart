/// Classe per rappresentare un'etichetta da stampare
class Etichetta {
  final int? prodottoId;
  final String nome;
  final String? sku; // Usato anche come barcode
  final double prezzo;
  final String? descrizioneBreve;
  final String? taglia;
  final String? colore;
  final DateTime dataCreazione;

  Etichetta({
    this.prodottoId,
    required this.nome,
    this.sku,
    required this.prezzo,
    this.descrizioneBreve,
    this.taglia,
    this.colore,
    DateTime? dataCreazione,
  }) : dataCreazione = dataCreazione ?? DateTime.now();

  /// Crea un'etichetta da un prodotto WooCommerce
  factory Etichetta.fromProdotto(Map<String, dynamic> prodotto) {
    return Etichetta(
      prodottoId: prodotto['id'],
      nome: prodotto['name'] ?? '',
      sku: prodotto['sku'],
      prezzo: double.tryParse(prodotto['price']?.toString() ?? '0') ?? 0,
      descrizioneBreve: prodotto['short_description'],
    );
  }

  /// Genera i dati per il QR code
  String generaContenutoQr() {
    // Formato base per il QR code - da personalizzare in seguito
    final buffer = StringBuffer();
    if (prodottoId != null) buffer.write('ID:$prodottoId|');
    buffer.write('NOME:$nome|');
    if (sku != null) buffer.write('SKU:$sku|');
    buffer.write('PREZZO:$prezzo');
    if (taglia != null) buffer.write('|TAGLIA:$taglia');
    if (colore != null) buffer.write('|COLORE:$colore');
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'prodottoId': prodottoId,
      'nome': nome,
      'sku': sku,
      'prezzo': prezzo,
      'descrizioneBreve': descrizioneBreve,
      'taglia': taglia,
      'colore': colore,
      'dataCreazione': dataCreazione.toIso8601String(),
    };
  }

  factory Etichetta.fromJson(Map<String, dynamic> json) {
    return Etichetta(
      prodottoId: json['prodottoId'],
      nome: json['nome'] ?? '',
      sku: json['sku'],
      prezzo: (json['prezzo'] as num?)?.toDouble() ?? 0,
      descrizioneBreve: json['descrizioneBreve'],
      taglia: json['taglia'],
      colore: json['colore'],
      dataCreazione: json['dataCreazione'] != null
          ? DateTime.parse(json['dataCreazione'])
          : DateTime.now(),
    );
  }

  Etichetta copyWith({
    int? prodottoId,
    String? nome,
    String? sku,
    double? prezzo,
    String? descrizioneBreve,
    String? taglia,
    String? colore,
    DateTime? dataCreazione,
  }) {
    return Etichetta(
      prodottoId: prodottoId ?? this.prodottoId,
      nome: nome ?? this.nome,
      sku: sku ?? this.sku,
      prezzo: prezzo ?? this.prezzo,
      descrizioneBreve: descrizioneBreve ?? this.descrizioneBreve,
      taglia: taglia ?? this.taglia,
      colore: colore ?? this.colore,
      dataCreazione: dataCreazione ?? this.dataCreazione,
    );
  }
}

/// Impostazioni per la stampa delle etichette
class EtichetteSettings {
  final double larghezzaEtichetta; // in mm
  final double altezzaEtichetta; // in mm
  final double margineSup;
  final double margineInf;
  final double margineSx;
  final double margineDx;
  final bool mostraPrezzo;
  final bool mostraQrCode;
  final bool mostraBarcode;
  final bool mostraSku;
  final bool mostraTaglia;
  final bool mostraColore;
  final double dimensioneQr; // in mm
  final double fontSizeNome;
  final double fontSizePrezzo;
  final int etichettaPerRiga;
  final int etichettaPerColonna;

  const EtichetteSettings({
    this.larghezzaEtichetta = 50,
    this.altezzaEtichetta = 30,
    this.margineSup = 2,
    this.margineInf = 2,
    this.margineSx = 2,
    this.margineDx = 2,
    this.mostraPrezzo = true,
    this.mostraQrCode = true,
    this.mostraBarcode = false,
    this.mostraSku = true,
    this.mostraTaglia = true,
    this.mostraColore = true,
    this.dimensioneQr = 15,
    this.fontSizeNome = 10,
    this.fontSizePrezzo = 12,
    this.etichettaPerRiga = 3,
    this.etichettaPerColonna = 8,
  });

  EtichetteSettings copyWith({
    double? larghezzaEtichetta,
    double? altezzaEtichetta,
    double? margineSup,
    double? margineInf,
    double? margineSx,
    double? margineDx,
    bool? mostraPrezzo,
    bool? mostraQrCode,
    bool? mostraBarcode,
    bool? mostraSku,
    bool? mostraTaglia,
    bool? mostraColore,
    double? dimensioneQr,
    double? fontSizeNome,
    double? fontSizePrezzo,
    int? etichettaPerRiga,
    int? etichettaPerColonna,
  }) {
    return EtichetteSettings(
      larghezzaEtichetta: larghezzaEtichetta ?? this.larghezzaEtichetta,
      altezzaEtichetta: altezzaEtichetta ?? this.altezzaEtichetta,
      margineSup: margineSup ?? this.margineSup,
      margineInf: margineInf ?? this.margineInf,
      margineSx: margineSx ?? this.margineSx,
      margineDx: margineDx ?? this.margineDx,
      mostraPrezzo: mostraPrezzo ?? this.mostraPrezzo,
      mostraQrCode: mostraQrCode ?? this.mostraQrCode,
      mostraBarcode: mostraBarcode ?? this.mostraBarcode,
      mostraSku: mostraSku ?? this.mostraSku,
      mostraTaglia: mostraTaglia ?? this.mostraTaglia,
      mostraColore: mostraColore ?? this.mostraColore,
      dimensioneQr: dimensioneQr ?? this.dimensioneQr,
      fontSizeNome: fontSizeNome ?? this.fontSizeNome,
      fontSizePrezzo: fontSizePrezzo ?? this.fontSizePrezzo,
      etichettaPerRiga: etichettaPerRiga ?? this.etichettaPerRiga,
      etichettaPerColonna: etichettaPerColonna ?? this.etichettaPerColonna,
    );
  }
}
