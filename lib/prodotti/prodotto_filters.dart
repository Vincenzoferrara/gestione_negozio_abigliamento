import 'class_prodotti.dart';

enum CampoFiltroProdotto {
  ricercaRapida,
  id,
  nome,
  sku,
  categoria,
  tag,
  marchio,
  prezzo,
  giacenza,
  disponibilita,
  descrizioneBreve,
  descrizioneCompleta,
  stanza,
  scaffale,
  mensola,
  status,
}

enum OperatoreFiltroProdotto {
  contiene,
  nonContiene,
  contieneSensibile,
  nonContieneSensibile,
  ugualeEsatto,
  diversoEsatto,
  iniziaCon,
  finisceCon,
  inElenco,
  nonInElenco,
  uguale,
  diverso,
  maggioreUguale,
  maggiore,
  minoreUguale,
  minore,
  tra,
}

class FiltroProdotto {
  final CampoFiltroProdotto campo;
  final OperatoreFiltroProdotto operatore;
  final List<String> valori;

  const FiltroProdotto({
    required this.campo,
    required this.operatore,
    required this.valori,
  });

  String get campoLabel => ProdottoFilterEngine.campoLabel(campo);
  String get operatoreLabel => ProdottoFilterEngine.operatoreLabel(operatore);
  String get chipLabel => '$campoLabel $operatoreLabel ${valori.join(', ')}';
}

class ProdottoFilterEngine {
  static const Map<CampoFiltroProdotto, List<String>> campoAliases =
      <CampoFiltroProdotto, List<String>>{
        CampoFiltroProdotto.ricercaRapida: <String>['ricerca rapida', 'ricerca', 'search'],
        CampoFiltroProdotto.id: <String>['id', 'identificativo id'],
        CampoFiltroProdotto.nome: <String>['nome', 'prodotto', 'product', 'titolo'],
        CampoFiltroProdotto.sku: <String>['sku', 'codice', 'codice prodotto', 'identificativo', 'articolo'],
        CampoFiltroProdotto.categoria: <String>['categoria', 'categorie', 'cat'],
        CampoFiltroProdotto.tag: <String>['tag', 'etichette'],
        CampoFiltroProdotto.marchio: <String>['marchio', 'marca', 'brand'],
        CampoFiltroProdotto.prezzo: <String>['prezzo', 'price', 'costo'],
        CampoFiltroProdotto.giacenza: <String>['giacenza', 'stock', 'quantita'],
        CampoFiltroProdotto.disponibilita: <String>['disponibilita', 'instock'],
        CampoFiltroProdotto.descrizioneBreve: <String>['descrizione breve', 'breve', 'excerpt'],
        CampoFiltroProdotto.descrizioneCompleta: <String>['descrizione', 'descrizione completa', 'contenuto'],
        CampoFiltroProdotto.stanza: <String>['stanza', 'room'],
        CampoFiltroProdotto.scaffale: <String>['scaffale', 'rack'],
        CampoFiltroProdotto.mensola: <String>['mensola', 'shelf'],
        CampoFiltroProdotto.status: <String>['stato', 'status'],
      };

  static const List<CampoFiltroProdotto> searchableFields = <CampoFiltroProdotto>[
    CampoFiltroProdotto.nome,
    CampoFiltroProdotto.sku,
    CampoFiltroProdotto.id,
    CampoFiltroProdotto.categoria,
    CampoFiltroProdotto.tag,
    CampoFiltroProdotto.marchio,
    CampoFiltroProdotto.prezzo,
    CampoFiltroProdotto.giacenza,
    CampoFiltroProdotto.descrizioneBreve,
    CampoFiltroProdotto.descrizioneCompleta,
    CampoFiltroProdotto.stanza,
    CampoFiltroProdotto.scaffale,
    CampoFiltroProdotto.mensola,
    CampoFiltroProdotto.status,
  ];

