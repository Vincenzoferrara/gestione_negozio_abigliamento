# Security

## Principles

- Login is the most sensitive part of the app
- Do not introduce insecure fallbacks or temporary shortcuts
- Sensitive credentials must not be stored or transmitted in clear text
- Verify the target endpoint before saving credentials
- Do not expose SQL, tokens, passwords, local paths or other customers' data in public errors

## Local development

Enable local development only for trusted local backends. This is useful for `localhost` and private LAN addresses during testing, including WordPress Admin login over HTTP.

## Authentication boundaries

`WooConnect` owns authenticated transport and site URL state. MGWS clients must use that authenticated transport instead of creating separate connectors.

## UI layout is not security

The choice between full-screen login on narrow screens and dialog login on large screens is visual only. It does not change credential storage, token handling, JWT behavior, connectors or authentication rules.

## POS attribution

The login username is stored only as an identifier, not as a password or token. It is used to attribute POS receipts to the authenticated operator and is removed on logout with the rest of the session.
