# WordPress Docker per WooCommerce Testing

Ambiente Docker per testare l'integrazione WooCommerce con l'app Flutter.

## Servizi inclusi

- **WordPress** (porta 8080) - con WooCommerce
- **MariaDB** (database)
- **phpMyAdmin** (porta 8081) - gestione database

## Plugin custom (Magazzino)

Il plugin custom **MG Warehouse Stock** (multi-sede / multi-magazzino con ubicazioni `room/rack/shelf` e stato ordine "Accettato") e' tenuto **fuori** da questo repo.

- Path sorgente (esempio): `/home/vincenzo/Desktop/softwere/gestione_negozio_abbigliamento/MG-Warehouse-Stock-plugin-wordpress`
- Path nel container: `/var/www/html/wp-content/plugins/mg-warehouse-stock`

Per montarlo senza modificare `docker/wordpress-docker/docker-compose.yml`, crea un file **locale** `docker/wordpress-docker/docker-compose.override.yml` (non committarlo) con:

```yaml
services:
  wordpress:
    volumes:
      - /home/vincenzo/Desktop/softwere/gestione_negozio_abbigliamento/MG-Warehouse-Stock-plugin-wordpress:/var/www/html/wp-content/plugins/mg-warehouse-stock
```

Dopo aver avviato i container, attivalo da WordPress: **Plugin -> MG Warehouse Stock -> Attiva**.

## Setup iniziale

1. **Copia il file di configurazione:**
   ```bash
   cp .env.example .env
   ```

2. **Imposta i tuoi UID/GID** (opzionale, se diversi da 1000):
   ```bash
   echo "UID=$(id -u)" >> .env
   echo "GID=$(id -g)" >> .env
   ```

3. **Avvia i container:**
   ```bash
   docker-compose up -d
   ```

## Accesso

- **WordPress**: http://localhost:8080
  - User: `testuser`
  - Password: `testpassword`

- **phpMyAdmin**: http://localhost:8081
  - User: `root`
  - Password: `rootpassword`

## Comandi utili

```bash
# Avvia i container
docker-compose up -d

# Ferma i container
docker-compose down

# Vedi i log
docker-compose logs -f

# Riavvia un servizio specifico
docker-compose restart wordpress

# Ricostruisci e riavvia tutto
docker-compose down && docker-compose up -d --build
```

## Struttura cartelle

- `wordpress_core/` - File core di WordPress
- `wordpress_plugins/` - Plugin installati
- `wordpress_themes/` - Temi installati
- `wordpress_uploads/` - Media caricati
- `db_data/` - Dati del database

## Note sui permessi

Il docker-compose è configurato per usare l'UID/GID dell'utente locale, evitando problemi di permessi sui file creati dai container. Questo rende il setup portabile su macchine diverse.

## Troubleshooting

**Errore permessi su db_data:**
```bash
sudo chown -R $(id -u):$(id -g) db_data/
```

**Reset completo:**
```bash
docker-compose down -v
rm -rf db_data wordpress_core wordpress_plugins wordpress_themes wordpress_uploads
docker-compose up -d
```
