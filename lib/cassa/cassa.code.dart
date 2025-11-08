// cassa.code.dart

import '../prodotti/class_prodotti.dart';
import 'class_scontrino.dart';
import '../log_viewer/app_logger.dart';
import '../login/jwt_api/adapter/platform_manager.dart';

/// Controller per la gestione della cassa
class CassaController {
  Scontrino _scontrinoCorrente;
  List<Prodotto_global> _prodotti = [];
  List<Prodotto_global> _prodottiFiltrati = [];
  Prodotto_global? _prodottoSelezionato;
  Variante_product_global? _varianteSelezionata;
  String _filtroRicerca = '';
  int _quantitaDaAggiungere = 1;

  // Cliente selezionato (opzionale)
  String? _clienteNome;
  String? _clienteEmail;
  String? _clienteTelefono;

  CassaController()
      : _scontrinoCorrente = Scontrino(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          data: DateTime.now(),
        );

  // Getters
  Scontrino get scontrinoCorrente => _scontrinoCorrente;
  List<Prodotto_global> get prodotti => _prodottiFiltrati;
  Prodotto_global? get prodottoSelezionato => _prodottoSelezionato;
  Variante_product_global? get varianteSelezionata => _varianteSelezionata;
  String get filtroRicerca => _filtroRicerca;
  int get quantitaDaAggiungere => _quantitaDaAggiungere;
  String? get clienteNome => _clienteNome;
  String? get clienteEmail => _clienteEmail;
  String? get clienteTelefono => _clienteTelefono;

  bool get hasProdottoSelezionato => _prodottoSelezionato != null;
  bool get hasVarianteSelezionata => _varianteSelezionata != null;
  bool get hasFiltroAttivo => _filtroRicerca.isNotEmpty;
  bool get hasCliente => _clienteNome != null;

