# Flussi Operativi

## Accesso

1. Inserisci URL
2. Scegli metodo di login
3. Entra nell'area Home

## Nuovo prodotto

1. Apri `Nuovo Prodotto`
2. Compila dati base
3. Configura immagini e attributi; la libreria media segnala le foto oltre soglia ma non blocca la selezione
4. Salva

## Vendita in cassa

1. Apri `Cassa`
2. Seleziona prodotti o varianti
3. Applica coupon se serve
4. Conferma checkout MGWS con payload POS e chiave idempotente quando disponibile
5. MGWS crea l'ordine WooCommerce, registra movimenti stock e audit, aggiorna `mg_stock_levels` e restituisce l'ID ordine
6. Se la stessa chiave idempotente viene reinviata con lo stesso payload, MGWS restituisce la risposta salvata senza duplicare ordine o movimenti

## Controllo inventario e stock MGWS

1. Apri `Prodotti`
2. Usa la barra comandi per cercare, filtrare per campo/operatore/valore, nascondere gli esauriti o cambiare ordinamento
3. Controlla nella griglia disponibilita, quantita, varianti e stato
4. Seleziona un prodotto per aprire il pannello dettaglio con foto, dati, modifica rapida e varianti
5. Seleziona piu prodotti se devi usare azioni di massa come deselezione o eliminazione
6. Verifica disponibilita e discrepanze sapendo che `mg_stock_levels` in MGWS e la sorgente autorevole dello stock gestionale
7. Quando crei o modifichi un prodotto, abilita `Inventario MGWS` nella sezione prezzi/stock se vuoi registrare subito lo stock gestionale totale finale: inserisci stock intero non negativo e motivo, poi salva il prodotto
8. Dopo il salvataggio prodotto riuscito, l'app usa il `product_id` salvato per inviare `Reconcile stock`; se il prodotto non ha ID valido, MGWS non viene chiamato e il feedback resta visibile
9. Apri `Inventario MGWS` per i flussi operativi di carico, riordino, ordini fornitore, ricezione, movimenti e conte fisiche

## Carico rapido MGWS

1. Apri `Inventario MGWS`
2. Vai alla scheda `Carico rapido`
3. Inserisci prodotto o variante, oppure usa il barcode quando disponibile
4. Inserisci una quantita positiva, motivo obbligatorio e nota se serve
5. Controlla la conferma riepilogo
6. Conferma il carico
7. MGWS applica il carico, registra un movimento `load` auditato e restituisce stock prima/dopo e ID movimento

## Riordino e ordini fornitore MGWS

1. Apri `Inventario MGWS`
2. Usa `Fornitori` per creare, modificare, inattivare o gestire cancellazioni protette dei fornitori
3. Usa `Riordino` per leggere suggerimenti da soglie MGWS, rimandare un suggerimento o creare una bozza ordine
4. Usa `Ordini Fornitore` per creare o aggiornare bozze, righe prodotto/variante, quantita, costo e stato ordine
5. Considera questi passaggi stock-neutral: fornitore, suggerimento, bozza e ordine non aumentano giacenza

## Ricezione e convalida MGWS

1. Apri `Inventario MGWS`
2. Vai a `Ricezione/Convalida`
3. Carica gli ordini e le ricezioni MGWS
4. Crea o aggiorna una bozza di ricezione con quantita ricevute, respinte, backorder e motivi richiesti
5. Lascia la bozza aperta finche la merce non e controllata: la bozza non modifica stock
6. Usa `Convalida` solo quando vuoi registrare lo stock ricevuto
7. MGWS applica un solo movimento idempotente per la convalida e blocca i doppi invii o payload in conflitto

## Movimenti e inventario fisico MGWS

1. Apri `Movimenti` per consultare il ledger MGWS in sola lettura
2. Filtra per prodotto, variante, data, fonte, operatore o motivo e apri il dettaglio del movimento
3. Apri `Inventario fisico` per creare una sessione di conta
4. Aggiungi righe manuali o barcode/tag risolti da MGWS
5. Rivedi le discrepanze senza modificare stock
6. Approva la sessione solo quando le differenze sono corrette
7. MGWS registra movimenti `adjust` per le discrepanze approvate e rende la sessione pubblicata non modificabile

## Carte fedelta MGWS

1. Apri `Carte Fedelta`
2. Cerca il cliente per ID, carta o email tramite rotte MGWS v1
3. Aggiungi o sottrai punti con riferimento e nota se servono per audit
4. Consulta lo storico punti dalla rotta history, ordinato dal movimento piu recente
5. Se rimuovi una carta, MGWS cancella solo il numero carta: conto cliente e storico movimenti restano disponibili

## Gestione dettaglio prodotto

1. Apri `Prodotti`
2. Seleziona una riga della griglia
3. Usa il pannello dettaglio per consultare immagini, categorie, tag, stato, prezzo, sconto e marca
4. Usa `Modifica rapida` per aggiornare categorie, tag, stato o dati varianti disponibili
5. Usa i filtri varianti per restringere taglia, colore o altri attributi e, se serve, mostra solo varianti disponibili
6. Usa il menu azioni del dettaglio per modificare, eliminare o creare un prodotto

## Etichette e report

1. Apri `Report`
2. Seleziona il contenuto da stampare
3. Esporta o invia in stampa
