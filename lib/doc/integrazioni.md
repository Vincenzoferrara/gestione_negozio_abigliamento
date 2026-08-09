# Integrazioni

## Supportate

- WooCommerce
- MGWS
- Smartcard NFC/USB
- CalDAV
- RFID
- Provider IA configurabili

## Flusso backend

- I provider diretti dell'app sono solo WooCommerce e MGWS
- WooCommerce resta il canale diretto per catalogo, ordini ecommerce nativi, clienti e funzioni Woo standard
- MGWS gestisce checkout POS, stock gestionale, carico rapido, fornitori, riordino, ordini fornitore, ricezione/convalida, movimenti, inventario fisico e loyalty v1
- La cassa invia `POST /wp-json/mgws/v1/pos/checkout` con righe vendita, righe reso, cliente, metodi di pagamento, totali e meta
- MGWS crea l'ordine WooCommerce, registra i movimenti in `mg_stock_moves`, aggiorna `mg_stock_levels` e restituisce `order_id` o `woo_order_id`
- `mg_stock_levels` e la sorgente autorevole dello stock; lo stock WooCommerce e una proiezione sincronizzata
- L'ID ordine WooCommerce restituito dal checkout e il riferimento ordine della vendita POS; meta ordine MGWS e `mg_stock_moves` conservano l'audit operativo
- Nel flusso creazione o modifica prodotto, l'app puo chiamare `PUT /wp-json/mgws/v1/inventory/stock/reconcile` dopo il salvataggio WooCommerce per impostare lo stock gestionale totale finale con motivo auditato.
- `InventoryGlobal.reconcileInventory(fixDiscrepancies)` confronta WooCommerce e MGWS e produce proposte; non corregge stock in automatico. Le correzioni operative passano da conte fisiche approvate o da endpoint MGWS di mutazione validati.
- L'app non richiama direttamente plugin terzi come ATUM o myCred; se un sito li usa, la scelta resta interna a MGWS

## MGWS v1 implementato

- POS: `POST /wp-json/mgws/v1/pos/checkout` e registrato e crea ordini WooCommerce con audit stock
- Idempotenza POS: `idempotency_key` nel payload e la chiave primaria; in assenza, MGWS usa il meta `_id_scontrino_locale`; senza chiave il checkout resta compatibile ma non ha garanzia di replay
- Inventario in lettura: `inventory/status`, `inventory/stock/product/{productId}`, `inventory/stock/all`, `inventory/statistics` e `inventory/low-stock`
- Inventario operativo legacy: `POST /wp-json/mgws/v1/inventory/stock/sync` sincronizza stock WooCommerce verso `mg_stock_levels`, `PUT /wp-json/mgws/v1/inventory/stock/reconcile` registra una rettifica motivata e `POST /wp-json/mgws/v1/inventory/rfid/scan` risolve tag o barcode senza mutare stock
- Carico rapido: `POST /wp-json/mgws/v1/inventory/quick-load` riceve prodotto o variante, quantita positiva, motivo, nota opzionale e chiave idempotente. Non accetta come requisito fornitore, ordine, fattura o DDT. Crea un movimento `load` auditato solo dopo conferma utente e risposta MGWS valida.
- Fornitori: le rotte supplier MGWS gestiscono elenco, dettaglio, creazione, aggiornamento, inattivazione e cancellazione protetta. Sono stock-neutral.
- Riordino: le rotte reorder MGWS leggono regole e suggerimenti da sottoscorta, permettono defer/snooze e creano bozze ordine quando richiesto. Non mutano stock.
- Ordini fornitore: le rotte purchase-order MGWS gestiscono bozze, righe prodotto/variante, stato, date, costi e cancellazione. Ordini e righe restano stock-neutral fino alla ricezione convalidata.
- Ricezione/convalida: le rotte receipt MGWS gestiscono bozze, righe ricevute, respinte, backorder, motivi e `convalida`. Solo la convalida/post cambia `mg_stock_levels`; l'idempotenza impedisce doppi carichi con la stessa richiesta.
- Movimenti: le rotte movement MGWS leggono il ledger autorevole `mg_stock_moves`, con filtri e dettaglio. Sono read-only e non fabricano movimenti derivati.
- Conteggi fisici MGWS: le rotte `count-sessions` gestiscono creazione, elenco, dettaglio, patch, righe, discrepanze e approvazione. Le righe possono risolvere un barcode/tag gia noto ma restano bozze e non modificano stock.
- L'approvazione di una sessione applica solo le discrepanze auditabili a `mg_stock_levels`, crea movimenti `adjust` collegati alla sessione e alla riga, e rende la sessione immutabile.
- Le griglie Flutter per fornitori, riordino, ordini, ricezioni, movimenti e conte usano la `DataGridView` condivisa sotto `lib/reuse_class/datagridview/`.
- Loyalty: stato servizio, scheda cliente, lookup carta, lookup email, creazione o modifica carta, cancellazione carta, aggiunta punti, sottrazione punti, storico e statistiche
- Cancellare una carta loyalty rimuove il numero carta dal conto MGWS, mantiene conto cliente e storico movimenti, e risponde `404` se la carta manca
- Lo storico loyalty e append-only, paginato e ordinato dal movimento piu recente

## MGWS v1 compatibilita

- Le richieste POS senza chiave idempotente sono accettate per compatibilita, ma non proteggono da invii duplicati
- Le operazioni inventario richiedono payload validi e restituiscono errori MGWS visibili nell'app quando il backend rifiuta o non completa la richiesta

## Sicurezza MGWS

- Le rotte richiedono utente WordPress autenticato; assenza login restituisce `401`
- Le rotte richiedono capability MGWS o capability amministrative WooCommerce/WordPress secondo il contratto route; permessi insufficienti restituiscono `403`
- Parametri numerici, lookup carta/email, payload inventario e chiave idempotente hanno validazione lato REST e nei handler
- Gli errori pubblici non devono esporre SQL, token, password, path locali o dati di altri clienti

## Login

- JWT
- WooCommerce API con Consumer Key e Secret
- Smartcard
