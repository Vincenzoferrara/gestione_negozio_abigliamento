// prodotti_gestisci.code.dart

import '../class_prodotti.dart';
import '../../reuse_class/class_formtter.dart';
import '../prodotto_filters.dart';
import '../../reuse_class/logic/global_pagination_controller.dart';
import '../../reuse_class/datagridview/datagridview_cache.dart';
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

enum ProductGridColumnId {
  preview,
  nome,
  sku,
  categoria,
  prezzo,
  sconto,
  disponibilita,
  quantita,
  varianti,
  stato,
  marca,
}

extension ProductGridColumnIdX on ProductGridColumnId {
  String get storageKey => name;

  String get label {
    switch (this) {
      case ProductGridColumnId.preview:
        return 'Anteprima';
      case ProductGridColumnId.nome:
        return 'Nome';
      case ProductGridColumnId.sku:
        return 'SKU';
      case ProductGridColumnId.categoria:
        return 'Categoria';
      case ProductGridColumnId.prezzo:
        return 'Prezzo';
      case ProductGridColumnId.sconto:
        return 'Sconto';
      case ProductGridColumnId.disponibilita:
        return 'Disponibilita';
      case ProductGridColumnId.quantita:
        return 'Quantita';
      case ProductGridColumnId.varianti:
        return 'Varianti';
      case ProductGridColumnId.stato:
        return 'Stato';
      case ProductGridColumnId.marca:
        return 'Marca';
    }
  }
}

const List<ProductGridColumnId> defaultProductGridColumns =
    <ProductGridColumnId>[
      ProductGridColumnId.preview,
      ProductGridColumnId.nome,
      ProductGridColumnId.sku,
      ProductGridColumnId.categoria,
      ProductGridColumnId.prezzo,
      ProductGridColumnId.sconto,
      ProductGridColumnId.disponibilita,
      ProductGridColumnId.quantita,
      ProductGridColumnId.varianti,
      ProductGridColumnId.stato,
    ];

typedef ProductPageLoader =
    Future<List<ProdottoGlobal>> Function({
      int page,
      int perPage,
      bool includeAllStatus,
    });

typedef ProductLoadProgress = void Function(List<ProdottoGlobal> products);

/// Classe per la gestione della logica dei prodotti
class ProdottiGestioneController {
  static List<FiltroProdotto> _sharedFiltriProdotto = <FiltroProdotto>[];
  static int _activeInstances = 0;

  List<ProdottoGlobal> _prodotti = [];
  List<ProdottoGlobal> _prodottiFiltrati = [];
  ProdottoGlobal? _prodottoSelezionato;
  final Set<int> _selectedProductIds = <int>{};
  VarianteProductGlobal? _varianteSelezionata;
  String _filtroRicerca = '';
  final List<FiltroProdotto> _filtriProdottoAttivi = <FiltroProdotto>[];
  OrdinamentoProdotti _ordinamentoCorrente = OrdinamentoProdotti.nessuno;

  final Map<String, String> _filtriVariantiAttivi = {};
  List<VarianteProductGlobal> _variantiFiltrate = [];
  String? _lastLoadWarning;
  int _selectedProductLoadToken = 0;

  static const int _productsPerPage = 100;
  static const int _productsMaxPages = 100;
  static const Duration _variantsTtl = Duration(minutes: 30);
  final ProductPageLoader _productPageLoader;

  ProdottiGestioneController({ProductPageLoader? productPageLoader})
    : _productPageLoader = productPageLoader ?? _loadProductPageFromPlatform {
    _activeInstances++;
  }

  static Future<List<ProdottoGlobal>> _loadProductPageFromPlatform({
    int page = 1,
    int perPage = _productsPerPage,
    bool includeAllStatus = true,
  }) async {
    final result = await PlatformManager.prodotti.getProducts(
      page: page,
      perPage: perPage,
      includeAllStatus: includeAllStatus,
    );
    return List<ProdottoGlobal>.from(result as List);
  }

  void dispose() {
    _activeInstances--;
    if (_activeInstances <= 0) {
      _activeInstances = 0;
    }
  }

