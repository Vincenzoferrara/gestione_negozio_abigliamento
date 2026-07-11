// cassa.code.dart

import '../prodotti/class_prodotti.dart';
import 'class_scontrino.dart';
import 'cassa_metrics.dart';
import '../log_viewer/app_logger.dart';
import '../login/jwt_api/adapter/platform_manager.dart';

/// Rappresenta un elemento della lista cassa (può essere un prodotto o una variante)
class ElementoCassa {
  final ProdottoGlobal prodotto;
  final VarianteProductGlobal? variante;

  ElementoCassa(this.prodotto, [this.variante]);

  String get nome => variante?.nomeVisualizzabile ?? prodotto.nome ?? '';
  String get sku => variante?.sku ?? prodotto.sku ?? '';
  double get prezzoEffettivo =>
      variante?.prezzoEffettivo ?? prodotto.prezzoEffettivo;
  String? get immagineUrl => variante?.immagineUrl ?? prodotto.immagineUrl;
  bool get isDisponibile {
    // Se c'è una variante specifica, controlla solo la quantità (ignora flag attiva)
    if (variante != null) {
      final disponibile = variante!.quantita > 0;
      if (!disponibile) {
        AppLogger().d(
          '❌ Variante ${variante!.sku} non disponibile: quantita=${variante!.quantita}',
        );
      }
      return disponibile;
    }
    // Per prodotti con varianti, controlla se almeno una ha stock > 0
    if (prodotto.varianti != null && prodotto.varianti!.isNotEmpty) {
      final disponibile = prodotto.varianti!.any((v) => v.quantita > 0);
      if (!disponibile) {
        AppLogger().d(
          '❌ Prodotto ${prodotto.nome} non disponibile: nessuna variante con stock',
        );
      }
      return disponibile;
    }
    // Prodotto semplice
    final disponibile = prodotto.inStock && (prodotto.quantitaTotale ?? 0) > 0;
    if (!disponibile) {
      AppLogger().d(
        '❌ Prodotto ${prodotto.nome} non disponibile: inStock=${prodotto.inStock}, qty=${prodotto.quantitaTotale}',
      );
    }
    return disponibile;
  }

  int get quantitaStock => variante?.quantita ?? prodotto.quantitaTotale ?? 0;
}

/// Controller per la gestione della cassa
class CassaController {
  Scontrino _scontrinoCorrente;
  List<ProdottoGlobal> _prodottiOriginali = [];
  final List<ElementoCassa> _elementiCassa = [];
  List<ElementoCassa> _elementiFiltrati = [];
  String _filtroRicerca = '';
  final CassaMetricheStore _metricheStore = CassaMetricheStore();

  // Cliente selezionato (opzionale)
  String? _clienteNome;
  String? _clienteEmail;
  String? _clienteTelefono;

  // Scontrini sospesi
  final List<Scontrino> _scontriniSospesi = [];

  CassaController()
    : _scontrinoCorrente = Scontrino(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        data: DateTime.now(),
      );

  // Getters
  Scontrino get scontrinoCorrente => _scontrinoCorrente;
  List<ElementoCassa> get elementi => _elementiFiltrati;
  String get filtroRicerca => _filtroRicerca;
  String? get clienteNome => _clienteNome;
  String? get clienteEmail => _clienteEmail;
  String? get clienteTelefono => _clienteTelefono;
  List<Scontrino> get scontriniSospesi => List.unmodifiable(_scontriniSospesi);
  CassaMetricheSnapshot get metricheSnapshot => _metricheStore.snapshot;
  TipoOperazioneCassa get tipoOperazioneCorrente =>
      _scontrinoCorrente.tipoOperazione;
  TipoOperazioneCassa get tipoOperazioneEffettivaCorrente =>
      _scontrinoCorrente.tipoOperazioneEffettiva;
  bool get isOperazioneCambio =>
      _scontrinoCorrente.tipoOperazione == TipoOperazioneCassa.cambio;
  bool get isOperazioneReso =>
      _scontrinoCorrente.tipoOperazione == TipoOperazioneCassa.reso;
  bool get isOperazioneVendita =>
      _scontrinoCorrente.tipoOperazione == TipoOperazioneCassa.vendita;

