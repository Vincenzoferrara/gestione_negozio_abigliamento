# Guida alla migrazione al tema

Obiettivo: **tutta la grafica deve fare riferimento al tema**. Nessun colore,
raggio o spaziatura scritto a mano dentro i `.gui.dart`.

## Sorgenti di verità

- `lib/theme/theme.dart` — `AppTheme`, `AppColorExtension`, `AppShapeExtension`,
  `AppSpacingExtension`, e l'estensione `AppThemeContext` su `BuildContext`.

## Accessori (usa questi, non `Theme.of(context).extension<T>()!` a mano)

```dart
context.colors    // AppColorExtension
context.shapes    // AppShapeExtension
context.spacing   // AppSpacingExtension
context.text      // TextTheme
context.theme     // ThemeData
```

Se in un file non è disponibile `context`, passa la `ThemeData` dentro e usa
`theme.extension<AppColorExtension>()!` come già fanno i pannelli inventario.

## Mappa colori

| Hardcoded | Sostituzione | Note |
|---|---|---|
| `Colors.red`, `Colors.redAccent` (icona/label di errore o elimina) | `context.colors.errorColorStatus` | |
| `Colors.red` (status ordine "fallito", badge) | `context.colors.errorColorStatus` | |
| `Colors.green`, `Colors.greenAccent` (ok/valido) | `context.colors.successColor` | |
| `Colors.orange`, `Colors.amber` (attenzione/pending) | `context.colors.warningColor` | |
| `Colors.blue` (informazione, stato "inviato") | `context.colors.infoColor` | vedi *colori di brand* |
| `Colors.grey`, `Colors.grey.shadeNNN` (testo secondario) | `context.colors.subtitleColor` | |
| `Colors.grey.shade900` (fondo pannello vuoto) | `context.colors.surfaceVariantColor` | |
| `Colors.white` / `Colors.black` (testo su gradiente o chip colorato) | **LASCIARE** | vedi *eccezioni* |
| `Colors.black87`, `Colors.white70` (testo su superficie) | `context.text.bodyLarge?.color` | |
| `Colors.transparent` | **LASCIARE** | è un valore neutro, non un colore di tema |

## Eccezioni: cosa NON convertire

1. **Testo/icone bianchi su gradiente o chip colorato.** Se lo sfondo è un
   gradiente o un `Container(color: <colore pieno>)`, il bianco serve a garantire
   il contrasto. Cambiarlo in `subtitleColor` lo rende illeggibile su gradiente
   rosso. Vedi `ordini_in_arrivo.gui.dart`, `carta_fedelta.gui.dart`,
   `coupon_gestisci*.gui.dart`, `cassa.gui.dart`, `dashboard.gui.dart`.

2. **Colori di brand.** `Colors.blue` per Meta/Facebook Ads,
   `Colors.black` per TikTok, `Colors.red` per Google Ads, le stelle oro/argento/
   bronzo di carta fedelta. Sono identità del brand, non tema.

3. **Icone decorative a grandezza fissa** dentro un badge colorato pieno
   (es. `Icon(Icons.stars, color: Colors.white, size: 28)`).

## Forme

`BorderRadius.circular(N)` → `context.shapes.<nome>`:

| N | accessor |
|---|---|
| 4 | `.xs` |
| 8 | `.s` |
| 9, 10 | `.s` |
| 12 | `.m` |
| 14, 16 | `.l` |
| 18, 20 | `.xl` |
| 999 | `.full` |

Usa `RoundedRectangleBorder(borderRadius: context.shapes.m)` mantenendo lo stile
già presente nel file.

## Spaziature

`EdgeInsets.all/symmetric(N)` → `context.spacing.<nome>`:

| N | accessor |
|---|---|
| 4 | `.xs` |
| 8 | `.iS` / `.hS` / `.vS` |
| 12 | `.iM` / `.hM` / `.vM` |
| 16 | `.iL` / `.hL` / `.vL` |
| 20, 24 | `.iXL` |
| 32 | `.iXXL` |

## Tipografia

`TextStyle(fontSize: N, ...)` → `context.text.<slot>?.copyWith(...)`.

| fontSize | slot |
|---|---|
| 32, 28 | `headlineLarge` |
| 24 | `headlineMedium` |
| 20 | `headlineSmall` |
| 18 | `titleLarge` |
| 16 | `titleMedium` |
| 14 | `titleSmall` |
| 12 | `bodyMedium` |
| 11, 10 | `bodySmall` |

Attenzione: se il `TextStyle` hardcoded ha **già** `color:`, conserva il
`copyWith` solo per il resto. Se il colore è bianco su sfondo colorato, lascialo.

## Elevazione

`elevation: 4` è già il default di `cardTheme`. **Rimuovi** gli `elevation: 4`
in esplicito su `Card` invece di tema-izzarli: lasciare l'override è più
 rumoroso che utile. Lascia `elevation: 0` (è una scelta deliberata di appiattire).

## Verifica

```bash
flutter analyze lib/            # deve restare "No issues found!"
flutter test                   # baseline: 18 test falliti (pre-esistenti)
```

I test `product_visual_refresh_test`, `filters_bar_layout_test`,
`woo_variation_parsing_test`, `woo_variations_e2e_test` fallono **prima** di
questa migrazione. I test `woo_*` che parlano con il server sono flaky.
Non introdurre regressioni: se un test passa prima e fallisce dopo, il lavoro
non è finito.