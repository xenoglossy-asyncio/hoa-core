# Protocol

## 0. Current state

- HoA state and UI data travel as `BONK~type~field...` chat lines: the server builds strings, the client shows them as ordinary system messages, and the addon parses them from `CHAT_MSG_SYSTEM` (`Interface/AddOns/HordesOfAzeroth/VanillaBonkUI.lua:231-243`) after hiding them from the chat frame.
- The Rust client recognizes only the `HOA~` prefix (`client/crates/hoa/src/world_fx.rs:62-65`); `parse_line` explicitly rejects `BONK~` (`hoa/src/server_draw.rs:342`), and unmatched lines fall through to system chat (`benilla-app/src/ui_chat/net.rs:14-20,46-61`).
- The client has no spell query path (`benilla-app/src/net.rs:1034-1058`), so custom spell metadata has nowhere to come from.
- State data (shield amount, dash, determination, card procs) all depends on this string channel; field order is by convention and every change must touch both sides.
- First typed slice (2026-11-04): opcode `SMSG_HOA_MESSAGE` (826) carries `hoa.hello` — protocol version, content hash and account language — after the addon's `.bonk hello`. `shared/protocol/messages.yaml` is the source; `tools/protocol/gen.py` generates `HoaProtocol.h` and `protocol_generated.rs`; the client compares version/hash, warns on a mismatch and fires `HOA_HELLO` into Lua. `hoa.aura_value` (`spell_id`, `value`, `max_value`) is sent alongside the shield text and fires `HOA_AURA_VALUE`, so the addon can read the amount without parsing the chat line. Everything else still uses `BONK~`.

## 1. Goals

- HoA data between server and client has an explicit schema and version; no more string assembly.
- State data (buffs, stacks, values) uses vanilla game state wherever possible; custom messages cover only display data vanilla cannot express.
- One schema generates both C++ and Rust code, avoiding parser drift.
- Content version, protocol version and language are negotiated during the handshake.

## 2. Layers

```
Vanilla 1.12.1 protocol (kept)
  ├─ login/character/movement/combat/items/auras/chat/...
  └─ native buffs, levels, casting, cooldowns are used directly

HoA protocol (new, versioned)
  ├─ handshake: account language, content hash, protocol version, capabilities
  ├─ content: manifest/incremental (client content-pack validation)
  ├─ run: start, waves, bosses, rewards, results
  └─ presentation: cards, codex, leaderboard, notices (UI only)
```

## 3. Handshake

On world login the server sends:

```yaml
handshake:
  protocol_version: 1
  content_hash: "sha256:..."
  locale: "zhCN"          # account language
  capabilities: [auras, content_pack, i18n]
```

- The client loads the matching language/content pack. On a hash mismatch:
  - single-player: warn about the update and allow continuing with an incompatible marker;
  - co-op: the LAN/direct host refuses different content versions.
- Language change: the client sends `set_locale` (or reuses a vanilla command); the server updates the account language and refreshes cached names; the client reloads language packs and UI.

## 4. Message definitions

`shared/protocol/*.yaml`:

```yaml
- name: hoa.run.stage_started
  id: 0xA001
  direction: server_to_client
  fields:
    - { name: stage, type: u8 }
    - { name: difficulty, type: u8 }
    - { name: boss_entry, type: u32 }
```

```yaml
- name: hoa.aura.value
  id: 0xA010
  direction: server_to_client
  fields:
    - { name: unit_guid, type: u64 }
    - { name: spell_id, type: u32 }
    - { name: value, type: u32 }     # shield remaining and other values that do not fit aura fields
    - { name: max_value, type: u32 }
```

- IDs use a dedicated HoA range; they do not take vanilla opcodes.
- Field types are fixed (u8/u16/u32/u64/i32/f32/string/array); strings are UTF-8 with a length prefix.
- Every message is versioned; incompatible changes bump `protocol_version`.

## 5. Generation

`tools/protocol-gen` reads the schema and generates:

- C++: `server/src/game/Hoa/protocol/generated/` (serialization/deserialization and message ID constants)
- Rust: `client/crates/hoa-protocol/src/generated/`
- Lua: only message constants the addon needs (the client forwards data; the addon never parses binary)

Generated files are committed; CI checks the diff.

## 6. How the addon receives data

Current: the server sends state and UI data as `BONK~type~...` chat lines and the addon parses strings.

New design:

1. The Rust client handles HoA messages.
2. The client exposes a stable Lua API to the addon, for example:

```lua
Hoa.GetRunState()          -- run state
Hoa.GetAuraValue(spellID)  -- shield amount, etc.
Hoa.GetCards()             -- card data
Hoa.RegisterEvent("RUN_STAGE", fn)
```

3. The addon no longer subscribes to chat lines or parses `~`-separated strings.

During the transition the `BONK~` channel may remain for UI data not yet migrated, but **state data must move to native auras first**, and no new chat-line state may be added.

## 7. Compatibility

- Protocol version, content hash and client version are independent; any mismatch has an explicit message.
- LAN discovery/direct-connect handshakes verify the version; different versions cannot play together.
- An old client connecting to a new server is rejected at the handshake with a clear update message.
- A new client connecting to an old server downgrades by capability bits or refuses.

## 8. Migration

1. Inventory existing `BONK~` messages and classify them as state/presentation/command.
2. Move state to auras (see [Auras and effects](../auras/README.md)).
3. Define presentation messages and the client Lua API.
4. Commands (`.bonk ...`) keep their chat entry point, but handlers call server APIs instead of assembling strings.
5. Finally delete the addon's `BONK~` parser and hand-written field indices.
