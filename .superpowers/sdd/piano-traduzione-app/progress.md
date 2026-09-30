# SDD ledger — plan: /home/vincenzo/.opencode/plan/piano-traduzione-app.md

## Context
Flutter 3.41.2, 180 file Dart, ~91.500 righe, ~868 stringhe visibili hardcoded. Zero i18n esistente. `intl` gia presente. `provider` e `shared_preferences` gia presenti.

## Constraints
- Un solo commit `adding translating`
- Template ARB = inglese; solo en+it
- Tutto il codice di traduzione sotto `lib/traduzioni`
- Attributi varianti canonical `size`/`color` con mappa in impostazioni
- Commit in inglese; commenti in una sola lingua per file

## Pre-flight
WIP utente non committato: `pubspec.lock` woocommerce hosted 2.0.1, test fdroid in corso.

## Task Status
- Task 1: complete (infra i18n: pubspec flutter_localizations + generate:true, l10n.yaml, ARB, LocaleSettings, estensioni.dart, main.dart MultiProvider+delegates, selettore lingua in GeneralSettingsTab)
- Task 2: complete (mappa attributi varianti size/color con mappa_attributi.dart + estensioni) — **non ancora collegata** a `woo_query_attributi.dart` né alla UI
- Task 3: Migrazione stringhe — in corso
- Task 4: complete (checker `verifica_traduzioni.dart` collaudato con 4 tipi di errore, workflow GitHub, README contributor)
- Task 5: complete (regole 17-25 in OPENCODE.md, lib/doc/architecture.md + developer-guide.md + user-guide.md)
- Task 6: pending (verifica finale + commit unico `adding translating`)

## Decisioni prese durante l'esecuzione
- `lib/importer/` **escluso dalla migrazione** su richiesta esplicita dell'utente. Motivo: contiene gli header delle colonne CSV, che sono identificatori di protocollo per l'importazione WooCommerce; tradurli romperebbe l'importazione. Restano quindi in italiano hardcoded e vanno trattati come debito noto.
- I subagent non scrivono mai direttamente sugli ARB condivisi: ognuno produce un frammento JSON in `/tmp/opencode/` e lo script `unisci_arb.py` lo applica con verifica post-scrittura. Senza questo, due scritture concorrenti in read-modify-write perdevano chiavi in silenzio.
- Le stringhe di errore che vivono in classi senza `BuildContext` (es. `dipendenti.code.dart`, `smartcard_service.dart`) restano in italiano: sono errori di servizio, non testo UI, e risolverle richiede una decisione architetturale separata.

## Baseline analyze
0 errori, 7 info preesistenti in packages/woocommerce_flutter_api.
