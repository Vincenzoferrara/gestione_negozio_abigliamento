# Desktop Background Removal - Binary Bundlato

Architettura unica adottata:

- Flutter desktop frontend
- Motore remove background esterno, binario locale bundlato
- Invocazione via `Process.run` con input/output file

## Struttura cartelle consigliata

```text
tools/
  bg_engine/
    windows/
      backgroundremover.exe
    linux/
      backgroundremover
    macos/
      backgroundremover

lib/
  background_removal_cli/
    process_runner.dart
    temp_file_manager.dart
    background_removal_service.dart
    background_removal_controller.dart
    background_removal_desktop_page.dart
```

## Risoluzione path binary (implementata)

Ordine di lookup:

1. Variabile ambiente `BG_REMOVER_BIN`
2. Path bundlato vicino all'app installata:
   - Windows: `<exeDir>/bg_engine/backgroundremover.exe`
   - Linux: `<exeDir>/bg_engine/backgroundremover`
   - macOS: `<exeDir>/../Resources/bg_engine/backgroundremover`
3. Path sviluppo locale:
   - `tools/bg_engine/<platform>/...`

## Packaging Windows

In `windows/CMakeLists.txt`, dopo la build del target, copia la cartella `tools/bg_engine/windows` nel bundle output:

```cmake
add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E make_directory
          "$<TARGET_FILE_DIR:${BINARY_NAME}>/bg_engine"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
          "${CMAKE_SOURCE_DIR}/../tools/bg_engine/windows/backgroundremover.exe"
          "$<TARGET_FILE_DIR:${BINARY_NAME}>/bg_engine/backgroundremover.exe"
)
```

## Packaging Linux

In `linux/CMakeLists.txt`, copia il binary nel bundle output e applica permessi esecuzione:

```cmake
add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E make_directory
          "$<TARGET_FILE_DIR:${BINARY_NAME}>/bg_engine"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
          "${CMAKE_SOURCE_DIR}/../tools/bg_engine/linux/backgroundremover"
          "$<TARGET_FILE_DIR:${BINARY_NAME}>/bg_engine/backgroundremover"
  COMMAND chmod +x "$<TARGET_FILE_DIR:${BINARY_NAME}>/bg_engine/backgroundremover"
)
```

## Packaging macOS

In `macos/Runner.xcodeproj` (Run Script phase) o CMake equivalente, copia in `Runner.app/Contents/Resources/bg_engine`:

```bash
mkdir -p "$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Resources/bg_engine"
cp "$PROJECT_DIR/../tools/bg_engine/macos/backgroundremover" \
   "$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Resources/bg_engine/backgroundremover"
chmod +x "$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH/Resources/bg_engine/backgroundremover"
```

## Problemi reali da considerare

- Path diversi tra Windows/macOS/Linux (gestiti nel resolver)
- Permessi esecuzione su Unix/macOS (`chmod +x`)
- Asset Flutter non adatti per executable (va copiato come file esterno bundle)
- Peso installer maggiore (binary ML)
- Primo avvio più lento su macchine lente (inizializzazione modello)

## Pipeline runtime implementata

1. Selezione immagine (FilePicker)
2. Copia in cartella temp di lavoro
3. Avvio binary con `-i input -o output`
4. Lettura PNG risultante in memoria
5. Anteprima in UI
6. Salvataggio finale con Save dialog
