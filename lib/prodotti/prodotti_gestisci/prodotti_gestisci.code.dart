// prodotti_gestisci.code.dart

import '../class_prodotti.dart';
import '../../login/jwt_api/adapter/platform_manager.dart';
import '../../log_viewer/app_logger.dart';

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
  List<ProdottoGlobal> _prodotti = [];
  List<ProdottoGlobal> _prodottiFiltrati = [];
  ProdottoGlobal? _prodottoSelezionato;
  VarianteProductGlobal? _varianteSelezionata;
  String _filtroRicerca = '';
  OrdinamentoProdotti _ordinamentoCorrente = OrdinamentoProdotti.nessuno;

  final Map<String, String> _filtriVariantiAttivi = {};
  List<VarianteProductGlobal> _variantiFiltrate = [];

  // --- NUOVO: STATO PER IL FILTRO DISPONIBILITÀ ---
  /// Se true, mostra solo le varianti con quantità > 0.
  bool _filtraSoloInStock = false;
  // --- FINE NOVITÀ ---

  // Getters
  List<ProdottoGlobal> get prodotti => _prodottiFiltrati;
  ProdottoGlobal? get prodottoSelezionato => _prodottoSelezionato;
  VarianteProductGlobal? get varianteSelezionata => _varianteSelezionata;
  String get filtroRicerca => _filtroRicerca;
  OrdinamentoProdotti get ordinamentoCorrente => _ordinamentoCorrente;
  List<VarianteProductGlobal> get variantiFiltrate => _variantiFiltrate;
  bool get hasFiltriVariantiAttivi => _filtriVariantiAttivi.isNotEmpty;
  Map<String, String> get filtriVariantiAttivi =>
      Map.unmodifiable(_filtriVariantiAttivi);

  // --- NUOVO: GETTER PER IL NUOVO FILTRO ---
  bool get filtraSoloInStock => _filtraSoloInStock;
  // --- FINE NOVITÀ ---

  int get numeroProdotti => _prodottiFiltrati.length;
  bool get hasProdottoSelezionato => _prodottoSelezionato != null;
  bool get hasVarianteSelezionata => _varianteSelezionata != null;
  bool get hasFiltroAttivo => _filtroRicerca.isNotEmpty;

  Future<void> selezionaProdotto(ProdottoGlobal prodotto) async {
    _prodottoSelezionato = prodotto;
    _varianteSelezionata = null;
    _filtraSoloInStock =
        false; // MODIFICATO: Mostra tutte le varianti di default
    cancellaFiltriVarianti();

    // Carica le varianti se il prodotto ne ha
    await _caricaVariantiProdotto(prodotto);
  }

  /// Carica le varianti per tutti i prodotti che ne hanno
  Future<void> _caricaVariantiTuttiProdotti() async {
    try {
      log.i('🔄 Caricamento varianti per tutti i prodotti...');

      for (int i = 0; i < _prodotti.length; i++) {
        final prodotto = _prodotti[i];

        final shouldFetchVariations =
            (prodotto.variations?.isNotEmpty ?? false) ||
            (prodotto.attributi?.isNotEmpty ?? false);

        if (shouldFetchVariations) {
          try {
            log.i(
              '📋 Caricamento varianti per: ${prodotto.nome} (ID: ${prodotto.id})',
            );

            // Carica le varianti complete da WooCommerce
            log.i(
              '🔍 DEBUG - Caricamento varianti per prodotto ${prodotto.id} con ${prodotto.attributi?.length ?? 0} attributi',
            );
            if (prodotto.attributi != null) {
              for (final attr in prodotto.attributi!) {
                log.i('🔍 DEBUG - Attributo prodotto: ${attr.toString()}');
              }
            }
            final variantiComplete = await PlatformManager.varianti
                .getProductVariations(
                  prodotto.id!,
                  attributiProdotto: prodotto.attributi,
                );
            log.i(
              '✅ Caricate ${variantiComplete.length} varianti per ${prodotto.nome}',
            );

            // Aggiorna il prodotto con le varianti caricate
            _prodotti[i] = prodotto.copyWith(varianti: variantiComplete);
          } catch (e) {
            log.e('❌ Errore caricamento varianti per ${prodotto.nome}', e);
          }
        }
      }

      log.i('✅ Completato caricamento varianti per tutti i prodotti');
    } catch (e) {
      log.e('❌ Errore generale caricamento varianti prodotti', e);
    }
  }

  /// Carica le varianti di un prodotto da WooCommerce
  Future<void> _caricaVariantiProdotto(ProdottoGlobal prodotto) async {
    try {
      log.i(
        '🔍 Caricamento varianti per prodotto: ${prodotto.nome} (ID: ${prodotto.id})',
      );

      // Carica sempre le varianti dal server per il prodotto selezionato:
      // alcuni prodotti appena creati non espongono subito gli ID variations.
      {
        log.i(
          '📋 Verifica varianti per prodotto ${prodotto.id} (variations=${prodotto.variations})',
        );

        // Carica le varianti complete da WooCommerce
        log.i(
          '🔍 DEBUG - Caricamento varianti per prodotto ${prodotto.id} con ${prodotto.attributi?.length ?? 0} attributi',
        );
        if (prodotto.attributi != null) {
          for (final attr in prodotto.attributi!) {
            log.i('🔍 DEBUG - Attributo prodotto: ${attr.toString()}');
          }
        }
        final variantiComplete = await PlatformManager.varianti
            .getProductVariations(
              prodotto.id!,
              attributiProdotto: prodotto.attributi,
            );
        log.i('✅ Caricate ${variantiComplete.length} varianti complete');

        // Aggiorna il prodotto con le varianti caricate
        _prodottoSelezionato = prodotto.copyWith(varianti: variantiComplete);

        // Applica i filtri varianti per popolare la lista
        _applicaFiltriVarianti();

        log.i('📊 Varianti filtrate: ${_variantiFiltrate.length}');
        for (final variante in _variantiFiltrate) {
          log.i(
            '   - ${variante.nome}: ${variante.quantita} pezzi, €${variante.prezzo}',
          );
        }
      }
    } catch (e) {
      log.e('❌ Errore caricamento varianti per prodotto ${prodotto.id}', e);
      // In caso di errore, applica comunque i filtri
      _applicaFiltriVarianti();
    }
  }

  void selezionaVariante(VarianteProductGlobal? variante) {
    _varianteSelezionata = variante;
  }

  bool isProdottoSelezionato(ProdottoGlobal prodotto) {
    return _prodottoSelezionato?.id == prodotto.id;
  }

  bool isVarianteSelezionata(VarianteProductGlobal variante) {
    return _varianteSelezionata?.id == variante.id;
  }

  String getCurrentImageUrl() {
    if (_varianteSelezionata?.immagineUrl != null &&
        _varianteSelezionata!.immagineUrl!.isNotEmpty) {
      return _varianteSelezionata!.immagineUrl!;
    }
    return _prodottoSelezionato?.immagineUrl ?? '';
  }

  void setFiltroRicerca(String filtro) {
    _filtroRicerca = filtro.toLowerCase();
    _applicaFiltroEOrdinamento();
  }

  void cancellaFiltro() {
    _filtroRicerca = '';
    _applicaFiltroEOrdinamento();
  }

  void setOrdinamento(OrdinamentoProdotti nuovoOrdinamento) {
    _ordinamentoCorrente = nuovoOrdinamento;
    _applicaFiltroEOrdinamento();
  }

  Map<String, List<AttributoVariante>> getOpzioniFiltroDisponibili() {
    if (_prodottoSelezionato == null) return {};

    final opzioniUniche = <String, Map<String, AttributoVariante>>{};

    for (final variante in _prodottoSelezionato!.varianti ?? []) {
      for (final attributo in variante.attributi) {
        opzioniUniche[attributo.nome] ??= {};
        opzioniUniche[attributo.nome]![attributo.opzione] = attributo;
      }
    }

    final risultato = <String, List<AttributoVariante>>{};
    opzioniUniche.forEach((nomeAttributo, mappaOpzioni) {
      risultato[nomeAttributo] = mappaOpzioni.values.toList();
    });

    return risultato;
  }

  void setFiltroVariante(String nomeAttributo, String opzione) {
    if (_filtriVariantiAttivi[nomeAttributo] == opzione) {
      _filtriVariantiAttivi.remove(nomeAttributo);
    } else {
      _filtriVariantiAttivi[nomeAttributo] = opzione;
    }
    _applicaFiltriVarianti();
  }

  void cancellaFiltriVarianti() {
    _filtriVariantiAttivi.clear();
    _applicaFiltriVarianti();
  }

  bool isFiltroVarianteSelezionato(String nomeAttributo, String opzione) {
    return _filtriVariantiAttivi[nomeAttributo] == opzione;
  }

  // --- NUOVO: METODO PER GESTIRE LA CHECKBOX ---
  /// Aggiorna lo stato del filtro di disponibilità e riapplica tutti i filtri.
  void setFiltraSoloInStock(bool mostraSoloDisponibili) {
    _filtraSoloInStock = mostraSoloDisponibili;
    _applicaFiltriVarianti();
  }
  // --- FINE NOVITÀ ---

  /// Filtra la lista delle varianti in base a TUTTI i filtri attivi (attributi + disponibilità).
  void _applicaFiltriVarianti() {
    if (_prodottoSelezionato == null) {
      _variantiFiltrate = [];
      return;
    }

    var variantiTemp = List<VarianteProductGlobal>.from(
      _prodottoSelezionato!.varianti ?? [],
    );
    log.i('🔍 Prodotto: ${_prodottoSelezionato!.nome}');
    log.i('📊 Varianti originali: ${variantiTemp.length}');
    log.i(
      '📦 Quantità varianti: ${variantiTemp.map((v) => '${v.nome}: ${v.quantita}').join(', ')}',
    );

    // 1. Applica i filtri per attributo (Colore, Taglia, etc.)
    if (_filtriVariantiAttivi.isNotEmpty) {
      _filtriVariantiAttivi.forEach((nomeFiltro, opzioneFiltro) {
        variantiTemp = variantiTemp.where((variante) {
          return variante.attributi.any(
            (attr) => attr.nome == nomeFiltro && attr.opzione == opzioneFiltro,
          );
        }).toList();
      });
    }

    // --- MODIFICA: Applica il filtro di disponibilità DOPO gli altri filtri ---
    // 2. Applica il filtro per disponibilità
    if (_filtraSoloInStock) {
      variantiTemp = variantiTemp.where((v) => v.quantita > 0).toList();
    }
    // --- FINE MODIFICA ---

    _variantiFiltrate = variantiTemp;
    log.i('✅ Varianti finali mostrate: ${_variantiFiltrate.length}');

    if (_varianteSelezionata != null &&
        !_variantiFiltrate.contains(_varianteSelezionata)) {
      _varianteSelezionata = null;
    }
  }

  /// Applica il filtro di ricerca e l'ordinamento alla lista dei prodotti
  void _applicaFiltroEOrdinamento() {
    // 1. Applica il filtro
    if (_filtroRicerca.isEmpty) {
      _prodottiFiltrati = List.from(_prodotti);
    } else {
      _prodottiFiltrati = _prodotti.where((prodotto) {
        return (prodotto.nome?.toLowerCase().contains(_filtroRicerca) ??
                false) ||
            (prodotto.sku?.toLowerCase().contains(_filtroRicerca) ?? false) ||
            (prodotto.categoria
                    ?.map((c) => c.nome.toLowerCase())
                    .join(' ')
                    .contains(_filtroRicerca) ??
                false) ||
            (prodotto.descrizioneBreve?.toLowerCase().contains(
                  _filtroRicerca,
                ) ??
                false) ||
            (prodotto.varianti?.any(
                  (variante) =>
                      variante.nomeVisualizzabile.toLowerCase().contains(
                        _filtroRicerca,
                      ) ||
                      variante.sku.toLowerCase().contains(_filtroRicerca),
                ) ??
                false);
      }).toList();
    }

    // 2. Applica l'ordinamento
    switch (_ordinamentoCorrente) {
      case OrdinamentoProdotti.nomeCrescente:
        _prodottiFiltrati.sort(
          (a, b) => (a.nome?.toLowerCase() ?? '').compareTo(
            b.nome?.toLowerCase() ?? '',
          ),
        );
        break;
      case OrdinamentoProdotti.nomeDecrescente:
        _prodottiFiltrati.sort(
          (a, b) => (b.nome?.toLowerCase() ?? '').compareTo(
            a.nome?.toLowerCase() ?? '',
          ),
        );
        break;
      case OrdinamentoProdotti.prezzoCrescente:
        _prodottiFiltrati.sort(
          (a, b) => (a.prezzoScontato ?? a.prezzoNormale ?? 0).compareTo(
            b.prezzoScontato ?? b.prezzoNormale ?? 0,
          ),
        );
        break;
      case OrdinamentoProdotti.prezzoDecrescente:
        _prodottiFiltrati.sort(
          (a, b) => (b.prezzoScontato ?? b.prezzoNormale ?? 0).compareTo(
            a.prezzoScontato ?? a.prezzoNormale ?? 0,
          ),
        );
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

  /// Carica i prodotti usando PlatformManager (modello globale)
  Future<void> caricaProdotti({bool forceTest = false}) async {
    try {
      if (forceTest) {
        log.i('🧪 Forzato caricamento prodotti di test');
        _prodotti = prodottiTest();
        log.i('✅ Caricati ${_prodotti.length} prodotti di test');
        _applicaFiltroEOrdinamento();
        return;
      }

      log.i('📦 Caricamento prodotti da WooCommerce...');

      // Prima prova a caricare da WooCommerce
      try {
        _prodotti = await PlatformManager.prodotti.getProducts(
          page: 1,
          perPage: 100,
          includeAllStatus: true, // Include bozze e prodotti privati
        );
        log.i('✅ Caricati ${_prodotti.length} prodotti da WooCommerce');

        // Carica le varianti per tutti i prodotti che ne hanno
        await _caricaVariantiTuttiProdotti();
      } catch (e) {
        log.w('⚠️ Errore caricamento da WooCommerce, uso dati di test', e);
        // In caso di errore, usa dati di test
        _prodotti = prodottiTest();
        log.i('✅ Usati ${_prodotti.length} prodotti di test');
      }

      // Se non ci sono prodotti, aggiungi dati di test
      if (_prodotti.isEmpty) {
        log.w('⚠️ Nessun prodotto trovato, aggiungo dati di test');
        _prodotti = prodottiTest();
        log.i('✅ Aggiunti ${_prodotti.length} prodotti di test');
      }

      _applicaFiltroEOrdinamento();
    } catch (e) {
      log.e('❌ Errore generale caricamento prodotti', e);
      log.e('   Dettagli errore: ${e.toString()}');
      // In caso di errore generale, usa dati di test
      _prodotti = prodottiTest();
      _applicaFiltroEOrdinamento();
    }
  }

  // --- DATI DI TEST (Commentati - usati solo per sviluppo/debug) ---
  /// Prodotti di test per sviluppo e debug
  /// Decommentare la chiamata in caricaProdotti() per usarli in caso di errore
  List<ProdottoGlobal> prodottiTest() {
    return [
      ProdottoGlobal(
        id: 1,
        nome: 'Maglietta T-Shirt',
        sku: 'TSHIRT-001',
        prezzoNormale: 20.0,
        prezzoScontato: 15.0,
        descrizioneBreve:
            'Maglietta in cotone 100%, disponibile in vari colori.',
        immagineUrl:
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop',
        categoria: [
          CategoriaProdotto(
            id: 1,
            nome: 'Abbigliamento',
            slug: 'abbigliamento',
          ),
        ],
        inStock: true,
        varianti: [
          VarianteProductGlobal(
            id: 101,
            nome: 'Rosso - M',
            sku: 'TSHIRT-001-RM',
            prezzo: 15.0,
            quantita: 10,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Rosso',
                valore: '#B71C1C',
              ),
              AttributoVariante(nome: 'Taglia', opzione: 'M'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=300&h=300&fit=crop',
          ),
          VarianteProductGlobal(
            id: 102,
            nome: 'Blu - L',
            sku: 'TSHIRT-001-BL',
            prezzo: 15.0,
            quantita: 5,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Blu',
                valore: '#0D47A1',
              ),
              AttributoVariante(nome: 'Taglia', opzione: 'L'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=300&h=300&fit=crop',
          ),
          VarianteProductGlobal(
            id: 103,
            nome: 'Verde - S',
            sku: 'TSHIRT-001-GS',
            prezzo: 15.0,
            quantita: 8,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Verde',
                valore: '#1B5E20',
              ),
              AttributoVariante(nome: 'Taglia', opzione: 'S'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=300&h=300&fit=crop',
          ),
          VarianteProductGlobal(
            id: 104,
            nome: 'Nero - XL',
            sku: 'TSHIRT-001-NXL',
            prezzo: 15.0,
            quantita: 0,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Nero',
                valore: '#212121',
              ),
              AttributoVariante(nome: 'Taglia', opzione: 'XL'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoGlobal(
        id: 2,
        nome: 'Jeans Casual',
        sku: 'JEANS-002',
        prezzoNormale: 45.0,
        prezzoScontato: null,
        descrizioneBreve: 'Jeans casual in denim di alta qualità.',
        immagineUrl:
            'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&h=400&fit=crop',
        categoria: [
          CategoriaProdotto(
            id: 1,
            nome: 'Abbigliamento',
            slug: 'abbigliamento',
          ),
        ],
        inStock: true,
        varianti: [
          VarianteProductGlobal(
            id: 201,
            nome: 'Blu Scuro - 32',
            sku: 'JEANS-002-BS32',
            prezzo: 45.0,
            quantita: 7,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Blu Scuro',
                valore: '#1A237E',
              ),
              AttributoVariante(nome: 'Taglia', opzione: '32'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1542272604-787c3835535d?w=300&h=300&fit=crop',
          ),
          VarianteProductGlobal(
            id: 202,
            nome: 'Blu Scuro - 34',
            sku: 'JEANS-002-BS34',
            prezzo: 45.0,
            quantita: 12,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Blu Scuro',
                valore: '#1A237E',
              ),
              AttributoVariante(nome: 'Taglia', opzione: '34'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoGlobal(
        id: 3,
        nome: 'Sneakers Sportive',
        sku: 'SNEAKERS-003',
        prezzoNormale: 89.99,
        prezzoScontato: 69.99,
        descrizioneBreve: 'Sneakers sportive per il tempo libero e lo sport.',
        immagineUrl:
            'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop',
        categoria: [
          CategoriaProdotto(id: 2, nome: 'Calzature', slug: 'calzature'),
        ],
        inStock: true,
        varianti: [
          VarianteProductGlobal(
            id: 301,
            nome: 'Bianco - 42',
            sku: 'SNEAKERS-003-W42',
            prezzo: 69.99,
            quantita: 15,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Bianco',
                valore: '#FAFAFA',
              ),
              AttributoVariante(nome: 'Numero', opzione: '42'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=300&h=300&fit=crop',
          ),
          VarianteProductGlobal(
            id: 302,
            nome: 'Nero - 43',
            sku: 'SNEAKERS-003-B43',
            prezzo: 69.99,
            quantita: 8,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Nero',
                valore: '#212121',
              ),
              AttributoVariante(nome: 'Numero', opzione: '43'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=300&h=300&fit=crop',
          ),
          VarianteProductGlobal(
            id: 303,
            nome: 'Rosso - 41',
            sku: 'SNEAKERS-003-R41',
            prezzo: 69.99,
            quantita: 6,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Rosso',
                valore: '#D50000',
              ),
              AttributoVariante(nome: 'Numero', opzione: '41'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1584735175315-9d5df23860e6?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoGlobal(
        id: 4,
        nome: 'Giacca Invernale',
        sku: 'JACKET-004',
        prezzoNormale: 120.0,
        prezzoScontato: null,
        descrizioneBreve: 'Giacca invernale impermeabile e calda.',
        immagineUrl:
            'https://images.unsplash.com/photo-1544966503-7cc5ac882d4a?w=400&h=400&fit=crop',
        categoria: [
          CategoriaProdotto(
            id: 1,
            nome: 'Abbigliamento',
            slug: 'abbigliamento',
          ),
        ],
        inStock: true,
        varianti: [
          VarianteProductGlobal(
            id: 401,
            nome: 'Nero - M',
            sku: 'JACKET-004-BM',
            prezzo: 120.0,
            quantita: 4,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Nero',
                valore: '#212121',
              ),
              AttributoVariante(nome: 'Taglia', opzione: 'M'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1544966503-7cc5ac882d4a?w=300&h=300&fit=crop',
          ),
          VarianteProductGlobal(
            id: 402,
            nome: 'Grigio - L',
            sku: 'JACKET-004-GL',
            prezzo: 120.0,
            quantita: 2,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Grigio',
                valore: '#616161',
              ),
              AttributoVariante(nome: 'Taglia', opzione: 'L'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoGlobal(
        id: 5,
        nome: 'Cappello Baseball',
        sku: 'HAT-005',
        prezzoNormale: 25.0,
        prezzoScontato: null,
        descrizioneBreve: 'Cappello da baseball classico, regolabile.',
        immagineUrl:
            'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=400&h=400&fit=crop',
        categoria: [
          CategoriaProdotto(id: 3, nome: 'Accessori', slug: 'accessori'),
        ],
        inStock: true,
        varianti: [
          VarianteProductGlobal(
            id: 501,
            nome: 'Nero - Unica',
            sku: 'HAT-005-BU',
            prezzo: 25.0,
            quantita: 20,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Nero',
                valore: '#212121',
              ),
              AttributoVariante(nome: 'Taglia', opzione: 'Unica'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=300&h=300&fit=crop',
          ),
          VarianteProductGlobal(
            id: 502,
            nome: 'Blu - Unica',
            sku: 'HAT-005-BLU',
            prezzo: 25.0,
            quantita: 15,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Blu',
                valore: '#0D47A1',
              ),
              AttributoVariante(nome: 'Taglia', opzione: 'Unica'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1521369909029-2afed882baee?w=300&h=300&fit=crop',
          ),
        ],
      ),
      ProdottoGlobal(
        id: 6,
        nome: 'Zaino Urbano',
        sku: 'BACKPACK-006',
        prezzoNormale: 55.0,
        prezzoScontato: 39.99,
        descrizioneBreve: 'Zaino urbano con scomparto per laptop.',
        immagineUrl:
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=400&fit=crop',
        categoria: [
          CategoriaProdotto(id: 3, nome: 'Accessori', slug: 'accessori'),
        ],
        inStock: true,
        varianti: [
          VarianteProductGlobal(
            id: 601,
            nome: 'Nero - Standard',
            sku: 'BACKPACK-006-BS',
            prezzo: 39.99,
            quantita: 12,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Nero',
                valore: '#212121',
              ),
              AttributoVariante(nome: 'Modello', opzione: 'Standard'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=300&h=300&fit=crop',
          ),
          VarianteProductGlobal(
            id: 602,
            nome: 'Grigio - Standard',
            sku: 'BACKPACK-006-GS',
            prezzo: 39.99,
            quantita: 8,
            attributi: [
              AttributoVariante(
                nome: 'Colore',
                opzione: 'Grigio',
                valore: '#757575',
              ),
              AttributoVariante(nome: 'Modello', opzione: 'Standard'),
            ],
            immagineUrl:
                'https://images.unsplash.com/photo-1582256808874-ac4c1ba8fe84?w=300&h=300&fit=crop',
          ),
        ],
      ),
    ];
  }

  Future<bool> aggiornaProdotto(ProdottoGlobal prodotto) async {
    return true;
  }

  Future<bool> eliminaProdotto(int prodottoId) async {
    try {
      log.i('🗑️ Eliminazione prodotto $prodottoId...');

      final deleted = await PlatformManager.prodotti.deleteProduct(
        prodottoId,
        force: true,
      );
      if (!deleted) {
        log.w('⚠️ Eliminazione non confermata per prodotto $prodottoId');
        return false;
      }

      _prodotti.removeWhere((p) => p.id == prodottoId);
      _prodottiFiltrati.removeWhere((p) => p.id == prodottoId);

      if (_prodottoSelezionato?.id == prodottoId) {
        _prodottoSelezionato = null;
        _varianteSelezionata = null;
        _variantiFiltrate = [];
        _filtriVariantiAttivi.clear();
        _filtraSoloInStock = false;
      }

      _applicaFiltroEOrdinamento();
      log.i('✅ Prodotto $prodottoId eliminato e lista aggiornata');
      return true;
    } catch (e) {
      log.e('❌ Errore eliminazione prodotto $prodottoId', e);
      return false;
    }
  }

  /// Rettifica lo stock di un prodotto semplice
  Future<bool> rettificaStockProdotto({
    required int prodottoId,
    required int nuovaQuantita,
    String? motivo,
  }) async {
    try {
      log.i(
        '📦 Rettifica stock prodotto $prodottoId: $nuovaQuantita (motivo: $motivo)',
      );

      await PlatformManager.prodotti.updateProductStock(
        prodottoId,
        stockQuantity: nuovaQuantita,
        stockStatus: nuovaQuantita > 0 ? 'instock' : 'outofstock',
      );

      // Aggiorna il prodotto locale
      final index = _prodotti.indexWhere((p) => p.id == prodottoId);
      if (index >= 0) {
        _prodotti[index] = _prodotti[index].copyWith(
          quantitaTotale: nuovaQuantita,
          inStock: nuovaQuantita > 0,
        );
        _applicaFiltroEOrdinamento();

        // Aggiorna anche il prodotto selezionato se è lo stesso
        if (_prodottoSelezionato?.id == prodottoId) {
          _prodottoSelezionato = _prodotti[index];
        }
      }

      log.i('✅ Stock prodotto $prodottoId aggiornato a $nuovaQuantita');
      return true;
    } catch (e) {
      log.e('❌ Errore rettifica stock prodotto $prodottoId', e);
      return false;
    }
  }

  /// Rettifica lo stock di una variante
  Future<bool> rettificaStockVariante({
    required int prodottoId,
    required int varianteId,
    required int nuovaQuantita,
    String? motivo,
  }) async {
    try {
      log.i(
        '📦 Rettifica stock variante $varianteId (prodotto $prodottoId): $nuovaQuantita (motivo: $motivo)',
      );

      await PlatformManager.varianti.updateVariationStock(
        productId: prodottoId,
        variationId: varianteId,
        stockQuantity: nuovaQuantita,
        stockStatus: nuovaQuantita > 0 ? 'instock' : 'outofstock',
      );

      // Aggiorna la variante locale
      final prodottoIndex = _prodotti.indexWhere((p) => p.id == prodottoId);
      if (prodottoIndex >= 0) {
        final varianti = _prodotti[prodottoIndex].varianti;
        if (varianti != null) {
          final varianteIndex = varianti.indexWhere((v) => v.id == varianteId);
          if (varianteIndex >= 0) {
            final varianteAggiornata = varianti[varianteIndex].copyWith(
              quantita: nuovaQuantita,
              attiva: nuovaQuantita > 0,
            );
            varianti[varianteIndex] = varianteAggiornata;

            // Aggiorna la variante selezionata se è la stessa
            if (_varianteSelezionata?.id == varianteId) {
              _varianteSelezionata = varianteAggiornata;
            }
          }
        }

        // Aggiorna anche il prodotto selezionato
        if (_prodottoSelezionato?.id == prodottoId) {
          _prodottoSelezionato = _prodotti[prodottoIndex];
          _applicaFiltriVarianti();
        }
      }

      log.i('✅ Stock variante $varianteId aggiornato a $nuovaQuantita');
      return true;
    } catch (e) {
      log.e('❌ Errore rettifica stock variante $varianteId', e);
      return false;
    }
  }
}

class PrezzoFormatter {
  static String formatPrezzo(double prezzo) {
    return '€${prezzo.toStringAsFixed(2)}';
  }

  static String formatPrezzoConSconto(
    double prezzoNormale,
    double? prezzoScontato,
  ) {
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
  factory ProdottoDisplayInfo.fromProdotto(ProdottoGlobal prodotto) {
    return ProdottoDisplayInfo(
      id: prodotto.id?.toString() ?? '',
      nome: prodotto.nome ?? '',
      sku: prodotto.sku ?? '',
      categoria: prodotto.categoria?.map((c) => c.nome).join(', ') ?? '',
      prezzo: PrezzoFormatter.formatPrezzoConSconto(
        prodotto.prezzoNormale ?? 0,
        prodotto.prezzoScontato,
      ),
      disponibilita: ProdottoUtils.getDisponibilitaText(prodotto.inStock),
      variantiCount: ProdottoUtils.getVariantiCountText(
        prodotto.varianti?.length ?? 0,
      ),
      inStock: prodotto.inStock,
      hasSconto: prodotto.prezzoScontato != null,
    );
  }
}
