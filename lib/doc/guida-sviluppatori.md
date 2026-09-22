# Guida Sviluppatori

## Stack

- Flutter + Dart
- `provider` per lo stato
- `docking` per il layout desktop
- `shared_preferences` e `flutter_secure_storage` per la persistenza
- `dio` e `http` per le API

## Struttura codice

- Ogni modulo principale vive in una cartella dedicata sotto `lib/`
- Ogni modulo separa sempre `.gui.dart` e `.code.dart`
- `.gui.dart` contiene solo widget, layout, input e rendering
- `.code.dart` contiene orchestrazione, stato e logica di schermata
- `lib/reuse_class/` contiene solo componenti usati in piu schermate
- `lib/reuse_class/barcode/` contiene lo scanner barcode/QR condiviso: grafica, fotocamera, lettura ed elaborazione restano nel modulo riusabile; i caller usano `showBarcodeScanner(context)` e ricevono solo `String?`
- `lib/utils/barcode_generator.dart` contiene il generatore barcode condiviso: `BarcodeGenerator.generaCode128(esclusi: ..., random: ..., now: ...)` produce un valore numerico di 30 cifre compatibile Code128 (13 cifre casuali + data/ora attuale `DDMMYYYYHHMMSS` + millisecondi), evita i valori esclusi e valida tramite il plugin `barcode`; `random`/`now` sono iniettabili per i test deterministici. Usato dall'editor prodotti, ma pensato per qualunque modulo che debba generare un barcode interno
- `login/jwt_api/` contiene il layer di integrazione con le piattaforme esterne
- `settings/` contiene la pagina madre delle impostazioni e le singole visualizzazioni settings dei moduli

## Entry point

- `lib/main.dart` inizializza logger, tema e `MaterialApp`
- `lib/home/home.gui.dart` costruisce la UI principale e le sezioni
- `lib/home/home.code.dart` gestisce login gate, mobile/desktop, tab docking e lettura versione runtime tramite `package_info_plus`
- `lib/cassa/cassa.code.dart` delega il checkout POS a MGWS
- `lib/login/jwt_api/query_mgws/query_mgws_pos.dart` parla con `/wp-json/mgws/v1/pos/checkout`

## Flusso auth

- `lib/login/gui/login.gui.dart` gestisce il form di accesso
- `lib/login/gui/login.code.dart` normalizza l'URL e chiama il connettore WooCommerce
- `lib/login/auth_service.dart` espone un layer astratto per piu piattaforme
- `JwtConnect.connect()` controlla l'esistenza di una route JWT prima di inviare username e password; se il plugin JWT manca, il login JWT fallisce senza spedire credenziali
- Il controllo JWT non mantiene stato applicativo e non condiziona il login WooCommerce API con Consumer Key e Secret
- `login/jwt_api/query_mgws/mgws_availability.dart` conserva la disponibilità centrale di MGWS dopo i controlli sicuri di inventario e loyalty; il suo esito non modifica l'esito della connessione WooCommerce
- `PlatformManager.isMgwsAvailable` e `LoginCode.isMgwsAvailable` sono i soli riferimenti di stato per schermate e controller MGWS; non devono ripetere chiamate dirette agli endpoint di stato
- `lib/home/home.gui.dart` decide solo la superficie di presentazione del login: sugli schermi stretti apre una route full-screen, sugli schermi grandi mantiene il dialog; la logica auth resta nel modulo `login/`
- Il login e il punto piu sensibile del progetto: ogni modifica deve essere valutata anche dal punto di vista sicurezza prima dell'implementazione
- I metodi di login futuri devono restare sicuri per default

## Backend e vincoli

