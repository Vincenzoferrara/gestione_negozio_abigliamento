# Troubleshooting

## Login fallito

- Verifica che l'URL sia corretto
- Prova JWT o WooCommerce API in base al backend
- Controlla che il sito risponda e che il plugin atteso sia attivo

## Nessun prodotto visibile

- Controlla che WooCommerce abbia prodotti pubblicati
- Verifica eventuali filtri salvati
- Controlla la connessione al backend

## Inventory sync non disponibile

- MGWS deve essere raggiungibile
- La sincronizzazione stock dipende dal servizio inventario MGWS

## Checkout cassa fallito

- Verifica che MGWS sia raggiungibile e autenticato
- Controlla che il payload POS sia valido
- Se l'ordine WooCommerce è stato creato dal plugin ma il checkout non si chiude, serve riconciliazione lato MGWS

## Problemi con immagini

- Verifica che il file originale sia un'immagine supportata da WordPress
- Se compare il badge oltre soglia, controlla le dimensioni configurate in `Impostazioni > Prodotti`
