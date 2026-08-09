# Guida Utente

## A cosa serve

L'app gestisce le attivita quotidiane di un negozio di abbigliamento: cassa, prodotti, ordini, clienti, carte fedelta, report e configurazione.

## Accesso

1. Inserisci l'URL del sito
2. Scegli il metodo di login
3. Usa JWT, WooCommerce API o smartcard
4. Se lavori in locale, attiva l'opzione per localhost

## Aree principali

- `Cassa` - vendita e chiusura ordine
- `Prodotti` - catalogo e inventario
- `Inventario MGWS` - carichi, riordini, ordini fornitore, ricezioni, movimenti e conte fisiche
- `Nuovo Prodotto` - inserimento articoli
- `Coupon` - sconti e promozioni
- `Ordini` - gestione ordini
- `Clienti` - anagrafiche clienti
- `Carte Fedelta` - punti e fidelizzazione
- `Report` - etichette e stampe
- `Dashboard` - metriche e grafici
- `Impostazioni` - preferenze dell'app
- `Aggiornamenti` - controllo e installazione aggiornamenti desktop

## Prodotti

La schermata `Prodotti` e una postazione operativa per consultare e gestire il catalogo.

- La barra comandi in alto permette di cercare, scegliere campo e operatore del filtro, inserire il valore, aggiungere filtri, cancellare i filtri, nascondere gli esauriti, ordinare la lista, importare/esportare CSV, scegliere le colonne e aggiornare la lista.
- I filtri attivi compaiono come chip rimovibili sotto i comandi; la selezione prodotti mostra il numero di righe selezionate.
- La griglia mostra anteprima, dati principali, prezzo, disponibilita, quantita, varianti, stato e marca in base alle colonne visibili.
- Su desktop la schermata e divisa in elenco prodotti a sinistra e dettaglio a destra; su schermi piccoli il dettaglio si apre in una pagina dedicata.
- Selezionando piu prodotti compare la barra azioni di massa per deselezionare o eliminare gli elementi selezionati.
- Il pannello dettaglio mostra immagine, galleria, dati prodotto, modifica rapida, filtri varianti, lista varianti e foto associate alle varianti.
- `Modifica rapida` consente di aggiornare categorie, tag, stato e, per singolo prodotto, prezzo e quantita delle varianti; in selezione multipla sono disponibili categorie, tag, stato ed eliminazione secondo le impostazioni.
- In creazione o modifica prodotto, la sezione `Inventario MGWS` permette di abilitare una rettifica auditata dopo il salvataggio: inserisci lo stock MGWS totale finale e un motivo obbligatorio; l'app registra il valore con `Reconcile stock` solo se il prodotto e stato salvato con un `product_id` valido.

## Inventario MGWS

La schermata `Inventario MGWS` e la postazione operativa per lo stock gestionale. MGWS resta la sorgente autorevole di stock, riordini, ricezioni, movimenti e conte fisiche; l'app mostra e invia solo dati MGWS o WooCommerce, senza chiamare plugin WordPress terzi.

- `Carico rapido` aggiunge stock a un prodotto o variante con ID prodotto, eventuale variante o barcode, quantita positiva, motivo e nota opzionale. Non richiede fornitore, ordine, fattura o DDT. Prima dell'invio mostra una conferma; dopo il successo mostra il movimento MGWS e lo stock prima/dopo.
- `Fornitori` gestisce anagrafica, modifica, stato attivo e cancellazione protetta. Queste azioni non modificano stock.
- `Riordino` legge suggerimenti e regole MGWS da sottoscorta, permette di rimandare un suggerimento o creare una bozza di ordine fornitore. Anche questo flusso e stock-neutral.
- `Ordini Fornitore` crea e aggiorna bozze, righe prodotto/variante, quantita ordinate, costo, date previste e stato ordine. Un ordine fornitore non aumenta lo stock finche non viene ricevuto e convalidato.
- `Ricezione/Convalida` registra ricevuto, respinto, backorder e note sulle righe ordine. La bozza di ricezione resta stock-neutral; lo stock cambia solo con `Convalida`, tramite movimento auditato e idempotente MGWS.
- `Movimenti` mostra il ledger MGWS in sola lettura, con filtri e dettaglio su stock prima/dopo, delta, fonte, operatore, motivo e link al documento sorgente. Non crea e non modifica movimenti.
- `Inventario fisico` gestisce sessioni di conta, righe manuali o barcode/tag, discrepanze e approvazione. Le bozze non cambiano stock; solo l'approvazione registra rettifiche `adjust` auditabili e rende la sessione pubblicata non modificabile.
- Le tabelle operative di fornitori, riordino, ordini, ricezioni, movimenti e conte usano la `DataGridView` condivisa del progetto.
- La riconciliazione globale di inventario e solo una proposta di correzione: anche quando viene richiesta una correzione, non aggiorna stock in automatico. Le rettifiche reali passano dal flusso approvato di inventario fisico o da un movimento MGWS validato.

## Consigli rapidi

- Usa `Impostazioni` per i parametri di immagini, IA, RFID e shortcut
- Nelle immagini prodotto l'app carica il file originale; se le dimensioni note superano le soglie configurate, nella libreria media compare un badge informativo accanto alla foto
- Se una pagina richiede accesso, fai login prima
- Per cassa, inventario e loyalty, il backend passa da MGWS
- Su Windows e Linux, usa `Aggiornamenti` per verificare nuove versioni desktop; quando installi un update l'app si chiude, affida l'installazione al processo Velopack e si riavvia automaticamente
- Dopo un aggiornamento desktop, l'app mostra una volta le note della release installata
