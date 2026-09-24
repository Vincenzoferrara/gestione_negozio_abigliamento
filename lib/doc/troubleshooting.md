# Troubleshooting

## Login fallito

- Verifica che l'URL sia corretto
- Prova JWT o WooCommerce API in base al backend
- Controlla che il sito risponda e che il plugin atteso sia attivo

## Nessun prodotto visibile

- Controlla che WooCommerce abbia prodotti pubblicati
- Verifica eventuali filtri salvati
- Controlla la connessione al backend

## Inventario MGWS non disponibile

- MGWS deve essere raggiungibile e autenticato
- Le letture inventario dipendono dalle tabelle MGWS e dalle capability di lettura stock
- Le operazioni di carico rapido, fornitori, riordino, ordini fornitore, ricezione/convalida, movimenti e conte fisiche richiedono capability MGWS coerenti con la rotta
- `Carico rapido` rifiuta quantita non positive, motivo vuoto, prodotto mancante o capability insufficiente; non chiedere fornitore, ordine, fattura o DDT per risolvere questi errori
- Se una ricezione non aggiorna stock, controlla che sia stata eseguita `Convalida`: la bozza di ricezione e stock-neutral
- Se un conteggio fisico non aggiorna stock, controlla che la sessione sia stata approvata: righe e bozze sono stock-neutral
- `Movimenti` e solo lettura; se il ledger e vuoto o filtrato, non deve creare movimenti nuovi
- `POST /inventory/stock/sync` e `PUT /inventory/stock/reconcile` sono operative e richiedono payload validi, utente autenticato e capability adeguate
- `InventoryGlobal.reconcileInventory(fixDiscrepancies)` produce proposte e non corregge stock in automatico
- `POST /inventory/rfid/scan` e resolve-only: risolve tag o barcode e non crea movimenti o incrementi stock impliciti
- Se una lettura stock prodotto restituisce `404 mgws_product_not_found`, verifica che il prodotto WooCommerce esista
- Se una lettura o mutazione restituisce `403`, verifica le capability WordPress dell'utente usato dall'app

## Backend MGWS non disponibile (flag stale)

- **Causa**: il flag `mgwsAvailability.isAvailable` viene calcolato all'avvio/login. Se a quel momento il sito non era ancora connesso (es. check partito troppo presto nella race di auto-connect), il flag resta `false` per tutta la sessione pur essendo il backend perfettamente raggiungibile.
- **Sintomo tipico**: `Crea turno` in Cassa, checkout, dipendenti, inventario o loyalty restituiscono tutti "Backend MGWS non disponibile" anche se il login WordPress è riuscito e i prodotti WooCommerce si caricano.
- **Fix applicata**: ogni chiamata MGWS ora usa `mgwsAvailability.ensureAvailable()` che, se il flag è stale, esegue un refresh live (`/inventory/status` + `/loyalty/status`) prima di decidere. Il flag si auto-ripara al primo accesso reale al modulo.
- **Diagnosi rapida**: nel log di avvio cerca `MGWS inventory non disponibile: Exception: Nessun sito connesso` — conferma che il check è partito prima della connessione.

## Checkout cassa fallito

- Verifica che MGWS sia raggiungibile e autenticato
- Controlla che il payload POS sia valido
- Usa una `idempotency_key` stabile per ogni scontrino locale; in alternativa MGWS usa il meta `_id_scontrino_locale` come fallback
- `409 mgws_idempotency_conflict` indica stessa chiave con payload diverso: non ritentare cambiando dati senza generare una nuova chiave operativa
- `409 mgws_idempotency_in_progress` indica una richiesta identica gia in corso: attendi il completamento e ripeti lo stesso payload
- Se MGWS restituisce una failure salvata dopo prenotazione idempotente, la stessa chiave ripete quella failure e richiede intervento operativo lato MGWS

## Cassa: ricerca prodotti ON-DEMAND (niente catalogo al avvio)

- Dal 2026-09-23 la cassa NON carica piu il catalogo completo (prodotti + varianti) all'avvio: l'eager-load veniva eseguito per pagine intere e rallentava il modulo e disturbava la race di connessione MGWS.
- La cassa popola la lista solo su richiesta:
  - **Scanner/barra di ricerca**: `ricercaPerBarcode()` interroga WooCommerce on-demand (`findProductByBarcodeInternoExact`, fallback `searchProducts`) e materializza solo la variante (o il prodotto semplice) che corrisponde.
  - **Digitazione**: `setFiltroRicerca()` con debounce 400 ms lancia `_ricercaOnDemand()` (barcode esatto + `searchProducts`, con `getAllVariations` solo per i prodotti candidati variabili).
  - **"Aggiungi esistente"**: il picker passa le varianti selezionate (o i prodotti semplici) e la cassa li recupera per ID (`getVariationById` / `getProductById`) senza passare dal catalogo.
- Se una ricerca non trova nulla, la lista resta vuota finche il filtro non cambia: non e un bug, e il comportamento a richiesta.
- `getAllVariations` viene chiamato solo quando serve (1-2 prodotti), non per tutto il catalogo.

## Cassa: errore pagination disposed dopo aggiunta prodotto

- **Sintomo**: dopo aver aggiunto un prodotto dalla selezione prodotti in Cassa compare `A GlobalPaginationController<ProdottoGlobal> was used after being disposed`.
- **Causa**: la pagina `Gestisci prodotti` in modalita cassa puo essere chiusa mentre il caricamento progressivo dei prodotti o il prefetch varianti e ancora in corso; i callback tardivi non devono piu toccare il controller di paginazione gia disposto.
- **Fix applicata**: `ProdottiGestisciPageState` usa un flag `_disposed` e guardie `_alive` su caricamento prodotti, callback `onProgress`, prefetch finestra, scroll infinito, cambio pagina e cambio dimensione pagina.

## Loyalty MGWS

- `404 mgws_loyalty_customer_not_found` indica cliente WordPress/Woo assente o senza conto loyalty quando richiesto dalla rotta
- `404 mgws_loyalty_card_not_found` su cancellazione carta significa che non c'e una carta da rimuovere; la cancellazione non e idempotente
- La cancellazione carta conserva conto cliente e storico punti, quindi lo storico resta la fonte per audit
- `400 mgws_insufficient_points` indica sottrazione punti superiore al saldo disponibile
- `503` sulle rotte loyalty indica storage MGWS non disponibile o tabelle non pronte

## Problemi con immagini

- Verifica che il file originale sia un'immagine supportata da WordPress
- Se compare il badge oltre soglia, controlla le dimensioni configurate in `Impostazioni > Prodotti`
