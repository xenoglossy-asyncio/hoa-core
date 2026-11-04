# Auras and effects

## 1. Problem

HoA effects currently have three representations and no single source of truth:

1. **Real server auras, but only half-done:** move speed/max health use spells 17498/19255 (`BonkRun.cpp:11365-11376`); Necrotic has aura 18951 (`BonkRun.cpp:4411`), but the healing cut actually reads `m_necroticStacks` (`BonkRun.cpp:4439`); shield visual 16051, Deterrence 33467 and Revive Shield 33468 are auras; weapon buffs are cast as auras but their expiry is also stored in `m_buffs` (`BonkRun.cpp:8071-8072,7913-7922`).
2. **Addon-maintained state:** shield amount `m_spellShield` (`BonkRun.h:2263`) goes to the addon as `shield~` (`BonkRun.cpp:4767`); dash `m_dashSpent/m_dashRechargeMs` (`BonkPlayer.h:544-545`, `BonkPlayerDash.cpp:194-221`); determination `m_determination` (`BonkPlayer.h:514`, persisted at `BonkPlayer.cpp:2322-2335`); boss wounds `m_bossWoundStacks` (`BonkRun.h:1796`, `BonkRun.cpp:4629`). These are synchronized through BONK chat lines and drawn/timed by the addon; the native buff frame cannot see them, and a UI reload or reconnect can lose them.
3. **Native spells plus an addon copy:** Blade Flurry, Enrage and kin reuse native spells, but the addon keeps a duplicate timer.

Card procs span all three. Zandalarian Hero Charm, for example, grants "25% Power for 10 sec every 30 sec" (`server/core/sql/migrations/20261027710000_world.sql:46-47`): the server uses `m_cardSurgeUntilMs` plus cooldown bookkeeping (`BonkRunCards.cpp:486-493`), `GetCardPower` folds the bonus into damage and stats (`BonkRunCards.cpp:156-170`, `BonkRun.cpp:4867,6284`), and there is no Unit aura. The UI relies on per-second `cardnow~` text (`BonkRunCards.cpp:507-533,586-596`) and one `Notify` (`:491`); the addon assembles the tooltip (`VanillaBonkCards.lua:84-86,205,313-328`).

The addon parses only `BONK~` chat lines (`VanillaBonkUI.lua:231-243`) and never uses `UNIT_AURA`/`GetPlayerBuff`; the client's `C_UnitAuras` serves only enemy nameplate debuffs (`VanillaBonkDebuffs.lua:62-78`), and boss debuffs still go through BONK (`VanillaBonkBoss.lua:194`). The addon also has several per-frame `OnUpdate` loops (`VanillaBonkDebuffs.lua:385`, `VanillaBonkCards.lua:255`, `VanillaBonkPlates.lua:652`, `VanillaBonkDash.lua:89`, etc.).

Result: what the player sees, what the addon shows and what the server applies may be three states; other addons/combat logs cannot identify HoA effects through standard APIs.

## 2. Principles

1. **One effect = one aura (spell/aura).** The server applies it; native client systems display it.
2. **The server is the only state source.** Duration, stacks and remaining values come from the server aura or from state bound to the aura lifecycle; the addon never times them independently.
3. **Prefer native aura types.** Stats, attack power, damage percent, move speed, regeneration and procs use stock `SPELL_AURA_*` where possible; when impossible, use `SPELL_AURA_DUMMY` plus server logic, but the state still hangs off an aura.
4. **The addon only reads.** It uses `UnitBuff`/`UnitDebuff`/`UNIT_AURA` to read and render; it never parses state chat lines or counts down on its own.
5. **The client can display custom spells.** Custom spell IDs are absent from the installed `Spell.dbc`; the client must get name, icon, description and stack-display rules from the content pack.

## 3. Effect categories

| Category | Representation | Examples |
| --- | --- | --- |
| Native WoW spells/auras | stock spell ID; server refreshes/removes | Blade Flurry, Enrage, Shield Wall, Bloodlust |
| HoA custom buffs | custom spell with stock aura effects | Darkmoon card stat procs, shields, damage boosts, move speed |
| HoA custom debuffs | custom spell with stock debuff effects | Necrotic, wounds, boss-applied debuffs |
| Resource/stack states | custom spell + aura stack | determination stacks, dash charges, combo/charges |
| Values that do not fit aura fields | custom spell + server `AuraState`, tied to the aura lifecycle | shield remaining, absorb pool |
| Non-combat/long-lived states | server state + a permanent aura when visualization is needed | codex unlocks, season markers |

## 4. Data model (draft)

`shared/content/auras/*.yaml`:

```yaml
id: hoa.aura.darkmoon.ogre_slayer
kind: aura
name_id: hoa.text.aura.ogre_slayer.name
description_id: hoa.text.aura.ogre_slayer.desc
icon: Interface/Icons/INV_Misc_Ticket_Darkmoon_01
duration_ms: 30000
max_stacks: 1
stack_rule: refresh          # refresh | stack | independent
visible: true
server:
  proc: on_melee_hit
  ppm: 1.0
  internal_cooldown_ms: 0
spell:
  school: physical
  effects:
    - type: mod_stat
      stat: strength
      amount: 30
```

