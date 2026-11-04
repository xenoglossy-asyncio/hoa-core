# Hordes of Azeroth Core / 艾泽拉斯之潮

一个把服务端、客户端、插件、启动器和共享内容放进同一个仓库的重构项目。

- 上游：[jonhaldors/hordes-of-azeroth](https://github.com/jonhaldors/hordes-of-azeroth)（GPL-3.0）、
  [hordes-of-azeroth-server](https://github.com/jonhaldors/hordes-of-azeroth-server)（VMaNGOS，GPL-2.0）、
  [hordes-of-azeroth-client](https://github.com/jonhaldors/hordes-of-azeroth-client)（benilla，MIT / Apache-2.0）
- 本仓库是**硬分叉**，按自己的架构独立演进，不再跟随上游；上游代码只作为起点和内容来源。
- 当前状态：**架构设计阶段**。先确定设计和仓库结构，再导入代码、开始重构。

## 目标

1. **语言是账号设置，不是客户端安装的属性。** 任何语言版本的 1.12.1 客户端数据都能运行，游戏文本由服务端和语言包决定。
2. **所有 HoA 效果都是真正的服务端光环。** 原生 buff 栏、`UnitBuff`、插件和战斗日志看到的是同一份状态；插件不再自己维护 buff 计时器。
3. **内容只有一个来源。** 物品、法术、光环、天赋、卡牌、地图、文本都定义在 `shared/content`，由编译器生成服务端 SQL、客户端数据和插件 Lua。
4. **保留能用的内核，重构有问题的层。** 服务端沿用 VMaNGOS、客户端沿用 benilla 的底层（网络、移动、战斗、渲染），重写 HoA 游戏层、i18n、光环和数据模型；性能热点单独处理。

## 目录结构

```
hoa-core/
  docs/               架构与设计文档（先读这里）
  server/             VMaNGOS C++ 服务端（GPL-2.0）
  client/             benilla Rust 客户端（MIT / Apache-2.0）
  addon/              Lua 插件（GPL-3.0）
  launcher/           Avalonia C# 启动器（GPL-3.0）
  lobby/              合作模式大厅服务（GPL-3.0）
  shared/
    content/          内容源：物品、法术、光环、地图、文本……
    i18n/             消息目录与语言包
    protocol/         服务端/客户端消息协议与代码生成
  tools/              内容编译器、翻译工具、测试工具
  scripts/            开发与构建脚本
  .github/workflows/  CI
```

## 设计文档

- [总体架构](docs/architecture.md)
- [i18n](docs/i18n.md)
- [光环与效果](docs/auras.md)
- [内容与数据](docs/content-data.md)
- [协议](docs/protocol.md)
- [迁移计划](docs/migration-plan.md)

## 许可

本仓库包含多个来源的代码，各部分保持自己的许可证：

| 目录 | 许可证 | 来源 |
| --- | --- | --- |
| `server/` | GPL-2.0 | VMaNGOS / hordes-of-azeroth-server |
| `client/` | MIT 或 Apache-2.0（二选一） | benilla / hordes-of-azeroth-client |
| `addon/`、`launcher/`、`lobby/` | GPL-3.0 | hordes-of-azeroth |
| `shared/`、`tools/`、`scripts/`、`docs/` | GPL-2.0-or-later | 本仓库新代码 |

详见 [LICENSE-NOTICE.md](LICENSE-NOTICE.md)。World of Warcraft 是 Blizzard Entertainment 的商标；本项目不附带任何游戏资源。
