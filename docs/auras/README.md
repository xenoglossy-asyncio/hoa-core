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
- First implementation: spell `60004` (migration `20261104120000_world.sql`) is a real positive aura; the server sets its duration from the card, and the generated client table supplies the name/icon/description through `SpellCatalog::with_overlay`, so the native buff frame and tooltip render it even though the installed `Spell.dbc` has no row. The source is `shared/content/spells/spells.yaml`; `tools/content/compile.py` emits the SQL, the server ids and the client table. Ids `60001`-`60099` are reserved for HoA.
- Addon: no timing or tooltip assembly; at most read the aura's remaining time for custom UI.

### 7.2 Darkmoon card buffs

Haste Burst (`60006`), Swiftness (`60007`), Immune (`60008`), Soulstone charges (`60009`) and Thorns (`60010`) are real auras too: the server applies them with the card's duration, and the client's buff frame/tooltips show them through the same overlay. The card window is still an addon UI (it has to be: cards are custom objects), but the effects themselves no longer live in addon timers.

### 7.3 Class buffs

Tiger's Fury (`60012`), Arcane Power (`60013`), Shadow Dance (`60014`), Envenom (`60015`), Dark Pact (`60016`), Soul Harvest (`60017`), glyph Bloodlust (`60018`), Ice Block (`60019`) the Nomad drawback (`60020`), Kill Power (`60021`) and Unhit Power (`60022`) are effects moved off internal timers onto real auras. Blade Flurry (`33466`), Enrage (`33462`), Divine Shield (`33463`) and Doom Winds now read their existing auras instead of parallel timers. the server applies a dummy aura with the buff's duration, reads `HasAura` for the behavior, and the client shows it through the overlay. The remaining timed class effects are covered in 7.6.

### 7.4 HoA shield/dash/determination

- Shield: custom aura `60005` (visual/presence); the remaining amount is still `m_spellShield` and reaches the addon as a value message until `AuraState` lands. The buff frame has the icon; the hero bar shows the value.
- Dash: a skill, not a buff. Its charges and recharge stay in `BonkPlayer`; `hoa.dash`/`dash~` carry the available charges and remaining recharge to the UI, and the native buff frame never changes when a charge is spent or returns.
- Determination: custom aura `60001`, permanent, stacks mirror the account value; the addon reads the stacks from the aura, and the server keeps the account row as the persistent source.
- Wounds: custom aura `60003`; stacks and duration live on the aura; the addon reads stacks and only takes the server-computed healing cut percentage from the notice.
- Necrotic: spell `18951` stacks are the state; the server reads them and the addon reads them through `UI.AuraStacks`.
- Weapon buffs: the server reads the live aura instead of the removed `m_buffs` expiry map.

### 7.5 Native spells

- Blade Flurry/Enrage: use the stock spell ID; the server only refreshes/removes. Delete the addon timer and read `UnitBuff`.
- If a native spell needs HoA-specific numbers, change the server spell data; do not start a second system.

### 7.6 Talent procs

Rapid Fire (`60023`), Slice and Dice (`60024`), Borrowed Time (`60025`), Flurry (`60026`) and Lifebloom (`60027`) are single-timer auras read with `HasAura`. Bloodsurge (`60028`), Forceful Winds (`60029`), Danse Macabre (`60030`), Avenging Wrath (`60031`), Zealotry (`60032`), Arcane Tempo (`60033`), Starlord (`60034`), Soul of the Forest (`60035`), Harvester of Souls (`60036`), Unrelenting Storm (`60037`), Mongoose Fury (`60038`), Bulwark (`60039`), Ancient Madness (`60040`) and Bloodtalons (`60041`) keep their per-stack expiry vectors as bookkeeping; `UpdateTalentAuras` mirrors the active count and the longest remaining time onto the aura every 400 ms, and only rewrites it when the count changes or the remaining time differs by more than 600 ms. Conditional stacks that have no expiry use permanent auras. The one-shot procs Clearcasting (`60048`), Fingers of Frost (`60049`), Arcane Potency (`60050`), Aegis (`60051`) and the Vanish opener (`60052`) are permanent auras while they wait to be spent, and their stacks mirror the stored counters.

### 7.7 Pet and enemy effects

Howl Frenzy (`60042`) is a player aura read by `IsHowlFrenzied`. Demoralizing Roar (`60043`), Strangling Vines (`60044`), Seduced (`60045`), Schism (`60046`) and Exposed (`60047`) are debuffs applied to the affected enemy with the player as caster; their damage hooks read the holder instead of a parallel timer map. Ground areas such as Smoke Bomb and Barrier stay area logic rather than buffs, because they affect a position, not a unit.

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
