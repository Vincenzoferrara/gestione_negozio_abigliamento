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
  final Set<int> _selectedProductIds = <int>{};
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
  Set<int> get selectedProductIds => Set.unmodifiable(_selectedProductIds);
  int get selectedProductsCount => _selectedProductIds.length;
  bool get hasSelectedProducts => _selectedProductIds.isNotEmpty;

  bool isProductSelectedForBulk(ProdottoGlobal prodotto) {
    final id = prodotto.id;
    return id != null && _selectedProductIds.contains(id);
  }

  void toggleProductBulkSelection(ProdottoGlobal prodotto) {
    final id = prodotto.id;
    if (id == null || id <= 0) return;
    if (_selectedProductIds.contains(id)) {
      _selectedProductIds.remove(id);
    } else {
      _selectedProductIds.add(id);
    }
  }

  void clearBulkSelection() {
    _selectedProductIds.clear();
  }

  void selectAllFilteredProducts() {
    for (final prodotto in _prodottiFiltrati) {
      final id = prodotto.id;
      if (id != null && id > 0) {
        _selectedProductIds.add(id);
      }
    }
  }

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
      _selectedProductIds.remove(prodottoId);

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

  Future<BulkCategoryUpdateResult> bulkUpdateSelectedProductCategories({
    required List<CategoriaProdotto> categorie,
    bool replaceExisting = false,
  }) async {
    if (_selectedProductIds.isEmpty) {
      return BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessun prodotto selezionato.',
      );
    }

    final selectedProducts = _prodotti.where(
      (p) => p.id != null && _selectedProductIds.contains(p.id),
    );

    final categoryMap = <int, CategoriaProdotto>{
      for (final c in categorie)
        if (c.id > 0) c.id: c,
    };

    if (categoryMap.isEmpty) {
      return BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: _selectedProductIds.length,
        message: 'Nessuna categoria valida selezionata.',
      );
    }

    try {
      final updates = <Map<String, dynamic>>[];

      for (final prodotto in selectedProducts) {
        final productId = prodotto.id;
        if (productId == null || productId <= 0) continue;

        final merged = <int, CategoriaProdotto>{
          if (!replaceExisting)
            for (final c in (prodotto.categoria ?? const <CategoriaProdotto>[]))
              if (c.id > 0) c.id: c,
          ...categoryMap,
        };

        updates.add({
          'id': productId,
          'categories': merged.keys.map((id) => {'id': id}).toList(),
        });
      }

      if (updates.isEmpty) {
        return BulkCategoryUpdateResult(
          successCount: 0,
          failedCount: _selectedProductIds.length,
          message: 'Nessun prodotto aggiornabile trovato.',
        );
      }

      const chunkSize = 25;
      final successfulProductIds = <int>{};
      final failedProductIds = <int>{};

      for (int i = 0; i < updates.length; i += chunkSize) {
        final chunk = updates.sublist(
          i,
          i + chunkSize > updates.length ? updates.length : i + chunkSize,
        );

        try {
          final response = await PlatformManager.prodotti.batchUpdateProducts(
            update: chunk,
          );

          final expectedIds = chunk
              .map((item) => item['id'])
              .whereType<int>()
              .toSet();

          final updated = response['update'];
          if (updated is List) {
            final updatedIds = updated
                .map((item) => item is Map<String, dynamic> ? item['id'] : null)
                .whereType<int>()
                .toSet();

            successfulProductIds.addAll(updatedIds);

            final missingIds = expectedIds.difference(updatedIds);
            failedProductIds.addAll(missingIds);

            final errors = response['errors'];
            if (errors is List) {
              for (final errorItem in errors) {
                if (errorItem is Map<String, dynamic>) {
                  final errorId = errorItem['id'];
                  if (errorId is int) {
                    failedProductIds.add(errorId);
                  }
                }
              }
            }
          } else {
            successfulProductIds.addAll(expectedIds);
          }
        } catch (e) {
          log.e('❌ Errore chunk batch categorie', e);
          for (final item in chunk) {
            final id = item['id'];
            if (id is int) {
              failedProductIds.add(id);
            }
          }
        }
      }

      final successCount = successfulProductIds.length;
      final failedCount = failedProductIds.length;

      final newCategories = categoryMap.values.toList();
      for (int i = 0; i < _prodotti.length; i++) {
        final id = _prodotti[i].id;
        if (id != null && successfulProductIds.contains(id)) {
          final current = _prodotti[i].categoria ?? const <CategoriaProdotto>[];
          final merged = <int, CategoriaProdotto>{
            if (!replaceExisting)
              for (final c in current)
                if (c.id > 0) c.id: c,
            for (final c in newCategories)
              if (c.id > 0) c.id: c,
          };
          _prodotti[i] = _prodotti[i].copyWith(
            categoria: merged.values.toList(),
          );
        }
      }

      if (_prodottoSelezionato?.id != null &&
          successfulProductIds.contains(_prodottoSelezionato!.id)) {
        final updatedProduct = _prodotti.firstWhere(
          (p) => p.id == _prodottoSelezionato!.id,
          orElse: () => _prodottoSelezionato!,
        );
        _prodottoSelezionato = updatedProduct;
      }

      _applicaFiltroEOrdinamento();

      return BulkCategoryUpdateResult(
        successCount: successCount,
        failedCount: failedCount,
        message:
            failedCount == 0
            ? 'Aggiornamento completato: $successCount prodotti aggiornati.'
            : 'Aggiornamento parziale: $successCount successi, $failedCount falliti.',
      );
    } catch (e) {
      log.e('❌ Errore bulk update categorie', e);
      return BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: _selectedProductIds.length,
        message: 'Errore durante aggiornamento categorie: $e',
      );
    }
  }

  Future<BulkCategoryUpdateResult> updateSelectedProductCategoriesByNames({
    required List<String> categoryNames,
    bool replaceExisting = false,
  }) async {
    final prodotto = _prodottoSelezionato;
    if (prodotto == null || prodotto.id == null || prodotto.id! <= 0) {
      return const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 1,
        message: 'Nessun prodotto selezionato valido.',
      );
    }

    final normalized = categoryNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (normalized.isEmpty) {
      return const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 1,
        message: 'Nessuna categoria selezionata.',
      );
    }

    try {
      final existing = await PlatformManager.categorie.getCategories(perPage: 100);
      final byName = <String, CategoriaProdotto>{
        for (final c in existing) c.nome.toLowerCase(): c,
      };

      final missing = normalized
          .where((name) => !byName.containsKey(name.toLowerCase()))
          .toList();

      if (missing.isNotEmpty) {
        final created = await PlatformManager.categorie.createCategoryIfNotExists(
          missing
              .map(
                (name) => CategoriaProdotto(
                  nome: name,
                  slug: name.toLowerCase().replaceAll(' ', '-'),
                ),
              )
              .toList(),
        );

        for (final c in created) {
          byName[c.nome.toLowerCase()] = c;
        }
      }

      final selectedCategories = normalized
          .map((name) => byName[name.toLowerCase()])
          .whereType<CategoriaProdotto>()
          .where((c) => c.id > 0)
          .toList();

      _selectedProductIds
        ..clear()
        ..add(prodotto.id!);

      return await bulkUpdateSelectedProductCategories(
        categorie: selectedCategories,
        replaceExisting: replaceExisting,
      );
    } catch (e) {
      log.e('❌ Errore aggiornamento categorie da nomi', e);
      return BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 1,
        message: 'Errore aggiornamento categorie: $e',
      );
    }
  }

  Future<List<CategoriaProdotto>> resolveCategoryNames({
    required List<String> categoryNames,
  }) async {
    final normalized = categoryNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (normalized.isEmpty) {
      return const <CategoriaProdotto>[];
    }

    final existing = await PlatformManager.categorie.getCategories(perPage: 100);
    final byName = <String, CategoriaProdotto>{
      for (final c in existing) c.nome.toLowerCase(): c,
    };

    final missing = normalized
        .where((name) => !byName.containsKey(name.toLowerCase()))
        .toList();

    if (missing.isNotEmpty) {
      final created = await PlatformManager.categorie.createCategoryIfNotExists(
        missing
            .map(
              (name) => CategoriaProdotto(
                nome: name,
                slug: name.toLowerCase().replaceAll(' ', '-'),
              ),
            )
            .toList(),
      );
      for (final c in created) {
        byName[c.nome.toLowerCase()] = c;
      }
    }

    return normalized
        .map((name) => byName[name.toLowerCase()])
        .whereType<CategoriaProdotto>()
        .where((c) => c.id > 0)
        .toList();
  }

  Future<List<TagProdotto>> resolveTagNames({
    required List<String> tagNames,
  }) async {
    final normalized = tagNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (normalized.isEmpty) {
      return const <TagProdotto>[];
    }

    final existing = await PlatformManager.tag.getTags(perPage: 100);
    final byName = <String, TagProdotto>{
      for (final t in existing) t.nome.toLowerCase(): t,
    };

    final missing = normalized
        .where((name) => !byName.containsKey(name.toLowerCase()))
        .toList();

    if (missing.isNotEmpty) {
      final created = await PlatformManager.tag.createTagIfNotExists(
        missing
            .map(
              (name) => TagProdotto(
                nome: name,
                slug: name.toLowerCase().replaceAll(' ', '-'),
              ),
            )
            .toList(),
      );
      for (final t in created) {
        byName[t.nome.toLowerCase()] = t;
      }
    }

    return normalized
        .map((name) => byName[name.toLowerCase()])
        .whereType<TagProdotto>()
        .where((t) => t.id > 0)
        .toList();
  }

  Future<BulkCategoryUpdateResult> bulkUpdateSelectedProductTags({
    required List<TagProdotto> tags,
    bool replaceExisting = false,
  }) async {
    if (_selectedProductIds.isEmpty) {
      return const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessun prodotto selezionato.',
      );
    }

    final tagMap = <int, TagProdotto>{
      for (final t in tags)
        if (t.id > 0) t.id: t,
    };
    if (tagMap.isEmpty) {
      return BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: _selectedProductIds.length,
        message: 'Nessun tag valido selezionato.',
      );
    }

    final selectedProducts = _prodotti.where(
      (p) => p.id != null && _selectedProductIds.contains(p.id),
    );
    final updates = <Map<String, dynamic>>[];
    for (final prodotto in selectedProducts) {
      final productId = prodotto.id;
      if (productId == null || productId <= 0) continue;
      final merged = <int, TagProdotto>{
        if (!replaceExisting)
          for (final t in (prodotto.tag ?? const <TagProdotto>[]))
            if (t.id > 0) t.id: t,
        ...tagMap,
      };
      updates.add({
        'id': productId,
        'tags': merged.keys.map((id) => {'id': id}).toList(),
      });
    }

    try {
      final response = await PlatformManager.prodotti.batchUpdateProducts(update: updates);
      final updated = response['update'];
      final updatedIds = <int>{};
      if (updated is List) {
        for (final item in updated) {
          if (item is Map<String, dynamic> && item['id'] is int) {
            updatedIds.add(item['id'] as int);
          }
        }
      }

      for (int i = 0; i < _prodotti.length; i++) {
        final id = _prodotti[i].id;
        if (id != null && updatedIds.contains(id)) {
          final current = _prodotti[i].tag ?? const <TagProdotto>[];
          final merged = <int, TagProdotto>{
            if (!replaceExisting)
              for (final t in current)
                if (t.id > 0) t.id: t,
            for (final t in tagMap.values)
              if (t.id > 0) t.id: t,
          };
          _prodotti[i] = _prodotti[i].copyWith(tag: merged.values.toList());
        }
      }
      _applicaFiltroEOrdinamento();
      return BulkCategoryUpdateResult(
        successCount: updatedIds.length,
        failedCount: _selectedProductIds.length - updatedIds.length,
        message: 'Tag aggiornati su ${updatedIds.length} prodotti.',
      );
    } catch (e) {
      log.e('❌ Errore bulk tag update', e);
      return BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: _selectedProductIds.length,
        message: 'Errore aggiornamento tag: $e',
      );
    }
  }

  Future<BulkCategoryUpdateResult> bulkUpdateSelectedProductsStatus({
    required String status,
  }) async {
    if (_selectedProductIds.isEmpty) {
      return const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessun prodotto selezionato.',
      );
    }

    final normalized = status.trim().toLowerCase();
    const allowed = {'publish', 'private', 'draft'};
    if (!allowed.contains(normalized)) {
      return BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: _selectedProductIds.length,
        message: 'Stato non valido: $status',
      );
    }

    final updates = _selectedProductIds.map((id) => {'id': id, 'status': normalized}).toList();
    try {
      final response = await PlatformManager.prodotti.batchUpdateProducts(update: updates);
      final updated = response['update'];
      final updatedIds = <int>{};
      if (updated is List) {
        for (final item in updated) {
          if (item is Map<String, dynamic> && item['id'] is int) {
            updatedIds.add(item['id'] as int);
          }
        }
      }

      for (int i = 0; i < _prodotti.length; i++) {
        final id = _prodotti[i].id;
        if (id != null && updatedIds.contains(id)) {
          _prodotti[i] = _prodotti[i].copyWith(status: normalized);
        }
      }

      if (_prodottoSelezionato?.id != null && updatedIds.contains(_prodottoSelezionato!.id)) {
        _prodottoSelezionato = _prodotti.firstWhere(
          (p) => p.id == _prodottoSelezionato!.id,
          orElse: () => _prodottoSelezionato!,
        );
      }

      _applicaFiltroEOrdinamento();

      return BulkCategoryUpdateResult(
        successCount: updatedIds.length,
        failedCount: _selectedProductIds.length - updatedIds.length,
        message: 'Stato aggiornato su ${updatedIds.length} prodotti.',
      );
    } catch (e) {
      log.e('❌ Errore bulk status update', e);
      return BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: _selectedProductIds.length,
        message: 'Errore aggiornamento stato: $e',
      );
    }
  }

  Future<BulkCategoryUpdateResult> deleteSelectedProducts({
    required bool force,
  }) async {
    if (_selectedProductIds.isEmpty) {
      return const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessun prodotto selezionato.',
      );
    }

    int success = 0;
    int failed = 0;
    final ids = _selectedProductIds.toList();
    for (final id in ids) {
      try {
        final deleted = await PlatformManager.prodotti.deleteProduct(id, force: force);
        if (deleted) {
          success++;
          _prodotti.removeWhere((p) => p.id == id);
          _prodottiFiltrati.removeWhere((p) => p.id == id);
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
        log.e('❌ Errore delete prodotto $id', e);
      }
    }

    _selectedProductIds.clear();
    if (_prodottoSelezionato?.id != null && !_prodotti.any((p) => p.id == _prodottoSelezionato!.id)) {
      _prodottoSelezionato = null;
      _varianteSelezionata = null;
      _variantiFiltrate = [];
    }
    _applicaFiltroEOrdinamento();

    return BulkCategoryUpdateResult(
      successCount: success,
      failedCount: failed,
      message: force
          ? 'Eliminazione definitiva: $success successi, $failed falliti.'
          : 'Spostati nel cestino: $success successi, $failed falliti.',
    );
  }

  Future<QuickVariantSaveResult> saveVariantQuickEdits({
    required int productId,
    required Map<int, QuickVariantEdit> edits,
  }) async {
    if (edits.isEmpty) {
      return const QuickVariantSaveResult(
        updated: 0,
        failed: 0,
        message: 'Nessuna modifica variante da salvare.',
      );
    }

    int updated = 0;
    int failed = 0;

    final updatedVariantsById = <int, VarianteProductGlobal>{};

    for (final entry in edits.entries) {
      final variationId = entry.key;
      final edit = entry.value;
      try {
        final varianteAggiornata = await PlatformManager.varianti.updateVariation(
          productId: productId,
          variante: VarianteProductGlobal(
            id: variationId,
            nome: edit.nome,
            attributi: edit.attributi,
            sku: edit.sku,
            prezzo: edit.prezzo,
            prezzoScontato: edit.prezzoScontato,
            quantita: edit.quantita,
            immagineUrl: edit.immagineUrl,
            immaginiAggiuntive: edit.immaginiAggiuntive,
            peso: edit.peso,
            dimensioni: edit.dimensioni,
            attiva: edit.attiva,
          ),
        );
        updatedVariantsById[variationId] = varianteAggiornata;
        updated++;
      } catch (e) {
        failed++;
        log.e('❌ Errore salvataggio variante $variationId', e);
      }
    }

    if (updatedVariantsById.isNotEmpty) {
      final prodottoIndex = _prodotti.indexWhere((p) => p.id == productId);
      if (prodottoIndex >= 0) {
        final current = _prodotti[prodottoIndex];
        final currentVariants = current.varianti ?? const <VarianteProductGlobal>[];
        final merged = currentVariants
            .map((v) => updatedVariantsById[v.id] ?? v)
            .toList();
        _prodotti[prodottoIndex] = current.copyWith(varianti: merged);

        if (_prodottoSelezionato?.id == productId) {
          _prodottoSelezionato = _prodotti[prodottoIndex];
          _applicaFiltriVarianti();
        }
      }
    }

    return QuickVariantSaveResult(
      updated: updated,
      failed: failed,
      message: failed == 0
          ? 'Varianti aggiornate: $updated.'
          : 'Aggiornamento varianti parziale: $updated successi, $failed fallite.',
    );
  }
}

