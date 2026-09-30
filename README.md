# Gestione Negozio Abbigliamento

A Flutter management app for clothing stores: point of sale, product catalog, stock operations, orders, customers, loyalty cards, reports and WordPress/WooCommerce integration through MGWS.

The app is designed for shops that want a self-hosted backend and a privacy-first front end. The WordPress side is handled by WooCommerce and the MG Warehouse Stock plugin; the Flutter app talks only to WooCommerce and MGWS for WordPress-related features.

## Highlights

- POS cashier workflow with local shift history and MGWS checkout
- Product catalog, variants, images, barcode and bulk operations
- MGWS inventory operations: add stock, reconcile stock, move stock and inspect the movement ledger
- WooCommerce orders, customers, coupons and dashboard reports
- Loyalty cards and points through MGWS
- RFID, barcode and QR workflows
- Desktop updates on Windows/Linux through Velopack
- Android releases installable from GitHub or Obtainium

## Download

[![Google Play](https://img.shields.io/badge/Google%20Play-Coming%20soon-414141?style=for-the-badge&logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=it.mgws.gestione_negozio_abbigliamento)
[![F-Droid](https://img.shields.io/badge/F--Droid-Coming%20soon-1976d2?style=for-the-badge&logo=fdroid&logoColor=white)](https://f-droid.org/packages/it.mgws.gestione_negozio_abbigliamento/)
[![Obtainium](https://img.shields.io/badge/Obtainium-Install-2563eb?style=for-the-badge&logo=obtainium&logoColor=white)](obtainium://add?url=https%3A%2F%2Fgithub.com%2FVincenzoferrara%2Fgestione_negozio_abigliamento)

> Google Play and F-Droid listings are not public yet. Use GitHub Releases or Obtainium until the store pages are available.

### Android

- Latest release: <https://github.com/Vincenzoferrara/gestione_negozio_abigliamento/releases/latest>
- Signed APK: <https://github.com/Vincenzoferrara/gestione_negozio_abigliamento/releases/latest/download/gestione_neogzio_abbigliameto.apk>
- Signed AAB: <https://github.com/Vincenzoferrara/gestione_negozio_abigliamento/releases/latest/download/gestione_neogzio_abbigliameto.aab>
- Obtainium source URL: `https://github.com/Vincenzoferrara/gestione_negozio_abigliamento`
- Obtainium deep link: `obtainium://add?url=https%3A%2F%2Fgithub.com%2FVincenzoferrara%2Fgestione_negozio_abigliamento`

The release asset names currently contain the historical typo `gestione_neogzio_abbigliameto`; keep those names in direct links until the release pipeline changes them.

### Windows

- Installer: <https://github.com/Vincenzoferrara/gestione_negozio_abigliamento/releases/latest/download/gestione_negozio_abbigliamento-win-Setup.exe>
- Portable ZIP: <https://github.com/Vincenzoferrara/gestione_negozio_abigliamento/releases/latest/download/gestione_negozio_abbigliamento-win-Portable.zip>

### Linux

- AppImage: <https://github.com/Vincenzoferrara/gestione_negozio_abigliamento/releases/latest/download/gestione_negozio_abbigliamento.AppImage>

## Screenshots

Screenshots for the README, Google Play and F-Droid metadata are planned but are not stored in the repository yet. The preferred targets are:

- Android phone screenshots for F-Droid/Google Play store metadata
- Desktop screenshots for GitHub README preview
- Main flows: Login, Home, POS, Products, Product editor, MGWS Inventory, Orders, Dashboard, Loyalty Cards and Settings

Recommended future layout:

```text
fastlane/metadata/android/en-US/images/phoneScreenshots/
docs/screenshots/android/
docs/screenshots/desktop/
```

## WordPress plugin

The companion WordPress plugin is **MG Warehouse Stock**:

- GitHub: <https://github.com/Vincenzoferrara/mg-warehouse-stock>
- WordPress.org listing: not public yet

MGWS provides stock locations, stock movements, POS checkout, loyalty, employees, permissions, suppliers, purchasing, receiving and inventory count APIs. Optional third-party WordPress plugins must stay behind MGWS; the Flutter app must not integrate directly with ATUM, myCred or similar plugins.

## Documentation

- [Documentation index](lib/doc/README.md)
- [Installation](lib/doc/installation.md)
- [User guide](lib/doc/user-guide.md)
- [Developer guide](lib/doc/developer-guide.md)
- [Architecture](lib/doc/architecture.md)
- [Integrations](lib/doc/integrations.md)

## Build from source

Requirements:

- Flutter `>=3.41.2`
- Dart SDK `>=3.11.0 <4.0.0`
- Android SDK for Android builds
- A configured WordPress/WooCommerce/MGWS backend for real data flows

Basic commands:

```bash
flutter pub get
flutter run
```

Android release artifacts require the local release signing setup used by the project release scripts.

## Project structure

```text
lib/
  cassa/          POS cashier and local POS history
  prodotti/       product catalog, editor, images and variants
  inventory/      MGWS stock operations and movement ledger
  ordini/         WooCommerce orders
  clienti/        WooCommerce customers
  carta_fedelta/  MGWS loyalty cards and points
  dashboard/      sales, orders, products and stock analytics
  settings/       global and module-specific settings
  login/          authentication connectors and API clients
  reuse_class/    shared UI and domain utilities
  doc/            current project documentation
```

## Contributing

Read [Developer Guide](lib/doc/developer-guide.md) before changing code. Documentation under `lib/doc` describes the current behavior only; keep backlog, historical notes and personal decisions out of it.