  bool _canUseSharedCache() {
    return DataGridViewCache.hasFreshProducts();
  }

  void _publishSharedCache() {
    DataGridViewCache.replaceProducts(_prodotti);
  }

  void _markSharedDirty() {
    DataGridViewCache.markProductsDirty();
    DataGridViewCache.clearProducts();
    DataGridViewCache.clearVariants();
  }

  /// Se true, mostra solo le varianti con quantità > 0.
  bool _filtraSoloInStock = false;
  bool _nascondiProdottiEsauriti = false;

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
  String? get lastLoadWarning => _lastLoadWarning;

  String? consumeLastLoadWarning() {
    final w = _lastLoadWarning;
    _lastLoadWarning = null;
    return w;
  }

  bool get filtraSoloInStock => _filtraSoloInStock;
  bool get nascondiProdottiEsauriti => _nascondiProdottiEsauriti;

  int get numeroProdotti => _prodottiFiltrati.length;
  bool get hasProdottoSelezionato => _prodottoSelezionato != null;
  bool get hasVarianteSelezionata => _varianteSelezionata != null;
  bool get hasFiltroAttivo =>
      _filtroRicerca.isNotEmpty ||
      _filtriProdottoAttivi.isNotEmpty ||
      _nascondiProdottiEsauriti;
  List<FiltroProdotto> get filtriProdottoAttivi =>
      List.unmodifiable(_filtriProdottoAttivi);
  Set<int> get selectedProductIds => Set.unmodifiable(_selectedProductIds);
  List<ProdottoGlobal> get selectedProducts => _prodotti
      .where((p) => p.id != null && _selectedProductIds.contains(p.id))
      .toList();
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

  void setBulkSelectionByIds(Iterable<int> productIds) {
    _selectedProductIds
      ..clear()
      ..addAll(productIds.where((id) => id > 0));
  }

  void selectOnlyProductForBulk(ProdottoGlobal prodotto) {
    final id = prodotto.id;
    if (id == null || id <= 0) return;
    _selectedProductIds
      ..clear()
      ..add(id);
  }

  void selectAllFilteredProducts() {
    for (final prodotto in _prodottiFiltrati) {
      final id = prodotto.id;
      if (id != null && id > 0) {
        _selectedProductIds.add(id);
      }
    }
  }

  void selezionaProdottoLocal(ProdottoGlobal prodotto) {
    _prodottoSelezionato = prodotto;
    _varianteSelezionata = null;
    _filtraSoloInStock = false;
    cancellaFiltriVarianti();

    final productId = prodotto.id;
    final cachedVariants = productId != null
        ? _cachedVariants(productId)
        : null;
    if (cachedVariants != null) {
      _prodottoSelezionato = prodotto.copyWith(varianti: cachedVariants);
    }

    _applicaFiltriVarianti();
  }

  Future<void> selezionaProdotto(ProdottoGlobal prodotto) async {
    selezionaProdottoLocal(prodotto);
  }

  Future<bool> caricaVariantiProdottoSelezionato({
    bool forceRefresh = false,
  }) async {
    final prodotto = _prodottoSelezionato;
    if (prodotto == null) return false;
    return _caricaVariantiProdotto(
      prodotto,
      forceRefresh: forceRefresh,
      onlyIfStillSelected: true,
    );
  }

  List<VarianteProductGlobal>? _cachedVariants(int productId) {
    return DataGridViewCache.readVariants(productId, _variantsTtl);
  }

  void _storeVariantsInCache(
    int productId,
    List<VarianteProductGlobal> varianti,
  ) {
    DataGridViewCache.writeVariants(productId, varianti);
  }

  void _removeVariantsFromCache(int productId) {
    DataGridViewCache.removeVariants(productId);
  }