- Le funzioni WooCommerce native parlano direttamente con WooCommerce
- MGWS gestisce checkout POS, inventario v1, loyalty v1, stock gestionale, restock, ricezioni, conte fisiche e movimenti custom
- L'app ha solo due provider WordPress diretti: WooCommerce e MGWS
- Il checkout POS crea l'ordine WooCommerce, registra i movimenti stock e risponde con `success`, `order_id` o `woo_order_id`, stato ordine, totali e righe processate
- Il payload POS deve inviare una chiave `idempotency_key` quando disponibile; MGWS accetta anche il meta legacy `_id_scontrino_locale` come fallback di compatibilita
- A parita di chiave e payload, MGWS restituisce la risposta salvata senza creare un secondo ordine o nuovi movimenti; a parita di chiave e payload diverso risponde `409 mgws_idempotency_conflict`
- L'app non deve dipendere da ATUM, myCred o plugin terzi in modo diretto
- WooCommerce resta il backend per il dominio ecommerce nativo
- MGWS resta il backend per la logica gestionale custom e per le regole non native di WooCommerce

## Contratto MGWS v1 per l'app

- `QueryMgwsPos` usa solo `POST /wp-json/mgws/v1/pos/checkout`
- `QueryMgwsInventory` usa le rotte di lettura `status`, `stock/product`, `stock/all`, `statistics` e `low-stock`
- `QueryMgwsInventory` espone sync Woo verso MGWS, reconcile stock auditato e RFID scan resolve-only; lo scan RFID risolve tag o barcode e non muta quantita
- `QueryMgwsInventory` espone anche carico rapido, fornitori, riordino, ordini fornitore, ricezioni/convalida, movimenti e conte fisiche tramite modelli tipizzati e gateway iniettabili
- Le schermate inventory mantengono UI e logica separate in file `.gui.dart` e `.code.dart`; i controller non chiamano Dio raw e passano sempre dal gateway MGWS tipizzato
- Il carico rapido usa `InventoryQuickLoadCatalogController` come adapter inventory del caricamento progressivo di `ProdottiGestioneController`; i prodotti variabili sono gruppi non selezionabili e solo le varianti concrete diventano righe di carico. L'adapter protegge i callback progressivi quando il dialog viene chiuso e il controller e gia stato disposto.
- Il catalogo mostra `immagineUrl` del prodotto o della variante con fallback variante-prodotto e filtra anche `metadatiCustom['barcode']`; i converter WooCommerce devono quindi reidratare `meta_data` sia sui prodotti sia sulle varianti.
- Durante il caricamento di una variante nell'editor `prodotti_crea` o del prodotto selezionato in `Prodotti > Gestisci`, solo nelle build debug il connettore WooCommerce registra il JSON REST completo della pagina e, per ogni variante, gli attributi JSON ricevuti insieme agli attributi `AttributoVariante` risultanti. Le voci usano rispettivamente i prefissi `PCREA_` e `PGEST_`; il prefetch delle altre righe della griglia non attiva il tracciamento. Il log serve a diagnosticare gruppi `Colore`/`Taglia` assenti.
- `InventoryQuickLoadController.submitPlan()` serializza le righe per rispettare il contratto MGWS a singola richiesta, conserva la chiave di idempotenza di ogni riga e restituisce risultati parziali e righe riprovabili. Magazzino e stanza sono condivisi, scaffale e ripiano appartengono alla riga; ogni valore di ubicazione vuoto viene omesso dal payload.
- `InventoryQuickLoadSettings` considera abilitato ciascun livello di ubicazione solo quando la relativa lista di opzioni non e vuota. Il pannello nasconde i livelli disabilitati e normalizza a vuoto eventuali valori di riga obsoleti prima di creare il piano di invio.
- Le tabelle inventory usano `DataGridView` da `lib/reuse_class/datagridview/`; non vanno creati grid o table bespoke per fornitori, riordino, ordini, ricezioni, movimenti o conte
- Il menu contestuale della griglia vive nella `DataGridView`: `DataGridViewContextAction` (modello in `datagridview.code.dart`) descrive etichetta, icona e callback; `showDataGridViewContextMenu` (in `datagridview.gui.dart`) mostra il menu costruendo voci icona+etichetta ed eseguendo l'azione sulla riga. Sul click destro la griglia seleziona la riga e mostra il menu; le card mobili che riusano lo stesso menu chiamano `showDataGridViewContextMenu` con la stessa lista di azioni. I caller non costruiscono piu `PopupMenuItem` o `showMenu` propri per la griglia: forniscono solo le azioni e i callback applicati alla riga
- Le sole azioni stock-changing del modulo sono carico rapido confermato, convalida ricezione e approvazione conteggio. Fornitori, riordino, ordini fornitore, bozze ricezione, ledger e bozze conteggio restano stock-neutral
- `QueryMgwsLoyalty` usa rotte registrate per stato, cliente, lookup carta/email, carta, punti, storico e statistiche
- Se `PlatformManager.isMgwsAvailable` è `false`, ogni flusso MGWS deve terminare prima della chiamata REST con il valore sicuro del proprio contratto: `false`, `null`, raccolta vuota o feedback operativo
- La cancellazione carta loyalty non cancella cliente o storico; se la carta non esiste, la rotta restituisce errore e non va trattata come successo idempotente
- Le rotte MGWS richiedono utente autenticato e capability route-specifiche; il codice client deve gestire `401`, `403`, `400`, `404`, `409` e `503` come risposte contrattuali possibili

