#!/usr/bin/env bash

# Avvio debug locale con contatore build solo-debug.
# Il numero NON tocca pubspec.yaml ne le release CI/GitHub: viaggia solo
# via --dart-define e l'app lo mostra solo nelle build debug (kDebugMode).
# Uso: script/run_debug.sh -d emulator-5554 [altri argomenti flutter run]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COUNTER="$ROOT/.debug_build_nr"

n=0
if [[ -f "$COUNTER" ]]; then
  n="$(cat "$COUNTER")"
fi
[[ "$n" =~ ^[0-9]+$ ]] || n=0
n=$((n + 1))
echo "$n" >"$COUNTER"

echo "Build debug locale #$n"
exec flutter run --dart-define="DEBUG_BUILD_NR=$n" "$@"