After compilation:

- Server: generated `spell_template` rows (or a custom spell registry) + effect ID constants + proc bindings.
- Client content pack: spell ID → name/icon/description/is-debuff/stack display.
- Addon: only the IDs needed for display, never the numbers.

## 5. Server

### 5.1 Lifecycle

```
content definition → Hoa::Auras::Apply(target, auraId, caster, duration, stacks)
        → Unit::AddAura(spellId)
        → client SMSG_AURA_UPDATE → native buff frame
        → server logic reads through HasAura/GetAuraCount
        → expiry/dispel/removal → AuraState cleanup
```

- Every effect goes through the `Hoa::Auras` facade; business code never hand-assembles spell IDs.
- `AuraState` (shield amount, etc.) shares the aura lifecycle: created on aura add, destroyed on remove; server reads only this copy.
- Refresh rules (refresh duration / stack / independent) come from data, not handwritten business code.

### 5.2 Relation to existing code

- Keep the existing `BONK_SPELL_*` constants and migrate them into the content table.
- Addon-maintained dash/determination/shield state becomes:
  - directly mappable to aura stacks → aura stack;
  - shield remaining and similar values → aura + `AuraState`; the server sends a lightweight update on change, not every frame.
- Native spells such as Blade Flurry/Enrage: remove the addon copy; read the native aura.

### 5.3 Performance

- Coalesce aura updates per server tick; give procs internal cooldowns/PPM limits to avoid high-frequency refreshes.
- Do not give each effect its own timer; use aura expiry.
- Synchronize large shield/absorb changes to the addon by threshold or at low frequency, never every frame.

## 6. Client

- **Native buff frame:** `SMSG_AURA_UPDATE` shows the aura immediately; custom spell names/icons come from the content-pack overlay. Today a missing `Spell.dbc` ID gives a `None` aura name/icon (`ui_aura.rs:256-260`) and the spellbook drops it (`ui_spellbook.rs:351-355`); the overlay must land first, or custom auras appear blank in the buff frame.
- **Spellbook/tooltips:** when the `Spell.dbc` lookup fails, fall back to the content pack; descriptions use content-pack text per language.
- **Addon:** read with `UnitBuff("player", i)`, `GetPlayerBuff`, and `UNIT_AURA`; the display layer may style it, but the data source must be the native aura.
- **Reload/reconnect:** the server re-sends state; the addon restores no timers of its own.

## 7. Examples

### 7.1 Darkmoon card: a 30-second burst cycle

Zandalarian Hero Charm: every 30 seconds, gain 25% Power for 10 seconds (`20261027710000_world.sql:46-47`).

- Content definition: `hoa.aura.darkmoon.zandalarian_surge`, `duration 10s`, `hoa_power_percent 25`, `internal_cooldown 30s`.
- Server: a combat/timer hook triggers → `Apply` → the real aura applies; damage calculation uses VMaNGOS's aura system. Remove `m_cardSurgeUntilMs`, the manual bonus in `GetCardPower`, and the per-second `cardnow~`.
- Client: the buff frame shows the icon and remaining time; tooltip text comes from the content pack.
- Addon: no timing or tooltip assembly; at most read the aura's remaining time for custom UI.

### 7.2 HoA shield/dash/determination

- Shield: custom aura (absorb/damage reduction + visual), remaining amount in `AuraState`; the buff frame has the icon and the hero bar shows the value.
- Dash: custom aura; charges use aura stacks; the addon reads `GetAuraCount`.
- Determination: custom aura + stacks; server logic reads the stack count and keeps no parallel counter.

### 7.3 Native spells

- Blade Flurry/Enrage: use the stock spell ID; the server only refreshes/removes. Delete the addon timer and read `UnitBuff`.
- If a native spell needs HoA-specific numbers, change the server spell data; do not start a second system.

## 8. Migration steps

1. Inventory every effect (server constants, addon state, reused native spells) in a table.
2. Assign a stable ID and content definition to each; map to native auras where possible.
3. Implement `Hoa::Auras` and `AuraState` on the server; migrate one by one behind a switch until verified.
4. Support custom spell display in the client content pack; verify icon/name/stacks/duration in a dev build first.
5. Make the addon read-only; delete BONK state messages and self-maintained timers.
6. Regress: buff frame, tooltips, combat results, UI reload, reconnect, language switch.

## 9. Tests

- Unit: aura apply/refresh/stack/expiry, `AuraState` lifecycle.
- Integration: a fixed combat script triggers a proc and asserts aura presence, stacks, remaining time and stat changes.
- Client: buff-frame screenshot comparison (enUS/zhCN), consistent state after reload/reconnect.
- Performance: aura packet rate and server tick time under high-frequency procs.
