# Installazione

## Requisiti

- Flutter SDK compatibile con il progetto
- Ambiente Android, iOS, Linux, macOS o Windows
- Backend WooCommerce/MGWS accessibile via rete

## Avvio rapido

1. Installa le dipendenze del progetto
2. Avvia l'app dal target desiderato
3. Inserisci l'URL del sito nella schermata di login
4. Scegli il metodo di autenticazione corretto

## Note

- In locale, abilita l'opzione per `localhost` solo se serve
- Se usi smartcard, verifica il supporto hardware del dispositivo
- Su Android, concedi i permessi richiesti per rete, camera e NFC quando usi le funzioni collegate
- Il supporto Bluetooth per scanner RFID non e attivo finche il modulo RFID resta in alpha
- La CI GitHub Actions produce artifact Android, Linux, Windows e macOS; la release Android pubblica APK e AAB firmati quando sono configurati i secret `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` e `ANDROID_STORE_PASSWORD`
- Le release desktop Windows e Linux sono pacchettizzate con Velopack e pubblicate su GitHub Releases a ogni push su `main` o `master`, oppure manualmente dal workflow dedicato; l'app usa la sezione `Aggiornamenti` per controllare, installare e riavviare dalla release piu recente
- Le note di rilascio desktop sono generate dalla release GitHub e mostrate una sola volta dopo il riavvio sulla nuova versione

## Firma Android

- La chiave release Android locale si genera con `script/create_android_release_key.sh`
- Lo script crea `android/keystore/gestione_negozio_abbigliamento-release.jks`, `android/key.properties` e il file base64 da caricare nei GitHub Secrets
- I file di signing locali sono ignorati da Git e non devono essere committati
- Il workflow `Velopack Release` ricrea temporaneamente `android/app/release.jks` e `android/key.properties` dai secret GitHub, poi compila APK e AAB firmati
- L'APK firmato viene pubblicato come `gestione_neogzio_abbigliameto.apk`; l'AAB firmato viene pubblicato come `gestione_neogzio_abbigliameto.aab`
