#!/bin/bash

# Script per verificare e avviare Docker e docker-compose

echo "🔍 Verifico stato Docker..."

# Usa il comando docker compose moderno (senza trattino)
COMPOSE_CMD="docker compose"
DOCKER_FILE_PATH="/../docker/wordpress-docker"

echo "📦 Uso $COMPOSE_CMD"

# Funzione per verificare se Docker è in esecuzione
is_docker_running() {
    docker info >/dev/null 2>&1
}

# Funzione per verificare se docker-compose è attivo nella directory docker
is_compose_running() {
    cd "$(dirname "$0")$DOCKER_FILE_PATH" 2>/dev/null || return 1
    $COMPOSE_CMD ps 2>/dev/null | grep -q "Up"
}

# Verifica se Docker è in esecuzione
if ! is_docker_running; then
    echo "⚠️  Docker non è in esecuzione. Tentativo di avvio..."

    # Prova ad avviare Docker (il comando dipende dal sistema)
    if command -v systemctl &> /dev/null; then
        echo "🚀 Avvio Docker con systemctl..."
        sudo systemctl start docker
        sleep 3
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🚀 Avvio Docker Desktop su macOS..."
        open -a Docker
        sleep 10
    else
        echo "❌ Non riesco ad avviare Docker automaticamente."
        echo "   Avvia Docker manualmente e riprova."
        exit 1
    fi

    # Ricontrolla
    if ! is_docker_running; then
        echo "❌ Docker non è stato avviato correttamente."
        exit 1
    fi
fi

echo "✅ Docker è in esecuzione"

# Naviga alla directory docker/wordpress-docker
DOCKER_DIR="$(dirname "$0")/../docker/wordpress-docker"
cd "$DOCKER_DIR" || exit 1

# Verifica se docker-compose è già attivo
if is_compose_running; then
    echo "✅ Docker Compose è già attivo"
    $COMPOSE_CMD ps
else
    echo "🚀 Avvio Docker Compose..."
    $COMPOSE_CMD up -d

    # Attendi che i servizi siano pronti
    echo "⏳ Attendo che i servizi siano pronti..."
    sleep 5

    # Verifica lo stato
    $COMPOSE_CMD ps

    if is_compose_running; then
        echo "✅ Docker Compose avviato con successo"
    else
        echo "⚠️  Alcuni servizi potrebbero non essere pronti"
    fi
fi

echo ""
echo "🎉 Docker pronto!"
