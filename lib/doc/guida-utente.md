# Guida Utente

## A cosa serve

L'app gestisce le attivita quotidiane di un negozio di abbigliamento: cassa, prodotti, ordini, clienti, carte fedelta, report e configurazione.

## Accesso

1. Inserisci l'URL del sito
2. Scegli il metodo di login
3. Usa JWT, WooCommerce API o smartcard
4. Se lavori in locale, attiva l'opzione per localhost

Su smartphone e schermi stretti il login si apre come schermata a pagina intera, cosi i campi usano tutta la larghezza disponibile. Su schermi grandi resta in una finestra di dialogo sopra l'area principale.

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
- `Dashboard` - analisi vendite, prodotti, ordini, stock e generazione report PDF/CSV
- `Impostazioni` - preferenze dell'app
- `Aggiornamenti` - controllo e installazione aggiornamenti desktop

## Scansione barcode e QR

Le azioni di scansione barcode o QR aprono lo scanner condiviso a schermo intero su smartphone e tablet. La schermata mostra l'inquadratura della fotocamera, l'area di scansione, il pulsante di chiusura e il controllo torcia quando disponibile; il codice rilevato viene restituito al flusso da cui e stata avviata la scansione.

## Prodotti

La schermata `Prodotti` e una postazione operativa per consultare e gestire il catalogo.

- La barra comandi in alto permette di cercare, scegliere campo e operatore del filtro, inserire il valore, aggiungere filtri, cancellare i filtri, nascondere gli esauriti, ordinare la lista, importare/esportare CSV, scegliere le colonne e aggiornare la lista.
- I filtri attivi compaiono come chip rimovibili sotto i comandi; la selezione prodotti mostra il numero di righe selezionate.
- La griglia mostra anteprima, dati principali, prezzo, disponibilita, quantita, varianti, stato e marca in base alle colonne visibili.
- La prima pagina di prodotti compare appena disponibile; le pagine successive continuano a caricarsi in background e una barra sottile indica l'aggiornamento in corso senza coprire la griglia.
- Su desktop la schermata e divisa in elenco prodotti a sinistra e dettaglio a destra; su schermi piccoli il dettaglio si apre in una pagina dedicata.
- Selezionando piu prodotti compare la barra azioni di massa per deselezionare o eliminare gli elementi selezionati.
- Il pannello dettaglio mostra immagine, galleria, dati prodotto, modifica rapida, filtri varianti e lista varianti; l'eventuale foto dedicata resta visibile direttamente nella riga della variante.
- `Modifica rapida` consente di aggiornare categorie, tag, stato e, per singolo prodotto, prezzo e quantita delle varianti; in selezione multipla sono disponibili categorie, tag, stato ed eliminazione secondo le impostazioni.
- Le shortcut configurate in `Impostazioni > Shortcut` sono operative nella griglia e nel dettaglio: modifica rapida, salvataggio, selezione visibile, eliminazione e annullamento/uscita.
- In creazione o modifica prodotto, la sezione `Inventario MGWS` permette di abilitare una rettifica auditata dopo il salvataggio: inserisci lo stock MGWS totale finale e un motivo obbligatorio; l'app registra il valore con `Reconcile stock` solo se il prodotto e stato salvato con un `product_id` valido.

## Inventario MGWS

La schermata `Inventario MGWS` e la postazione operativa per lo stock gestionale. MGWS resta la sorgente autorevole di stock, riordini, ricezioni, movimenti e conte fisiche; l'app mostra e invia solo dati MGWS o WooCommerce, senza chiamare plugin WordPress terzi.

