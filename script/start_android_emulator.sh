#!/usr/bin/env bash

# Avvia un AVD Android locale e attende il completamento del boot.
set -euo pipefail

AVD_NAME="${1:-pixel_36}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/opt/android-sdk}}"
EMULATOR="$ANDROID_SDK_ROOT/emulator/emulator"
ADB="$ANDROID_SDK_ROOT/platform-tools/adb"
EMULATOR_LOG="${TMPDIR:-/tmp}/flutter-android-emulator-${AVD_NAME}.log"

if [[ ! -x "$EMULATOR" || ! -x "$ADB" ]]; then
  echo "Android SDK locale non trovato in: $ANDROID_SDK_ROOT" >&2
  echo "Imposta ANDROID_SDK_ROOT oppure installa emulator e platform-tools." >&2
  exit 1
fi

if ! "$EMULATOR" -list-avds | grep -Fxq "$AVD_NAME"; then
  echo "AVD '$AVD_NAME' non trovato. AVD disponibili:" >&2
  "$EMULATOR" -list-avds >&2
  exit 1
fi

"$ADB" start-server >/dev/null

wait_for_android_boot() {
  timeout 180 "$ADB" wait-for-device
  timeout 180 bash -c "until '$ADB' shell getprop sys.boot_completed 2>/dev/null | grep -qx '1'; do sleep 2; done"
  "$ADB" shell getprop ro.build.version.sdk >/dev/null
}

configure_reverse_proxy() {
  for port in 8080 8081; do
    "$ADB" reverse "tcp:$port" "tcp:$port"
  done
  echo "Inoltro ADB attivo: localhost:8080 e localhost:8081 dell'emulatore puntano al PC."
}

if "$ADB" devices | awk 'NR > 1 && $1 ~ /^emulator-/ && $2 == "device" { found = 1 } END { exit !found }'; then
  echo "Un emulatore Android e' gia' avviato."
  echo "Verifico che Android sia pronto..."
  wait_for_android_boot
  configure_reverse_proxy
  exit 0
fi

echo "Avvio dell'emulatore Android locale '$AVD_NAME'..."
# setsid separa l'emulatore dal task VS Code: il task puo terminare senza
# inviare il proprio segnale di arresto anche al processo dell'emulatore.
setsid --fork "$EMULATOR" -avd "$AVD_NAME" -no-snapshot-load >"$EMULATOR_LOG" 2>&1

echo "Attendo il completamento del boot..."
wait_for_android_boot

echo "Emulatore '$AVD_NAME' pronto."
configure_reverse_proxy
