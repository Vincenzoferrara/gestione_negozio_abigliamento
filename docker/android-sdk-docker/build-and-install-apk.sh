#!/bin/bash

# Script Compilazione Flutter per Android
# Semplice, veloce, diretto

set -uo pipefail

# ========================================
# COLORI E LOGGING
# ========================================

declare -r RED='\033[0;31m' GREEN='\033[0;32m' BLUE='\033[0;34m' \
          CYAN='\033[0;36m' MAGENTA='\033[0;35m' NC='\033[0m'

declare -r LOG_DIR="${XDG_STATE_HOME:-.}/.flutter_build_logs"
declare -r LOG_FILE="$LOG_DIR/build_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

log_base() {
    local level="$1" color="$2" && shift 2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${color}[$level]${NC} $*"
    echo "[$timestamp] [$level] $*" >> "$LOG_FILE"
}

log_info() { log_base "INFO" "$BLUE" "$@"; }
log_success() { log_base "SUCCESS" "$GREEN" "$@"; }
log_error() { log_base "ERROR" "$RED" "$@" >&2; }

# ========================================
# PERCORSI COSTANTI
# ========================================

declare -r SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -r PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
declare -r APK_PATH="$PROJECT_ROOT/build/app/outputs/flutter-apk"
declare -r BUILD_GRADLE="$PROJECT_ROOT/android/app/build.gradle.kts"
declare -r PUBSPEC_FILE="$PROJECT_ROOT/pubspec.yaml"
declare -r DOCKER_IMAGE="ghcr.io/cirruslabs/flutter:latest"
declare -r MIN_SDK=21

trap 'log_error "Build interrotto"; exit 1' ERR

# ========================================
# FUNZIONI UTILITÀ
# ========================================

