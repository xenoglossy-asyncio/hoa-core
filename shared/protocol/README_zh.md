# shared/protocol / 协议

服务端、客户端、插件、启动器之间的消息定义与代码生成输入。

## 目标

- 用一份 schema 生成 C++ 和 Rust 两端代码，消除手写解析器的重复和偏差。
- HoA 状态（护盾、冲刺、决心、层数、计时）走真正的游戏状态/光环，不再用 `BONK~state~...` 聊天行同步。
- 保留原版 opcode 处理原生能力（移动、战斗、buff、施法、物品查询）；HoA 只定义缺失的消息。
- 每条消息带协议版本/内容哈希；不一致时握手阶段就拒绝或降级。

## 建议分类

```
protocol/
  handshake.yaml    版本、内容哈希、语言协商
  content.yaml      内容清单/增量下发
  run.yaml          远征流程（开始、波次、奖励、结算）
  ui.yaml           仅 HoA 界面需要的展示数据（卡牌、图鉴、排行榜）
```

## 生成

`tools/protocol-gen` 读取 schema，生成：

- `server/src/game/Hoa/protocol/generated/`
- `client/crates/hoa-protocol/src/generated/`
- `addon/` 需要的 Lua 常量（如仍有插件通道）

生成物不手改；CI 校验 schema 与生成结果一致。
