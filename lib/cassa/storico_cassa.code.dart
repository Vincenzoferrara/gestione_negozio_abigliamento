// storico_cassa.code.dart
//
// Storico scontrini POS separato dagli ordini WooCommerce, resi vincolati
// alla riga venduta e chiusure di giornata. Persistenza locale in
// SharedPreferences/JSON in attesa dell'enforcement server-side MGWS.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../log_viewer/app_logger.dart';
import 'class_scontrino.dart';

/// Riga vendita con residuo rendibile.
class RigaRendibile {
  final String chiaveRiga;
  final String nome;
  final String sku;
  final double prezzoUnitario;
  final int quantitaVenduta;
  final int quantitaGiaResa;

  const RigaRendibile({
    required this.chiaveRiga,
    required this.nome,
    required this.sku,
    required this.prezzoUnitario,
    required this.quantitaVenduta,
    required this.quantitaGiaResa,
  });

  int get quantitaRendibile => quantitaVenduta - quantitaGiaResa;
  bool get isEsaurita => quantitaRendibile <= 0;
}

/// Esito del controllo rigido sul reso.
class EsitoReso {
  final bool ok;
  final String? errore;

  const EsitoReso.ok() : ok = true, errore = null;
  const EsitoReso.ko(this.errore) : ok = false;
}

/// Chiusura di giornata per una cassa. Immodificabile dopo la registrazione:
/// eventuali correzioni passano da una nuova nota di rettifica, mai da edit.
class ChiusuraCassa {
  final String id;
  final String giornataId;
  final String cassaNome;
  final String? sede;
  final DateTime data;
  final int? operatoreId;
  final String? operatoreNome;
  final String? operatoreCognome;
  final double fondoIniziale;
  final double incassiContanti;
  final double incassiCarta;
  final double incassiAltri;
  final double rimborsi;
  final double entrateManuali;
  final double usciteManuali;
  final double contanteContato;
  final double cartaContato;
  final String? causaleDifferenza;
  final String? note;
  final List<String> rettifiche;

  const ChiusuraCassa({
    required this.id,
    required this.giornataId,
    required this.cassaNome,
    this.sede,
    required this.data,
    this.operatoreId,
    this.operatoreNome,
    this.operatoreCognome,
    this.fondoIniziale = 0,
    this.incassiContanti = 0,
    this.incassiCarta = 0,
    this.incassiAltri = 0,
    this.rimborsi = 0,
    this.entrateManuali = 0,
    this.usciteManuali = 0,
    this.contanteContato = 0,
    this.cartaContato = 0,
    this.causaleDifferenza,
    this.note,
    this.rettifiche = const [],
  });

  double get contanteAtteso =>
      fondoIniziale +
      incassiContanti +
      entrateManuali -
      rimborsi -
      usciteManuali;

  double get differenzaContanti => contanteContato - contanteAtteso;

  double get cartaAttesa => incassiCarta;

  double get differenzaCarta => cartaContato - cartaAttesa;

  bool get hasDifferenze =>
      differenzaContanti.abs() > 0.009 || differenzaCarta.abs() > 0.009;

  Map<String, dynamic> toJson() => {
    'id': id,
    'giornataId': giornataId,
    'cassaNome': cassaNome,
    'sede': sede,
    'data': data.toIso8601String(),
    'operatoreId': operatoreId,
    'operatoreNome': operatoreNome,
    'operatoreCognome': operatoreCognome,
    'fondoIniziale': fondoIniziale,
    'incassiContanti': incassiContanti,
    'incassiCarta': incassiCarta,
    'incassiAltri': incassiAltri,
    'rimborsi': rimborsi,
    'entrateManuali': entrateManuali,
    'usciteManuali': usciteManuali,
    'contanteContato': contanteContato,
    'cartaContato': cartaContato,
    'causaleDifferenza': causaleDifferenza,
    'note': note,
    'rettifiche': rettifiche,
  };

