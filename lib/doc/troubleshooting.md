# Troubleshooting

## Login fallito

- Verifica che l'URL sia corretto
- Prova JWT o WooCommerce API in base al backend
- Controlla che il sito risponda e che il plugin atteso sia attivo

## Nessun prodotto visibile

- Controlla che WooCommerce abbia prodotti pubblicati
- Verifica eventuali filtri salvati
- Controlla la connessione al backend

## Inventario MGWS non disponibile

- MGWS deve essere raggiungibile e autenticato
- Le letture inventario dipendono dalle tabelle MGWS e dalle capability di lettura stock
- Le operazioni di carico rapido, fornitori, riordino, ordini fornitore, ricezione/convalida, movimenti e conte fisiche richiedono capability MGWS coerenti con la rotta
- `Carico rapido` rifiuta quantita non positive, motivo vuoto, prodotto mancante o capability insufficiente; non chiedere fornitore, ordine, fattura o DDT per risolvere questi errori
- Se una ricezione non aggiorna stock, controlla che sia stata eseguita `Convalida`: la bozza di ricezione e stock-neutral
- Se un conteggio fisico non aggiorna stock, controlla che la sessione sia stata approvata: righe e bozze sono stock-neutral
- `Movimenti` e solo lettura; se il ledger e vuoto o filtrato, non deve creare movimenti nuovi
- `POST /inventory/stock/sync` e `PUT /inventory/stock/reconcile` sono operative e richiedono payload validi, utente autenticato e capability adeguate
- `InventoryGlobal.reconcileInventory(fixDiscrepancies)` produce proposte e non corregge stock in automatico
- `POST /inventory/rfid/scan` e resolve-only: risolve tag o barcode e non crea movimenti o incrementi stock impliciti
- Se una lettura stock prodotto restituisce `404 mgws_product_not_found`, verifica che il prodotto WooCommerce esista
- Se una lettura o mutazione restituisce `403`, verifica le capability WordPress dell'utente usato dall'app

## Checkout cassa fallito

- Verifica che MGWS sia raggiungibile e autenticato
- Controlla che il payload POS sia valido
- Usa una `idempotency_key` stabile per ogni scontrino locale; in alternativa MGWS usa il meta `_id_scontrino_locale` come fallback
- `409 mgws_idempotency_conflict` indica stessa chiave con payload diverso: non ritentare cambiando dati senza generare una nuova chiave operativa
- `409 mgws_idempotency_in_progress` indica una richiesta identica gia in corso: attendi il completamento e ripeti lo stesso payload
- Se MGWS restituisce una failure salvata dopo prenotazione idempotente, la stessa chiave ripete quella failure e richiede intervento operativo lato MGWS

## Loyalty MGWS

- `404 mgws_loyalty_customer_not_found` indica cliente WordPress/Woo assente o senza conto loyalty quando richiesto dalla rotta
- `404 mgws_loyalty_card_not_found` su cancellazione carta significa che non c'e una carta da rimuovere; la cancellazione non e idempotente
- La cancellazione carta conserva conto cliente e storico punti, quindi lo storico resta la fonte per audit
- `400 mgws_insufficient_points` indica sottrazione punti superiore al saldo disponibile
- `503` sulle rotte loyalty indica storage MGWS non disponibile o tabelle non pronte

## Problemi con immagini

- Verifica che il file originale sia un'immagine supportata da WordPress
- Se compare il badge oltre soglia, controlla le dimensioni configurate in `Impostazioni > Prodotti`
