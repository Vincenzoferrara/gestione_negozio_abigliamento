# Integrazioni

## Supportate

- WooCommerce
- MGWS
- Smartcard NFC/USB
- CalDAV
- RFID
- Provider IA configurabili

## Flusso backend

- Le funzioni native parlano con WooCommerce
- La cassa invia il checkout a MGWS, che crea l'ordine WooCommerce e registra i movimenti
- Il checkout POS usa `POST /wp-json/mgws/v1/pos/checkout` con righe vendita, righe reso, cliente, metodi di pagamento, totali e meta
- MGWS centralizza stock, loyalty e integrazioni custom
- L'app non deve richiamare direttamente plugin terzi come ATUM o myCred

## Login

- JWT
- WooCommerce API con Consumer Key e Secret
- Smartcard
