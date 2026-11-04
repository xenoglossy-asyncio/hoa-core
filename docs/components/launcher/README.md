# launcher

Imported from the main repository's `tools/launcher` (`3ca658b`, 2026-11-04); license GPL-3.0. The source currently lives in `launcher/`. See [`UPSTREAM.md`](../../../launcher/UPSTREAM.md).

Avalonia C# launcher.

## Refactor points

- Language selection is part of the launcher/client settings and is decoupled from the client install language; the value reaches the game through the account/config, not by changing client data.
- No longer requires an English 1.12.1 install: accept any language's 1.12.1 build 5875 (file version), with the English MD5 as a fast path only. The upstream PR #25 experiment validated this.
- Clear/expire client caches by `(locale, content version)` before launch (keep and upgrade the current `*.bin` cleanup).
- Keep the server, database and realmlist start/stop logic.
- Co-op supports only two modes: LAN auto-discovery (same-subnet broadcast) and `ip/domain:port` direct connect. No public lobby, room registration or central notification service; NAT traversal is the player's responsibility (port forwarding, ZeroTier/Tailscale, etc.).
- Launcher text uses i18n resources and follows the language setting.

## Build

See [BUILDING.md](../../../BUILDING.md). `dotnet build` passes; publishing and packaging are still to be documented.

## To change

- Remove public lobby/registration code (`CoopAgent`'s `/host` registration, `LobbyUrl` metadata, related network probes); keep LAN discovery and `ip/domain:port` direct connect.
- Make language selection account-level; expire caches by `(locale, contentVersion)` before launch.
- Clean up upstream URLs in `Repository`/`StatsUrl`/`MirrorUrl`; point them at the new repository or leave them empty.
