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
- La CI GitHub Actions produce artifact Android, Linux, Windows e macOS; per Android release serve configurare il signing prima della distribuzione pubblica
- Le release desktop Windows e Linux sono pacchettizzate con Velopack e pubblicate su GitHub Releases a ogni push su `main` o `master`, oppure manualmente dal workflow dedicato; l'app usa la sezione `Aggiornamenti` per controllare, installare e riavviare dalla release piu recente
- Le note di rilascio desktop sono generate dalla release GitHub e mostrate una sola volta dopo il riavvio sulla nuova versione
