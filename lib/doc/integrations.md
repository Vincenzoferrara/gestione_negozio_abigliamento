# Integrations

## WordPress perimeter

The Flutter app integrates with WordPress through two approved providers:

- WooCommerce
- MGWS

The app must not integrate directly with ATUM, myCred or other WordPress plugins. If those plugins are used by a shop, MGWS must expose the needed behavior as its own API or gateway.

## MG Warehouse Stock

MGWS is the operational backend for:

- stock levels and locations
- movement ledger
- POS checkout
- loyalty accounts, cards and points
- employees and permissions
- suppliers, purchase orders and receiving
- physical inventory counts
- management reports and custom operational flows

Companion plugin repository: <https://github.com/Vincenzoferrara/mg-warehouse-stock>

## WooCommerce

WooCommerce remains the e-commerce source for:

- products and variants
- orders
- coupons
- customers
- standard e-commerce data exposed by WooCommerce APIs

The cashier flow delegates POS checkout to MGWS; MGWS creates the WooCommerce order and records the operational audit data.

## Authentication

Supported authentication paths include JWT, WooCommerce API credentials and WordPress Admin credentials. The JWT connector checks for known JWT routes before sending username/password; if the routes are absent, login fails without sending credentials to the backend.

`WooConnect` is the owner of authenticated transport. MGWS queries build requests on the same authenticated transport, so MGWS routes use the credentials of the active session.

## User settings sync

`GET/PATCH /wp-json/mgws/v1/me/settings` synchronizes non-secret app preferences for the authenticated WordPress user. Passwords, tokens, secrets and sensitive keys are excluded.

## Employee credentials

The app can list and revoke employee Application Passwords and WooCommerce keys through MGWS routes. It does not generate those credentials. Credential routes require administrator-level MGWS capability and a 403 must be treated as an authorization limit for that section, not as a full employee-page failure.
