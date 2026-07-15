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

- Le funzioni native parlano direttamente con WooCommerce
- MGWS gestisce checkout POS, inventario, loyalty e integrazioni custom
- Il checkout POS crea l'ordine WooCommerce, registra i movimenti stock e risponde con `success`, `order_id` e totali
- L'app non deve dipendere da ATUM, myCred o plugin terzi in modo diretto
- WooCommerce resta il backend per il dominio ecommerce nativo
- MGWS resta il backend per la logica gestionale custom e per le regole non native di WooCommerce

## Persistenza

- `AppSettings` salva solo preferenze globali o condivise
- Segreti e token sensibili usano storage sicuro
- Le impostazioni coprono immagini, IA, shortcut, pagina default e backend WordPress
- Le impostazioni specifiche di una pagina o modulo stanno nella sua settings view dedicata

## Moduli chiave

- `inventory/inventory_global.dart` per sync WooCommerce <-> MGWS
- `dashboard/` per report, grafici e widget configurabili
- `cassa/` per vendita e checkout
- `report/class_report.dart` per etichette e QR

## Build e CI

- `.github/workflows/flutter-build.yml` compila Android APK e bundle desktop Linux, Windows e macOS
- Su push a `main` o `master`, il workflow incrementa il build number in `pubspec.yaml` e committa la modifica con `[skip ci]` per evitare loop
- Gli artifact CI usano la stessa versione risolta dal workflow: nome versione e build number letti o incrementati da `pubspec.yaml`
- `.github/workflows/velopack-release.yml` pubblica release Windows/Linux Velopack e release Android firmate
- Il signing Android usa solo GitHub Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` e `ANDROID_STORE_PASSWORD`
- Le chiavi locali stanno sotto `android/keystore/` e `android/key.properties`, entrambi ignorati da Git
- `script/create_android_release_key.sh` genera il keystore locale e il base64 da caricare come secret `ANDROID_KEYSTORE_BASE64`
- Le release Android pubblicano sia APK per GitHub/Obtainium sia AAB per Play Store futuro

## Regole pratiche

- Se il comportamento e ecommerce standard, il riferimento diretto e WooCommerce
- Se il comportamento e gestionale, di audit, POS o loyalty, il riferimento e MGWS
- Se il dato e temporaneo o di sola interfaccia, resta nella pagina Flutter
- Se il dato e persistente e condiviso da piu utenti o dispositivi, deve avere una strategia lato WordPress/MGWS

## Regola pratica

Tieni separati UI, logica di dominio e integrazione backend. Se una funzione dipende da un plugin esterno non nativo, passa prima da MGWS.