  bool get hasFiltroAttivo => _filtroRicerca.isNotEmpty;
  bool get hasCliente => _clienteNome != null;
  bool get hasScontriniSospesi => _scontriniSospesi.isNotEmpty;
  int get numeroScontriniSospesi => _scontriniSospesi.length;

  Future<void> _ensureMetricheLoaded() async {
    await _metricheStore.init();
  }

  /// Carica tutti i prodotti pubblicati da WooCommerce
  Future<void> caricaProdotti() async {
    try {
      await _ensureMetricheLoaded();
      AppLogger().i('🔄 Caricamento prodotti per la cassa...');

      // Verifica connessione WooCommerce
      if (!PlatformManager.isReady) {
        AppLogger().e('❌ WooCommerce non connesso! Verifica autenticazione.');
        throw Exception('WooCommerce non connesso. Effettua il login.');
      }

      // Carica tutti i prodotti pubblicati (con paginazione)
      final List<ProdottoGlobal> prodottiCaricati = [];
      int currentPage = 1;
      bool hasMore = true;
      const int perPage = 100;

      while (hasMore) {
        AppLogger().d('📦 Caricamento pagina $currentPage...');
        final batch = await PlatformManager.prodotti.getProducts(
          page: currentPage,
          perPage: perPage,
          includeAllStatus:
              true, // Include tutti i prodotti (publish, draft, private)
        );

        if (batch.isEmpty) {
          hasMore = false;
        } else {
          prodottiCaricati.addAll(batch);

          // Se abbiamo ricevuto meno prodotti del limite, siamo all'ultima pagina
          if (batch.length < perPage) {
            hasMore = false;
          } else {
            currentPage++;
          }
        }
      }

      // Per ogni prodotto con varianti, carica le varianti
      // Nota: usiamo variations (ID da WooCommerce) invece di hasVarianti (che controlla varianti già caricate)
      for (var prodotto in prodottiCaricati) {
        final hasVariationIds =
            prodotto.variations != null && prodotto.variations!.isNotEmpty;
        AppLogger().d(
          '🔍 Prodotto ${prodotto.nome}: hasVariationIds=$hasVariationIds, variations=${prodotto.variations?.length ?? 0}',
        );
        if (hasVariationIds && (prodotto.id ?? 0) > 0) {
          try {
            final varianti = await PlatformManager.varianti.getAllVariations(
              prodotto.id,
            );
            AppLogger().d(
              '📦 Trovate ${varianti.length} varianti per ${prodotto.nome}',
            );
            // Crea una copia del prodotto con le varianti
            final index = prodottiCaricati.indexOf(prodotto);
            prodottiCaricati[index] = ProdottoGlobal(
              id: prodotto.id,
              nome: prodotto.nome,
              sku: prodotto.sku,
              prezzoNormale: prodotto.prezzoNormale,
              prezzoScontato: prodotto.prezzoScontato,
              descrizioneBreve: prodotto.descrizioneBreve,
              descrizioneCompleta: prodotto.descrizioneCompleta,
              immagineUrl: prodotto.immagineUrl,
              immaginiAggiuntive: prodotto.immaginiAggiuntive,
              //categoria: prodotto.categoria,
              //tag: prodotto.tag,
              inStock: prodotto.inStock,
              quantitaTotale: prodotto.quantitaTotale,
              peso: prodotto.peso,
              dimensioni: prodotto.dimensioni,
              dataCreazione: prodotto.dataCreazione,
              dataModifica: prodotto.dataModifica,
              status: prodotto.status,
              varianti: varianti,
            );
            AppLogger().d(
              '✅ Caricate ${varianti.length} varianti per prodotto ${prodotto.nome}',
            );
          } catch (e) {
            AppLogger().w(
              '⚠️ Errore caricamento varianti per prodotto ${prodotto.id}: $e',
            );
          }
        }
      }

      // Salva i prodotti originali
      _prodottiOriginali = prodottiCaricati;

      // Crea gli elementi cassa: un elemento per ogni prodotto o variante
      _elementiCassa.clear();
      for (var prodotto in _prodottiOriginali) {
        if (prodotto.hasVarianti && prodotto.varianti?.isNotEmpty == true) {
          // Per i prodotti con varianti, crea un elemento per ogni variante
          for (var variante in prodotto.varianti!) {
            _elementiCassa.add(ElementoCassa(prodotto, variante));
          }
        } else {
          // Per i prodotti senza varianti, crea un singolo elemento
          _elementiCassa.add(ElementoCassa(prodotto));
        }
      }

      _applicaFiltro();

      if (_prodottiOriginali.isEmpty) {
        AppLogger().w(
          '⚠️ Nessun prodotto trovato! Verifica che ci siano prodotti pubblicati su WooCommerce.',
        );
      } else {
        AppLogger().i(
          '✅ Caricati ${_prodottiOriginali.length} prodotti (${_elementiCassa.length} elementi totali) per la cassa',
        );
      }
    } catch (e) {
      AppLogger().e('❌ Errore durante il caricamento dei prodotti: $e');
      rethrow;
    }
  }

