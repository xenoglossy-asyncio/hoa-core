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

- [x] Pick the repository license: GPL-3.0 for original code; `shared/` stays GPL-2.0-or-later so
      the GPL-2.0 server and GPL-3.0 addon can both use it.
- [x] Keep the repository a monorepo; add `LICENSES/` and per-directory `UPSTREAM.md` files instead
      of submodules.
- [x] Regenerate `THIRD-PARTY-NOTICES.md` from the verified dependency list.
- [ ] Add SPDX headers to new files where practical.
- [ ] Replace or isolate the bundled Windows MySQL client and OpenSSL 1.0.2 before distributing the
      server under GPL-3.0.
- [ ] Optional: if upstream tracking later needs submodules, update CI checkout and
      `tools/release.ps1` first (`git archive` does not include submodule contents).

See [docs/licensing](docs/licensing/README.md) for the audit and the proposed layout.
