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
2. Seleziona prodotti o varianti, cercandoli manualmente oppure tramite scanner barcode/QR a schermo intero
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
3. Controlla o cambia magazzino, stanza e motivo condivisi; le opzioni e i valori predefiniti si configurano in `Impostazioni > Inventario`
4. Premi `Seleziona prodotti`, cerca per nome, SKU o barcode e usa le checkbox: seleziona direttamente i prodotti semplici oppure espandi un prodotto variabile e scegli le varianti concrete; ogni riga mostra la copertina disponibile
5. Imposta una quantita positiva per ogni riga selezionata; scaffale e piano/ripiano sono campi testuali specifici della riga e possono restare vuoti
6. Lascia pure vuoti magazzino, stanza, scaffale e piano/ripiano se non vuoi specificare l'ubicazione: MGWS usa il primo magazzino valido autorizzato e mantiene vuoti i dettagli non inseriti
7. Per rimuovere completamente un livello dal flusso, svuota la relativa lista in `Impostazioni > Inventario`: il campo viene nascosto e non viene incluso nelle richieste
8. Controlla la conferma con posizione, motivo, righe e quantita totale
9. Conferma il carico: l'app invia le righe a MGWS una alla volta con chiavi di idempotenza distinte
10. Controlla l'esito per riga; in caso di successo parziale, correggi e riprova le sole righe fallite rimaste nella selezione

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
4. Aggiungi righe manuali o barcode/tag risolti da MGWS; quando usi lo scanner barcode/QR, la scansione occupa lo schermo intero e rientra poi nella sessione di conta
5. Rivedi le discrepanze senza modificare stock
6. Approva la sessione solo quando le differenze sono corrette
7. MGWS registra movimenti `adjust` per le discrepanze approvate e rende la sessione pubblicata non modificabile

## Carte fedelta MGWS

1. Apri `Carte Fedelta`
2. Cerca il cliente per ID, carta o email tramite rotte MGWS v1; la scansione della carta usa lo scanner condiviso a schermo intero
3. Aggiungi o sottrai punti con riferimento e nota se servono per audit
4. Consulta lo storico punti dalla rotta history, ordinato dal movimento piu recente
5. Se rimuovi una carta, MGWS cancella solo il numero carta: conto cliente e storico movimenti restano disponibili

## Analisi dashboard e generazione report

1. Apri `Dashboard`
2. Scegli il periodo dal menu rapido: oggi, settimana, mese o anno
3. Consulta vendite, ordini, prodotti, stock, clienti, grafici e accessi ai report dettagliati disponibili
4. Usa il pannello `Analisi dashboard` per vedere quali dati sono gia analizzabili nel periodo corrente
5. Premi `Genera report`
6. Scegli `Dashboard CSV`, `Dashboard PDF`, `Vendite CSV` o `Vendite PDF`
7. L'app genera e condivide il file usando i dati caricati nella dashboard e lo stesso periodo selezionato

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