  factory ChiusuraCassa.fromJson(Map<String, dynamic> json) => ChiusuraCassa(
    id: json['id']?.toString() ?? '',
    giornataId: json['giornataId']?.toString() ?? '',
    cassaNome: json['cassaNome']?.toString() ?? 'cassa',
    sede: json['sede']?.toString(),
    data: DateTime.tryParse(json['data']?.toString() ?? '') ?? DateTime.now(),
    operatoreId: (json['operatoreId'] as num?)?.toInt(),
    operatoreNome: json['operatoreNome']?.toString(),
    operatoreCognome: json['operatoreCognome']?.toString(),
    fondoIniziale: (json['fondoIniziale'] as num?)?.toDouble() ?? 0,
    incassiContanti: (json['incassiContanti'] as num?)?.toDouble() ?? 0,
    incassiCarta: (json['incassiCarta'] as num?)?.toDouble() ?? 0,
    incassiAltri: (json['incassiAltri'] as num?)?.toDouble() ?? 0,
    rimborsi: (json['rimborsi'] as num?)?.toDouble() ?? 0,
    entrateManuali: (json['entrateManuali'] as num?)?.toDouble() ?? 0,
    usciteManuali: (json['usciteManuali'] as num?)?.toDouble() ?? 0,
    contanteContato: (json['contanteContato'] as num?)?.toDouble() ?? 0,
    cartaContato: (json['cartaContato'] as num?)?.toDouble() ?? 0,
    causaleDifferenza: json['causaleDifferenza']?.toString(),
    note: json['note']?.toString(),
    rettifiche: ((json['rettifiche'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
  );

  ChiusuraCassa withRettifica(String nota) => ChiusuraCassa(
    id: id,
    giornataId: giornataId,
    cassaNome: cassaNome,
    sede: sede,
    data: data,
    operatoreId: operatoreId,
    operatoreNome: operatoreNome,
    operatoreCognome: operatoreCognome,
    fondoIniziale: fondoIniziale,
    incassiContanti: incassiContanti,
    incassiCarta: incassiCarta,
    incassiAltri: incassiAltri,
    rimborsi: rimborsi,
    entrateManuali: entrateManuali,
    usciteManuali: usciteManuali,
    contanteContato: contanteContato,
    cartaContato: cartaContato,
    causaleDifferenza: causaleDifferenza,
    note: note,
    rettifiche: [...rettifiche, nota],
  );
}

/// Store locale dello storico POS + chiusure.
class StoricoCassaStore {
  static const String _scontriniKey = 'storico_cassa_scontrini_pos_v1';
  static const String _chiusureKey = 'storico_cassa_chiusure_v1';
  static const String _progressivoKey = 'storico_cassa_progressivo_v1';

  final List<Scontrino> _scontrini = [];
  final List<ChiusuraCassa> _chiusure = [];
  int _progressivo = 0;
  bool _initialized = false;

  List<Scontrino> get scontrini => List.unmodifiable(_scontrini);
  List<ChiusuraCassa> get chiusure => List.unmodifiable(_chiusure);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _progressivo = prefs.getInt(_progressivoKey) ?? 0;
    final rawScontrini = prefs.getString(_scontriniKey);
    if (rawScontrini != null && rawScontrini.isNotEmpty) {
      try {
        final list = (jsonDecode(rawScontrini) as List).whereType<Map>();
        _scontrini
          ..clear()
          ..addAll(
            list.map((e) => Scontrino.fromJson(Map<String, dynamic>.from(e))),
          );
      } catch (e) {
        AppLogger().w('Storico cassa: scontrini locali non leggibili: $e');
      }
    }
    final rawChiusure = prefs.getString(_chiusureKey);
    if (rawChiusure != null && rawChiusure.isNotEmpty) {
      try {
        final list = (jsonDecode(rawChiusure) as List).whereType<Map>();
        _chiusure
          ..clear()
          ..addAll(
            list.map(
              (e) => ChiusuraCassa.fromJson(Map<String, dynamic>.from(e)),
            ),
          );
      } catch (e) {
        AppLogger().w('Storico cassa: chiusure locali non leggibili: $e');
      }
    }
    _initialized = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_progressivoKey, _progressivo);
    await prefs.setString(
      _scontriniKey,
      jsonEncode(_scontrini.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _chiusureKey,
      jsonEncode(_chiusure.map((e) => e.toJson()).toList()),
    );
  }

  /// Registra uno scontrino POS chiuso. Gli ordini Woo non entrano mai qui:
  /// resta il documento origine solo come riferimento `wooOrderId`.
  Future<Scontrino> registraScontrinoChiuso(Scontrino scontrino) async {
    await init();
    _progressivo += 1;
    scontrino.numeroProgressivo = _progressivo;
    scontrino.canale = 'pos';
    scontrino.dataChiusura = DateTime.now();
    scontrino.giornataId ??= Scontrino.calcolaGiornataId(
      scontrino.data,
      scontrino.cassaNome,
    );
    if (scontrino.stato == 'aperto' || scontrino.stato == 'sospeso') {
      scontrino.stato = scontrino.totale < 0 ? 'rimborsato' : 'pagato';
    }
    _scontrini.insert(0, scontrino);
    await _save();
    AppLogger().i(
      'Storico POS #$_progressivo registrato (${scontrino.righe.length} righe)',
    );
    return scontrino;
  }

  List<Scontrino> filtra({
    DateTime? dal,
    DateTime? al,
    String? cassaNome,
    String? metodoPagamento,
    String? queryCliente,
    int? operatoreId,
    bool? soloResi,
  }) {
    return _scontrini.where((s) {
      if (dal != null && s.data.isBefore(dal)) return false;
      if (al != null && s.data.isAfter(al)) return false;
      if (cassaNome != null && cassaNome.isNotEmpty) {
        if ((s.cassaNome ?? '') != cassaNome) return false;
      }
      if (metodoPagamento != null && metodoPagamento.isNotEmpty) {
        if (s.metodoPagamento != metodoPagamento) return false;
      }
      if (operatoreId != null && s.operatoreId != operatoreId) return false;
      if (soloResi == true && !s.hasResi) return false;
      if (queryCliente != null && queryCliente.trim().isNotEmpty) {
        final q = queryCliente.toLowerCase();
        final haystack =
            '${s.clienteNome ?? ''} ${s.clienteEmail ?? ''} '
            '${s.numeroProgressivo ?? ''} ${s.wooOrderId ?? ''} ${s.id}';
        if (!haystack.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Scontrino? cercaPerId(String id) {
    for (final s in _scontrini) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Righe vendita di uno scontrino con quantita gia resa e residuo.
  List<RigaRendibile> righeRendibili(String scontrinoId) {
    final origine = cercaPerId(scontrinoId);
    if (origine == null) return const [];
    final rese = <String, int>{};
    for (final s in _scontrini) {
      for (final riga in s.righe) {
        if (riga.isReso &&
            riga.riferimentoScontrinoId == scontrinoId &&
            riga.riferimentoChiaveRiga != null) {
          rese[riga.riferimentoChiaveRiga!] =
              (rese[riga.riferimentoChiaveRiga!] ?? 0) + riga.quantita;
        }
      }
    }
    final out = <RigaRendibile>[];
    for (final riga in origine.righe) {
      if (riga.isReso) continue;
      out.add(
        RigaRendibile(
          chiaveRiga: riga.chiaveRiga,
          nome: riga.nomeCompleto,
          sku: riga.sku,
          prezzoUnitario: riga.prezzoUnitario,
          quantitaVenduta: riga.quantita,
          quantitaGiaResa: rese[riga.chiaveRiga] ?? 0,
        ),
      );
    }
    return out;
  }

  /// Controllo rigido: il reso esiste solo come riga collegata a una vendita
  /// reale, entro il residuo rendibile e con motivo obbligatorio.
  EsitoReso validaReso({
    required String scontrinoOrigineId,
    required String chiaveRiga,
    required int quantita,
    required String? motivo,
  }) {
    if (cercaPerId(scontrinoOrigineId) == null) {
      return const EsitoReso.ko('Scontrino di origine non trovato.');
    }
    if (quantita <= 0) {
      return const EsitoReso.ko('Quantita reso non valida.');
    }
    if (motivo == null || motivo.trim().isEmpty) {
      return const EsitoReso.ko('Motivo del reso obbligatorio.');
    }
    RigaRendibile? target;
    for (final r in righeRendibili(scontrinoOrigineId)) {
      if (r.chiaveRiga == chiaveRiga) target = r;
    }
    if (target == null) {
      return const EsitoReso.ko('Riga vendita non trovata nello scontrino.');
    }
    if (quantita > target.quantitaRendibile) {
      return EsitoReso.ko(
        'Disponibili per il reso: ${target.quantitaRendibile} '
        '(venduti ${target.quantitaVenduta}, gia resi ${target.quantitaGiaResa}).',
      );
    }
    return const EsitoReso.ok();
  }

  /// Totali di giornata per una cassa: base della chiusura.
  Map<String, double> totaliGiornata(String giornataId) {
    double contanti = 0;
    double carta = 0;
    double altri = 0;
    double rimborsi = 0;
    for (final s in _scontrini) {
      if (s.giornataId != giornataId) continue;
      if (s.totale < 0) {
        rimborsi += s.totale.abs();
        continue;
      }
      switch (s.metodoPagamento) {
        case 'contanti':
          contanti += s.totale;
          break;
        case 'carta':
        case 'bancomat':
          carta += s.totale;
          break;
        default:
          altri += s.totale;
      }
    }
    return {
      'contanti': contanti,
      'carta': carta,
      'altri': altri,
      'rimborsi': rimborsi,
    };
  }

  bool hasChiusura(String giornataId) =>
      _chiusure.any((c) => c.giornataId == giornataId);

  /// Registra la chiusura. Causale obbligatoria in presenza di differenze.
  /// La chiusura non si modifica: solo note di rettifica append-only.
  Future<EsitoReso> registraChiusura(ChiusuraCassa chiusura) async {
    await init();
    if (hasChiusura(chiusura.giornataId)) {
      return const EsitoReso.ko('Giornata gia chiusa: usare una rettifica.');
    }
    if (chiusura.hasDifferenze &&
        (chiusura.causaleDifferenza ?? '').trim().isEmpty) {
      return const EsitoReso.ko(
        'Causale differenza obbligatoria quando contato e atteso non coincidono.',
      );
    }
    _chiusure.insert(0, chiusura);
    await _save();
    return const EsitoReso.ok();
  }

  Future<void> aggiungiRettifica(String chiusuraId, String nota) async {
    await init();
    final index = _chiusure.indexWhere((c) => c.id == chiusuraId);
    if (index < 0) return;
    _chiusure[index] = _chiusure[index].withRettifica(
      '${DateTime.now().toIso8601String()} - $nota',
    );
    await _save();
  }

  ChiusuraCassa? cercaChiusura(String giornataId) {
    for (final c in _chiusure) {
      if (c.giornataId == giornataId) return c;
    }
    return null;
  }
}
