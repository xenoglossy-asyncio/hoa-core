# Migration plan

Deliver phase by phase. At the end of every phase the repository must build, run and be revertible.

## Phase 0: design and skeleton (done)

- Output: this repository, architecture/i18n/auras/content/protocol docs, component notes, license notes.
- Acceptance: the design direction and directory layout are approved.
- Not done: importing code or changing any existing implementation.

## Phase 1: import and baseline

- Import these snapshots into the monorepo, keeping their licenses and copyright:
  - `server/` ← `hordes-of-azeroth-server` (VMaNGOS, the 0.6.3 `vanilla-bonk`/Chinese branch)
  - `client/` ← `hordes-of-azeroth-client` (benilla, 0.6.3 snapshot)
  - `addon/` ← `Interface/AddOns/HordesOfAzeroth`
  - `glue/` ← `Interface/GlueXML`
  - `launcher/` ← `tools/launcher`
  - `config/`, `localization/`, `tools/` ← matching directories in the main repository
- Do not import `tools/lobby-server`: co-op is LAN and `ip/domain:port` direct only; no public directory/registration service.
- Version starts at **0.1.0** (`VERSION`).
- Add unified build scripts and CI: server CMake, client Cargo, launcher dotnet, addon Lua syntax check.
- Acceptance: one command builds every component; existing functionality runs; CI is green.
- Progress (2026-11-04): code imported and committed; `scripts/build.ps1 -Component server` passes, launcher passes, 64 addon Lua files parse, client workspace manifests pass; a full client `cargo build` is still pending.
- Risks: repository size (tracked files only, no `target/`, `bin/`, `obj/`, databases); mixed licenses (kept per directory).

## Phase 2: i18n foundation

- Create the `shared/i18n` message catalogue (stable IDs, placeholders, language tables).
- Add the server `Hoa::I18n` runtime; migrate the 900+ `BonkStrings`/`BonkLocale` messages to IDs.
- Client language packs: UI text (options, menus, Glue) reads from packs; the login handshake carries the account language.
- Generate the addon language tables; delete English-key indices and reverse lookups.
- Add `(locale, contentVersion)` to cache keys; language changes refresh item/creature/spell names.
- Acceptance: any-language 1.12.1 install + Chinese account → all Chinese; switching enUS/zhCN without a game restart leaves no stale names; missing translations have a list.
- Progress (2026-11-04): 995 server strings and 1451 addon entries have stable IDs (`shared/i18n/messages/server.yaml`, `shared/i18n/addon/addon.yaml`, enUS + zhCN complete, zhTW pending); `tools/i18n` extractor/validator/generator and the `i18n-check` CI job are in place; `BonkStrings.h/.cpp` and `VanillaBonkLocaleZhCN.lua` are generated from the catalogue, and the server builds; the client WDB header folds the HOA account language into its cache tag (FORMAT 2). Next: client UI language packs and zhTW translation.
- Note: this touches a lot of client text but no game values.

## Phase 3: unify auras

- Implement `Hoa::Auras` and `AuraState`; build the effect inventory.
- Support custom spell name/icon/description/stacks in the client content pack; first make the client display one test aura.
- Migrate category by category: native spell copies → custom buffs → resource/stack states → special values such as shield amounts.
- Switch the addon to `UnitBuff`/`UNIT_AURA`; delete state timers and `BONK~state`.
- Acceptance: every HoA effect appears in the buff frame; addon/server/combat-log state agrees; UI reload, reconnect and language switch preserve it.
- Progress (2026-11-04): weapon buffs, Necrotic, Determination (60001), Dash (60002), Wounds (60003), Darkmoon Surge (60004) and Shield (60005) are on real auras. Custom ids live in the migration `20261104120000_world.sql`; the client overlay renders them; the addon reads stacks through `C_UnitAuras` (`UI.AuraStacks`). Shield amount and dash recharge still travel as server-computed value messages until `AuraState` lands. Weapon buffs read the live aura instead of the removed `m_buffs` expiry map; Necrotic stacks live on spell 18951 and the server reads `GetStackAmount`, while the addon reads the stack count through `C_UnitAuras` and only takes the server-computed healing cut from the notice.
- Risks: custom spell display on the client, aura packet rate, effects that no stock aura type can express.

## Phase 4: single content source

- `tools/content-dump` exports current `bonk_*`, custom items and text.
- `tools/content-compiler` generates equivalent SQL; compare row by row on a test database.
- Switch to the generated flow; replace duplicated addon/client tables with generated artifacts or protocol data.
- Acceptance: one source generates all three artifacts; content changes only touch sources; CI checks artifact diffs.
- Risks: large content volume, conflicts with old SQL during migration; guarantee equivalence with export → generate → compare.

## Phase 5: protocol cleanup

- Define the HoA message schema and generate C++/Rust.
- Expose the client Lua API; migrate presentation data in the addon.
- Delete the `BONK~` parser and string assembly.
- Acceptance: all state uses native auras; presentation data uses the typed protocol; version mismatches are explicit.

## Phase 6: performance and kernel cleanup

- Inventory and fix hot spots: Lua polling, aura refreshes, grid searches, per-frame scans, duplicated calculations.
- Establish benchmarks (server tick, login time, memory, client frame time).
- Remove migration switches and dead code.
- Acceptance: benchmarks are no worse than before; no regressions; docs updated.

## Why this order

1. **i18n first:** it is the most direct user pain, and it requires server/client/addon changes together, best done while the monorepo is new and coupling is still clear.
2. **Auras second:** they depend on custom spell display in the client content pack, but can share the language-pack infrastructure.
3. **Content compiler third:** aura and text definitions can start handwritten and be compiled once the shape stabilizes; avoid blocking on a huge migration.
4. **Protocol last:** define messages after state and presentation data settle, minimizing churn.

## Rollback strategy

- Isolate each phase behind branches/switches; keep the old path until the new one passes regression.
- Do not switch the content compiler until "generated result == existing DB" is verified.
- Version client caches so a rollback invalidates old caches automatically.
