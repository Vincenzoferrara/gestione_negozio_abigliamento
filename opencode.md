# OPENCODE Local Routing

Questo progetto usa LLM Wiki con root fissa:

- `/home/vincenzo/Desktop/obsidian/llm-wiki/`

Vault di progetto associato:

- `/home/vincenzo/Desktop/obsidian/llm-wiki/vault-gestione-negozio-abbigliamento/`

Regole locali:

1. Per knowledge di progetto, salvare nel vault progetto associato.
2. Per knowledge riusabile cross-progetto, promuovere nel `general vault` con bridge.
3. In assenza di altre istruzioni utente, non chiedere nuovamente la root wiki per questo progetto.
4. Se non e esplicitamente richiesto, o non serve, non leggere la cartella `docker`, dato che questa codebase e un'app Flutter.
5. Per ogni implementazione, fare domande finche non sei sicuro al 95% di cio che l'utente vuole e di come lo vuole.
6. Questo progetto Flutter e parte dello stesso sistema del plugin WordPress proprietario `MG-Warehouse-Stock-plugin-wordpress` in:
   - `/mnt/home/Scrivania/softwere/gestione_negozio_abbigliamento/MG-Warehouse-Stock-plugin-wordpress`
7. Per integrazioni WordPress, l'app deve considerare validi solo due provider esterni: `MGWS` e `WooCommerce`. L'app non deve parlare direttamente con `ATUM`, `myCred` o altri plugin WordPress terzi; se quelle funzioni servono, devono passare da `MGWS`.
8. `MGWS` e il plugin principale devono diventare completi: stock, inventario, movimenti, punti fedelta, clienti, report, fornitori e riordini devono essere nativi in `MGWS` oppure esposti da `MGWS` come gateway verso plugin esterni opzionali.
9. Se un'installazione preferisce usare plugin esterni come `ATUM` o `myCred`, la scelta deve restare interna a `MGWS`; l'app Flutter non deve conoscere quei plugin.
10. A ogni modifica funzionale al progetto, aggiornare sempre la documentazione in `lib/doc`. Questo vale quando si aggiunge, rimuove o modifica un'impostazione, un pulsante, una schermata, una classe, una funzione, un flusso utente, un'integrazione o qualsiasi comportamento dell'app. La documentazione deve descrivere solo l'utilizzo reale e attuale: non inserire confronti "prima/ora", changelog, note di versione o spiegazioni storiche. Aggiornare il file piu adatto tra quelli presenti in `lib/doc`, ad esempio `guida-utente.md`, `configurazione.md`, `guida-sviluppatori.md`, `mappa-moduli.md`, `flussi-operativi.md`, `integrazioni.md` o altri file pertinenti.
11. Quando si creano commit, usare questo formato nel messaggio:
   - prima riga: titolo breve del commit
   - riga vuota
   - righe successive: descrizioni brevi, una per riga, ciascuna che inizia con `-`
12. La wiki Obsidian del progetto e memoria personale interna: contiene idee, todo, decisioni e log. `lib/doc` e la documentazione tecnica attuale del codice, utile a contributor e IA; non deve contenere backlog o analisi storiche.
13. Quando una task viene completata, aggiornare `log.md` con una descrizione completa di cosa e stato fatto e perche. Il log deve spiegare il problema risolto, la scelta fatta, il motivo della scelta e i file toccati. Se restano dubbi, rischi o follow-up, aggiungerli come nuove voci in `todo.md` invece di lasciarli nel log. Non c'e un limite rigido di lunghezza: la voce deve essere abbastanza completa da permettere di capire in futuro cosa e stato fatto senza rileggere tutta la conversazione.
14. Prima di fare qualsiasi cosa sul progetto, leggere `lib/doc/architettura.md` e rispettare le regole architetturali li descritte.
