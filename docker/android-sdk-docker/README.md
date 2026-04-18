# Flutter Android Builder - Docker

Ambiente Docker completo per compilare APK Android senza installare SDK locali.

## Cosa include

- **Ubuntu 22.04** - Base stabile
- **Java 21** - Richiesto da Gradle/Kotlin
- **Flutter 3.32.8** - Versione stabile
- **Android SDK**:
  - Platform Tools (adb, fastboot)
  - Platforms: 33, 34, 35, 36
  - Build Tools: 34.0.0, 35.0.1
- **Android NDK 28.2.13676358** - Per codice nativo C/C++
- **CMake 3.22.1** - Per compilare progetti NDK

## Utilizzo rapido

### 1. Compilare l'APK (metodo semplice)

```bash
cd docker/android-sdk-docker
./build-apk.sh
```

**Prima volta**: Costruisce l'immagine Docker (5-10 minuti)
**Volte successive**: Usa la cache, molto più veloce!

L'APK sarà in: `build/app/outputs/flutter-apk/app-release.apk`

### 2. Compilare manualmente

#### Costruire l'immagine Docker:
```bash
docker build -t flutter-android-builder .
```

#### Compilare l'APK:
```bash
docker run --rm \
  -v $(pwd)/../..:/app \
  -w /app \
  flutter-android-builder \
  flutter build apk --release
```

#### Compilare APK split per ABI (più piccoli):
```bash
docker run --rm \
  -v $(pwd)/../..:/app \
  -w /app \
  flutter-android-builder \
  flutter build apk --release --split-per-abi
```

### 3. Modalità interattiva (per debug)

```bash
docker run -it --rm \
  -v $(pwd)/../..:/app \
  -w /app \
  flutter-android-builder \
  /bin/bash
```

Poi dentro il container:
```bash
flutter doctor -v        # Verifica ambiente
flutter pub get          # Scarica dipendenze
flutter build apk        # Compila
```

## Comandi utili

```bash
# Ricostruire l'immagine (se cambia Dockerfile)
docker build -t flutter-android-builder . --no-cache

# Vedere le immagini Docker
docker images | grep flutter

# Rimuovere l'immagine
docker rmi flutter-android-builder

# Vedere spazio occupato
docker images flutter-android-builder --format "{{.Size}}"
```

## Troubleshooting

### Errore di permessi sui file generati

I file creati dal container appartengono all'utente UID 1000. Se il tuo utente è diverso:

```bash
sudo chown -R $(id -u):$(id -g) build/
```

### Build fallisce con "Out of memory"

Aumenta la memoria disponibile per Docker:
- Docker Desktop: Settings → Resources → Memory (min 4GB)
- Linux: Modifica `/etc/docker/daemon.json`

### Aggiornare Flutter nel container

```bash
docker build -t flutter-android-builder . --no-cache
```

## Struttura file

```
android-sdk-docker/
├── Dockerfile          # Definizione ambiente
├── build-apk.sh        # Script automatico
└── README.md           # Questa guida
```

## Note

- **Dimensione immagine**: ~5-7 GB (include tutti gli SDK)
- **Cache Docker**: Le build successive sono molto più veloci
- **Portabilità**: Funziona su qualsiasi sistema con Docker
- **Nessuna installazione locale**: Non serve Flutter/Android SDK sul PC

## Requisiti

- Docker installato (o Podman)
- Almeno 10 GB di spazio disco libero
- Connessione internet (solo per la prima build)