get_local_dependencies() {
    local -a deps=()
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*[a-z_]+:[[:space:]]*$ ]]; then
            IFS= read -r next_line
            if [[ $next_line =~ path:[[:space:]]*\"?([^\"]+)\"? ]]; then
                local full_path=$(cd "$PROJECT_ROOT" && cd "${BASH_REMATCH[1]}" 2>/dev/null && pwd)
                [[ -d "$full_path" ]] && deps+=("$full_path")
            fi
        fi
    done < "$PUBSPEC_FILE"
    printf '%s\n' "${deps[@]}"
}

configure_android() {
    log_info "Configurazione minSdk=$MIN_SDK..."
    if grep -q "minSdk\s*=" "$BUILD_GRADLE"; then
        sed -i "s/minSdk\s*=\s*[0-9]\+/minSdk = $MIN_SDK/" "$BUILD_GRADLE"
    else
        sed -i "/defaultConfig\s*{/a\\        minSdk = $MIN_SDK" "$BUILD_GRADLE"
    fi
    log_success "Configurazione completata"
}

clean_caches() {
    log_info "Pulizia cache..."
    rm -rf "$PROJECT_ROOT/build" "$PROJECT_ROOT/.dart_tool" "$PROJECT_ROOT/.gradle" "$PROJECT_ROOT/android/.gradle" 2>/dev/null
    log_success "Cache pulita"
}

get_common_path() {
    local common="$PROJECT_ROOT"
    local -a deps
    mapfile -t deps < <(get_local_dependencies)
    
    for dep in "${deps[@]}"; do
        local prefix=$(printf '%s\n' "$PROJECT_ROOT" "$dep" | sed -e 'N;s/^\(.*\)\/.*\n\1\/.*$/\1/')
        [[ -z "$prefix" ]] && prefix="/"
        [[ ${#prefix} -lt ${#common} ]] && common="$prefix"
    done
    echo "$common"
}

# ========================================
# BUILD PROCESS
# ========================================

build_local() {
    log_info "Build Locale"
    export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
    export PATH="$JAVA_HOME/bin:$PATH"
    
    configure_android
    cd "$PROJECT_ROOT" || return 1
    
    log_info "Compilazione..."
    local start=$(date +%s)
    flutter build apk --release || return 1
    
    local duration=$(($(date +%s) - start))
    [[ -f "$APK_PATH/app-release.apk" ]] && {
        log_success "Build completato in ${duration}s - Size: $(du -h "$APK_PATH/app-release.apk" | cut -f1)"
        return 0
    }
    log_error "APK non generato"
    return 1
}

build_docker() {
    log_info "Build Docker: $DOCKER_IMAGE"
    configure_android
    
    log_info "Pull immagine..."
    docker pull "$DOCKER_IMAGE" || return 1
    
    clean_caches
    
    local common_path=$(get_common_path)
    local volumes="-v $common_path:$common_path"
    
    log_info "Struttura montata: $common_path"
    local -a deps
    mapfile -t deps < <(get_local_dependencies)
    for dep in "${deps[@]}"; do
        log_info "  ├── $(basename "$dep")"
    done
    
    log_info "Compilazione in container..."
    local start=$(date +%s)
    
    docker run $volumes -w "$PROJECT_ROOT" "$DOCKER_IMAGE" \
        bash -c "flutter build apk --release" || return 1
    
    local duration=$(($(date +%s) - start))
    [[ -f "$APK_PATH/app-release.apk" ]] && {
        log_success "Build completato in ${duration}s - Size: $(du -h "$APK_PATH/app-release.apk" | cut -f1)"
        return 0
    }
    log_error "APK non generato"
    return 1
}

# ========================================
# MENU PRINCIPALE
# ========================================

show_apk() {
    echo ""
    echo -e "${MAGENTA}===== APK Generati =====${NC}"
    [[ ! -d "$APK_PATH" ]] && log_error "Nessun APK" && return
    
    local count=0
    for apk in "$APK_PATH"/*.apk; do
        [[ -f "$apk" ]] && echo -e "  ${CYAN}$(basename "$apk")${NC} - $(du -h "$apk" | cut -f1)" && ((count++))
    done
    [[ $count -eq 0 ]] && log_error "Nessun APK disponibile"
    echo ""
}

show_devices() {
    clear
    echo -e "${MAGENTA}===== Dispositivi Android =====${NC}\n"
    command -v adb &>/dev/null || { log_error "ADB non installato"; read -p "Premi Invio..."; return; }
    
    local -a devices=($(adb devices 2>/dev/null | grep -w "device" | awk '{print $1}'))
    [[ ${#devices[@]} -eq 0 ]] && { log_error "Nessun dispositivo"; read -p "Premi Invio..."; return; }
    
    local i=1
    for device in "${devices[@]}"; do
        local model=$(adb -s "$device" shell getprop ro.product.model 2>/dev/null || echo "?")
        local android=$(adb -s "$device" shell getprop ro.build.version.release 2>/dev/null || echo "?")
        local api=$(adb -s "$device" shell getprop ro.build.version.sdk 2>/dev/null | grep -o '[0-9]\+' | head -1 || echo "?")
        local status=$([[ $api -ge 21 ]] && echo "${GREEN}✓${NC}" || echo "${RED}✗${NC}")
        echo -e "  $((i++))) ${CYAN}$device${NC} - $model (Android $android, API $api) $status"
    done
    echo ""
    read -p "Premi Invio..."
}

show_status() {
    clear
    echo -e "${MAGENTA}===== Stato Progetto =====${NC}\n"
    echo -e "${BLUE}Flutter:${NC} $(flutter --version 2>/dev/null | head -1 || echo "non disponibile")"
    echo -e "${BLUE}Progetto:${NC} $PROJECT_ROOT"
    echo -e "${BLUE}minSdk:${NC} $MIN_SDK (Android 5.0+)"
    [[ -d "$APK_PATH" ]] && echo -e "${BLUE}APK:${NC} $(find "$APK_PATH" -name "*.apk" -type f 2>/dev/null | wc -l)"
    echo -e "${BLUE}Log:${NC} $LOG_FILE"
    echo ""
    read -p "Premi Invio..."
}

main() {
    mkdir -p "$APK_PATH"
    
    while true; do
        clear
        echo -e "${MAGENTA}================================${NC}"
        echo -e "${MAGENTA}  Flutter Build (minSdk: $MIN_SDK)${NC}"
        echo -e "${MAGENTA}================================${NC}\n"
        echo -e "  ${CYAN}1)${NC} Compila Locale"
        echo -e "  ${CYAN}2)${NC} Compila Docker"
        echo -e "  ${CYAN}3)${NC} Mostra dispositivi"
        echo -e "  ${CYAN}4)${NC} Visualizza APK"
        echo -e "  ${CYAN}5)${NC} Stato progetto"
        echo -e "  ${CYAN}6)${NC} Pulisci cache"
        echo -e "  ${CYAN}0)${NC} Esci\n"
        echo -n "Scelta: "
        
        read -r choice
        case $choice in
            1) build_local && show_apk; exit 0 ;;
            2) build_docker && show_apk; exit 0 ;;
            3) show_devices ;;
            4) show_apk && read -p "Premi Invio..." ;;
            5) show_status ;;
            6) clean_caches && read -p "Premi Invio..." ;;
            0) log_info "Uscita..."; exit 0 ;;
            *) log_error "Scelta non valida"; sleep 1 ;;
        esac
    done
}

main "$@"