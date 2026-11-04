# addon

Imported from the main repository's `Interface/AddOns/HordesOfAzeroth` (`3ca658b`, 2026-11-04); license GPL-3.0. The source currently lives in `addon/HordesOfAzeroth/`. See [`UPSTREAM.md`](../../../addon/HordesOfAzeroth/UPSTREAM.md).

## Responsibilities after the refactor

The addon is a **presentation layer only**:

- Reads native client APIs (`UnitBuff`, `UnitLevel`, `GetTime`, combat events) to render the HoA UI.
- No longer maintains buff/effect timers, stacks or state machines; those live in server auras (see [Auras and effects](../../auras/README.md)).
- No longer computes item level, gear stats or other values the server already knows; those come from the content pack or protocol.
- All text comes from Lua tables generated from `shared/i18n`; the language is the server/client setting, never the installed client language.

## Planned layout

```
addon/
  HordesOfAzeroth/
    *.lua            UI and interaction
    generated/       generated from shared/i18n and shared/content (never hand-edited)
    Fonts/           language font fallbacks (Noto Sans SC / Noto Sans TC)
    HordesOfAzeroth.toc
```

## Kept

The usable parts of the current addon (window layout, card/reward UI, tooltips, bindings, GlueXML language mechanism) stay and migrate to the new data sources step by step.
