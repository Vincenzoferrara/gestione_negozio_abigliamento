// prodotti_gestisci.code.dart

import '../class_prodotti.dart';

/// Definisce i tipi di ordinamento possibili per la lista dei prodotti.
enum OrdinamentoProdotti {
  nessuno, // Ordine predefinito
  nomeCrescente, // Dalla A alla Z
  nomeDecrescente, // Dalla Z alla A
  prezzoCrescente, // Dal più economico
  prezzoDecrescente, // Dal più costoso
}


/// Classe per la gestione della logica dei prodotti
class ProdottiGestioneController {
  List<ProdottoWoo> _prodotti = [];
  List<ProdottoWoo> _prodottiFiltrati = [];
  ProdottoWoo? _prodottoSelezionato;
  VarianteWoo? _varianteSelezionata;
  String _filtroRicerca = '';
  OrdinamentoProdotti _ordinamentoCorrente = OrdinamentoProdotti.nessuno;

  // --- NUOVO: STATO PER I FILTRI DELLE VARIANTI ---
  /// Mappa che tiene traccia dei filtri attivi per le varianti.
  /// Es: { 'Colore': 'Rosso', 'Taglia': 'M' }
  Map<String, String> _filtriVariantiAttivi = {};

  /// La lista di varianti da mostrare, dopo aver applicato i filtri.
  List<VarianteWoo> _variantiFiltrate = [];
  // --- FINE NOVITÀ ---

  // Getters
  List<ProdottoWoo> get prodotti => _prodottiFiltrati;
  ProdottoWoo? get prodottoSelezionato => _prodottoSelezionato;
  VarianteWoo? get varianteSelezionata => _varianteSelezionata;
  String get filtroRicerca => _filtroRicerca;
  OrdinamentoProdotti get ordinamentoCorrente => _ordinamentoCorrente;

  // --- NUOVO: GETTER PER LE VARIANTI FILTRATE ---
  List<VarianteWoo> get variantiFiltrate => _variantiFiltrate;
  bool get hasFiltriVariantiAttivi => _filtriVariantiAttivi.isNotEmpty;
  // --- FINE NOVITÀ ---


  int get numeroProdotti => _prodottiFiltrati.length;
  bool get hasProdottoSelezionato => _prodottoSelezionato != null;
  bool get hasVarianteSelezionata => _varianteSelezionata != null;
  bool get hasFiltroAttivo => _filtroRicerca.isNotEmpty;

  /// Seleziona un prodotto e resetta la variante e i filtri delle varianti
  void selezionaProdotto(ProdottoWoo prodotto) {
    _prodottoSelezionato = prodotto;
    _varianteSelezionata = null;
    // Quando cambio prodotto, cancello i filtri precedenti e applico quelli nuovi (nessuno)
    cancellaFiltriVarianti();
  }

  /// Seleziona una variante
  void selezionaVariante(VarianteWoo? variante) {
    _varianteSelezionata = variante;
  }

  /// Verifica se un prodotto è selezionato
  bool isProdottoSelezionato(ProdottoWoo prodotto) {
    return _prodottoSelezionato?.id == prodotto.id;
  }

  /// Verifica se una variante è selezionata
  bool isVarianteSelezionata(VarianteWoo variante) {
    return _varianteSelezionata?.id == variante.id;
  }

  /// Ottiene l'URL dell'immagine corrente (variante o prodotto)
  String getCurrentImageUrl() {
    if (_varianteSelezionata?.immagineUrl != null &&
        _varianteSelezionata!.immagineUrl!.isNotEmpty) {
      return _varianteSelezionata!.immagineUrl!;
    }
    return _prodottoSelezionato?.immagineUrl ?? '';
  }

  /// Imposta il filtro di ricerca e aggiorna la lista
  void setFiltroRicerca(String filtro) {
    _filtroRicerca = filtro.toLowerCase();
    _applicaFiltroEOrdinamento();
  }

  /// Cancella il filtro di ricerca
  void cancellaFiltro() {
    _filtroRicerca = '';
    _applicaFiltroEOrdinamento();
  }

