# TODO

## Addon object refactor (phase D) — complete

Run and panel state now lives on `UI.Module` controllers; the remaining local helpers are stateless
layout/text utilities or the public `VanillaBonkRun` API. The tracker remains the panel/list/row pilot.

- [x] Convert `run/VanillaBonkHeroBar.lua` to a `UI.Module("heroBar")` controller with explicit state.
- [x] Convert `run/VanillaBonkResults.lua` and `panels/VanillaBonkCodex.lua` to controllers.
- [x] Convert `run/VanillaBonkMeter.lua`, `run/VanillaBonkQuartermaster.lua`, `run/VanillaBonkVault.lua`
      and `run/VanillaBonkTransmog.lua` to controllers.
- [x] Convert the controller panels (`panels/VanillaBonkController*.lua`) to one controller object.
- [x] Introduce an `OfferCard` class so offer cards own their frame, option and layout methods.
- [x] Reduce the remaining free functions in `core/VanillaBonk.lua` to a thin protocol/state bridge.

## Licensing and repository structure

- [x] Pick the repository license: GPL-3.0 for original code, `shared/` and the server distribution.
- [x] Keep the repository a monorepo; add `LICENSES/` and per-directory `UPSTREAM.md` files instead
      of submodules.
- [x] Regenerate `THIRD-PARTY-NOTICES.md` from the verified dependency list.
- [x] Add SPDX headers to repository-owned scripts: `scripts/` and `tools/` are GPL-3.0-only;
      imported and derived files keep their upstream notices.
- [x] Replace the bundled Windows MySQL client and OpenSSL 1.0.2: MariaDB Connector/C 3.4.10
      (LGPL-2.1-or-later) and OpenSSL 3.5.9 LTS (Apache-2.0); the server is now GPL-3.0.
      MariaDB Server remains GPL-2.0-only but is downloaded and run as a separate program.
- Not planned unless upstream tracking changes: use submodules and update CI checkout plus
      `tools/release.ps1` first (`git archive` does not include submodule contents).

See [docs/licensing](docs/licensing/README.md) for the audit and the proposed layout.
