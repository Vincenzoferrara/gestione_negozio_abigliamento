import 'package:flutter/foundation.dart';

class Dipendente {
  final int id;
  final String nome;
  final String cognome;
  final String email;
  final String ruolo;
  final double stipendio;
  final DateTime? dataNascita;
  final DateTime? dataAssunzione;
  final String?
  tipoContratto; // full-time, part-time, contratto a tempo determinato, etc.
  final String? orarioLavoro; // es. "9:00-18:00"
  final int giorniFerieDisponibili;
  final int giorniFerieUsati;
  final int giorniMalattia;
  final List<Map<String, dynamic>>?
  storicoPagamenti; // lista di mappe con data, importo, etc.
  final List<String>? benefici; // lista di benefici
  final List<String>? formazione; // corsi di formazione
  final List<Map<String, dynamic>>? valutazioni; // valutazioni performance
  final List<String>? documenti; // nomi file documenti allegati
  final double? venditeTotali; // per ruoli di vendita
  final int? produzioneTotale; // per ruoli di produzione

  Dipendente({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.ruolo,
    required this.stipendio,
    this.dataNascita,
    this.dataAssunzione,
    this.tipoContratto,
    this.orarioLavoro,
    this.giorniFerieDisponibili = 0,
    this.giorniFerieUsati = 0,
    this.giorniMalattia = 0,
    this.storicoPagamenti,
    this.benefici,
    this.formazione,
    this.valutazioni,
    this.documenti,
    this.venditeTotali,
    this.produzioneTotale,
  });

  factory Dipendente.fromJson(Map<String, dynamic> json) {
    return Dipendente(
      id: json['id'],
      nome: json['nome'],
      cognome: json['cognome'],
      email: json['email'],
      ruolo: json['ruolo'],
      stipendio: json['stipendio'].toDouble(),
      dataNascita: json['dataNascita'] != null
          ? DateTime.parse(json['dataNascita'])
          : null,
      dataAssunzione: json['dataAssunzione'] != null
          ? DateTime.parse(json['dataAssunzione'])
          : null,
      tipoContratto: json['tipoContratto'],
      orarioLavoro: json['orarioLavoro'],
      giorniFerieDisponibili: json['giorniFerieDisponibili'] ?? 0,
      giorniFerieUsati: json['giorniFerieUsati'] ?? 0,
      giorniMalattia: json['giorniMalattia'] ?? 0,
      storicoPagamenti: json['storicoPagamenti'] != null
          ? List<Map<String, dynamic>>.from(json['storicoPagamenti'])
          : null,
      benefici: json['benefici'] != null
          ? List<String>.from(json['benefici'])
          : null,
      formazione: json['formazione'] != null
          ? List<String>.from(json['formazione'])
          : null,
      valutazioni: json['valutazioni'] != null
          ? List<Map<String, dynamic>>.from(json['valutazioni'])
          : null,
      documenti: json['documenti'] != null
          ? List<String>.from(json['documenti'])
          : null,
      venditeTotali: json['venditeTotali']?.toDouble(),
      produzioneTotale: json['produzioneTotale']?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'ruolo': ruolo,
      'stipendio': stipendio,
      'dataNascita': dataNascita?.toIso8601String(),
      'dataAssunzione': dataAssunzione?.toIso8601String(),
      'tipoContratto': tipoContratto,
      'orarioLavoro': orarioLavoro,
      'giorniFerieDisponibili': giorniFerieDisponibili,
      'giorniFerieUsati': giorniFerieUsati,
      'giorniMalattia': giorniMalattia,
      'storicoPagamenti': storicoPagamenti,
      'benefici': benefici,
      'formazione': formazione,
      'valutazioni': valutazioni,
      'documenti': documenti,
      'venditeTotali': venditeTotali,
      'produzioneTotale': produzioneTotale,
    };
  }
}

class DipendentiService extends ChangeNotifier {
  List<Dipendente> _dipendenti = [];
  bool _isLoading = false;

  List<Dipendente> get dipendenti => _dipendenti;
  bool get isLoading => _isLoading;

  Future<void> loadDipendenti() async {
    _isLoading = true;
    notifyListeners();
    // TODO: Implement API call to load dipendenti from WordPress
    // For now, mock data
    _dipendenti = [
      Dipendente(
        id: 1,
        nome: 'Mario',
        cognome: 'Rossi',
        email: 'mario@example.com',
        ruolo: 'Cassiere',
        stipendio: 1500.0,
        dataNascita: DateTime(1985, 5, 15),
        dataAssunzione: DateTime(2020, 1, 10),
        tipoContratto: 'Full-time',
        orarioLavoro: '9:00-18:00',
        giorniFerieDisponibili: 25,
        giorniFerieUsati: 5,
        giorniMalattia: 2,
        storicoPagamenti: [
          {'data': '2024-01-01', 'importo': 1500.0},
        ],
        benefici: ['Assicurazione sanitaria', 'Buoni pasto'],
        formazione: ['Corso sicurezza', 'Corso cassa'],
        valutazioni: [
          {'anno': 2023, 'valutazione': 'Buona'},
        ],
        documenti: ['CV_Mario_Rossi.pdf', 'Contratto.pdf'],
        venditeTotali: 25000.0,
      ),
      Dipendente(
        id: 2,
        nome: 'Luca',
        cognome: 'Bianchi',
        email: 'luca@example.com',
        ruolo: 'Manager',
        stipendio: 2000.0,
        dataNascita: DateTime(1980, 3, 22),
        dataAssunzione: DateTime(2018, 6, 5),
        tipoContratto: 'Full-time',
        orarioLavoro: '8:00-17:00',
        giorniFerieDisponibili: 30,
        giorniFerieUsati: 10,
        giorniMalattia: 1,
        storicoPagamenti: [
          {'data': '2024-01-01', 'importo': 2000.0},
        ],
        benefici: ['Auto aziendale', 'Assicurazione sanitaria'],
        formazione: ['Corso management', 'Corso leadership'],
        valutazioni: [
          {'anno': 2023, 'valutazione': 'Eccellente'},
        ],
        documenti: ['CV_Luca_Bianchi.pdf', 'Contratto.pdf'],
        produzioneTotale: 500,
      ),
    ];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDipendente(Dipendente dipendente) async {
    // TODO: Implement API call to add dipendente
    _dipendenti.add(dipendente);
    notifyListeners();
  }

  Future<void> updateDipendente(Dipendente dipendente) async {
    // TODO: Implement API call to update dipendente
    final index = _dipendenti.indexWhere((d) => d.id == dipendente.id);
    if (index != -1) {
      _dipendenti[index] = dipendente;
      notifyListeners();
    }
  }

  Future<void> deleteDipendente(int id) async {
    // TODO: Implement API call to delete dipendente
    _dipendenti.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}