  /// Imposta il criterio di ordinamento e aggiorna la lista
  void setOrdinamento(OrdinamentoProdotti nuovoOrdinamento) {
    _ordinamentoCorrente = nuovoOrdinamento;
    _applicaFiltroEOrdinamento();
  }

  // --- NUOVE FUNZIONI PER LA GESTIONE DEI FILTRI VARIANTE ---

  /// Estrae tutte le opzioni di attributo uniche dal prodotto attualmente selezionato.
  /// Ritorna una mappa tipo: { 'Colore': [AttributoRosso, AttributoBlu], 'Taglia': [AttributoM, AttributoL] }
  Map<String, List<AttributoVariante>> getOpzioniFiltroDisponibili() {
    if (_prodottoSelezionato == null) return {};

    // Usiamo una mappa intermedia per garantire l'unicità delle opzioni (es. "Rosso" appare una sola volta)
    final opzioniUniche = <String, Map<String, AttributoVariante>>{};

    for (final variante in _prodottoSelezionato!.varianti) {
      for (final attributo in variante.attributi) {
        // Se l'attributo (es. "Colore") non è ancora nella mappa, lo inizializzo
        opzioniUniche[attributo.nome] ??= {};
        // Aggiungo l'opzione (es. "Rosso") alla mappa interna dell'attributo
        opzioniUniche[attributo.nome]![attributo.opzione] = attributo;
      }
    }

    // Converto la mappa in un formato più facile da usare per la UI
    final risultato = <String, List<AttributoVariante>>{};
    opzioniUniche.forEach((nomeAttributo, mappaOpzioni) {
      risultato[nomeAttributo] = mappaOpzioni.values.toList();
    });

    return risultato;
  }

  /// Imposta o deseleziona un filtro per le varianti.
  void setFiltroVariante(String nomeAttributo, String opzione) {
    // Se l'utente clicca su un filtro già attivo, lo deseleziona.
    if (_filtriVariantiAttivi[nomeAttributo] == opzione) {
      _filtriVariantiAttivi.remove(nomeAttributo);
    } else {
      // Altrimenti, imposta il nuovo filtro per quell'attributo.
      _filtriVariantiAttivi[nomeAttributo] = opzione;
    }
    _applicaFiltriVarianti();
  }
  
  /// Cancella tutti i filtri delle varianti attivi.
  void cancellaFiltriVarianti() {
    _filtriVariantiAttivi.clear();
    _applicaFiltriVarianti();
  }

  /// Verifica se una specifica opzione di filtro è attualmente selezionata.
  bool isFiltroVarianteSelezionato(String nomeAttributo, String opzione) {
    return _filtriVariantiAttivi[nomeAttributo] == opzione;
  }

  /// Filtra la lista delle varianti in base ai filtri attivi.
  void _applicaFiltriVarianti() {
    if (_prodottoSelezionato == null) {
      _variantiFiltrate = [];
      return;
    }

    // Se non ci sono filtri, mostra tutte le varianti
    if (_filtriVariantiAttivi.isEmpty) {
      _variantiFiltrate = List.from(_prodottoSelezionato!.varianti);
      return;
    }
    
    // Parto con tutte le varianti e le filtro progressivamente
    var variantiTemp = List<VarianteWoo>.from(_prodottoSelezionato!.varianti);

    // Per ogni filtro attivo (es. 'Colore':'Rosso')...
    _filtriVariantiAttivi.forEach((nomeFiltro, opzioneFiltro) {
      // ...mantengo solo le varianti che soddisfano la condizione.
      variantiTemp = variantiTemp.where((variante) {
        // La variante deve avere un attributo che matcha sia il nome che l'opzione del filtro.
        return variante.attributi.any((attr) =>
            attr.nome == nomeFiltro && attr.opzione == opzioneFiltro);
      }).toList();
    });

    _variantiFiltrate = variantiTemp;

    // Se la variante precedentemente selezionata non è più visibile, la deseleziono.
    if (_varianteSelezionata != null && !_variantiFiltrate.contains(_varianteSelezionata)) {
      _varianteSelezionata = null;
    }
  }

  // --- FINE NUOVE FUNZIONI ---


