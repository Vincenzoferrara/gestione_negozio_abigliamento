# Configurazione

## Sezioni principali

- `Backend WordPress` - impostazioni globali di connessione al backend
- `Prodotti` - regole su immagini, eliminazione e filtri
- `Tema` - look chiaro/scuro e colori
- `IA` - token e modelli supportati
- `RFID` - parametri lettori e scansione
- `Shortcut` - tasti rapidi personalizzati

## Regola settings

- Le impostazioni globali stanno in `AppSettings`
- Le impostazioni specifiche di una pagina stanno nella sua settings view dedicata
- La pagina `settings.gui.dart` mostra tutte le views di configurazione disponibili

## Preferenze utili

- Dimensione pagina predefinita
- Colonne visibili nella griglia prodotti
- Persistenza filtri nella pagina prodotti
- Modalita testo per i parametri attributo
- Avvisi dimensioni immagini prodotto: le soglie larghezza/altezza servono solo a mostrare un avviso informativo nella libreria media, senza modificare i file caricati
- Connessione RFID tramite USB o WiFi; Bluetooth non e disponibile finche il modulo RFID resta in alpha

## Regola backend

- WooCommerce resta il canale diretto per le funzioni native WooCommerce
- MGWS gestisce checkout POS, stock gestionale, carico rapido, fornitori, riordino, ordini fornitore, ricezione/convalida, movimenti, inventario fisico e loyalty v1
- Per il perimetro WordPress, l'app deve configurare e usare solo provider diretti WooCommerce e MGWS
- Plugin terzi non vanno configurati come provider app; eventuali scelte interne al sito devono passare da MGWS
- Il checkout POS dovrebbe inviare `idempotency_key`; il meta `_id_scontrino_locale` resta fallback di compatibilita
- L'utente WordPress usato dalle chiamate MGWS deve essere autenticato e avere le capability richieste dalla rotta, per esempio lettura stock, movimento stock, accettazione ordine o gestione WooCommerce
- Le rotte inventario `stock/sync`, `stock/reconcile`, `quick-load`, fornitori, riordino, ordini fornitore, ricezioni, movimenti e conte fisiche sono operative e dipendono dalle capability MGWS/WooCommerce dell'utente configurato
- La rotta `rfid/scan` e operativa come resolve-only: risolve tag o barcode e non va configurata o presentata come incremento automatico stock
- `Carico rapido` non richiede campi documento: bastano prodotto o variante, quantita positiva, motivo, nota opzionale e conferma
- Fornitori, riordino e ordini fornitore non vanno configurati come carichi diretti: preparano dati e documenti, ma lo stock cambia solo con ricezione convalidata
- Le conte fisiche cambiano stock solo dopo approvazione/post della sessione
