# Runbook: recovery errore connessione DB WordPress (Docker)

Riferimento per il ripristino dell'ambiente `docker/wordpress-docker` senza perdita
accidentale di dati. Leggere **"Regole anti-perdita"** prima di qualunque operazione.

## Stack di riferimento

| Servizio        | Container        | Immagine        | Porta | Volume dati |
|-----------------|------------------|-----------------|-------|-------------|
| Database        | `wordpress_db`   | `mariadb:10.6`  | –     | `./db_data:/var/lib/mysql` |
| WordPress       | `wordpress_app`  | `wordpress:latest` | 8080 → 80 | `wordpress_core`, `wordpress_plugins`, ... |
| phpMyAdmin      | `wordpress_phpmyadmin` | `phpmyadmin:latest` | 127.0.0.1:8081 → 80 | – |

- Config: `docker-compose.yml` + `.env` (obbligatorio: `MYSQL_PASSWORD`,
  `MYSQL_ROOT_PASSWORD`, `WORDPRESS_ADMIN_USER`, `WORDPRESS_ADMIN_PASSWORD`).
  Con password/sedi non omessi, il compose fallisce subito con un messaggio chiaro.
- Plugin MGWS montato da host nel compose (path `/home/vincenzo/Desktop/softwere/
  gestione_negozio_abbigliamento/MG-Warehouse-Stock-plugin-wordpress`).
  Se il path host non esiste, il volume fallisce silenziosamente all'avvio.
- Snapshot esistenti: `db_data/` (live), `db_data_fresh_20260430_1423/` (copia pulita).

## Regole anti-perdita (sempre)

1. **Mai `docker-compose down -v`** senza aver prima creato un backup del volume.
   `-v` elimina i volumi e con questo compose **cancella fisicamente `db_data/`**.
2. **Mai `rm -rf db_data`**: se serve un reset, prima sposta
   `mv db_data db_data_backup_$(date +%Y%m%d_%H%M)`.
3. **Prima di ogni operazione invasiva** (upgrade, restore, reset): dump del DB.
   ```bash
   docker exec wordpress_db sh -c 'exec mariadb-dump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' > backup_$(date +%Y%m%d_%H%M).sql
   ```
4. **Non `chown` a caso su `db_data/`**: se servono permessi,
   `sudo chown -R $(id -u):$(id -g) db_data/` (solo quando l'utente host
   coincide con quello dei container; verificare con `stat -c %u db_data`).
5. Ogni snapshot di ripristino va copiato, **mai spostato** sopra il volume live.

## Sintomo: "Error establishing a database connection"

Il frontend WordPress non raggiunge MariaDB. Cause tipiche nell'ordine:

1. Container `db` giù o mai partito
2. `db_data/` con permessi errati (MariaDB non avvia)
3. Password del DB cambiata ma compose `.env` non aggiornato
4. Filesystem pieno
5. `db_data/` corrotto dopo arresti bruschi

### Diagnosi

```bash
cd docker/wordpress-docker

# Stato dei container
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Log del database (qui sta quasi sempre la causa)
docker logs --tail 100 wordpress_db

# Log di WordPress
docker logs --tail 50 wordpress_app

# Verifica connettività db->wordpress
docker exec wordpress_app sh -c 'php -r "var_export(class_exists(\"mysqli\"));"'
docker exec wordpress_db sh -c 'mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;"' 2>/dev/null || echo "AUTH DB FALLITA"
```

### Recovery

**A. Container db fermo / mai avviato**

```bash
docker-compose up -d db
sleep 5
docker logs --tail 50 wordpress_db
docker-compose up -d wordpress   # riparte anche WordPress ordinato
```

**B. Errore permessi / "cannot open database" in `db_data`**

```bash
# Prima: backup del volume live (regola 3)
# Poi correggi i permessi sull'utente host dei container
stat -c %u db_data
sudo chown -R $(id -u):$(id -g) db_data/
docker-compose restart db wordpress
```

**C. Mismatch password DB**

Riconcilia `.env` con le credenziali attuali, poi riavvia solo WordPress
(il DB non va riavviato per una sola password):

```bash
docker-compose up -d --force-recreate wordpress
```

**D. Ripristino da snapshot pulito (`db_data_fresh_*`)**

Usa solo se accetti di tornare allo stato della copia (perde le modifiche
successive alla data dello snapshot) e hai già fatto il dump (regola 3):

```bash
# 1. Ferma tutto
docker-compose down

# 2. Metti in sicurezza il volume corrotto, NON cancellarlo
mv db_data db_data_corrupt_$(date +%Y%m%d_%H%M)

# 3. Copia lo snapshot (copia, non move)
cp -a db_data_fresh_20260430_1423 db_data

# 4. Riavvio
docker-compose up -d
docker logs --tail 20 wordpress_db
```

**E. Ripristino da dump SQL**

```bash
docker-compose up -d db
# Creazione schema se assente + import
docker exec -i wordpress_db sh -c \
  'exec mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' < backup_YYYYMMDD_HHMM.sql
docker-compose restart wordpress
```

**F. Reset totale SOLO da delibera consapevole**

```bash
docker-compose down
mv db_data db_data_reset_$(date +%Y%m%d_%H%M)
docker-compose up -d
```

## Verifica finale

```bash
docker exec wordpress_db sh -c \
  'mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -D"$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM wp_posts;"' 2>/dev/null
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080
```

- `200` e query ok = ambiente ripristinato.
- `200` ma pagina lenta = probabilmente plugin in crash: controlla
  `docker logs wordpress_app`.

## Checklist simile per "porta già in uso" all'avvio

- `wordpress_app` su 8080 occupato: ferma il processo o cambia porta nel
  compose; NON eliminare volumi per liberare la porta.