  void _replaceProductVariantsInLists(
    int productId,
    List<VarianteProductGlobal> varianti,
  ) {
    for (int i = 0; i < _prodotti.length; i++) {
      if (_prodotti[i].id == productId) {
        _prodotti[i] = _prodotti[i].copyWith(varianti: varianti);
      }
    }
    for (int i = 0; i < _prodottiFiltrati.length; i++) {
      if (_prodottiFiltrati[i].id == productId) {
        _prodottiFiltrati[i] = _prodottiFiltrati[i].copyWith(
          varianti: varianti,
        );
      }
    }
  }

  /// Applica solo varianti gia presenti in cache globale: nessuna rete qui.
  Future<void> _caricaVariantiTuttiProdotti({int startIndex = 0}) async {
    try {
      for (int i = startIndex; i < _prodotti.length; i++) {
        final prodotto = _prodotti[i];
        final productId = prodotto.id;
        if (productId == null) continue;
        final cachedVariants = _cachedVariants(productId);
        if (cachedVariants == null) continue;
        _prodotti[i] = prodotto.copyWith(varianti: cachedVariants);
      }
    } catch (e) {
      log.e('❌ Errore applicazione cache varianti prodotti', e);
    }
  }

  /// Carica le varianti di un prodotto da WooCommerce
  Future<bool> _caricaVariantiProdotto(
    ProdottoGlobal prodotto, {
    bool forceRefresh = false,
    bool onlyIfStillSelected = false,
  }) async {
    final productId = prodotto.id;
    if (productId == null || productId <= 0) {
      _applicaFiltriVarianti();
      return false;
    }

    if (!forceRefresh) {
      final cachedVariants = _cachedVariants(productId);
      if (cachedVariants != null) {
        log.d(
          '[prodotti-grid] variants cache hit productId=$productId count=${cachedVariants.length}',
        );
        if (!onlyIfStillSelected || _prodottoSelezionato?.id == productId) {
          _replaceProductVariantsInLists(productId, cachedVariants);
          _prodottoSelezionato = prodotto.copyWith(varianti: cachedVariants);
          _applicaFiltriVarianti();
        }
        return false;
      }
    }

    final loadToken = ++_selectedProductLoadToken;
    log.d(
      '[prodotti-grid] variants fetch start productId=$productId token=$loadToken onlyIfStillSelected=$onlyIfStillSelected',
    );
    try {
      log.i(
        '🔍 Caricamento varianti per prodotto: ${prodotto.nome} (ID: $productId)',
      );

      log.i(
        '📋 Verifica varianti per prodotto $productId (variations=${prodotto.variations})',
      );

      final variantiComplete = await PlatformManager.varianti
          .getProductVariations(
            productId,
            attributiProdotto: prodotto.attributi,
          );
      log.i('✅ Caricate ${variantiComplete.length} varianti complete');

      _storeVariantsInCache(productId, variantiComplete);
      _replaceProductVariantsInLists(productId, variantiComplete);

      if (onlyIfStillSelected &&
          (_prodottoSelezionato?.id != productId ||
              loadToken != _selectedProductLoadToken)) {
        log.d(
          '[prodotti-grid] variants fetch stale productId=$productId token=$loadToken currentSelected=${_prodottoSelezionato?.id} currentToken=$_selectedProductLoadToken',
        );
        return false;
      }

      _prodottoSelezionato = prodotto.copyWith(varianti: variantiComplete);
      _applicaFiltriVarianti();

      log.i('📊 Varianti filtrate: ${_variantiFiltrate.length}');
      for (final variante in _variantiFiltrate) {
        log.i(
          '   - ${variante.nome}: ${variante.quantita} pezzi, €${variante.prezzo}',
        );
      }
      log.d(
        '[prodotti-grid] variants fetch applied productId=$productId token=$loadToken filtered=${_variantiFiltrate.length}',
      );
      return true;
    } catch (e) {
      log.e('❌ Errore caricamento varianti per prodotto $productId', e);
      _applicaFiltriVarianti();
      return false;
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

  void addFiltroProdotto({
    required CampoFiltroProdotto campo,
    required OperatoreFiltroProdotto operatore,
    required String valoreInput,
  }) {
    final valori = valoreInput
        .split(RegExp(r'[,;]'))
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (valori.isEmpty) return;

    _filtriProdottoAttivi.add(
      FiltroProdotto(campo: campo, operatore: operatore, valori: valori),
    );
    _sharedFiltriProdotto = List<FiltroProdotto>.from(_filtriProdottoAttivi);
    _applicaFiltroEOrdinamento();
    _logAppliedFilters(trigger: 'add');
  }

  void removeFiltroProdottoAt(int index) {
    if (index < 0 || index >= _filtriProdottoAttivi.length) return;
    _filtriProdottoAttivi.removeAt(index);
    _sharedFiltriProdotto = List<FiltroProdotto>.from(_filtriProdottoAttivi);
    _applicaFiltroEOrdinamento();
    _logAppliedFilters(trigger: 'remove');
  }

  void clearFiltriProdotto() {
    _filtriProdottoAttivi.clear();
    _sharedFiltriProdotto = <FiltroProdotto>[];
    _applicaFiltroEOrdinamento();
    _logAppliedFilters(trigger: 'clear');
  }

  void setPersistedAdvancedFiltersEnabled(bool enabled) {
    if (enabled) {
      _filtriProdottoAttivi
        ..clear()
        ..addAll(_sharedFiltriProdotto);
    } else {
      _filtriProdottoAttivi.clear();
    }
    _applicaFiltroEOrdinamento();
  }

  List<String> getFilterValueSuggestions(
    CampoFiltroProdotto campo,
    String query, {
    int limit = 60,
  }) {
    return ProdottoFilterEngine.getFilterValueSuggestions(
      _prodotti,
      campo,
      query,
      limit: limit,
    );
  }

  void _logAppliedFilters({required String trigger}) {
    final expr = _filtriProdottoAttivi.isEmpty
        ? '(none)'
        : _filtriProdottoAttivi
              .map(
                (f) =>
                    '${f.campoLabel.toLowerCase()}${_opSymbol(f.operatore)}${f.valori.join('|')}',
              )
              .join(' AND ');
    log.d(
      '[filters] applied trigger=$trigger expr="$expr" matched=${_prodottiFiltrati.length}/${_prodotti.length}',
    );
  }

  String _opSymbol(OperatoreFiltroProdotto op) {
    switch (op) {
      case OperatoreFiltroProdotto.contiene:
        return '~';
      case OperatoreFiltroProdotto.nonContiene:
        return '!~';
      case OperatoreFiltroProdotto.contieneSensibile:
        return '~!';
      case OperatoreFiltroProdotto.nonContieneSensibile:
        return '!~!';
      case OperatoreFiltroProdotto.ugualeEsatto:
        return '==';
      case OperatoreFiltroProdotto.diversoEsatto:
        return '!==';
      case OperatoreFiltroProdotto.iniziaCon:
        return '^';
      case OperatoreFiltroProdotto.finisceCon:
        return r'$';
      case OperatoreFiltroProdotto.inElenco:
        return 'IN';
      case OperatoreFiltroProdotto.nonInElenco:
        return 'NOT IN';
      case OperatoreFiltroProdotto.uguale:
        return '=';
      case OperatoreFiltroProdotto.diverso:
        return '!=';
      case OperatoreFiltroProdotto.maggioreUguale:
        return '>=';
      case OperatoreFiltroProdotto.maggiore:
        return '>';
      case OperatoreFiltroProdotto.minoreUguale:
        return '<=';
      case OperatoreFiltroProdotto.minore:
        return '<';
      case OperatoreFiltroProdotto.tra:
        return 'BETWEEN';
    }
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

  /// Aggiorna lo stato del filtro di disponibilità e riapplica tutti i filtri.
  void setFiltraSoloInStock(bool mostraSoloDisponibili) {
    _filtraSoloInStock = mostraSoloDisponibili;
    _applicaFiltriVarianti();
  }

  void setNascondiProdottiEsauriti(bool value) {
    if (_nascondiProdottiEsauriti == value) return;
    _nascondiProdottiEsauriti = value;
    _applicaFiltroEOrdinamento();
  }

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

    if (_filtraSoloInStock) {
      variantiTemp = variantiTemp.where((v) => v.quantita > 0).toList();
    }

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
    _prodottiFiltrati = _prodotti.where((prodotto) {
      if (_nascondiProdottiEsauriti && !prodotto.inStock) return false;
      return _matchesLegacyTextFilter(prodotto) &&
          _matchesAdvancedFilters(prodotto);
    }).toList();

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

  bool _matchesLegacyTextFilter(ProdottoGlobal prodotto) {
    return ProdottoFilterEngine.matchesQuickSearch(prodotto, _filtroRicerca);
  }

  bool _matchesAdvancedFilters(ProdottoGlobal prodotto) {
    return ProdottoFilterEngine.matchesFilters(prodotto, _filtriProdottoAttivi);
  }

  /// Carica i prodotti usando PlatformManager (modello globale)
  Future<void> caricaProdotti({
    bool forceRefresh = false,
    ProductLoadProgress? onProgress,
  }) async {
    final previousLocal =
        DataGridViewCache.readProducts() ??
        List<ProdottoGlobal>.from(_prodotti);
    try {
      _lastLoadWarning = null;

      if (!forceRefresh && _canUseSharedCache()) {
        _prodotti = DataGridViewCache.readProducts() ?? <ProdottoGlobal>[];
        _applicaFiltroEOrdinamento();
        onProgress?.call(List<ProdottoGlobal>.unmodifiable(_prodottiFiltrati));
        return;
      }

      if (forceRefresh) {
        DataGridViewCache.clearProducts();
        DataGridViewCache.clearVariants();
      }

      log.i('📦 Caricamento prodotti da WooCommerce...');
      final loaded = <ProdottoGlobal>[];
      bool partial = false;

      for (int page = 1; page <= _productsMaxPages; page++) {
        try {
          final chunk = await _productPageLoader(
            page: page,
            perPage: _productsPerPage,
            includeAllStatus: true,
          );
          if (chunk.isEmpty) break;
          final chunkStart = loaded.length;
          loaded.addAll(chunk);
          _prodotti = List<ProdottoGlobal>.from(loaded);
          await _caricaVariantiTuttiProdotti(startIndex: chunkStart);
          _applicaFiltroEOrdinamento();
          onProgress?.call(
            List<ProdottoGlobal>.unmodifiable(_prodottiFiltrati),
          );
          if (chunk.length < _productsPerPage) break;
        } catch (e) {
          partial = loaded.isNotEmpty;
          log.w('⚠️ Errore caricamento prodotti pagina $page', e);
          break;
        }
      }

      if (loaded.isNotEmpty) {
        _prodotti = List<ProdottoGlobal>.from(loaded);
        log.i('✅ Caricati ${_prodotti.length} prodotti da WooCommerce');
        if (partial) {
          _lastLoadWarning =
              'Caricamento prodotti parziale: alcuni elementi potrebbero mancare.';
        }
        _publishSharedCache();
      } else if (previousLocal.isNotEmpty) {
        _prodotti = previousLocal;
        _lastLoadWarning =
            'Server non raggiungibile: uso elenco prodotti locale già caricato.';
        _publishSharedCache();
      } else {
        _prodotti = <ProdottoGlobal>[];
        _lastLoadWarning =
            'Server non raggiungibile: nessun prodotto disponibile.';
      }

      if (_prodotti.isEmpty) {
        _lastLoadWarning ??= 'Nessun prodotto trovato sul server.';
      }

      _applicaFiltroEOrdinamento();
    } catch (e) {
      log.e('❌ Errore generale caricamento prodotti', e);
      log.e('   Dettagli errore: ${e.toString()}');
      if (previousLocal.isNotEmpty) {
        _prodotti = previousLocal;
        _lastLoadWarning =
            'Errore durante il caricamento prodotti: uso cache precedente.';
        _publishSharedCache();
      } else {
        _prodotti = <ProdottoGlobal>[];
        _lastLoadWarning = 'Errore durante il caricamento prodotti.';
      }
      _applicaFiltroEOrdinamento();
    }
  }

  Future<PaginatedResult<ProdottoGlobal>> caricaProdottiPaginati({
    required int page,
    required int perPage,
    bool append = false,
  }) async {
    try {
      _lastLoadWarning = null;
      final hasLocalProducts =
          _prodotti.isNotEmpty || DataGridViewCache.hasProducts;
      if (!hasLocalProducts) {
        await caricaProdotti();
      }
      _applicaFiltroEOrdinamento();

      final total = _prodottiFiltrati.length;
      final totalPages = total == 0 ? 1 : (total / perPage).ceil();
      final safePage = page < 1
          ? 1
          : page > totalPages
          ? totalPages
          : page;
      final start = total == 0 ? 0 : (safePage - 1) * perPage;
      final end = total == 0 ? 0 : (start + perPage).clamp(0, total);
      final items = total == 0
          ? <ProdottoGlobal>[]
          : _prodottiFiltrati.sublist(start, end);

      return PaginatedResult<ProdottoGlobal>(
        items: List<ProdottoGlobal>.from(items),
        page: safePage,
        perPage: perPage,
        totalItems: total,
        totalPages: totalPages,
        hasMore: safePage < totalPages,
      );
    } catch (e) {
      log.e('❌ Errore caricamento prodotti paginato', e);
      if (_prodotti.isNotEmpty) {
        _lastLoadWarning =
            'Server non raggiungibile: uso elenco prodotti locale gia caricato.';
        _applicaFiltroEOrdinamento();
        final total = _prodottiFiltrati.length;
        final totalPages = total == 0 ? 1 : (total / perPage).ceil();
        final safePage = page < 1
            ? 1
            : page > totalPages
            ? totalPages
            : page;
        final start = total == 0 ? 0 : (safePage - 1) * perPage;
        final end = total == 0 ? 0 : (start + perPage).clamp(0, total);
        return PaginatedResult<ProdottoGlobal>(
          items: List<ProdottoGlobal>.from(
            total == 0
                ? <ProdottoGlobal>[]
                : _prodottiFiltrati.sublist(start, end),
          ),
          page: safePage,
          perPage: perPage,
          totalItems: total,
          totalPages: totalPages,
          hasMore: safePage < totalPages,
        );
      }
      rethrow;
    }
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
      _removeVariantsFromCache(prodottoId);

      if (_prodottoSelezionato?.id == prodottoId) {
        _prodottoSelezionato = null;
        _varianteSelezionata = null;
        _variantiFiltrate = [];
        _filtriVariantiAttivi.clear();
        _filtraSoloInStock = false;
      }

      _applicaFiltroEOrdinamento();
      _markSharedDirty();
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
        _markSharedDirty();
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
            _storeVariantsInCache(prodottoId, varianti);
          }
        }

        // Aggiorna anche il prodotto selezionato
        if (_prodottoSelezionato?.id == prodottoId) {
          _prodottoSelezionato = _prodotti[prodottoIndex];
          _applicaFiltriVarianti();
        }
        _markSharedDirty();
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
      _markSharedDirty();

      return BulkCategoryUpdateResult(
        successCount: successCount,
        failedCount: failedCount,
        message: failedCount == 0
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

    final normalized =
        categoryNames
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
      final existing = await PlatformManager.categorie.getCategories(
        perPage: 100,
      );
      final byName = <String, CategoriaProdotto>{
        for (final c in existing) c.nome.toLowerCase(): c,
      };

      final missing = normalized
          .where((name) => !byName.containsKey(name.toLowerCase()))
          .toList();

      if (missing.isNotEmpty) {
        final created = await PlatformManager.categorie
            .createCategoryIfNotExists(
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
    final normalized =
        categoryNames
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (normalized.isEmpty) {
      return const <CategoriaProdotto>[];
    }

    final existing = await PlatformManager.categorie.getCategories(
      perPage: 100,
    );
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
    final normalized =
        tagNames
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
      final response = await PlatformManager.prodotti.batchUpdateProducts(
        update: updates,
      );
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
      _markSharedDirty();
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

    final updates = _selectedProductIds
        .map((id) => {'id': id, 'status': normalized})
        .toList();
    try {
      final response = await PlatformManager.prodotti.batchUpdateProducts(
        update: updates,
      );
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

      if (_prodottoSelezionato?.id != null &&
          updatedIds.contains(_prodottoSelezionato!.id)) {
        _prodottoSelezionato = _prodotti.firstWhere(
          (p) => p.id == _prodottoSelezionato!.id,
          orElse: () => _prodottoSelezionato!,
        );
      }

      _applicaFiltroEOrdinamento();
      _markSharedDirty();

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
        final deleted = await PlatformManager.prodotti.deleteProduct(
          id,
          force: force,
        );
        if (deleted) {
          success++;
          _prodotti.removeWhere((p) => p.id == id);
          _prodottiFiltrati.removeWhere((p) => p.id == id);
          _removeVariantsFromCache(id);
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
        log.e('❌ Errore delete prodotto $id', e);
      }
    }

    _selectedProductIds.clear();
    if (_prodottoSelezionato?.id != null &&
        !_prodotti.any((p) => p.id == _prodottoSelezionato!.id)) {
      _prodottoSelezionato = null;
      _varianteSelezionata = null;
      _variantiFiltrate = [];
    }
    _applicaFiltroEOrdinamento();
    _markSharedDirty();

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
        final varianteAggiornata = await PlatformManager.varianti
            .updateVariation(
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
        final currentVariants =
            current.varianti ?? const <VarianteProductGlobal>[];
        final merged = currentVariants
            .map((v) => updatedVariantsById[v.id] ?? v)
            .toList();
        _prodotti[prodottoIndex] = current.copyWith(varianti: merged);
        _storeVariantsInCache(productId, merged);

        if (_prodottoSelezionato?.id == productId) {
          _prodottoSelezionato = _prodotti[prodottoIndex];
          _applicaFiltriVarianti();
        }
        _markSharedDirty();
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

class ProdottoPricingInfo {
  final String prezzoLabel;
  final String scontoLabel;
  final String prezzoCompletoLabel;
  final bool hasSconto;
  final bool prezzoVariabile;
  final bool scontoVariabile;

  const ProdottoPricingInfo({
    required this.prezzoLabel,
    required this.scontoLabel,
    required this.prezzoCompletoLabel,
    required this.hasSconto,
    required this.prezzoVariabile,
    required this.scontoVariabile,
  });
}

class ProdottoUtils {
  static String getStatusLabel(String? status) {
    switch ((status ?? '').trim().toLowerCase()) {
      case 'publish':
        return 'Pubblico';
      case 'private':
        return 'Privato';
      case 'pending':
        return 'In revisione';
      case 'draft':
      default:
        return 'Bozza';
    }
  }

  static ProdottoPricingInfo getPricingInfo(ProdottoGlobal prodotto) {
    final varianti = prodotto.varianti ?? const <VarianteProductGlobal>[];
    if (varianti.isEmpty) {
      final prezzoLabel = ClassFormtter.formatPrezzo(
        prodotto.prezzoNormale ?? 0,
      );
      final scontoLabel = prodotto.prezzoScontato != null
          ? ClassFormtter.formatPrezzo(prodotto.prezzoScontato!)
          : '-';
      return ProdottoPricingInfo(
        prezzoLabel: prezzoLabel,
        scontoLabel: scontoLabel,
        prezzoCompletoLabel: ClassFormtter.formatPrezzoConSconto(
          prodotto.prezzoNormale ?? 0,
          prodotto.prezzoScontato,
        ),
        hasSconto: prodotto.prezzoScontato != null,
        prezzoVariabile: false,
        scontoVariabile: false,
      );
    }

    final regularPrices = varianti.map((v) => v.prezzo).toSet();
    final saleValues = varianti.map((v) => v.prezzoScontato).toSet();

    final prezzoVariabile = regularPrices.length > 1;
    final scontoVariabile = saleValues.length > 1;
    final hasSconto = saleValues.any((value) => value != null);

    final prezzoLabel = prezzoVariabile
        ? 'Variabile'
        : ClassFormtter.formatPrezzo(regularPrices.first);
    final scontoLabel = !hasSconto
        ? '-'
        : scontoVariabile
        ? 'Variabile'
        : ClassFormtter.formatPrezzo(saleValues.first!);

    final prezzoCompletoLabel = hasSconto
        ? prezzoVariabile || scontoVariabile
              ? 'Variabile'
              : ClassFormtter.formatPrezzoConSconto(
                  regularPrices.first,
                  saleValues.first,
                )
        : prezzoLabel;

    return ProdottoPricingInfo(
      prezzoLabel: prezzoLabel,
      scontoLabel: scontoLabel,
      prezzoCompletoLabel: prezzoCompletoLabel,
      hasSconto: hasSconto,
      prezzoVariabile: prezzoVariabile,
      scontoVariabile: scontoVariabile,
    );
  }
}

class ProdottoDisplayInfo {
  final String id;
  final String nome;
  final String sku;
  final String categoria;
  final String prezzo;
  final String sconto;
  final String status;
  final String disponibilita;
  final String variantiCount;
  final bool inStock;
  final bool hasSconto;
  final bool prezzoVariabile;
  final bool scontoVariabile;
  ProdottoDisplayInfo({
    required this.id,
    required this.nome,
    required this.sku,
    required this.categoria,
    required this.prezzo,
    required this.sconto,
    required this.status,
    required this.disponibilita,
    required this.variantiCount,
    required this.inStock,
    required this.hasSconto,
    required this.prezzoVariabile,
    required this.scontoVariabile,
  });
  factory ProdottoDisplayInfo.fromProdotto(ProdottoGlobal prodotto) {
    final pricing = ProdottoUtils.getPricingInfo(prodotto);
    return ProdottoDisplayInfo(
      id: prodotto.id?.toString() ?? '',
      nome: prodotto.nome ?? '',
      sku: prodotto.sku ?? '',
      categoria: prodotto.categoria?.map((c) => c.nome).join(', ') ?? '',
      prezzo: pricing.prezzoCompletoLabel,
      sconto: pricing.scontoLabel,
      status: ProdottoUtils.getStatusLabel(prodotto.status),
      disponibilita: ClassFormtter.getDisponibilitaText(prodotto.inStock),
      variantiCount: ClassFormtter.getVariantiCountText(
        prodotto.varianti?.length ?? 0,
      ),
      inStock: prodotto.inStock,
      hasSconto: pricing.hasSconto,
      prezzoVariabile: pricing.prezzoVariabile,
      scontoVariabile: pricing.scontoVariabile,
    );
  }
}

class QuickEditSelectionUtils {
  static List<String> categoryNamesFromProduct(ProdottoGlobal prodotto) {
    return _normalizeNames(
      (prodotto.categoria ?? const <CategoriaProdotto>[]).map((c) => c.nome),
    );
  }

  static List<String> tagNamesFromProduct(ProdottoGlobal prodotto) {
    return _normalizeNames(
      (prodotto.tag ?? const <TagProdotto>[]).map((t) => t.nome),
    );
  }

  static List<String> normalizeNames(Iterable<dynamic> values) {
    return _normalizeNames(values);
  }

  static bool hasSameNames(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    final leftNormalized = left.map((v) => v.trim().toLowerCase()).toList()
      ..sort();
    final rightNormalized = right.map((v) => v.trim().toLowerCase()).toList()
      ..sort();
    for (int i = 0; i < leftNormalized.length; i++) {
      if (leftNormalized[i] != rightNormalized[i]) return false;
    }
    return true;
  }

  static List<String> _normalizeNames(Iterable<dynamic> values) {
    final names = <String>{};
    for (final value in values) {
      final name = value.toString().trim();
      if (name.isNotEmpty) {
        names.add(name);
      }
    }
    final list = names.toList()..sort();
    return list;
  }
}
