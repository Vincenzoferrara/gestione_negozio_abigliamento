# Mappa Moduli

## Home

La schermata iniziale usa una docking layout su desktop e un flusso piu semplice su schermi piccoli. Il drawer mostra la versione pubblica dell'app letta dai metadati runtime, usando la sintassi GitHub `major.minor.build` senza mostrare il suffisso tecnico Flutter `+build`.

## Moduli disponibili

- `Cassa` - punto vendita con checkout MGWS idempotente, ordine WooCommerce e audit movimenti
- `Prodotti` - gestione catalogo con barra comandi, filtri, griglia, selezione multipla, pannello dettaglio prodotti/varianti e letture inventario MGWS
- `Inventario MGWS` - schermata operativa per carico rapido, fornitori, riordino, ordini fornitore, ricezione/convalida, movimenti e inventario fisico
- `Nuovo Prodotto` - creazione articolo con selezione immagini originali, avvisi informativi sulle dimensioni oltre soglia e rettifica stock totale MGWS opzionale dopo il salvataggio
- `Coupon` - gestione sconti
- `Ordini` - lista e dettaglio ordini
- `Clienti` - gestione clienti
- `Carte Fedelta` - punti, carta cliente, lookup e storico loyalty tramite MGWS v1
- `Report` - etichette, QR e stampe
- `Dashboard` - statistiche e widget configurabili
- `Impostazioni` - backend, prodotti, tema, IA, RFID, shortcut
- `Aggiornamenti` - aggiornamenti desktop Windows/Linux via Velopack e note release post-riavvio
- `Utenti` - utenti WordPress
- `CalDAV` - calendario e contatti
- `Dipendenti` - gestione personale
- `RFID` - test e scansione tag
- `DataGridView` - pagina tecnica di test

## Note di navigazione

- Alcuni moduli sono singleton e si riaprono nella stessa scheda
- Alcuni moduli possono avere istanze duplicate
- Su mobile l'app mostra una singola vista alla volta

## Confini MGWS nei moduli

- `Cassa` usa MGWS per il checkout POS; WooCommerce conserva l'ordine creato dal plugin
- `Prodotti` consulta catalogo e disponibilita e puo registrare stock iniziale/totale MGWS durante creazione o modifica prodotto
- `Inventario MGWS` contiene le schede operative `Carico rapido`, `Fornitori`, `Riordino`, `Ordini Fornitore`, `Ricezione/Convalida`, `Movimenti` e `Inventario fisico`
- `Carico rapido` e document-free e muta stock solo dopo conferma, con movimento MGWS auditato
- `Fornitori`, `Riordino`, `Ordini Fornitore` e bozze di `Ricezione/Convalida` sono stock-neutral; la giacenza cambia solo su convalida/post MGWS
- `Movimenti` legge il ledger MGWS in sola lettura; `Inventario fisico` muta stock solo dopo approvazione delle discrepanze
- `Carte Fedelta` usa MGWS per conto loyalty, carta, punti e storico; rimuovere una carta non rimuove conto o movimenti
- I report gestionali MGWS restano distinti dal modulo inventario descritto qui
