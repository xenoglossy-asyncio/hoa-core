# shared/protocol / protocol

Message definitions and codegen inputs shared by the server, client and addon.

## Goals

- Generate C++ and Rust from one schema, eliminating duplicate hand-written parsers.
- HoA state (shield, dash, determination, stacks, timers) travels as real game state/auras, not `BONK~state~...` chat lines.
- Keep vanilla opcodes for native capabilities (movement, combat, buffs, casting, item queries); define only the messages vanilla lacks.
- Every message carries a protocol/content version; mismatches are rejected or downgraded at the handshake.

## Suggested layout

```
protocol/
  handshake.yaml    version, content hash, language negotiation
  content.yaml      content manifest/incremental delivery
  run.yaml          run flow (start, waves, rewards, results)
  ui.yaml           presentation data needed only by HoA UI (cards, codex, leaderboard)
```

## Generation

`tools/protocol-gen` reads the schema and generates:

- `server/src/game/Hoa/protocol/generated/`
- `client/crates/hoa-protocol/src/generated/`
- Lua constants for the addon (while an addon channel remains)

Never hand-edit generated artifacts; CI verifies schema and output agree.