  static String campoLabel(CampoFiltroProdotto campo) {
    switch (campo) {
      case CampoFiltroProdotto.ricercaRapida:
        return 'Ricerca rapida';
      case CampoFiltroProdotto.id:
        return 'ID';
      case CampoFiltroProdotto.nome:
        return 'Nome prodotto';
      case CampoFiltroProdotto.sku:
        return 'Identificativo / Articolo';
      case CampoFiltroProdotto.categoria:
        return 'Categoria';
      case CampoFiltroProdotto.tag:
        return 'Tag';
      case CampoFiltroProdotto.marchio:
        return 'Marchio';
      case CampoFiltroProdotto.prezzo:
        return 'Prezzo';
      case CampoFiltroProdotto.giacenza:
        return 'Giacenza';
      case CampoFiltroProdotto.disponibilita:
        return 'Disponibilita';
      case CampoFiltroProdotto.descrizioneBreve:
        return 'Descrizione breve';
      case CampoFiltroProdotto.descrizioneCompleta:
        return 'Descrizione completa';
      case CampoFiltroProdotto.stanza:
        return 'Stanza';
      case CampoFiltroProdotto.scaffale:
        return 'Scaffale';
      case CampoFiltroProdotto.mensola:
        return 'Mensola';
      case CampoFiltroProdotto.status:
        return 'Stato';
    }
  }

  static String operatoreLabel(OperatoreFiltroProdotto operatore) {
    switch (operatore) {
      case OperatoreFiltroProdotto.contiene:
        return '~ Contiene';
      case OperatoreFiltroProdotto.nonContiene:
        return '!~ Non contiene';
      case OperatoreFiltroProdotto.contieneSensibile:
        return '~! Contiene sensibile';
      case OperatoreFiltroProdotto.nonContieneSensibile:
        return '!~! Non contiene sensibile';
      case OperatoreFiltroProdotto.ugualeEsatto:
        return '== Uguale esatto';
      case OperatoreFiltroProdotto.diversoEsatto:
        return '!== Diverso esatto';
      case OperatoreFiltroProdotto.iniziaCon:
        return '^ Inizia con';
      case OperatoreFiltroProdotto.finisceCon:
        return r'$ Finisce con';
      case OperatoreFiltroProdotto.inElenco:
        return 'IN In elenco';
      case OperatoreFiltroProdotto.nonInElenco:
        return 'NOT IN Non in elenco';
      case OperatoreFiltroProdotto.uguale:
        return '= Uguale a';
      case OperatoreFiltroProdotto.diverso:
        return '!= Diverso da';
      case OperatoreFiltroProdotto.maggioreUguale:
        return '>= Maggiore o uguale';
      case OperatoreFiltroProdotto.maggiore:
        return '> Maggiore di';
      case OperatoreFiltroProdotto.minoreUguale:
        return '<= Minore o uguale';
      case OperatoreFiltroProdotto.minore:
        return '< Minore di';
      case OperatoreFiltroProdotto.tra:
        return 'BETWEEN Tra';
    }
  }

  static String operatoreTooltip(OperatoreFiltroProdotto operatore) {
    switch (operatore) {
      case OperatoreFiltroProdotto.uguale:
        return 'Confronto numerico o booleano uguale.';
      case OperatoreFiltroProdotto.diverso:
        return 'Confronto numerico o booleano diverso.';
      case OperatoreFiltroProdotto.contiene:
        return 'Cerca testo in qualsiasi posizione (ignora maiuscole/accenti).';
      case OperatoreFiltroProdotto.nonContiene:
        return 'Esclude testo in qualsiasi posizione (ignora maiuscole/accenti).';
      case OperatoreFiltroProdotto.contieneSensibile:
        return 'Cerca testo rispettando maiuscole e accenti.';
      case OperatoreFiltroProdotto.nonContieneSensibile:
        return 'Esclude testo rispettando maiuscole e accenti.';
      case OperatoreFiltroProdotto.ugualeEsatto:
        return 'Confronto esatto normalizzato.';
      case OperatoreFiltroProdotto.diversoEsatto:
        return 'Diverso esatto normalizzato.';
      case OperatoreFiltroProdotto.iniziaCon:
        return 'Match da inizio testo.';
      case OperatoreFiltroProdotto.finisceCon:
        return 'Match fine testo.';
      case OperatoreFiltroProdotto.inElenco:
        return 'Piu valori separati da , o ;.';
      case OperatoreFiltroProdotto.nonInElenco:
        return 'Esclude piu valori separati da , o ;.';
      case OperatoreFiltroProdotto.maggioreUguale:
        return 'Confronto numerico maggiore o uguale.';
      case OperatoreFiltroProdotto.maggiore:
        return 'Confronto numerico maggiore di.';
      case OperatoreFiltroProdotto.minoreUguale:
        return 'Confronto numerico minore o uguale.';
      case OperatoreFiltroProdotto.minore:
        return 'Confronto numerico minore di.';
      case OperatoreFiltroProdotto.tra:
        return 'Intervallo numerico con due valori.';
    }
  }