## Persistenza

- `AppSettings` salva solo preferenze globali o condivise
- Segreti e token sensibili usano storage sicuro
- Le impostazioni coprono immagini, IA, shortcut, pagina default e backend WordPress
- Le impostazioni specifiche di una pagina o modulo stanno nella sua settings view dedicata

## Moduli chiave

- `inventory/inventory_global.dart` per lettura e confronto dello stock WooCommerce/MGWS
- `prodotti/prodotti_gestisci/` pubblica ogni pagina WooCommerce appena caricata tramite il controller, mantenendo il download delle pagine successive in background; la UI sincronizza la paginazione locale a ogni avanzamento senza overlay bloccante. Quando un prodotto variabile viene selezionato, `ProdottiGestioneController` carica tutte le pagine varianti WooCommerce tramite un loader iniettabile e passa gli attributi del prodotto alla conversione delle varianti. La modifica rapida usa gli stati WooCommerce `publish`, `private`, `draft` e `pending`, etichettando `pending` come `In revisione`.
- `prodotti/prodotti_crea/` usa uno stepper con `Informazioni Base`, `Prezzi e Stock`, `Immagini`, `Dettagli` e `Varianti`. Il `Tipo prodotto` e nullable in creazione e blocca gli altri controlli finche non viene selezionato; in modifica l'editor riceve solo `prodottoIdDaModificare` e `codiceProdotto`, ricarica dal server il `ProdottoGlobal` fresco e usa `codiceProdotto` come fallback se l'ID non e risolvibile. Il tipo resta `variabile` quando il prodotto Woo e variabile anche se la ricarica varianti e vuota. L'editor passa gli attributi del prodotto al caricamento delle varianti e non sovrascrive varianti con attributi validi con una ricarica degradata; i barcode top-level vengono compilati solo per prodotti semplici e sono forzati vuoti nel payload dei prodotti variabili. Il payload WooCommerce usa un unico builder prodotto, ma in update non include gli attributi variabili del padre per evitare di riscrivere gli attributi globali WooCommerce delle varianti; in create li include. Prima dell'update il recap mostra solo i nuovi valori dei campi modificati e i campi mancanti, e usa testo selezionabile con copia negli appunti; la conferma resta bloccata se ci sono errori obbligatori. Dopo il salvataggio l'editor marca sporca la cache prodotti e rimuove la cache varianti del prodotto salvato. La scheda `Immagini` mantiene `immagineUrl` come principale e `immaginiAggiuntive` come gallery ordinata; il selector media multi-selezione restituisce piu `MediaFile` e conserva localmente i metadati disponibili per nome, dimensione e badge pixel non bloccanti. Le varianti riusano lo stesso selector multi-selezione: la prima foto diventa `image`, le successive vengono salvate in `gallery_image_ids` quando esiste l'ID media WordPress, e il meta legacy `immagini_variante` resta come fallback compatibile per URL non risolvibili a ID. La sezione attributi della variante e in sola lettura con chiavi stabili per evitare stati errati dei campi dopo l'espansione della riga.
- Il mapping WooCommerce → modello globale usa `prezzoNormale = regular_price ?? price` come fallback iniziale, ma per i prodotti variabili il prezzo autorevole della griglia arriva dalle varianti: su `wc/v3` il prodotto padre può esporre solo il prezzo attivo e lasciare vuoti `regular_price`/`sale_price`.
- In griglia, quando le varianti sono caricate: se tutte condividono lo stesso prezzo o sconto la label mostra il valore unico; se i prezzi o gli sconti differiscono mostra `Prezzi variabili`. La cache pricing della `DataGridViewCache` va invalidata a ogni aggiornamento varianti prima del ricalcolo. Il calcolo del pricing consulta prima le varianti agganciate all'istanza prodotto e poi la cache varianti condivisa: in questo modo resta corretto anche quando le istanze vengono ricreate dal caricamento WooCommerce (che le produce senza `varianti` agganciate) e il prefetch successivo salta i prodotti già in cache.
- `dashboard/` per analisi WooCommerce, grafici, widget configurabili e generazione PDF/CSV dal periodo corrente; `dashboard.gui.dart` ospita la pagina, `dashboard_report_panel.gui.dart` ospita il pannello analisi/export, `dashboard.code.dart` contiene modelli, filtro periodo, capability e gateway report, `dashboard_report_export.dart` contiene scelte e servizi di export
- `cassa/` per vendita e checkout
- `report/class_report.dart` per etichette e QR