  void setTipoOperazione(TipoOperazioneCassa tipo) {
    _scontrinoCorrente.tipoOperazione = tipo;
    _scontrinoCorrente.calcolaTotale();
  }

  /// Imposta il filtro di ricerca
  void setFiltroRicerca(String filtro) {
    _filtroRicerca = filtro.toLowerCase();
    _applicaFiltro();
  }

  /// Cancella il filtro di ricerca
  void cancellaFiltro() {
    _filtroRicerca = '';
    _applicaFiltro();
  }

  /// Applica il filtro agli elementi cassa
  void _applicaFiltro() {
    if (_filtroRicerca.isEmpty) {
      _elementiFiltrati = [];
      return;
    }

    _elementiFiltrati = _elementiCassa.where((elemento) {
      final nomeLower = elemento.nome.toLowerCase();
      final skuLower = elemento.sku.toLowerCase();

      return nomeLower.contains(_filtroRicerca) ||
          skuLower.contains(_filtroRicerca);
    }).toList();
  }

  /// Aggiunge un elemento (prodotto o variante) allo scontrino
  /// Restituisce true se l'aggiunta è riuscita, false altrimenti
  bool aggiungiElemento(
    ElementoCassa elemento, {
    int quantita = 1,
    TipoRigaCassa? tipoMovimento,
  }) {
    if (quantita <= 0) {
      AppLogger().w('⚠️ Quantità non valida: $quantita');
      return false;
    }

    final tipoRiga =
        tipoMovimento ??
        (isOperazioneReso ? TipoRigaCassa.reso : TipoRigaCassa.vendita);

    // Controlla se la riga esiste già nello scontrino
    final rigaEsistente = _trovaRigaEsistente(
      elemento,
      tipoMovimento: tipoRiga,
    );

    if (rigaEsistente != null) {
      // Incrementa la quantità della riga esistente
      rigaEsistente.aggiornaQuantita(rigaEsistente.quantita + quantita);
      _scontrinoCorrente.calcolaTotale();
      AppLogger().d(
        '📦 Quantità aggiornata per ${elemento.nome}: ${rigaEsistente.quantita}',
      );
    } else {
      // Crea una nuova riga
      final prezzo = elemento.prezzoEffettivo;
      final subtotale = prezzo * quantita;

      final riga = RigaScontrino(
        prodotto: elemento.prodotto,
        variante: elemento.variante,
        quantita: quantita,
        subtotale: subtotale,
        tipoMovimento: tipoRiga,
      );

      _scontrinoCorrente.aggiungiRiga(riga);
      AppLogger().d('➕ Aggiunto ${elemento.nome} x$quantita al carrello');
    }

    AppLogger().i(
      '✅ Elemento aggiunto. Totale righe: ${_scontrinoCorrente.righe.length}',
    );
    return true;
  }

