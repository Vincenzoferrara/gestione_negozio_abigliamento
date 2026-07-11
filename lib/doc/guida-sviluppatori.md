# Guida Sviluppatori

## Stack

- Flutter + Dart
- `provider` per lo stato
- `docking` per il layout desktop
- `shared_preferences` e `flutter_secure_storage` per la persistenza
- `dio` e `http` per le API

## Entry point

- `lib/main.dart` inizializza logger, tema e `MaterialApp`
- `lib/home/home.gui.dart` costruisce la UI principale e le sezioni
- `lib/home/home.code.dart` gestisce login gate, mobile/desktop e tab docking
- `lib/cassa/cassa.code.dart` delega il checkout POS a MGWS
- `lib/login/jwt_api/query_mgws/query_mgws_pos.dart` parla con `/wp-json/mgws/v1/pos/checkout`

## Flusso auth

- `lib/login/gui/login.gui.dart` gestisce il form di accesso
- `lib/login/gui/login.code.dart` normalizza l'URL e chiama il connettore WooCommerce
- `lib/login/auth_service.dart` espone un layer astratto per piu piattaforme

## Backend e vincoli

- Le funzioni native parlano direttamente con WooCommerce
- MGWS gestisce checkout POS, inventario, loyalty e integrazioni custom
- Il checkout POS crea l'ordine WooCommerce, registra i movimenti stock e risponde con `success`, `order_id` e totali
- L'app non deve dipendere da ATUM, myCred o plugin terzi in modo diretto

## Persistenza

- `AppSettings` salva preferenze in locale
- Segreti e token sensibili usano storage sicuro
- Le impostazioni coprono immagini, IA, shortcut, pagina default e backend WordPress

## Moduli chiave

- `inventory/inventory_global.dart` per sync WooCommerce <-> MGWS
- `dashboard/` per report, grafici e widget configurabili
- `cassa/` per vendita e checkout
- `report/class_report.dart` per etichette e QR

## Regola pratica

Tieni separati UI, logica di dominio e integrazione backend. Se una funzione dipende da un plugin esterno non nativo, passa prima da MGWS.
