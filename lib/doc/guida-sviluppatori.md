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
- Le tabelle inventory usano `DataGridView` da `lib/reuse_class/datagridview/`; non vanno creati grid o table bespoke per fornitori, riordino, ordini, ricezioni, movimenti o conte
- Le sole azioni stock-changing del modulo sono carico rapido confermato, convalida ricezione e approvazione conteggio. Fornitori, riordino, ordini fornitore, bozze ricezione, ledger e bozze conteggio restano stock-neutral
- `QueryMgwsLoyalty` usa rotte registrate per stato, cliente, lookup carta/email, carta, punti, storico e statistiche
- La cancellazione carta loyalty non cancella cliente o storico; se la carta non esiste, la rotta restituisce errore e non va trattata come successo idempotente
- Le rotte MGWS richiedono utente autenticato e capability route-specifiche; il codice client deve gestire `401`, `403`, `400`, `404`, `409` e `503` come risposte contrattuali possibili

## Persistenza

- `AppSettings` salva solo preferenze globali o condivise
- Segreti e token sensibili usano storage sicuro
- Le impostazioni coprono immagini, IA, shortcut, pagina default e backend WordPress
- Le impostazioni specifiche di una pagina o modulo stanno nella sua settings view dedicata

## Moduli chiave

- `inventory/inventory_global.dart` per lettura e confronto dello stock WooCommerce/MGWS
- `dashboard/` per report, grafici e widget configurabili
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

## Regola pratica

Tieni separati UI, logica di dominio e integrazione backend. Se una funzione dipende da un plugin esterno non nativo, passa prima da MGWS.
