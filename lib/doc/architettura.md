# Architettura

## Strati

- UI Flutter
- Logica di schermata
- Servizi di dominio
- Connettori backend

## Nodi principali

- `main.dart` avvia tema e app
- `home/` controlla navigazione e docking
- `login/` gestisce autenticazione e connettori
- `settings/` conserva preferenze e segreti
- `inventory/` unifica stock WooCommerce e MGWS
- `cassa/` delega il checkout POS a MGWS
- `dashboard/` produce dati e grafici

## Principi

- UI e backend restano separati
- Le dipendenze da plugin esterni passano da MGWS
- Le credenziali sensibili non vanno in chiaro
- WooCommerce resta il motore e-commerce usato dal plugin, non orchestrato direttamente dalla cassa Flutter
