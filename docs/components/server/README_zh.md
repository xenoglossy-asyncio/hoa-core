# server / 服务端

导入自 `hordes-of-azeroth-server` 的 `zhcn-063` 快照（`930628c2c`，2026-11-04）；许可证 GPL-2.0。这是重构起点，不是最终结构。

VMaNGOS 1.12.1 服务端（C++，GPL-2.0），HoA 游戏逻辑在 `src/game/Bonk/`。

**状态：已导入**，按 [架构文档](../../architecture/README_zh.md) 逐步调整目录。

## 计划中的分层

```
server/
  src/
    game/
      Bonk/          现有 HoA 游戏层（跑团、掉落、卡牌、天赋、光环）
      Hoa/           重构后的 HoA 层（建议）
        content/     从 shared/content 生成的数据访问
        auras/       效果注册表与光环生命周期
        i18n/        消息目录运行时
        run/         远征流程
        combat/      战斗钩子、触发器、proc
  sql/
    base/            VMaNGOS 基础库结构
    content/         由共享内容编译器生成（不手改）
    migrations/      仅结构/数据修复
```

## 原则

- 所有 HoA 效果通过真实光环实现，服务端只保留一份效果状态（见 [光环与效果](../../auras/README_zh.md)）。
- 服务端不硬编码英文句子；文本走消息 ID 和语言表（见 [i18n](../../i18n/README_zh.md)）。
- 内容数据由 `tools/content-compiler` 生成；`sql/content/` 是构建产物。
- 保留内核，只对性能热点做必要重构（见 [总体架构](../../architecture/README_zh.md)）。

## 构建

见 [构建说明](../../../BUILDING_zh.md)。CMake 配置 + `mangosd` Release 构建已在本机通过；数据库初始化步骤待补。
