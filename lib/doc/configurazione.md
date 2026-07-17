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

- WooCommerce resta il canale diretto per le funzioni native
- MGWS gestisce stock, loyalty e logica esterna opzionale
