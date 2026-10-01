# Developer Guide

## Before changing code

1. Read [Architecture](architecture.md).
2. Check the module documentation relevant to the change.
3. Preserve existing user work and unrelated working-tree changes.
4. Keep documentation in `lib/doc` aligned with current behavior.

## File organization

Large modules should split UI and logic:

- `*.gui.dart` for widgets, layout and user interaction
- `*.code.dart` for state, orchestration and screen logic

Reusable UI and domain utilities belong under `lib/reuse_class/`. Do not duplicate scanner, pagination, table or shared dialog behavior inside feature modules.

## Integration boundaries

The app may talk directly only to:

- WooCommerce
- MGWS

Do not add direct integrations to ATUM, myCred or other WordPress plugins. If a capability is needed, expose it through MGWS.

`WooConnect` is the owner of authenticated transport. MGWS clients must use its authenticated Dio and site URL instead of creating their own connector.

## Reading MGWS state in a module

`MgwsConnection` in `lib/login/mgws/connection/mgws_connection.dart` is the only owner of the MGWS connection state.

Rules:

- call `MgwsConnection.instance.ensureConnected()` before an MGWS operation; it reuses the verification already produced by the login chain and hits the network only when the state is unknown
- do not call `verify()` from a module. It is reserved for the end of the login chain and for deliberate user-triggered checks, because it always hits the network
- do not keep a module-local copy of the availability flag
- do not call `verify()` before every operation: permissions, supplier reads and stock reads do not need a fresh check and would multiply the requests
- a checkout or another action that must not run against a stale state uses `PlatformManager.refreshCanUseMgws()`
- call `markDisconnected()` when a session changes, so a stale state cannot block a module
- read `lastFailure` to tell a non-reachable backend, a disabled service and a missing session apart, and show the matching localized notice

A home section that cannot work without MGWS declares `requiresMgws: true` in its `_HomeSection`: the card is not opened and the notice is shown instead.

## Localization

Visible user strings must be localized through `context.l10n.<key>` and the ARB files under `lib/traduzioni/`.

Rules:

- template: `lib/traduzioni/app_en.arb`
- Italian translation: `lib/traduzioni/app_it.arb`
- keys are English, `camelCase`, and valid Dart getter names
- do not translate user data, protocol fields, persistence keys or backend payload names
- after touching visible strings run `flutter gen-l10n` and `dart run lib/traduzioni/verifica_traduzioni.dart`

## Documentation

`lib/doc` is current project documentation for contributors and AI agents. It is not a backlog and must not contain historical "before/after" notes. Update the most relevant file whenever behavior, settings, screens, integrations or user flows change.

## Testing and verification

Follow the verification relevant to the change. For documentation-only changes, run link checks and grep for stale references. For UI/string changes, also run localization checks. For Dart behavior changes, run `flutter analyze` and the relevant tests.

Do not add new tests unless the task explicitly asks for them; preserve existing tests and do not break them.

## SDK and dependency maintenance

Use Flutter with Dart `>=3.12.0 <4.0.0`. Dependency upgrades must keep the local `report_flutter` package at `../../report` resolvable together with the app.

`woocommerce_flutter_api` is kept on the latest compatible hosted release because WooCommerce is a direct integration boundary of the app. When upgrading packages, run `flutter pub upgrade --major-versions`, then `flutter pub get`, then `flutter analyze` from the app root. If dependency conflicts involve `report_flutter`, update that local package first and then rerun the app dependency resolution.

`velopack_flutter` is pinned to the `0.1.x` line for the current desktop runtime. The `0.3.x` line uses a native-assets build hook that currently fails during `flutter run -d linux` with a missing `config.code` value in the hook input. Re-test that package separately before upgrading it again.

## Android emulator and local backend

The project includes:

```bash
script/start_android_emulator.sh
```

It starts the configured local AVD and forwards host ports `8080` and `8081` to the emulator so local WordPress services are reachable from Android.

## Commits

Use the repository commit format:

```text
short title

- short detail
- short detail
```

Current project rules require commit messages in English.
