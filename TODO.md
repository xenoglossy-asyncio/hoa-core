# TODO

## Addon object refactor (phase D)

Controllers now exist for the shop, offer/results, gear and starters; the tracker is the
panel/list/row pilot. Remaining work:

- [ ] Convert `run/VanillaBonkHeroBar.lua` to a `UI.Module("heroBar")` controller with explicit state.
- [ ] Convert `run/VanillaBonkResults.lua` and `panels/VanillaBonkCodex.lua` to controllers.
- [ ] Convert `run/VanillaBonkMeter.lua`, `run/VanillaBonkQuartermaster.lua`, `run/VanillaBonkVault.lua`
      and `run/VanillaBonkTransmog.lua` to controllers.
- [ ] Convert the controller panels (`panels/VanillaBonkController*.lua`) to one controller object.
- [ ] Introduce an `OfferCard` class so offer cards own their frame, option and layout methods.
- [ ] Reduce the remaining free functions in `core/VanillaBonk.lua` to a thin protocol/state bridge.

## Licensing and repository structure

- [x] Pick the repository license: GPL-3.0 for original code; `shared/` stays GPL-2.0-or-later so
      the GPL-2.0 server and GPL-3.0 addon can both use it.
- [x] Keep the repository a monorepo; add `LICENSES/` and per-directory `UPSTREAM.md` files instead
      of submodules.
- [ ] Regenerate `THIRD-PARTY-NOTICES.md` from the verified dependency list and add SPDX headers to
      new files where practical.
- [ ] Replace or isolate the bundled Windows MySQL client and OpenSSL 1.0.2 before distributing the
      server under GPL-3.0.
- [ ] Optional: if upstream tracking later needs submodules, update CI checkout and
      `tools/release.ps1` first (`git archive` does not include submodule contents).

See [docs/licensing](docs/licensing/README.md) for the audit and the proposed layout.