  /// Applica il filtro di ricerca e l'ordinamento alla lista dei prodotti
  void _applicaFiltroEOrdinamento() {
    // 1. Applica il filtro
    if (_filtroRicerca.isEmpty) {
      _prodottiFiltrati = List.from(_prodotti);
    } else {
      _prodottiFiltrati = _prodotti.where((prodotto) {
        return prodotto.nome.toLowerCase().contains(_filtroRicerca) ||
               prodotto.sku.toLowerCase().contains(_filtroRicerca) ||
               prodotto.categoria.toLowerCase().contains(_filtroRicerca) ||
               prodotto.descrizioneBreve.toLowerCase().contains(_filtroRicerca) ||
               prodotto.varianti.any((variante) =>
                 variante.nomeVisualizzabile.toLowerCase().contains(_filtroRicerca) ||
                 variante.sku.toLowerCase().contains(_filtroRicerca));
      }).toList();
    }

    // 2. Applica l'ordinamento
    switch (_ordinamentoCorrente) {
      case OrdinamentoProdotti.nomeCrescente:
        _prodottiFiltrati.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        break;
      case OrdinamentoProdotti.nomeDecrescente:
        _prodottiFiltrati.sort((a, b) => b.nome.toLowerCase().compareTo(a.nome.toLowerCase()));
        break;
      case OrdinamentoProdotti.prezzoCrescente:
        _prodottiFiltrati.sort((a, b) => (a.prezzoScontato ?? a.prezzoNormale).compareTo(b.prezzoScontato ?? b.prezzoNormale));
        break;
      case OrdinamentoProdotti.prezzoDecrescente:
        _prodottiFiltrati.sort((a, b) => (b.prezzoScontato ?? b.prezzoNormale).compareTo(a.prezzoScontato ?? a.prezzoNormale));
        break;
      case OrdinamentoProdotti.nessuno:
        break;
    }


    if (_prodottoSelezionato != null &&
        !_prodottiFiltrati.any((p) => p.id == _prodottoSelezionato!.id)) {
      _prodottoSelezionato = null;
      _varianteSelezionata = null;
    }
  }

  /// Carica i prodotti (da implementare con API)
  Future<void> caricaProdotti() async {
    // TODO: Implementare chiamata API
    _prodotti = prodotti_Test();
    _applicaFiltroEOrdinamento();
  }