  static List<OperatoreFiltroProdotto> orderedOperators() {
    return <OperatoreFiltroProdotto>[
      OperatoreFiltroProdotto.contiene,
      OperatoreFiltroProdotto.nonContiene,
      OperatoreFiltroProdotto.ugualeEsatto,
      OperatoreFiltroProdotto.diversoEsatto,
      OperatoreFiltroProdotto.inElenco,
      OperatoreFiltroProdotto.nonInElenco,
      OperatoreFiltroProdotto.iniziaCon,
      OperatoreFiltroProdotto.finisceCon,
      OperatoreFiltroProdotto.contieneSensibile,
      OperatoreFiltroProdotto.nonContieneSensibile,
      OperatoreFiltroProdotto.uguale,
      OperatoreFiltroProdotto.diverso,
      OperatoreFiltroProdotto.maggiore,
      OperatoreFiltroProdotto.maggioreUguale,
      OperatoreFiltroProdotto.minore,
      OperatoreFiltroProdotto.minoreUguale,
      OperatoreFiltroProdotto.tra,
    ];
  }

  static String operatorSectionLabel(OperatoreFiltroProdotto operatore) {
    switch (operatore) {
      case OperatoreFiltroProdotto.contiene:
      case OperatoreFiltroProdotto.nonContiene:
      case OperatoreFiltroProdotto.ugualeEsatto:
      case OperatoreFiltroProdotto.diversoEsatto:
      case OperatoreFiltroProdotto.inElenco:
      case OperatoreFiltroProdotto.nonInElenco:
        return 'Comuni';
      case OperatoreFiltroProdotto.iniziaCon:
      case OperatoreFiltroProdotto.finisceCon:
      case OperatoreFiltroProdotto.contieneSensibile:
      case OperatoreFiltroProdotto.nonContieneSensibile:
        return 'Testo avanzato';
      case OperatoreFiltroProdotto.uguale:
      case OperatoreFiltroProdotto.diverso:
      case OperatoreFiltroProdotto.maggiore:
      case OperatoreFiltroProdotto.maggioreUguale:
      case OperatoreFiltroProdotto.minore:
      case OperatoreFiltroProdotto.minoreUguale:
      case OperatoreFiltroProdotto.tra:
        return 'Numerici';
    }
  }