class BulkCategoryUpdateResult {
  final int successCount;
  final int failedCount;
  final String message;

  const BulkCategoryUpdateResult({
    required this.successCount,
    required this.failedCount,
    required this.message,
  });
}

class QuickVariantEdit {
  final String nome;
  final List<AttributoVariante> attributi;
  final String sku;
  final double prezzo;
  final double? prezzoScontato;
  final int quantita;
  final String? immagineUrl;
  final List<String> immaginiAggiuntive;
  final String? peso;
  final DimensioniProdotto? dimensioni;
  final bool attiva;

  const QuickVariantEdit({
    required this.nome,
    required this.attributi,
    required this.sku,
    required this.prezzo,
    required this.prezzoScontato,
    required this.quantita,
    required this.immagineUrl,
    required this.immaginiAggiuntive,
    required this.peso,
    required this.dimensioni,
    required this.attiva,
  });

  factory QuickVariantEdit.fromVariante(VarianteProductGlobal variante) {
    return QuickVariantEdit(
      nome: variante.nome,
      attributi: variante.attributi,
      sku: variante.sku,
      prezzo: variante.prezzo,
      prezzoScontato: variante.prezzoScontato,
      quantita: variante.quantita,
      immagineUrl: variante.immagineUrl,
      immaginiAggiuntive: variante.immaginiAggiuntive,
      peso: variante.peso,
      dimensioni: variante.dimensioni,
      attiva: variante.attiva,
    );
  }
}

class QuickVariantSaveResult {
  final int updated;
  final int failed;
  final String message;

  const QuickVariantSaveResult({
    required this.updated,
    required this.failed,
    required this.message,
  });
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