  // --- IL RESTO DEL FILE RIMANE INVARIATO (dati di test, utility, ecc.) ---
  List<ProdottoWoo> prodotti_Test() {
    return [
      ProdottoWoo(
        id: 1,
        nome: 'Maglietta T-Shirt',
        sku: 'TSHIRT-001',
        prezzoNormale: 20.0,
        prezzoScontato: 15.0,
        descrizioneBreve: 'Maglietta in cotone 100%, disponibile in vari colori.',
        immagineUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop',
        categoria: 'Abbigliamento',
        inStock: true,
        varianti: [
          VarianteWoo(
            id: 101,
            nome: 'Rosso - M',
            sku: 'TSHIRT-001-RM',
            prezzo: 15.0,
            quantita: 10,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Rosso', valore: '#B71C1C'),
              AttributoVariante(nome: 'Taglia', opzione: 'M'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=300&h=300&fit=crop',
          ),
          VarianteWoo(
            id: 102,
            nome: 'Blu - L',
            sku: 'TSHIRT-001-BL',
            prezzo: 15.0,
            quantita: 5,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Blu', valore: '#0D47A1'),
              AttributoVariante(nome: 'Taglia', opzione: 'L'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=300&h=300&fit=crop',
          ),
          VarianteWoo(
            id: 103,
            nome: 'Verde - S',
            sku: 'TSHIRT-001-GS',
            prezzo: 15.0,
            quantita: 8,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Verde', valore: '#1B5E20'),
              AttributoVariante(nome: 'Taglia', opzione: 'S'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=300&h=300&fit=crop',
          ),
          VarianteWoo(
            id: 104,
            nome: 'Nero - XL',
            sku: 'TSHIRT-001-NXL',
            prezzo: 15.0,
            quantita: 3,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Nero', valore: '#212121'),
              AttributoVariante(nome: 'Taglia', opzione: 'XL'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoWoo(
        id: 2,
        nome: 'Jeans Casual',
        sku: 'JEANS-002',
        prezzoNormale: 45.0,
        prezzoScontato: null,
        descrizioneBreve: 'Jeans casual in denim di alta qualità.',
        immagineUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&h=400&fit=crop',
        categoria: 'Abbigliamento',
        inStock: true,
        varianti: [
          VarianteWoo(
            id: 201,
            nome: 'Blu Scuro - 32',
            sku: 'JEANS-002-BS32',
            prezzo: 45.0,
            quantita: 7,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Blu Scuro', valore: '#1A237E'),
              AttributoVariante(nome: 'Taglia', opzione: '32'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=300&h=300&fit=crop',
          ),
          VarianteWoo(
            id: 202,
            nome: 'Blu Scuro - 34',
            sku: 'JEANS-002-BS34',
            prezzo: 45.0,
            quantita: 12,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Blu Scuro', valore: '#1A237E'),
              AttributoVariante(nome: 'Taglia', opzione: '34'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoWoo(
        id: 3,
        nome: 'Sneakers Sportive',
        sku: 'SNEAKERS-003',
        prezzoNormale: 89.99,
        prezzoScontato: 69.99,
        descrizioneBreve: 'Sneakers sportive per il tempo libero e lo sport.',
        immagineUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop',
        categoria: 'Calzature',
        inStock: true,
        varianti: [
          VarianteWoo(
            id: 301,
            nome: 'Bianco - 42',
            sku: 'SNEAKERS-003-W42',
            prezzo: 69.99,
            quantita: 15,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Bianco', valore: '#FAFAFA'),
              AttributoVariante(nome: 'Numero', opzione: '42'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=300&h=300&fit=crop',
          ),
          VarianteWoo(
            id: 302,
            nome: 'Nero - 43',
            sku: 'SNEAKERS-003-B43',
            prezzo: 69.99,
            quantita: 8,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Nero', valore: '#212121'),
              AttributoVariante(nome: 'Numero', opzione: '43'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=300&h=300&fit=crop',
          ),
          VarianteWoo(
            id: 303,
            nome: 'Rosso - 41',
            sku: 'SNEAKERS-003-R41',
            prezzo: 69.99,
            quantita: 6,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Rosso', valore: '#D50000'),
              AttributoVariante(nome: 'Numero', opzione: '41'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1584735175315-9d5df23860e6?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoWoo(
        id: 4,
        nome: 'Giacca Invernale',
        sku: 'JACKET-004',
        prezzoNormale: 120.0,
        prezzoScontato: null,
        descrizioneBreve: 'Giacca invernale impermeabile e calda.',
        immagineUrl: 'https://images.unsplash.com/photo-1544966503-7cc5ac882d4a?w=400&h=400&fit=crop',
        categoria: 'Abbigliamento',
        inStock: true,
        varianti: [
          VarianteWoo(
            id: 401,
            nome: 'Nero - M',
            sku: 'JACKET-004-BM',
            prezzo: 120.0,
            quantita: 4,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Nero', valore: '#212121'),
              AttributoVariante(nome: 'Taglia', opzione: 'M'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1544966503-7cc5ac882d4a?w=300&h=300&fit=crop',
          ),
          VarianteWoo(
            id: 402,
            nome: 'Grigio - L',
            sku: 'JACKET-004-GL',
            prezzo: 120.0,
            quantita: 2,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Grigio', valore: '#616161'),
              AttributoVariante(nome: 'Taglia', opzione: 'L'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoWoo(
        id: 5,
        nome: 'Cappello Baseball',
        sku: 'HAT-005',
        prezzoNormale: 25.0,
        prezzoScontato: null,
        descrizioneBreve: 'Cappello da baseball classico, regolabile.',
        immagineUrl: 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=400&h=400&fit=crop',
        categoria: 'Accessori',
        inStock: true,
        varianti: [
          VarianteWoo(
            id: 501,
            nome: 'Nero - Unica',
            sku: 'HAT-005-BU',
            prezzo: 25.0,
            quantita: 20,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Nero', valore: '#212121'),
              AttributoVariante(nome: 'Taglia', opzione: 'Unica'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=300&h=300&fit=crop',
          ),
          VarianteWoo(
            id: 502,
            nome: 'Blu - Unica',
            sku: 'HAT-005-BLU',
            prezzo: 25.0,
            quantita: 15,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Blu', valore: '#0D47A1'),
              AttributoVariante(nome: 'Taglia', opzione: 'Unica'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1521369909029-2afed882baee?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoWoo(
        id: 6,
        nome: 'Zaino Urbano',
        sku: 'BACKPACK-006',
        prezzoNormale: 55.0,
        prezzoScontato: 39.99,
        descrizioneBreve: 'Zaino urbano con scomparto per laptop.',
        immagineUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=400&fit=crop',
        categoria: 'Accessori',
        inStock: true,
        varianti: [
          VarianteWoo(
            id: 601,
            nome: 'Nero - Standard',
            sku: 'BACKPACK-006-BS',
            prezzo: 39.99,
            quantita: 12,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Nero', valore: '#212121'),
              AttributoVariante(nome: 'Modello', opzione: 'Standard'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=300&h=300&fit=crop',
          ),
          VarianteWoo(
            id: 602,
            nome: 'Grigio - Standard',
            sku: 'BACKPACK-006-GS',
            prezzo: 39.99,
            quantita: 8,
            attributi: [
              AttributoVariante(nome: 'Colore', opzione: 'Grigio', valore: '#757575'),
              AttributoVariante(nome: 'Modello', opzione: 'Standard'),
            ],
            immagineUrl: 'https://images.unsplash.com/photo-1582256808874-ac4c1ba8fe84?w=300&h=300&fit=crop',
          ),
        ],
      ),
    ];
  }
  Future<bool> aggiornaProdotto(ProdottoWoo prodotto) async {
    return true;
  }
  Future<bool> eliminaProdotto(int prodottoId) async {
    return true;
  }
}
class PrezzoFormatter {
  static String formatPrezzo(double prezzo) {
    return '€${prezzo.toStringAsFixed(2)}';
  }
  static String formatPrezzoConSconto(double prezzoNormale, double? prezzoScontato) {
    if (prezzoScontato != null) {
      return '${formatPrezzo(prezzoScontato)} (era ${formatPrezzo(prezzoNormale)})';
    }
    return formatPrezzo(prezzoNormale);
  }
}
class ProdottoUtils {
  static String getDisponibilitaText(bool inStock) {
    return inStock ? 'Disponibile' : 'Esaurito';
  }
  static String getVariantiCountText(int count) {
    return count == 1 ? '1 variante' : '$count varianti';
  }
  static String getVariantiCountShort(int count) {
    return '$count var.';
  }
}
class ProdottoDisplayInfo {
  final String id;
  final String nome;
  final String sku;
  final String categoria;
  final String prezzo;
  final String disponibilita;
  final String variantiCount;
  final bool inStock;
  final bool hasSconto;
  ProdottoDisplayInfo({
    required this.id,
    required this.nome,
    required this.sku,
    required this.categoria,
    required this.prezzo,
    required this.disponibilita,
    required this.variantiCount,
    required this.inStock,
    required this.hasSconto,
  });
  factory ProdottoDisplayInfo.fromProdotto(ProdottoWoo prodotto) {
    return ProdottoDisplayInfo(
      id: prodotto.id.toString(),
      nome: prodotto.nome,
      sku: prodotto.sku,
      categoria: prodotto.categoria,
      prezzo: PrezzoFormatter.formatPrezzoConSconto(
        prodotto.prezzoNormale,
        prodotto.prezzoScontato,
      ),
      disponibilita: ProdottoUtils.getDisponibilitaText(prodotto.inStock),
      variantiCount: ProdottoUtils.getVariantiCountText(prodotto.varianti.length),
      inStock: prodotto.inStock,
      hasSconto: prodotto.prezzoScontato != null,
    );
  }
}