  /// Carica tutti i prodotti pubblicati da WooCommerce
  Future<void> caricaProdotti() async {
    try {
      AppLogger().i('🔄 Caricamento prodotti per la cassa...');

      // Carica tutti i prodotti pubblicati (con paginazione)
      final List<Prodotto_global> prodottiCaricati = [];
      int currentPage = 1;
      bool hasMore = true;
      const int perPage = 100;

      while (hasMore) {
        final batch = await PlatformManager.prodotti.getProducts(
          page: currentPage,
          perPage: perPage,
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
      for (var prodotto in prodottiCaricati) {
        if (prodotto.hasVarianti && (prodotto.id ?? 0) > 0) {
          try {
            final varianti = await PlatformManager.varianti.getAllVariations(prodotto.id);
            // Crea una copia del prodotto con le varianti
            final index = prodottiCaricati.indexOf(prodotto);
            prodottiCaricati[index] = Prodotto_global(
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
            AppLogger().d('✅ Caricate ${varianti.length} varianti per prodotto ${prodotto.nome}');
          } catch (e) {
            AppLogger().w('⚠️ Errore caricamento varianti per prodotto ${prodotto.id}: $e');
          }
        }
      }

      _prodotti = prodottiCaricati;
      _prodottiFiltrati = List.from(_prodotti);

      AppLogger().i('✅ Caricati ${_prodotti.length} prodotti per la cassa');
    } catch (e) {
      AppLogger().e('❌ Errore durante il caricamento dei prodotti: $e');
      rethrow;
    }
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

  /// Applica il filtro ai prodotti
  void _applicaFiltro() {
    if (_filtroRicerca.isEmpty) {
      _prodottiFiltrati = List.from(_prodotti);
      return;
    }

    _prodottiFiltrati = _prodotti.where((prodotto) {
      final nomeLower = prodotto.nome?.toLowerCase() ?? '';
      final skuLower = prodotto.sku?.toLowerCase() ?? '';
      //final categoriaLower = prodotto.categoria.toLowerCase();

      return nomeLower.contains(_filtroRicerca) ||
          skuLower.contains(_filtroRicerca) /* ||
          categoriaLower.contains(_filtroRicerca) */;
    }).toList();
  }

  /// Seleziona un prodotto
  void selezionaProdotto(Prodotto_global prodotto) {
    _prodottoSelezionato = prodotto;
    _varianteSelezionata = null;

    // Se il prodotto non ha varianti, è pronto per essere aggiunto
    if (!prodotto.hasVarianti) {
      //AppLogger.debug('Prodotto selezionato: ${prodotto.nome}');
    }
  }

  /// Seleziona una variante
  void selezionaVariante(Variante_product_global? variante) {
    _varianteSelezionata = variante;
    //AppLogger.debug('Variante selezionata: ${variante?.nomeVisualizzabile ?? "nessuna"}');
  }

  /// Imposta la quantità da aggiungere
  void setQuantita(int quantita) {
    if (quantita > 0) {
      _quantitaDaAggiungere = quantita;
    }
  }

  /// Incrementa la quantità da aggiungere
  void incrementaQuantita() {
    _quantitaDaAggiungere++;
  }

  /// Decrementa la quantità da aggiungere
  void decrementaQuantita() {
    if (_quantitaDaAggiungere > 1) {
      _quantitaDaAggiungere--;
    }
  }

  /// Aggiunge il prodotto/variante selezionato allo scontrino
  bool aggiungiAlCarrello() {
    if (_prodottoSelezionato == null) {
      //AppLogger.warning('Nessun prodotto selezionato');
      return false;
    }

    // Se il prodotto ha varianti ma nessuna è selezionata, errore
    if (_prodottoSelezionato!.hasVarianti && _varianteSelezionata == null) {
      //AppLogger.warning('Seleziona una variante prima di aggiungere');
      return false;
    }

    // Controlla se la riga esiste già nello scontrino
    final rigaEsistente = _trovaRigaEsistente();

    if (rigaEsistente != null) {
      // Incrementa la quantità della riga esistente
      rigaEsistente.aggiornaQuantita(rigaEsistente.quantita + _quantitaDaAggiungere);
      _scontrinoCorrente.calcolaTotale();
    } else {
      // Crea una nuova riga
      final prezzo = _varianteSelezionata?.prezzoEffettivo ??
                     _prodottoSelezionato!.prezzoEffettivo;

      final riga = RigaScontrino(
        prodotto: _prodottoSelezionato!,
        variante: _varianteSelezionata,
        quantita: _quantitaDaAggiungere,
        subtotale: prezzo * _quantitaDaAggiungere,
      );

      _scontrinoCorrente.aggiungiRiga(riga);
    }

    // Reset selezione
    _quantitaDaAggiungere = 1;
    _prodottoSelezionato = null;
    _varianteSelezionata = null;

    //AppLogger.info('Prodotto aggiunto al carrello. Totale righe: ${_scontrinoCorrente.righe.length}');
    return true;
  }

  /// Trova una riga esistente nello scontrino con stesso prodotto/variante
  RigaScontrino? _trovaRigaEsistente() {
    for (final riga in _scontrinoCorrente.righe) {
      if (riga.prodotto.id == _prodottoSelezionato!.id) {
        // Se entrambi non hanno varianti selezionate, è una corrispondenza
        if (_varianteSelezionata == null && riga.variante == null) {
          return riga;
        }
        // Se entrambi hanno la stessa variante, è una corrispondenza
        if (_varianteSelezionata != null &&
            riga.variante != null &&
            riga.variante!.id == _varianteSelezionata!.id) {
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
  void aggiornaQuantitaRiga(int index, int nuovaQuantita) {
    if (index >= 0 && index < _scontrinoCorrente.righe.length) {
      if (nuovaQuantita <= 0) {
        rimuoviRiga(index);
      } else {
        _scontrinoCorrente.righe[index].aggiornaQuantita(nuovaQuantita);
        _scontrinoCorrente.calcolaTotale();
      }
    }
  }

  /// Incrementa quantità di una riga dello scontrino
  void incrementaQuantitaRiga(int index) {
    if (index >= 0 && index < _scontrinoCorrente.righe.length) {
      _scontrinoCorrente.righe[index].incrementaQuantita();
      _scontrinoCorrente.calcolaTotale();
    }
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
    _scontrinoCorrente.reset();
    _prodottoSelezionato = null;
    _varianteSelezionata = null;
    _quantitaDaAggiungere = 1;
    //AppLogger.info('Carrello svuotato');
  }

  /// Imposta i dati del cliente
  void setCliente({String? nome, String? email, String? telefono}) {
    _clienteNome = nome;
    _clienteEmail = email;
    _clienteTelefono = telefono;

    _scontrinoCorrente.clienteNome = nome;
    _scontrinoCorrente.clienteEmail = email;
    _scontrinoCorrente.clienteTelefono = telefono;
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

  /// Completa la vendita creando un ordine su WooCommerce
  Future<bool> completaVendita() async {
    if (_scontrinoCorrente.isVuoto) {
      AppLogger().w('⚠️ Impossibile completare: scontrino vuoto');
      return false;
    }

    try {
      AppLogger().i('💰 Inizio completamento vendita - Totale: €${_scontrinoCorrente.totale.toStringAsFixed(2)}');

      // Prepara i line_items per l'ordine
      final lineItems = _scontrinoCorrente.righe.map((riga) {
        final item = <String, dynamic>{
          'product_id': riga.prodotto.id,
          'quantity': riga.quantita,
        };

        // Aggiungi variation_id se è una variante
        if (riga.variante != null) {
          item['variation_id'] = riga.variante!.id;
        }

        return item;
      }).toList();

      // Prepara i dati dell'ordine per WooCommerce
      final orderData = <String, dynamic>{
        'status': 'completed', // Ordine già pagato e completato
        'payment_method': _scontrinoCorrente.metodoPagamento,
        'payment_method_title': _getMetodoPagamentoTitolo(_scontrinoCorrente.metodoPagamento),
        'set_paid': true, // Marca come pagato
        'line_items': lineItems,
        'meta_data': [
          {
            'key': '_punto_vendita',
            'value': 'Cassa POS',
          },
          {
            'key': '_id_scontrino_locale',
            'value': _scontrinoCorrente.id,
          },
          {
            'key': '_data_vendita',
            'value': _scontrinoCorrente.data.toIso8601String(),
          },
        ],
      };

      // Aggiungi dati cliente se presenti
      if (_clienteNome != null && _clienteNome!.isNotEmpty) {
        orderData['billing'] = <String, dynamic>{
          'first_name': _clienteNome,
          'last_name': '', // Non richiesto
        };

        if (_clienteEmail != null && _clienteEmail!.isNotEmpty) {
          orderData['billing']['email'] = _clienteEmail;
        }

        if (_clienteTelefono != null && _clienteTelefono!.isNotEmpty) {
          orderData['billing']['phone'] = _clienteTelefono;
        }
      }

      // Aggiungi note se presenti
      if (_scontrinoCorrente.note != null && _scontrinoCorrente.note!.isNotEmpty) {
        orderData['customer_note'] = _scontrinoCorrente.note;
      }

      // Crea l'ordine su WooCommerce usando PlatformManager
      AppLogger().d('📤 Invio ordine a WooCommerce...');
      final order = await PlatformManager.ordini.createOrder(orderData);

      final orderId = order.id;
      AppLogger().i('✅ Ordine creato con successo - ID WooCommerce: $orderId');

      // Aggiorna lo stato dello scontrino locale
      _scontrinoCorrente.stato = 'pagato';

      // Crea un nuovo scontrino per la prossima vendita
      _nuovoScontrino();

      return true;
    } catch (e, stackTrace) {
      AppLogger().e('❌ Errore durante il completamento della vendita', e, stackTrace);
      return false;
    }
  }

  /// Ottiene il titolo del metodo di pagamento in formato leggibile
  String _getMetodoPagamentoTitolo(String metodo) {
    switch (metodo) {
      case 'contanti':
        return 'Pagamento in Contanti';
      case 'carta':
        return 'Carta di Credito';
      case 'bancomat':
        return 'Bancomat/POS';
      default:
        return 'Altro';
    }
  }

  /// Crea un nuovo scontrino vuoto
  void _nuovoScontrino() {
    _scontrinoCorrente = Scontrino(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: DateTime.now(),
    );
    _prodottoSelezionato = null;
    _varianteSelezionata = null;
    _quantitaDaAggiungere = 1;
    _clienteNome = null;
    _clienteEmail = null;
    _clienteTelefono = null;
  }

  /// Ricerca prodotto per SKU o barcode
  Prodotto_global? ricercaPerSku(String sku) {
    try {
      return _prodotti.firstWhere(
        (p) => (p.sku?.toLowerCase() ?? '') == sku.toLowerCase(),
      );
    } catch (e) {
      //AppLogger.debug('Prodotto con SKU "$sku" non trovato');
      return null;
    }
  }
}
