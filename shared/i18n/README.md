# shared/i18n / internationalization

Language is a **session/account property** decided by the server at login. The installed client data language only parses resources; it never decides display text.

## Text categories

| Category | Location | Runtime source |
| --- | --- | --- |
| Game content text (items/spells/auras/maps/creatures/talents/cards) | `shared/content` entries | server-localized query responses + client content pack |
| Server runtime text (notices, rewards, combat messages) | `shared/i18n/messages` | server sends message ID + arguments |
| Client UI text (options, menus, Glue, errors) | `shared/i18n/ui` | client language packs |
| Addon text | `shared/i18n/addon` | addon Lua language tables |

## Message catalogue (draft)

```yaml
- id: hoa.notice.stage_unlocked
  enUS: "Stage {stage} unlocked."
  zhCN: "第{stage}阶段已解锁。"
  zhTW: "第{stage}階段已解鎖。"
  placeholders:
    stage: number
```

- Use **stable IDs**, not English sentences as keys; changing English never invalidates a translation.
- Placeholders use `{name}` uniformly; the build checks types and missing entries; plurals use `_one` / `_other`.
- First languages: enUS, zhCN and zhTW, with room for more.
- zhTW prefers official 1.12.1 Traditional Chinese names; missing entries are converted from zhCN and manually reviewed. Use Noto Sans TC.
- Missing translations fall back to enUS; CI fails on missing entries, placeholder mismatches and unused entries.

## Current seed

The catalogue now holds 995 server messages (`messages/server.yaml`) plus 1451 addon entries (`addon/addon.yaml`), all with enUS and zhCN. `BonkStrings.h/.cpp` and `addon/HordesOfAzeroth/VanillaBonkLocaleZhCN.lua` are generated from it; the server builds and the addon table round-trips byte-for-byte in content. zhTW is not translated yet and is reported as a warning, not an error. The legacy numeric placeholders (`{1}`, `{2}`) are kept until the server call sites move to named arguments.

```bash
python tools/i18n/gen_server_strings.py       # write BonkStrings.h/.cpp from the catalogue
python tools/i18n/check.py                    # validate ids, placeholders and required languages
python tools/i18n/build.py                    # write shared/i18n/generated
python tools/i18n/build.py --check            # fail if generated files are out of date
python tools/i18n/gen_server_strings.py --check  # fail if BonkStrings.h/.cpp drifted
```

## Generated artifacts

- `server/src/game/Bonk/BonkStrings.h/.cpp`: enum + English source, generated from the catalogue
- `shared/i18n/generated/`: JSON catalogue (translation tool/export)
- `client/assets/i18n/<locale>.json`: client UI language packs
- `addon/HordesOfAzeroth/VanillaBonkLocaleZhCN.lua`: generated addon language table (the file name is fixed by the TOC)

## Client and caches

- The login handshake carries the account language and content version; the client loads language packs accordingly.
- Add `(locale, content version)` to WDB/template cache keys; language or content changes discard old caches automatically, avoiding the "gear is still English after switching to Chinese" problem.
- Fonts: each language ships its own fallback (Noto Sans SC for zhCN, Noto Sans TC for zhTW); the client selects by language.
- A client UI language change reloads the interface; it does not require a full game restart.

## Translation workflow

1. Developers change only the English source and IDs.
2. `tools/translate` lists missing/changed entries incrementally.
3. Translations go into `shared/i18n/messages/<locale>.yaml` (or split by domain).
4. CI validates, then the content compiler generates every artifact.
