#!/bin/bash

# Script per fermare Docker Compose quando si chiude VSCode

echo "🛑 Arresto Docker Compose..."

# Usa il comando docker compose moderno (senza trattino)
COMPOSE_CMD="docker compose"

# Naviga alla directory docker
DOCKER_DIR="$(dirname "$0")/../docker"
cd "$DOCKER_DIR" || exit 1

# Ferma docker-compose
$COMPOSE_CMD down

echo "✅ Docker Compose arrestato"

# Opzionale: ferma anche Docker daemon (commentato di default)
# Se vuoi fermare anche il daemon Docker, decommenta le righe seguenti:
#
# echo "🛑 Arresto Docker daemon..."
# if command -v systemctl &> /dev/null; then
#     sudo systemctl stop docker
# fi
# echo "✅ Docker daemon arrestato"