  /// Trova una riga esistente nello scontrino con stesso prodotto/variante
  RigaScontrino? _trovaRigaEsistente(
    ElementoCassa elemento, {
    required TipoRigaCassa tipoMovimento,
  }) {
    for (final riga in _scontrinoCorrente.righe) {
      if (riga.prodotto.id == elemento.prodotto.id &&
          riga.tipoMovimento == tipoMovimento) {
        // Se entrambi non hanno varianti, è una corrispondenza
        if (elemento.variante == null && riga.variante == null) {
          return riga;
        }
        // Se entrambi hanno la stessa variante, è una corrispondenza
        if (elemento.variante != null &&
            riga.variante != null &&
            riga.variante!.id == elemento.variante!.id) {
          return riga;
        }
      }
    }
    return null;
  }

  /// Rimuove una riga dallo scontrino
  void rimuoviRiga(int index) {
    _scontrinoCorrente.rimuoviRiga(index);
    //AppLogger.info('Riga rimossa. Totale righe: ${_scontrinoCorrente.righe.length}');
  }

  /// Aggiorna la quantità di una riga
  String? aggiornaQuantitaRiga(int index, int nuovaQuantita) {
    if (index < 0 || index >= _scontrinoCorrente.righe.length) {
      return 'Riga non valida.';
    }

    if (nuovaQuantita <= 0) {
      rimuoviRiga(index);
      return null;
    }

    final riga = _scontrinoCorrente.righe[index];
    if (riga.tipoMovimento == TipoRigaCassa.vendita) {
      final stockDisponibile =
          riga.variante?.quantita ?? riga.prodotto.quantitaTotale ?? 0;
      if (nuovaQuantita > stockDisponibile) {
        return 'Stock insufficiente. Disponibili: $stockDisponibile, Richiesti: $nuovaQuantita';
      }
    }

    riga.aggiornaQuantita(nuovaQuantita);
    _scontrinoCorrente.calcolaTotale();
    return null;
  }

  /// Incrementa quantità di una riga dello scontrino
  String? incrementaQuantitaRiga(int index) {
    if (index < 0 || index >= _scontrinoCorrente.righe.length) {
      return 'Riga non valida.';
    }
    final riga = _scontrinoCorrente.righe[index];
    return aggiornaQuantitaRiga(index, riga.quantita + 1);
  }

  /// Decrementa quantità di una riga dello scontrino
  void decrementaQuantitaRiga(int index) {
    if (index >= 0 && index < _scontrinoCorrente.righe.length) {
      final riga = _scontrinoCorrente.righe[index];
      if (riga.quantita > 1) {
        riga.decrementaQuantita();
        _scontrinoCorrente.calcolaTotale();
      } else {
        rimuoviRiga(index);
      }
    }
  }

  /// Svuota il carrello
  void svuotaCarrello() {
    final tipoOperazione = _scontrinoCorrente.tipoOperazione;
    _scontrinoCorrente.reset();
    _scontrinoCorrente.tipoOperazione = tipoOperazione;
    AppLogger().i('🗑️ Carrello svuotato');
  }

  /// Imposta i dati del cliente e carica automaticamente la carta fedeltà
  Future<Map<String, dynamic>?> setCliente({
    String? nome,
    String? email,
    String? telefono,
  }) async {
    _clienteNome = nome;
    _clienteEmail = email;
    _clienteTelefono = telefono;

    _scontrinoCorrente.clienteNome = nome;
    _scontrinoCorrente.clienteEmail = email;
    _scontrinoCorrente.clienteTelefono = telefono;

    // Cerca automaticamente la carta fedeltà associata all'email
    if (email != null && email.isNotEmpty) {
      try {
        final carta = await PlatformManager.cartaFedelta.findCustomerByEmail(
          email,
        );
        if (carta != null) {
          _scontrinoCorrente.clienteId = carta['user_id']?.toString();
          AppLogger().i(
            '🎯 Carta fedeltà trovata per $email: ${carta['points']} punti',
          );
          return carta;
        }
      } catch (e) {
        AppLogger().d('⚠️ Nessuna carta fedeltà trovata per $email');
      }
    }
    return null;
  }

