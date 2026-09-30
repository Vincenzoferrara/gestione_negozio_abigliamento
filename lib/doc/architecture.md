# Architecture

## Layers

- Flutter UI
- Screen logic
- Domain services
- Backend connectors

## Folder structure

- Each main page or module lives in a dedicated folder under `lib/`.
- UI and screen logic are split into sibling files when the module is large enough:
  - `module_name.gui.dart` for widgets, layout and user interaction
  - `module_name.code.dart` for state, orchestration and screen logic
- `lib/reuse_class/` contains reusable components and shared utilities.
- `lib/reuse_class/barcode/` centralizes barcode scanning and internal barcode generation.
- `lib/reuse_class/datagridview/` contains the shared table grid used by operational tables.
- `lib/reuse_class/device_utils/` classifies smartphone, tablet and desktop layouts.
- `login/jwt_api/` is the integration layer for WordPress, WooCommerce and MGWS connectors.
- `settings/` contains app settings and module settings views.

## Settings architecture

`settings.gui.dart` is the settings container. Module-specific settings must have their own view and must not be mixed into unrelated global settings. `AppSettings` should contain only truly global settings or settings used by global classes.

## Main nodes

- `main.dart` starts the app, theme, localization and runtime services.
- `home/` controls navigation and desktop docking.
- `login/` manages authentication and authenticated connectors.
- `settings/` stores global preferences and module settings views.
- `inventory/` manages MGWS stock operations and movement ledger UI.
- `cassa/` delegates POS checkout to MGWS and keeps local POS receipt history.
- `dashboard/` loads and exports analytical data.

## MGWS contract

- `login/jwt_api/query_mgws/` contains MGWS clients used by the app.
- `WooConnect` owns authenticated transport and site URL state.
- MGWS clients must not create separate connectors.
- `QueryMgwsPos` handles idempotent POS checkout.
- `QueryMgwsInventory` handles stock reads, stock writes, movement ledger, suppliers, reordering, purchase orders, receptions and counts.
- `QueryMgwsLoyalty` handles loyalty service status, customer lookup, cards, points and history.
- Employee roles/capabilities are managed only for MGWS employees linked to a WordPress user.

## Login and security

Login is the most sensitive part of the app. Every change to login must be reviewed for security risk. No insecure fallback or temporary credential shortcut is allowed.

## Privacy and de-Googled design

The app must remain privacy-first. Google services must not be a base architectural dependency. If a feature can work without Google, it must be able to work without Google. Hidden tracking, telemetry, ads and unnecessary data collection are not allowed.

## Principles

- UI and backend remain separated.
- Dependencies on external WordPress plugins pass through MGWS.
- WooCommerce remains the e-commerce engine.
- MGWS manages custom operational logic and POS.
- The Flutter app talks directly only with WooCommerce and MGWS inside the WordPress perimeter.
- Persistent shared data must pass through WordPress/MGWS.
- Temporary UI state stays in Flutter.
