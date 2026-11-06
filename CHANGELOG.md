## 0.1.2

- Package and navmesh entries in the manifest now list a Gitee mirror next to their GitHub URL; the launcher prefers the mirror in China and falls back to the other host on failure.
- Linux builds run in Docker (`ubuntu:22.04`) when WSL 22.04 is not installed, so this release ships the Linux client, server and extractors again.
- `tools/release.ps1` builds from the monorepo layout and tolerates a regenerated `config/navtiles.json` whose content did not change.

## 0.1.1

- Simplified Chinese and Traditional Chinese across the client, addon, launcher and server text; the account language drives `GetLocale`, and stock GlobalStrings and DBC names load from an installed language pack.
- Protocol v31 with Hardcore mode (fallen and remembered runs), several characters per class, transmogrification and outfits, and Regular and Hardcore leaderboards.
- Direct co-op: hosts share an `ip:port`; the public lobby and punch-through are gone.
- Content manifest with per-section hashes and server-side integrity checks for leaderboard runs.
- Addon: shared `UI.Hover`, `UI.IconRow`, `UI.IconButton` and `UI.Listen` helpers, named event modules in `UI.modules`, and far less duplicated tooltip and event wiring.
- Launcher: Gitee release mirror for China, domestic MariaDB mirrors (TUNA, Aliyun, USTC), download resume and database start retries.
- CI: client tests link with lld so private-repo runners stop dying mid-link.