  /// Cancella i dati del cliente
  void cancellaCliente() {
    _clienteNome = null;
    _clienteEmail = null;
    _clienteTelefono = null;

    _scontrinoCorrente.clienteNome = null;
    _scontrinoCorrente.clienteEmail = null;
    _scontrinoCorrente.clienteTelefono = null;
  }

  /// Applica uno sconto
  void applicaSconto(double sconto) {
    _scontrinoCorrente.sconto = sconto;
    _scontrinoCorrente.calcolaTotale();
  }

  /// Completa la vendita tramite checkout MGWS.
  Future<bool> completaVendita() async {
    return completaOperazione();
  }

  Future<bool> completaOperazione() async {
    if (_scontrinoCorrente.isVuoto) {
      AppLogger().w('⚠️ Impossibile completare: scontrino vuoto');
      return false;
    }

    try {
      AppLogger().i(
        '💰 Inizio checkout MGWS ${_scontrinoCorrente.tipoOperazioneEffettiva.label.toLowerCase()} - Saldo: €${_scontrinoCorrente.totale.toStringAsFixed(2)}',
      );

      final checkoutPayload = _buildCheckoutPayload();
      final response = await PlatformManager.pos.checkout(checkoutPayload);
      final success = response['success'] == true ||
          response['status_code'] != null &&
              (response['status_code'] as int) >= 200 &&
              (response['status_code'] as int) < 300;

      if (!success) {
        throw Exception(
          response['message']?.toString() ??
              'Checkout MGWS non completato',
        );
      }

      final orderId = response['order_id'] ?? response['woo_order_id'];
      if (orderId != null) {
        AppLogger().i('✅ Checkout MGWS completato - ID ordine: $orderId');
      } else {
        AppLogger().i('✅ Checkout MGWS completato');
      }

      await _metricheStore.registraOperazione(_scontrinoCorrente);

      // Aggiorna lo stato dello scontrino locale
      _scontrinoCorrente.stato = _scontrinoCorrente.totale < 0
          ? 'rimborsato'
          : 'pagato';

      try {
        await caricaProdotti();
      } catch (e) {
        AppLogger().w('Checkout MGWS completato ma refresh catalogo fallito: $e');
      }

      // Crea un nuovo scontrino per la prossima vendita
      _nuovoScontrino();

      return true;
    } catch (e, stackTrace) {
      AppLogger().e(
        '❌ Errore durante il completamento della vendita',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Ottiene il titolo del metodo di pagamento in formato leggibile
  String _getMetodoPagamentoTitolo(String metodo) {
    final isRefund = _scontrinoCorrente.totale < 0;
    switch (metodo) {
      case 'contanti':
        return isRefund ? 'Rimborso in Contanti' : 'Pagamento in Contanti';
      case 'carta':
        return isRefund ? 'Rimborso su Carta' : 'Carta di Credito';
      case 'bancomat':
        return isRefund ? 'Rimborso Bancomat/POS' : 'Bancomat/POS';
      default:
        return isRefund ? 'Rimborso' : 'Altro';
    }
  }

  /// Crea un nuovo scontrino vuoto
  void _nuovoScontrino() {
    final tipoOperazione = _scontrinoCorrente.tipoOperazione;
    _scontrinoCorrente = Scontrino(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: DateTime.now(),
      tipoOperazione: tipoOperazione,
    );
    _clienteNome = null;
    _clienteEmail = null;
    _clienteTelefono = null;
  }

  Map<String, dynamic> _buildCheckoutPayload() {
    final saleItems = _scontrinoCorrente.righe
        .where((riga) => riga.tipoMovimento == TipoRigaCassa.vendita)
        .map(_serializeRiga)
        .toList();
    final returnItems = _scontrinoCorrente.righe
        .where((riga) => riga.tipoMovimento == TipoRigaCassa.reso)
        .map(_serializeRiga)
        .toList();

    final payload = <String, dynamic>{
      'operation_type': _scontrinoCorrente.tipoOperazione.value,
      'effective_operation_type':
          _scontrinoCorrente.tipoOperazioneEffettiva.value,
      'payment_method': _scontrinoCorrente.metodoPagamento,
      'payment_method_title': _getMetodoPagamentoTitolo(
        _scontrinoCorrente.metodoPagamento,
      ),
      'set_paid': _scontrinoCorrente.totale >= 0,
      'customer': {
        if (_clienteNome != null && _clienteNome!.isNotEmpty)
          'first_name': _clienteNome,
        if (_clienteEmail != null && _clienteEmail!.isNotEmpty)
          'email': _clienteEmail,
        if (_clienteTelefono != null && _clienteTelefono!.isNotEmpty)
          'phone': _clienteTelefono,
      },
      'sale_items': saleItems,
      'return_items': returnItems,
      'totals': {
        'subtotale': _scontrinoCorrente.subtotale,
        'iva': _scontrinoCorrente.iva,
        'sconto': _scontrinoCorrente.sconto,
        'coupon_sconto': _scontrinoCorrente.couponSconto,
        'totale': _scontrinoCorrente.totale,
        'totale_vendite': _scontrinoCorrente.totaleVendite,
        'totale_resi': _scontrinoCorrente.totaleResi,
        'saldo_operazione': _scontrinoCorrente.saldoOperazione,
        'resto': _scontrinoCorrente.resto,
      },
      'meta_data': [
        {'key': '_punto_vendita', 'value': 'Cassa POS'},
        {'key': '_id_scontrino_locale', 'value': _scontrinoCorrente.id},
        {
          'key': '_data_operazione',
          'value': _scontrinoCorrente.data.toIso8601String(),
        },
        {
          'key': '_tipo_operazione_cassa',
          'value': _scontrinoCorrente.tipoOperazioneEffettiva.value,
        },
        {
          'key': '_totale_resi',
          'value': _scontrinoCorrente.totaleResi.toStringAsFixed(2),
        },
        {
          'key': '_saldo_operazione',
          'value': _scontrinoCorrente.totale.toStringAsFixed(2),
        },
      ],
    };

    if (_scontrinoCorrente.note != null &&
        _scontrinoCorrente.note!.isNotEmpty) {
      payload['note'] = _scontrinoCorrente.note;
    }

    if (saleItems.isNotEmpty && returnItems.isNotEmpty) {
      payload['meta_data'].add({
        'key': '_righe_reso',
        'value': returnItems
            .map(
              (item) =>
                  '${item['sku']} x${item['quantity']} (€${item['subtotal'].toString()})',
            )
            .join(' | '),
      });
    }

    return payload;
  }

  Map<String, dynamic> _serializeRiga(RigaScontrino riga) {
    return <String, dynamic>{
      if (riga.prodotto.id != null) 'product_id': riga.prodotto.id,
      if (riga.variante != null) 'variation_id': riga.variante!.id,
      'quantity': riga.quantita,
      'sku': riga.variante?.sku ?? riga.prodotto.sku,
      'name': riga.nomeCompleto,
      'unit_price': riga.prezzoUnitario,
      'subtotal': riga.subtotale,
      'movement_type': riga.tipoMovimento.value,
    };
  }

  /// Ricerca elemento per SKU o barcode
  /// Restituisce il primo elemento (prodotto o variante) che corrisponde allo SKU
  ElementoCassa? ricercaPerSku(String sku) {
    final skuLower = sku.toLowerCase();

    try {
      return _elementiCassa.firstWhere(
        (elemento) => elemento.sku.toLowerCase() == skuLower,
      );
    } catch (e) {
      AppLogger().d('🔍 Elemento con SKU "$sku" non trovato');
      return null;
    }
  }

  // =======================================================
  // == NUOVE FUNZIONALITÀ                                ==
  // =======================================================

  /// Imposta il metodo di pagamento
  void setMetodoPagamento(String metodo) {
    _scontrinoCorrente.metodoPagamento = metodo;
    AppLogger().d('💳 Metodo pagamento impostato: $metodo');
  }

  /// Imposta l'importo ricevuto (per calcolo resto)
  void setImportoRicevuto(double importo) {
    _scontrinoCorrente.importoRicevuto = importo;
    AppLogger().d('💵 Importo ricevuto: €${importo.toStringAsFixed(2)}');
  }

  /// Ottiene il resto da dare
  double get resto => _scontrinoCorrente.resto;

  /// Verifica se l'importo è sufficiente
  bool get importoSufficiente => _scontrinoCorrente.importoSufficiente;

  /// Applica sconto percentuale a una riga
  void applicaScontoRigaPercentuale(int index, double percentuale) {
    if (index >= 0 && index < _scontrinoCorrente.righe.length) {
      _scontrinoCorrente.righe[index].applicaScontoPercentuale(percentuale);
      _scontrinoCorrente.calcolaTotale();
      AppLogger().d('🏷️ Sconto $percentuale% applicato alla riga $index');
    }
  }

  /// Applica sconto fisso a una riga
  void applicaScontoRigaFisso(int index, double sconto) {
    if (index >= 0 && index < _scontrinoCorrente.righe.length) {
      _scontrinoCorrente.righe[index].applicaScontoFisso(sconto);
      _scontrinoCorrente.calcolaTotale();
      AppLogger().d(
        '🏷️ Sconto €${sconto.toStringAsFixed(2)} applicato alla riga $index',
      );
    }
  }

  /// Rimuove sconti da una riga
  void rimuoviScontiRiga(int index) {
    if (index >= 0 && index < _scontrinoCorrente.righe.length) {
      _scontrinoCorrente.righe[index].rimuoviSconti();
      _scontrinoCorrente.calcolaTotale();
    }
  }

  /// Applica sconto percentuale globale
  void applicaScontoPercentuale(double percentuale) {
    _scontrinoCorrente.applicaScontoPercentualeGlobale(percentuale);
    AppLogger().d('🏷️ Sconto globale ${percentuale}% applicato');
  }

  /// Applica un coupon WooCommerce
  Future<bool> applicaCoupon(String codice) async {
    try {
      AppLogger().i('🎟️ Verifica coupon: $codice');

      // Verifica il coupon su WooCommerce
      final coupon = await PlatformManager.coupon.getCouponByCode(codice);

      if (coupon == null) {
        AppLogger().w('⚠️ Coupon non trovato: $codice');
        return false;
      }

      // Verifica validità
      if (coupon.dateExpires != null &&
          coupon.dateExpires!.isBefore(DateTime.now())) {
        AppLogger().w('⚠️ Coupon scaduto: $codice');
        return false;
      }

      // Calcola lo sconto
      double scontoCoupon = 0.0;
      if (coupon.discountType == 'percent') {
        scontoCoupon =
            _scontrinoCorrente.subtotale *
            (double.tryParse(coupon.amount ?? '0') ?? 0) /
            100;
      } else {
        scontoCoupon = double.tryParse(coupon.amount ?? '0') ?? 0;
      }

      // Applica il coupon
      _scontrinoCorrente.couponCode = codice;
      _scontrinoCorrente.couponSconto = scontoCoupon;
      _scontrinoCorrente.calcolaTotale();

      AppLogger().i(
        '✅ Coupon applicato: $codice - Sconto: €${scontoCoupon.toStringAsFixed(2)}',
      );
      return true;
    } catch (e) {
      AppLogger().e('❌ Errore applicazione coupon', e);
      return false;
    }
  }

  /// Rimuove il coupon applicato
  void rimuoviCoupon() {
    _scontrinoCorrente.couponCode = null;
    _scontrinoCorrente.couponSconto = 0.0;
    _scontrinoCorrente.calcolaTotale();
    AppLogger().d('🗑️ Coupon rimosso');
  }

  /// Sospende lo scontrino corrente
  void sospendiScontrino() {
    if (_scontrinoCorrente.isVuoto) {
      AppLogger().w('⚠️ Impossibile sospendere: scontrino vuoto');
      return;
    }

    _scontrinoCorrente.stato = 'sospeso';
    _scontriniSospesi.add(_scontrinoCorrente);
    AppLogger().i('⏸️ Scontrino sospeso - ID: ${_scontrinoCorrente.id}');

    // Crea un nuovo scontrino
    _nuovoScontrino();
  }

  /// Riprende uno scontrino sospeso
  void riprendiScontrino(int index) {
    if (index < 0 || index >= _scontriniSospesi.length) {
      AppLogger().w('⚠️ Indice scontrino sospeso non valido');
      return;
    }

    // Se lo scontrino corrente non è vuoto, lo sospende prima
    if (!_scontrinoCorrente.isVuoto) {
      sospendiScontrino();
    }

    // Riprende lo scontrino sospeso
    _scontrinoCorrente = _scontriniSospesi.removeAt(index);
    _scontrinoCorrente.stato = 'aperto';

    // Ripristina i dati cliente
    _clienteNome = _scontrinoCorrente.clienteNome;
    _clienteEmail = _scontrinoCorrente.clienteEmail;
    _clienteTelefono = _scontrinoCorrente.clienteTelefono;

    AppLogger().i('▶️ Scontrino ripreso - ID: ${_scontrinoCorrente.id}');
  }

  /// Elimina uno scontrino sospeso
  void eliminaScontrinoSospeso(int index) {
    if (index >= 0 && index < _scontriniSospesi.length) {
      final scontrino = _scontriniSospesi.removeAt(index);
      AppLogger().d('🗑️ Scontrino sospeso eliminato - ID: ${scontrino.id}');
    }
  }

  /// Verifica disponibilità stock prima di aggiungere
  /// Restituisce null se disponibile, altrimenti il messaggio di errore
  String? verificaDisponibilitaStock(
    ElementoCassa elemento,
    int quantitaRichiesta,
  ) {
    // Trova quantità già nel carrello
    int quantitaInCarrello = 0;
    final rigaEsistente = _trovaRigaEsistente(
      elemento,
      tipoMovimento: TipoRigaCassa.vendita,
    );
    if (rigaEsistente != null) {
      quantitaInCarrello = rigaEsistente.quantita;
    }

    final quantitaTotale = quantitaInCarrello + quantitaRichiesta;
    final stockDisponibile = elemento.quantitaStock;

    if (quantitaTotale > stockDisponibile) {
      return 'Stock insufficiente. Disponibili: $stockDisponibile, Richiesti: $quantitaTotale';
    }

    return null; // Disponibile
  }

  /// Aggiunge elemento con controllo stock
  /// Restituisce un messaggio di errore se fallisce, null se successo
  String? aggiungiElementoConControlloStock(
    ElementoCassa elemento, {
    int quantita = 1,
    TipoRigaCassa tipoMovimento = TipoRigaCassa.vendita,
  }) {
    if (tipoMovimento == TipoRigaCassa.vendita) {
      final errore = verificaDisponibilitaStock(elemento, quantita);
      if (errore != null) {
        AppLogger().w('⚠️ $errore');
        return errore;
      }
    }

    aggiungiElemento(
      elemento,
      quantita: quantita,
      tipoMovimento: tipoMovimento,
    );
    return null;
  }

  /// Imposta le note per una riga
  void setNoteRiga(int index, String? note) {
    if (index >= 0 && index < _scontrinoCorrente.righe.length) {
      _scontrinoCorrente.righe[index].note = note;
    }
  }

  /// Imposta le note dello scontrino
  void setNote(String? note) {
    _scontrinoCorrente.note = note;
  }

  /// Imposta l'aliquota IVA
  void setAliquotaIva(double aliquota) {
    _scontrinoCorrente.aliquotaIva = aliquota.clamp(0, 100);
    _scontrinoCorrente.calcolaTotale();
  }
}
