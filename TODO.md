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

- [ ] Pick the repository license: GPL-3.0 is recommended (the addon, Glue and launcher are
      GPL-3.0 derivatives); MIT can only cover original standalone code.
- [ ] Move `server/` and `client/` to submodules of their own fork repositories.
- [ ] Update CI checkout and `tools/release.ps1` for submodules (`git archive` does not include
      submodule contents).
- [ ] Replace or isolate the bundled Windows MySQL client and OpenSSL 1.0.2 before distributing
      the server under GPL-3.0.
- [ ] Normalize `LICENSES/`, `LICENSE-NOTICE.md` and `THIRD-PARTY-NOTICES.md`.

See [docs/licensing](docs/licensing/README.md) for the audit and the proposed layout.
