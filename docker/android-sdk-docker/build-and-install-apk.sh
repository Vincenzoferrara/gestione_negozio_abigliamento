#!/bin/bash
# Script per compilare e installare l'APK Android su dispositivo USB

set -e  # Esce in caso di errore

# Colori per output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}  Flutter APK Build & Install${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# Immagine Docker standard (nessun build necessario)
IMAGE_NAME="instrumentisto/flutter"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APK_PATH="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-debug.apk"

# Step 1: Compilazione APK debug
echo -e "${BLUE}[1/2] Compilazione APK debug...${NC}"
echo -e "Pulizia cache e sincronizzazione dipendenze..."
docker run \
    -v "$PROJECT_ROOT:/app:rw" \
    -w /app \
    -t \
    $IMAGE_NAME \
    sh -c "flutter build apk --debug -v"

# Verifica che l'APK sia stato creato
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}✗ Errore: APK non trovato${NC}"
    exit 1
fi

echo -e "${GREEN}✓ APK compilato con successo${NC}"
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "Dimensione: ${BLUE}$APK_SIZE${NC}"

# Step 2: Installazione su dispositivo USB
echo ""
echo -e "${BLUE}[2/2] Installazione su dispositivo USB...${NC}"

# Verifica che adb sia disponibile
if ! command -v adb &> /dev/null; then
    echo -e "${RED}✗ Errore: adb non trovato${NC}"
    echo -e "${YELLOW}Installa Android SDK Platform Tools per usare adb${NC}"
    exit 1
fi

# Verifica dispositivi connessi
DEVICES=$(adb devices | grep -w "device" | wc -l)
if [ "$DEVICES" -eq 0 ]; then
    echo -e "${RED}✗ Nessun dispositivo Android connesso${NC}"
    echo -e "${YELLOW}Collega il dispositivo via USB e abilita il debug USB${NC}"
    exit 1
fi

# Mostra dispositivi connessi
echo -e "Dispositivi connessi:"
adb devices | grep -w "device"

# Disinstalla vecchia versione se presente (per evitare conflitti di firma)
echo ""
echo -e "Rimozione versione precedente (se presente)..."
adb uninstall com.example.gestione_negozio_abigliamento 2>/dev/null || echo "Nessuna versione precedente trovata"

# Installa l'APK
echo ""
echo -e "Installazione APK su dispositivo..."
adb install "$APK_PATH"

echo ""
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}✓ Installazione completata!${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo -e "APK installato da:"
echo -e "${BLUE}$APK_PATH${NC}"
echo ""
