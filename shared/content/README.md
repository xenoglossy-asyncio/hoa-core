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

## Current pilot: cards

The first table set is wired end to end:

- `cards/cards.yaml` is the source (46 cards, English + zhCN).
- `tools/content/dump_cards.py` imports it from the current `bonk_card`/`bonk_card_locale` tables once.
- `tools/content/compile.py` emits `server/sql/content/bonk_card.sql`; `--check` keeps the SQL in sync in CI.

The generated SQL was applied to the test database and compared row for row with the old `bonk_card` and zhCN locale rows; both were identical. The next tables follow the same pattern.

## Migration

First write a dump tool that exports the current `bonk_*` tables, custom `item_template` rows and `locales_*` text into these sources. Once the generated result matches the existing database, switch to the generated flow. See [the migration plan](../../docs/migration-plan/README.md).
