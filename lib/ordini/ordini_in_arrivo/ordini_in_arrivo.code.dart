import '../../login/jwt_api/adapter/platform_manager.dart';
import '../../log_viewer/app_logger.dart';
import '../class_ordini.dart';

/// Risultato della verifica locale di un prodotto ordine.
class RisultatoVerifica {
  const RisultatoVerifica({
    required this.trovato,
    this.prodotto,
    this.codiceScansionato,
  });

  final bool trovato;
  final ProdottoOrdine? prodotto;
  final String? codiceScansionato;
}

/// Controller per la gestione degli ordini in arrivo
class OrdiniInArrivoController {
  // Usa PlatformManager invece di istanza diretta
  dynamic get _ordiniQuery => PlatformManager.ordini;

  List<OrdiniGlobal> _ordini = [];
  OrdiniGlobal? _ordineSelezionato;
  bool _isLoading = false;
  String? _errorMessage;

  // Filtri
  OrdineStatus? _filtroStatus = OrdineStatus.processing;
  String _searchQuery = '';

  // Verifiche prodotti
  final Set<String> _skusVerificati = {};

  // Getters
  List<OrdiniGlobal> get ordini => _ordiniFiltrati;
  OrdiniGlobal? get ordineSelezionato => _ordineSelezionato;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasOrdineSelezionato => _ordineSelezionato != null;
  OrdineStatus? get filtroStatus => _filtroStatus;
  String get searchQuery => _searchQuery;
  Set<String> get skusVerificati => Set.unmodifiable(_skusVerificati);

  /// Carica gli ordini dal server
  Future<void> caricaOrdini() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      log.i('Caricamento ordini in arrivo...');

      final ordini = await _ordiniQuery.getOrders(
        perPage: 100,
        status: _filtroStatus,
      );

      _ordini = ordini;
      log.i('Caricati ${_ordini.length} ordini in arrivo');
    } catch (e) {
      log.e('Errore nel caricamento degli ordini in arrivo: $e');
      _errorMessage = 'Errore nel caricamento degli ordini in arrivo: $e';
      _ordini = [];
    } finally {
      _isLoading = false;
    }
  }

  /// Filtra gli ordini in base alla ricerca
  List<OrdiniGlobal> get _ordiniFiltrati {
    if (_searchQuery.isEmpty) return _ordini;

    return _ordini.where((ordine) {
      final query = _searchQuery.toLowerCase();

      // Cerca per ID ordine
      final idMatch = ordine.id.toString().contains(query);
      final numberMatch = ordine.number?.toLowerCase().contains(query) ?? false;

      // Cerca per nome cliente
      final firstNameMatch =
          ordine.billing?.firstName?.toLowerCase().contains(query) ?? false;
      final lastNameMatch =
          ordine.billing?.lastName?.toLowerCase().contains(query) ?? false;
      final emailMatch =
          ordine.billing?.email?.toLowerCase().contains(query) ?? false;

      return idMatch ||
          numberMatch ||
          firstNameMatch ||
          lastNameMatch ||
          emailMatch;
    }).toList();
  }

  /// Seleziona un ordine
  void selezionaOrdine(OrdiniGlobal ordine) {
    if (_ordineSelezionato?.id != ordine.id) {
      _skusVerificati.clear();
    }
    _ordineSelezionato = ordine;
    log.d('Ordine in arrivo selezionato: #${ordine.number}');
  }

  /// Deseleziona l'ordine corrente
  void deselezionaOrdine() {
    resetVerifiche();
  }

  /// Verifica se un ordine è selezionato
  bool isOrdineSelezionato(OrdiniGlobal ordine) {
    return _ordineSelezionato?.id == ordine.id;
  }

  /// Imposta il filtro per stato
  void setFiltroStatus(OrdineStatus? status) {
    _filtroStatus = status;
    log.d(
      'Filtro stato ordini in arrivo impostato: ${status?.name ?? "tutti"}',
    );
  }

  /// Imposta la query di ricerca
  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  /// Cancella tutti i filtri
  void cancellaFiltri() {
    _filtroStatus = OrdineStatus.processing;
    _searchQuery = '';
    log.d('Filtri ordini in arrivo cancellati');
  }

  /// Verifica se uno SKU è già stato controllato
  bool isSkuVerificato(String? sku) {
    final normalizedSku = _normalizzaSku(sku);
    if (normalizedSku.isEmpty) return false;
    return _skusVerificati.contains(normalizedSku);
  }

  /// Cancella le verifiche e deseleziona l'ordine corrente
  void resetVerifiche() {
    _skusVerificati.clear();
    _ordineSelezionato = null;
    log.d('Verifiche prodotti ordini in arrivo cancellate');
  }

  /// Numero di prodotti distinti già verificati per l'ordine selezionato
  int get numeroProdottiVerificati {
    final skusOrdine = _skusDistintiOrdineSelezionato;
    if (skusOrdine.isEmpty) return _skusVerificati.length;

    return skusOrdine.where(_skusVerificati.contains).length;
  }

  /// Numero totale di prodotti distinti nell'ordine selezionato
  int get numeroProdottiTotali {
    final lineItems = _ordineSelezionato?.lineItems ?? [];
    final skusOrdine = _skusDistintiOrdineSelezionato;
    if (skusOrdine.isNotEmpty) return skusOrdine.length;

    return lineItems.length;
  }

  /// Indica se tutti i prodotti dell'ordine selezionato sono stati verificati
  bool get verificaCompleta {
    final totale = numeroProdottiTotali;
    return totale > 0 && numeroProdottiVerificati == totale;
  }

  /// Verifica localmente un codice prodotto rispetto all'ordine selezionato
  RisultatoVerifica verificaCodiceProdotto(String codice) {
    final ordine = _ordineSelezionato;
    if (ordine == null) {
      log.e('Nessun ordine selezionato per verifica prodotto');
      return const RisultatoVerifica(
        trovato: false,
        codiceScansionato: 'Nessun ordine selezionato',
      );
    }

    final codiceNormalizzato = _normalizzaSku(codice);
    for (final prodotto in ordine.lineItems ?? <ProdottoOrdine>[]) {
      final skuNormalizzato = _normalizzaSku(prodotto.sku);
      if (skuNormalizzato.isEmpty) continue;

      if (skuNormalizzato == codiceNormalizzato) {
        _skusVerificati.add(skuNormalizzato);
        log.i(
          'Prodotto verificato per ordine #${ordine.number}: ${prodotto.sku}',
        );
        return RisultatoVerifica(trovato: true, prodotto: prodotto);
      }
    }

    log.e('Codice prodotto non trovato per ordine #${ordine.number}: $codice');
    return RisultatoVerifica(trovato: false, codiceScansionato: codice);
  }

  Set<String> get _skusDistintiOrdineSelezionato {
    final lineItems = _ordineSelezionato?.lineItems ?? [];
    return lineItems
        .map((prodotto) => _normalizzaSku(prodotto.sku))
        .where((sku) => sku.isNotEmpty)
        .toSet();
  }

  String _normalizzaSku(String? sku) {
    return sku?.trim().toUpperCase() ?? '';
  }
}