  static CampoFiltroProdotto? resolveCampoFromInput(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final entry in campoAliases.entries) {
      final label = campoLabel(entry.key).toLowerCase();
      if (label == normalized || entry.value.any((alias) => alias == normalized)) {
        return entry.key;
      }
    }
    return null;
  }

  static bool isNumericField(CampoFiltroProdotto campo) {
    return campo == CampoFiltroProdotto.id ||
        campo == CampoFiltroProdotto.prezzo ||
        campo == CampoFiltroProdotto.giacenza;
  }

  static bool isBooleanField(CampoFiltroProdotto campo) {
    return campo == CampoFiltroProdotto.disponibilita;
  }

  static bool supportsOperator(
    CampoFiltroProdotto campo,
    OperatoreFiltroProdotto operatore,
  ) {
    if (isNumericField(campo)) {
      return operatore == OperatoreFiltroProdotto.uguale ||
          operatore == OperatoreFiltroProdotto.diverso ||
          operatore == OperatoreFiltroProdotto.maggiore ||
          operatore == OperatoreFiltroProdotto.maggioreUguale ||
          operatore == OperatoreFiltroProdotto.minore ||
          operatore == OperatoreFiltroProdotto.minoreUguale ||
          operatore == OperatoreFiltroProdotto.tra;
    }
    if (isBooleanField(campo)) {
      return operatore == OperatoreFiltroProdotto.uguale ||
          operatore == OperatoreFiltroProdotto.diverso;
    }
    return operatore == OperatoreFiltroProdotto.contiene ||
        operatore == OperatoreFiltroProdotto.nonContiene ||
        operatore == OperatoreFiltroProdotto.contieneSensibile ||
        operatore == OperatoreFiltroProdotto.nonContieneSensibile ||
        operatore == OperatoreFiltroProdotto.ugualeEsatto ||
        operatore == OperatoreFiltroProdotto.diversoEsatto ||
        operatore == OperatoreFiltroProdotto.iniziaCon ||
        operatore == OperatoreFiltroProdotto.finisceCon ||
        operatore == OperatoreFiltroProdotto.inElenco ||
        operatore == OperatoreFiltroProdotto.nonInElenco;
  }

  static bool matchesQuickSearch(ProdottoGlobal prodotto, String query) {
    final normalizedQuery = normalizeText(query);
    if (normalizedQuery.isEmpty) return true;

    for (final campo in searchableFields) {
      final values = _extractTextValues(prodotto, campo);
      if (values.any((value) => normalizeText(value).contains(normalizedQuery))) {
        return true;
      }
    }
    return false;
  }

  static bool matchesFilters(ProdottoGlobal prodotto, List<FiltroProdotto> filtri) {
    for (final filtro in filtri) {
      if (!matchesSingleFilter(prodotto, filtro)) return false;
    }
    return true;
  }

  static bool matchesSingleFilter(ProdottoGlobal prodotto, FiltroProdotto filtro) {
    if (filtro.campo == CampoFiltroProdotto.ricercaRapida) {
      return matchesQuickSearch(prodotto, filtro.valori.join(' '));
    }
    if (isNumericField(filtro.campo)) {
      return _matchNumericValues(
        values: _extractNumericValues(prodotto, filtro.campo),
        filtro: filtro,
      );
    }
    if (isBooleanField(filtro.campo)) {
      return _matchBooleanValue(
        value: _extractBooleanValue(prodotto, filtro.campo),
        filtro: filtro,
      );
    }
    return _matchTextSet(
      values: _extractTextValues(prodotto, filtro.campo).toSet(),
      filtro: filtro,
    );
  }

  static List<String> getFilterValueSuggestions(
    List<ProdottoGlobal> prodotti,
    CampoFiltroProdotto campo,
    String query, {
    int limit = 60,
  }) {
    if (isNumericField(campo) || isBooleanField(campo)) {
      return const <String>[];
    }

    final values = <String>{};
    for (final prodotto in prodotti) {
      values.addAll(_extractTextValues(prodotto, campo));
    }

    final normalizedQuery = normalizeText(query);
    final ordered = values.where((value) => value.trim().isNotEmpty).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (normalizedQuery.isEmpty) return ordered.take(limit).toList();

    final startsWith = <String>[];
    final contains = <String>[];
    for (final value in ordered) {
      final normalized = normalizeText(value);
      if (normalized.startsWith(normalizedQuery)) {
        startsWith.add(value);
      } else if (normalized.contains(normalizedQuery)) {
        contains.add(value);
      }
    }
    return <String>[...startsWith, ...contains].take(limit).toList();
  }

  static String normalizeText(String input) {
    var out = input.trim().toLowerCase();
    const map = <String, String>{
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    map.forEach((k, v) {
      out = out.replaceAll(k, v);
    });
    return out;
  }

  static double? parseNumericFlexible(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  static List<String> _extractTextValues(
    ProdottoGlobal prodotto,
    CampoFiltroProdotto campo,
  ) {
    switch (campo) {
      case CampoFiltroProdotto.ricercaRapida:
        return <String>{
          ..._extractTextValues(prodotto, CampoFiltroProdotto.id),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.nome),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.sku),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.categoria),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.tag),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.marchio),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.prezzo),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.giacenza),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.descrizioneBreve),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.descrizioneCompleta),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.stanza),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.scaffale),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.mensola),
          ..._extractTextValues(prodotto, CampoFiltroProdotto.status),
        }.toList();
      case CampoFiltroProdotto.id:
        return _singleNumeric((prodotto.id ?? 0).toDouble());
      case CampoFiltroProdotto.nome:
        return <String>{
          ..._singleText(prodotto.nome),
          for (final variante in prodotto.varianti ?? const <VarianteProductGlobal>[]) ..._singleText(variante.nomeVisualizzabile),
          for (final variante in prodotto.varianti ?? const <VarianteProductGlobal>[]) ...variante.attributi.map((attr) => attr.opzione.trim()).where((value) => value.isNotEmpty),
        }.toList();
      case CampoFiltroProdotto.sku:
        return <String>{
          ..._singleText(prodotto.sku),
          for (final variante in prodotto.varianti ?? const <VarianteProductGlobal>[]) ..._singleText(variante.sku),
        }.toList();
      case CampoFiltroProdotto.categoria:
        return prodotto.categoria?.map((categoria) => categoria.nome.trim()).where((value) => value.isNotEmpty).toList() ?? const <String>[];
      case CampoFiltroProdotto.tag:
        return prodotto.tag?.map((tag) => tag.nome.trim()).where((value) => value.isNotEmpty).toList() ?? const <String>[];
      case CampoFiltroProdotto.marchio:
        return _singleText(prodotto.marca);
      case CampoFiltroProdotto.prezzo:
        return _singleNumeric(prodotto.prezzoEffettivo);
      case CampoFiltroProdotto.giacenza:
        return _singleNumeric(prodotto.quantitaTotaleVarianti.toDouble());
      case CampoFiltroProdotto.disponibilita:
        return _singleText(prodotto.isDisponibile ? 'disponibile' : 'non disponibile');
      case CampoFiltroProdotto.descrizioneBreve:
        return _singleText(prodotto.descrizioneBreve);
      case CampoFiltroProdotto.descrizioneCompleta:
        return _singleText(prodotto.descrizioneCompleta);
      case CampoFiltroProdotto.stanza:
        return _singleText(prodotto.stanza);
      case CampoFiltroProdotto.scaffale:
        return _singleText(prodotto.scaffale);
      case CampoFiltroProdotto.mensola:
        return _singleText(prodotto.mensola);
      case CampoFiltroProdotto.status:
        return _singleText(prodotto.status);
    }
  }

  static List<double> _extractNumericValues(
    ProdottoGlobal prodotto,
    CampoFiltroProdotto campo,
  ) {
    switch (campo) {
      case CampoFiltroProdotto.id:
        return prodotto.id == null ? const <double>[] : <double>[prodotto.id!.toDouble()];
      case CampoFiltroProdotto.prezzo:
        return <double>[prodotto.prezzoEffettivo];
      case CampoFiltroProdotto.giacenza:
        return <double>[prodotto.quantitaTotaleVarianti.toDouble()];
      default:
        return const <double>[];
    }
  }

  static bool _extractBooleanValue(
    ProdottoGlobal prodotto,
    CampoFiltroProdotto campo,
  ) {
    switch (campo) {
      case CampoFiltroProdotto.disponibilita:
        return prodotto.isDisponibile;
      default:
        return false;
    }
  }

  static List<String> _singleText(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? const <String>[] : <String>[trimmed];
  }

  static List<String> _singleNumeric(double? value) {
    if (value == null) return const <String>[];
    return <String>[value.toString()];
  }

  static bool _matchTextSet({
    required Set<String> values,
    required FiltroProdotto filtro,
  }) {
    final rawTokens = filtro.valori;
    final normalizedValues = values.map(normalizeText).toSet();
    final normalizedTokens = rawTokens.map(normalizeText).toList();
    switch (filtro.operatore) {
      case OperatoreFiltroProdotto.contiene:
        return normalizedValues.any((value) => normalizedTokens.any((token) => value.contains(token)));
      case OperatoreFiltroProdotto.nonContiene:
        return normalizedValues.every((value) => normalizedTokens.every((token) => !value.contains(token)));
      case OperatoreFiltroProdotto.contieneSensibile:
        return values.any((value) => rawTokens.any((token) => value.contains(token)));
      case OperatoreFiltroProdotto.nonContieneSensibile:
        return values.every((value) => rawTokens.every((token) => !value.contains(token)));
      case OperatoreFiltroProdotto.ugualeEsatto:
      case OperatoreFiltroProdotto.inElenco:
      case OperatoreFiltroProdotto.uguale:
        return normalizedTokens.any((token) => normalizedValues.contains(token));
      case OperatoreFiltroProdotto.diversoEsatto:
      case OperatoreFiltroProdotto.nonInElenco:
      case OperatoreFiltroProdotto.diverso:
        return normalizedTokens.every((token) => !normalizedValues.contains(token));
      case OperatoreFiltroProdotto.iniziaCon:
        return normalizedValues.any((value) => normalizedTokens.any((token) => value.startsWith(token)));
      case OperatoreFiltroProdotto.finisceCon:
        return normalizedValues.any((value) => normalizedTokens.any((token) => value.endsWith(token)));
      case OperatoreFiltroProdotto.maggioreUguale:
      case OperatoreFiltroProdotto.maggiore:
      case OperatoreFiltroProdotto.minoreUguale:
      case OperatoreFiltroProdotto.minore:
      case OperatoreFiltroProdotto.tra:
        return false;
    }
  }

  static bool _matchNumericValues({
    required List<double> values,
    required FiltroProdotto filtro,
  }) {
    if (values.isEmpty) return false;
    final numeri = filtro.valori.map(parseNumericFlexible).whereType<double>().toList();
    if (numeri.isEmpty) return false;

    bool matchesValue(double value) {
      switch (filtro.operatore) {
        case OperatoreFiltroProdotto.uguale:
          return numeri.any((n) => value == n);
        case OperatoreFiltroProdotto.diverso:
          return numeri.every((n) => value != n);
        case OperatoreFiltroProdotto.maggioreUguale:
          return numeri.any((n) => value >= n);
        case OperatoreFiltroProdotto.maggiore:
          return numeri.any((n) => value > n);
        case OperatoreFiltroProdotto.minoreUguale:
          return numeri.any((n) => value <= n);
        case OperatoreFiltroProdotto.minore:
          return numeri.any((n) => value < n);
        case OperatoreFiltroProdotto.tra:
          if (numeri.length < 2) return false;
          final min = numeri[0] <= numeri[1] ? numeri[0] : numeri[1];
          final max = numeri[0] <= numeri[1] ? numeri[1] : numeri[0];
          return value >= min && value <= max;
        default:
          return false;
      }
    }

    return values.any(matchesValue);
  }

  static bool _matchBooleanValue({
    required bool value,
    required FiltroProdotto filtro,
  }) {
    final boolTokens = filtro.valori.map(_parseBooleanFlexible).whereType<bool>().toList();
    if (boolTokens.isEmpty) return false;

    switch (filtro.operatore) {
      case OperatoreFiltroProdotto.uguale:
        return boolTokens.any((token) => token == value);
      case OperatoreFiltroProdotto.diverso:
        return boolTokens.every((token) => token != value);
      default:
        return false;
    }
  }

  static bool? _parseBooleanFlexible(String input) {
    final normalized = normalizeText(input);
    if (<String>{'true', '1', 'si', 'yes', 'disponibile', 'instock', 'in stock'}.contains(normalized)) {
      return true;
    }
    if (<String>{'false', '0', 'no', 'non disponibile', 'outofstock', 'out of stock'}.contains(normalized)) {
      return false;
    }
    return null;
  }
}
