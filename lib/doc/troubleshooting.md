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
- Le operazioni di magazzino (carico, rettifica, spostamento) richiedono capability MGWS coerenti con la rotta
- Il carico rifiuta quantita non positive, motivo vuoto, prodotto mancante o capability insufficiente; non chiedere fornitore, ordine, fattura o DDT per risolvere questi errori
- Lo spostamento usa una rotta (`stock/move`) diversa dalla rettifica (`stock/reconcile`). Se compaiono errori di capability solo sullo spostamento, non e' un problema della rettifica
- Se una ricezione non aggiorna stock, controlla che sia stata eseguita `Convalida`: la bozza di ricezione e stock-neutral
- Se un conteggio fisico non aggiorna stock, controlla che la sessione sia stata approvata: righe e bozze sono stock-neutral
- Il ledger di `Movimenti` non si modifica: l'app non ha una rotta che lo faccia e non deve costruirne una. Se un movimento e' sbagliato, l'unica correzione e' l'annullamento, che registra un movimento nuovo: contromovimento con `stock/reconcile` quando cambia il totale, spostamento al contrario con `stock/move` quando la merce cambia solo magazzino
- `Annulla` su un movimento resta spento per gli spostamenti e si blocca per prodotto se lo stock attuale non coincide piu' con lo `stock_after` del movimento: in entrambi i casi la schermata spiega il motivo accanto al pulsante, non in un errore generico. Non e' un bug, e' il controllo che impedisce di azzerare un movimento successivo
- Se una riga di `Movimenti` mostra un solo pezzo di un'operazione con molti prodotti, il backend ha tagliato la risposta: MGWS pagina e non filtra per documento, quindi stringi i filtri per data o prodotto. Il pannello avvisa quando la risposta e' incompleta
- Se la scheda di un movimento non ha una data "ultima modifica" distinta dalla data del movimento, e' normale: il ledger non si modifica, quindi l'ultima modifica e' per definizione il movimento piu' recente del gruppo ed e' ricavata da lì
- La colonna operatore mostra un identificativo numerico (`operator_user_id`): MGWS non manda il nome e non c'e' una rotta `users/{id}` collegata, quindi l'app non lo indovina
- `POST /inventory/stock/sync` e `PUT /inventory/stock/reconcile` sono operative e richiedono payload validi, utente autenticato e capability adeguate
- `InventoryGlobal.reconcileInventory(fixDiscrepancies)` produce proposte e non corregge stock in automatico
- `POST /inventory/rfid/scan` e resolve-only: risolve tag o barcode e non crea movimenti o incrementi stock impliciti
- Se una lettura stock prodotto restituisce `404 mgws_product_not_found`, verifica che il prodotto WooCommerce esista
- Se una lettura o mutazione restituisce `403`, verifica le capability WordPress dell'utente usato dall'app

## Backend MGWS non disponibile

- **Sintomo tipico**: `Crea turno` in Cassa, checkout, dipendenti, inventario o loyalty restituiscono tutti "Backend MGWS non disponibile" anche se il login è riuscito e i prodotti WooCommerce si caricano.
- **Diagnosi veloce**: se nel log del container WordPress non compare alcuna richiesta a `/wp-json/mgws/*`, il problema è lato app: la richiesta non parte, quindi non è un problema di plugin, capability o rete. Con una riga per rotta nel log del container si distingue subito "non parte" da "parte e viene respinta".
- **Causa**: i client MGWS devono prendere base URL e credenziali da `WooConnect`, l'unico owner dei connettori. Se un client MGWS istanzia un connettore proprio, la richiesta viaggia con credenziali diverse da quelle della sessione attiva e non raggiunge mai il plugin.
- La disponibilità si ricalcola dopo ogni connessione riuscita, in tutte le modalità e dopo l'auto-connessione. Se un modulo MGWS resta chiuso, verificare che `refreshMgwsAvailability()` venga invocato anche dal ramo di login usato.
- In modalità Consumer Key/Secret le chiavi WooCommerce autenticano solo le rotte `wc/`: MGWS risponde 401 e l'app lo degrada correttamente come non disponibile. Per usare MGWS serve un login JWT o WordPress.
- Se il log riporta 200 ma il modulo resta chiuso, il servizio è spento lato server: le rotte rispondono 200 anche con `enabled: false`. Controllare che le tabelle MGWS siano installate e che l'utente abbia le capability di lettura stock.

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
