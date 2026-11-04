# shared/content / content sources

The single source of game content. Suggested layout by domain:

```
content/
  items/          gear, consumables, materials
  spells/         spells (including custom HoA spells)
  auras/          HoA effect/aura definitions (see docs/auras)
  creatures/      creatures, NPCs, bosses
  zones/          maps, areas, scenarios
  talents/        talents, mastery trees
  cards/          Darkmoon cards, card effects
  gear/           gear pools, qualities, level curves, loot tables
  quests/         quests
  loot/           loot tables
  strings/        long text referenced by content (or inline in entries)
```

## Entry format (draft)

Every entry has a stable ID, English source, localized fields, values and relations. Example:

```yaml
id: hoa.item.darkmoon.ogre_slayer
kind: item
name_id: hoa.text.item.darkmoon.ogre_slayer.name
description_id: hoa.text.item.darkmoon.ogre_slayer.desc
icon: Interface/Icons/INV_Misc_Ticket_Darkmoon_01
quality: 3
stats: { strength: 12, stamina: 8 }
```

Text lives beside the entry or in separate `i18n` files and is referenced by `*_id`; never use English sentences as keys.

## Compiler output

`tools/content-compiler` reads this directory and generates:

- `server/sql/content/*.sql`: repeatable schema/data SQL
- `server/src/game/Hoa/content/generated/`: ID constants and static tables
- `client/assets/content/<version>/content.bin`: client content pack
- `addon/HordesOfAzeroth/generated/content.lua`: addon data tables
- `shared/i18n/generated/*.json`: text catalogue shared by C++, Rust and Lua
- `content.hash`: content version hash

## Current state

The design-content tables are now sourced here:

- `cards/cards.yaml` is the hand-shaped source for the 46 cards (English + zhCN).
- `spells/spells.yaml` defines every custom HoA spell/aura; the compiler emits its `spell_template` SQL, the server's C++ ids and the client's display table.
- `tables/<table>.yaml` holds the 49 design-content `bonk_*` tables (weapons, upgrades, glyphs, talents, mastery, maps, quests, titles, tiers, mobs, item stats and their locale rows).
- `tools/content/dump_cards.py` / `dump_tables.py` imported them once from the database.
- `tools/content/compile.py` emits `server/sql/content/*.sql`; `--check` keeps every generated file in sync in CI.
- `tools/content/apply.py --maria <client> --database <world db>` applies those files in order; this is how the test database picks up source changes.

Every generated table was applied to the test database and compared row for row with the old data; all 49 matched. The large generated spawn tables (`bonk_hidden_creature`, `bonk_hidden_gameobject`) deliberately stay in the database, per the project decision, so the source tree stays reviewable.

## Migration

First write a dump tool that exports the current `bonk_*` tables, custom `item_template` rows and `locales_*` text into these sources. Once the generated result matches the existing database, switch to the generated flow. See [the migration plan](../../docs/migration-plan/README.md).
