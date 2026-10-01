# Configuration

## Settings structure

Settings are split by responsibility:

- global settings for app-wide behavior
- module settings for a specific feature area
- backend settings for WordPress/WooCommerce/MGWS connectivity

A module-specific setting should stay near the module it configures. Do not add unrelated settings to a generic global bucket.

## Backend

The backend settings define the WordPress site and connector behavior. The app must consider only two WordPress-side providers valid:

- WooCommerce
- MGWS

If a deployment uses plugins such as ATUM or myCred, that choice must stay inside MGWS. The Flutter app must not talk to those plugins directly.

## Login and credentials

The login flow supports JWT, WooCommerce API credentials and WordPress Admin credentials. Sensitive credentials must be stored securely and must not be synced through generic user settings.

The employee `Active credentials` section requires `mgws_manage_credentials`, which MGWS grants only to administrators. Non-admin users can still manage the parts of employee roles/capabilities they are allowed to access, but credential revocation is not operational for them.

`DELETE /employees/{id}` disables the employee in MGWS; it does not automatically revoke WordPress Application Passwords or WooCommerce keys. Revoke those from the employee credentials section when needed.

## Products

Product settings cover catalog behavior, images, variants, barcode handling and bulk actions. Product image thresholds are informative: they show whether an image is compliant, out of spec, has no spec or cannot be checked, but they do not block saving.

## Inventory

Inventory settings support MGWS workflows. MGWS remains the authoritative source for operational stock and movement ledger data.

## Theme and layout

Theme settings are global. Layout adapts to smartphone, tablet and desktop using shared device utilities.

`Background follows light/dark theme` defaults to `true`: a fresh install follows the light or dark theme for decorative backgrounds. Disabling it makes the backgrounds use the selected primary colour instead. The default only applies when no value is stored, so a value saved by the user is never overwritten.

## Interface language

The language selector is a dropdown with the system language first and the supported languages after it. Selecting the system language passes `null` to `MaterialApp.locale`, so Flutter resolves the best supported locale and falls back to English. A language stored in preferences that is no longer supported is ignored at load time instead of freezing the app on a missing locale.

A language change must reach every visible string without a restart. A widget that stays mounted across the change has to read its translations in `build` on its own `BuildContext`: reading them once and storing the result in a field, or in a list captured by a widget inserted once into the docking layout, keeps the strings of the previous language. The home landing page therefore takes a section builder instead of a prebuilt list, so the `Localizations` lookup happens during its build and the page rebuilds with the new language.

Tab titles are the exception, because the docking library reads them from `DockingItem.name`, a plain string, and exposes no builder for the label. `HomeLogic.aggiornaTitoli` re-resolves every open tab and rewrites the name in place while the widget tree is rebuilding, so the same rebuild picks the new labels up without a `setState`. The instance suffix (`#2`, `#3`) is stored once per tab in `HomeTabMeta.istanza` and reapplied on every refresh, so closing a tab does not renumber the ones left open.

## AI providers

AI provider configuration is optional. Do not make any AI provider a required runtime dependency for basic store operations.

## RFID and smartcard

RFID and smartcard settings affect only related workflows. They must not change the standard login or stock paths unless explicitly selected by the user.
