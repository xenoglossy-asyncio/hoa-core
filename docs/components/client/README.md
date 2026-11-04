# client

Imported from the `hordes-of-azeroth-client` `zhcn-063` snapshot (`74a4e4e`, 2026-11-04); license MIT / Apache-2.0. This is the refactor starting point, not the final structure. See [`UPSTREAM.md`](../../../client/UPSTREAM.md) and [`provenance.yaml`](../../../provenance.yaml).

benilla: a from-scratch 1.12.1 client written in Rust + Bevy.

**Status: imported.** `LICENSE-MIT`, `LICENSE-APACHE` and the `third_party/` copyright notices are kept.

## Planned changes

- **Content overlay:** custom spells/auras/items are absent from the installed DBCs. The client reads name, icon and description from a content pack generated from `shared/content` and overrides DBC lookups at runtime.
- **Language packs:** the client's own UI text (options, menus, Glue, error messages) comes from language packs; the language is supplied by the server at login and no longer decided by the installed data language.
- **Cache keys:** WDB/template caches are keyed by `(locale, content version)` and expire when either changes, so switching language no longer leaves old names behind. The account language is folded into the WDB header tag now; the content version comes with the content pack.
- **Native capabilities:** buffs, levels, casting and cooldowns use the client's existing systems; HoA state no longer travels through custom chat lines.
- **Kernel kept:** networking, movement, combat, rendering and the Lua/FrameXML engine stay benilla's; only HoA integration points and hot spots change.

## Data sources

The client still needs the user's own 1.12.1 install for models, textures, audio and base DBC data, but **display text and game-content definitions no longer depend on the install language**. Missing resources or custom entries come from the content pack (see [Content and data](../../content-data/README.md)).

## Build

See [BUILDING.md](../../../BUILDING.md). The workspace manifests pass; a full `cargo build` is still pending.