- `Carico rapido` propone magazzino, stanza e motivo predefiniti configurati in `Impostazioni > Inventario`. Il pulsante `Seleziona prodotti` apre il catalogo WooCommerce progressivo con foto di copertina e ricerca per nome, SKU o barcode: i prodotti semplici sono selezionabili direttamente, mentre i prodotti variabili espongono le sole varianti concrete. Puoi scegliere piu righe e assegnare a ciascuna quantita, scaffale e piano/ripiano.
- Magazzino, stanza, scaffale e piano/ripiano sono opzionali e vengono usati solo quando valorizzati. Se non indichi dettagli di ubicazione, MGWS carica la merce sulla giacenza aggregata del primo magazzino valido per la sede autorizzata, senza inventare stanza, scaffale o ripiano. Il flusso non richiede fornitore, ordine, fattura o DDT.
- In `Impostazioni > Inventario`, una lista vuota disattiva il relativo livello di ubicazione: magazzino, stanza, scaffale e ripiano vengono nascosti singolarmente nel `Carico rapido` e non sono inviati a MGWS.
- Prima dell'invio, `Carico rapido` mostra un riepilogo con posizione, motivo, righe e quantita totale. MGWS riceve una richiesta idempotente per riga, in sequenza; se alcune righe falliscono, quelle riuscite restano registrate e l'app conserva solo le righe fallite per un nuovo tentativo.
- `Fornitori` gestisce anagrafica, modifica, stato attivo e cancellazione protetta. Queste azioni non modificano stock.
- `Riordino` legge suggerimenti e regole MGWS da sottoscorta, permette di rimandare un suggerimento o creare una bozza di ordine fornitore. Anche questo flusso e stock-neutral.
- `Ordini Fornitore` crea e aggiorna bozze, righe prodotto/variante, quantita ordinate, costo, date previste e stato ordine. Un ordine fornitore non aumenta lo stock finche non viene ricevuto e convalidato.
- `Ricezione/Convalida` registra ricevuto, respinto, backorder e note sulle righe ordine. La bozza di ricezione resta stock-neutral; lo stock cambia solo con `Convalida`, tramite movimento auditato e idempotente MGWS.
- `Movimenti` mostra il ledger MGWS in sola lettura, con filtri e dettaglio su stock prima/dopo, delta, fonte, operatore, motivo e link al documento sorgente. Non crea e non modifica movimenti.
- `Inventario fisico` gestisce sessioni di conta, righe manuali o barcode/tag, discrepanze e approvazione. Le bozze non cambiano stock; solo l'approvazione registra rettifiche `adjust` auditabili e rende la sessione pubblicata non modificabile.
- Le tabelle operative di fornitori, riordino, ordini, ricezioni, movimenti e conte usano la `DataGridView` condivisa del progetto.
- La riconciliazione globale di inventario e solo una proposta di correzione: anche quando viene richiesta una correzione, non aggiorna stock in automatico. Le rettifiche reali passano dal flusso approvato di inventario fisico o da un movimento MGWS validato.

## Dashboard

La `Dashboard` e la postazione rapida per controllare e analizzare i dati WooCommerce del negozio. Mostra il periodo attivo, vendite, ordini, prodotti, stock, clienti quando disponibili, andamento vendite e accessi ai dettagli gia presenti come top prodotti, performance e analisi ordini.

- Il menu periodo permette di cambiare l'intervallo attivo tra oggi, settimana, mese e anno; la dashboard ricarica i dati per quel periodo.
- Il pannello `Analisi dashboard` riepiloga il filtro attivo e distingue i dati gia analizzabili dai dati che richiedono aggregazioni future.
- Il pannello `Analisi dashboard` adatta disposizione, riepiloghi e pulsante report a layout smartphone, tablet e desktop.
- `Genera report` crea un file PDF o CSV usando il periodo e i dati attualmente caricati nella dashboard.
- Le scelte di export disponibili sono `Dashboard CSV`, `Dashboard PDF`, `Vendite CSV` e `Vendite PDF`.
- I report `Vendite` usano lo stesso periodo della dashboard e includono riepilogo vendite, top prodotti e tendenze disponibili.
- I filtri avanzati per vendite per brand, varianti e attributi non sono ancora controlli attivi nella dashboard: compaiono come capacita mancanti finche non esiste l'aggregazione dati corrispondente.

## Consigli rapidi

- Usa `Impostazioni` per i parametri di inventario, immagini, IA, RFID e shortcut
- Nelle immagini prodotto l'app carica il file originale; se le dimensioni note superano le soglie configurate, nella libreria media compare un badge informativo accanto alla foto
- Se una pagina richiede accesso, fai login prima
- Per cassa, inventario e loyalty, il backend passa da MGWS
- Su Windows e Linux, usa `Aggiornamenti` per verificare nuove versioni desktop; quando installi un update l'app si chiude, affida l'installazione al processo Velopack e si riavvia automaticamente
- Dopo un aggiornamento desktop, l'app mostra una volta le note della release installata
