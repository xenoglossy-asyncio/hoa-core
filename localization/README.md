# Translations (legacy import data)

This folder is the old import source, kept for provenance. The live catalogue is
`shared/i18n`; edit translations there and regenerate the artifacts with
`tools/i18n`.

- `zhCN/server.json`: the original server string table from `BonkStrings.cpp`
  and the Bonk database tables. It is read only by
  `tools/i18n/extract_server_strings.py`, the one-time importer that seeded
  `shared/i18n/messages/server.yaml`.
- `zhCN/glossary.json`: agreed terms used by that import.

The addon, GlueXML and launcher no longer have per-language Lua files. All of
their text comes from `shared/i18n/addon`, `shared/i18n/ui` and
`shared/i18n/launcher`, generated into:

- `addon/HordesOfAzeroth/VanillaBonkLocaleData.lua` (every language in one file)
- `client/crates/benilla-app/assets/i18n/<locale>.json`
- `launcher/LauncherStrings.g.cs`
- `server/src/game/Bonk/BonkStrings.{h,cpp}`

To translate, edit the YAML under `shared/i18n` and run:

```
python tools/i18n/check.py
python tools/i18n/gen_addon_locale.py
python tools/i18n/gen_client_pack.py
python tools/i18n/gen_launcher_strings.py
python tools/i18n/gen_server_strings.py
```