## Build e distribuzione

- La configurazione di build e distribuzione non fa parte del contratto backend MGWS v1 descritto in questa guida
- Le modifiche al contratto MGWS devono restare separate da pipeline, pacchetti pubblici e canali di distribuzione
- Per sviluppare o verificare il backend MGWS, usa le sezioni su connettori, capability, rotte e test di contratto

## Regole pratiche

- Se il comportamento e ecommerce standard, il riferimento diretto e WooCommerce
- Se il comportamento e gestionale, di audit, POS o loyalty, il riferimento e MGWS
- Se il dato e temporaneo o di sola interfaccia, resta nella pagina Flutter
- Se il dato e persistente e condiviso da piu utenti o dispositivi, deve avere una strategia lato WordPress/MGWS
- Nella dashboard il filtro di analisi attivo e oggi solo il periodo; brand, varianti, attributi e filtri avanzati non devono essere mostrati come controlli effettivi finche il layer dati non aggrega davvero quelle dimensioni.
- Nomenclatura codici prodotto: `codiceProdotto` e `variante.codiceProdotto` corrispondono a `sku` WooCommerce; `barcodeInterno` corrisponde a `global_unique_id`; `barcodeProduttore` (prodotto) e `barcodeFornitore` (variante) corrispondono a `barcode_manufacturer`. SKU e barcode non sono intercambiabili e non devono avere fallback fra loro. Il filtro `Barcode` ricerca in OR barcode interno ed esterno, mantenendo i valori separati nel modello. Le chiavi tecniche restano invariate: MGWS `supplier_sku`, header CSV `SKU`, chiavi SharedPreferences/storico (`productSku`, `variationSku`), contenuto QR `SKU:`; il campo della libreria `woocommerce_flutter_api` resta `WooProduct.sku`.

## Regola pratica

Tieni separati UI, logica di dominio e integrazione backend. Se una funzione dipende da un plugin esterno non nativo, passa prima da MGWS.
