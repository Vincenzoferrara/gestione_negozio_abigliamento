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

# Nome dell'immagine Docker
IMAGE_NAME="flutter-android-builder"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APK_PATH="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-debug.apk"

# Step 0: Avvio Docker WordPress
echo -e "${BLUE}[0/4] Avvio Docker WordPress...${NC}"
bash "$PROJECT_ROOT/.vscode/start-docker.sh"
echo -e "${GREEN}✓ Docker WordPress pronto${NC}"
echo ""

# Step 1: Costruzione immagine Docker
echo -e "${BLUE}[1/3] Costruzione immagine Docker...${NC}"
docker build -t $IMAGE_NAME "$SCRIPT_DIR"
echo -e "${GREEN}✓ Immagine Docker creata${NC}"

# Step 2: Installazione dipendenze e compilazione APK
echo ""
echo -e "${BLUE}[2/3] Compilazione APK debug...${NC}"
docker run --rm \
    -v "$PROJECT_ROOT:/app:rw" \
    -v flutter-pub-cache:/root/.pub-cache \
    -w /app \
    $IMAGE_NAME \
    sh -c "flutter pub get && flutter build apk --debug"

# Verifica che l'APK sia stato creato
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}✗ Errore: APK non trovato${NC}"
    exit 1
fi

echo -e "${GREEN}✓ APK compilato con successo${NC}"
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "Dimensione: ${BLUE}$APK_SIZE${NC}"

# Step 3: Avvio emulatore (se necessario)
echo ""
echo -e "${BLUE}[3/4] Avvio emulatore (se necessario)...${NC}"

# Verifica che adb sia disponibile
if ! command -v adb &> /dev/null; then
    echo -e "${RED}✗ Errore: adb non trovato${NC}"
    exit 1
fi

# Verifica se emulatore è già in esecuzione
EMULATOR_RUNNING=$(adb devices | grep emulator | wc -l)
if [ "$EMULATOR_RUNNING" -eq 0 ]; then
    echo -e "Avvio emulatore pixel_35..."
    export ANDROID_SDK_ROOT=/opt/android-sdk
    nohup emulator -avd pixel_35 -no-snapshot-load -no-window -no-audio > /tmp/emulator.log 2>&1 &
    echo -e "Attendo che l'emulatore si avvii (può richiedere 30-60 secondi)..."
    adb wait-for-device
    # Aspetta che il boot sia completamente finito
    timeout 90 bash -c 'until adb shell getprop sys.boot_completed 2>/dev/null | grep -q 1; do sleep 2; done'
    sleep 5
    echo -e "${GREEN}✓ Emulatore avviato${NC}"
else
    echo -e "${GREEN}✓ Emulatore già in esecuzione${NC}"
fi

# Step 4: Installazione su emulatore
echo ""
echo -e "${BLUE}[4/4] Installazione su emulatore...${NC}"

# Trova l'emulatore
EMULATOR_ID=$(adb devices | grep emulator | awk '{print $1}' | head -1)
if [ -z "$EMULATOR_ID" ]; then
    echo -e "${RED}✗ Nessun emulatore trovato${NC}"
    exit 1
fi

echo -e "Emulatore: ${BLUE}$EMULATOR_ID${NC}"

# Disinstalla vecchia versione se presente
echo ""
echo -e "Rimozione versione precedente (se presente)..."
adb -s "$EMULATOR_ID" uninstall com.example.gestione_negozio_abigliamento 2>/dev/null || echo "Nessuna versione precedente trovata"

# Installa l'APK
echo ""
echo -e "Installazione APK su emulatore..."
adb -s "$EMULATOR_ID" install "$APK_PATH"

# Configura ADB reverse proxy per accedere a localhost del PC
echo ""
echo -e "Configurazione ADB reverse proxy per WordPress..."
adb -s "$EMULATOR_ID" reverse tcp:8080 tcp:8080
adb -s "$EMULATOR_ID" reverse tcp:8081 tcp:8081
echo -e "${GREEN}✓ Porta 8080 (WordPress) e 8081 (phpMyAdmin) inoltrate${NC}"

echo ""
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}✓ Installazione completata!${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo -e "APK installato da:"
echo -e "${BLUE}$APK_PATH${NC}"
echo ""
echo -e "${YELLOW}Nota: Puoi usare http://localhost:8080 nell'app${NC}"
echo ""
