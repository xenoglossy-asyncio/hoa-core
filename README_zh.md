# Hordes of Azeroth Core / 艾泽拉斯之潮

一个把服务端、客户端、插件、启动器和共享内容放进同一个仓库的重构项目。

- 上游：[jonhaldors/hordes-of-azeroth](https://github.com/jonhaldors/hordes-of-azeroth)（GPL-3.0）、
  [hordes-of-azeroth-server](https://github.com/jonhaldors/hordes-of-azeroth-server)（VMaNGOS，GPL-2.0）、
  [hordes-of-azeroth-client](https://github.com/jonhaldors/hordes-of-azeroth-client)（benilla，MIT / Apache-2.0）
- 本仓库是**硬分叉**，按自己的架构独立演进，不再跟随上游；上游代码只作为起点和内容来源。
- 版本线从 **0.1.0** 开始。
- 首发语言：**enUS + zhCN + zhTW**。
- 联机只支持**局域网**和 `ip/domain:port` 直连，不做公网大厅或注册服务器。
- 当前状态：**阶段 1 完成，阶段 2 进行中**。0.1.0 以上游 0.6.3 的代码快照起步，后续按 `docs/` 的设计逐步重构。

## 目标

1. **语言是账号设置，不是客户端安装的属性。** 任何语言版本的 1.12.1 客户端数据都能运行，游戏文本由服务端和语言包决定。
2. **所有 HoA 效果都是真正的服务端光环。** 原生 buff 栏、`UnitBuff`、插件和战斗日志看到的是同一份状态；插件不再自己维护 buff 计时器。
3. **内容只有一个来源。** 物品、法术、光环、天赋、卡牌、地图、文本都定义在 `shared/content`，由编译器生成服务端 SQL、客户端数据和插件 Lua。
4. **保留能用的内核，重构有问题的层。** 服务端沿用 VMaNGOS、客户端沿用 benilla 的底层（网络、移动、战斗、渲染），重写 HoA 游戏层、i18n、光环和数据模型；性能热点单独处理。

## 目录结构

```
hoa-core/
  VERSION             0.1.0
  docs/               架构与设计文档（每个文档都有 README.md / README_zh.md）
  server/             VMaNGOS C++ 服务端（GPL-2.0）
  client/             benilla Rust 客户端（MIT / Apache-2.0）
  addon/              Lua 插件（GPL-3.0）
  glue/               登录/选人/建号 GlueXML（GPL-3.0）
  launcher/           Avalonia C# 启动器；局域网/直连联机（GPL-3.0）
  config/             服务端与启动器默认配置（GPL-3.0）
  localization/       现有翻译数据与工具（过渡期参考，GPL-3.0）
  shared/
    content/          内容源：物品、法术、光环、地图、文本……
    i18n/             消息目录与语言包
    protocol/         服务端/客户端消息协议与代码生成
  tools/              内容编译器、协议生成器、翻译与测试工具
  scripts/            开发与构建脚本
  .github/workflows/  CI
```

## 设计文档

- [构建说明](BUILDING_zh.md)
- [文档索引与当前决策](docs/README_zh.md)
- [导入的代码与来源](docs/imported-code/README_zh.md)
- [总体架构](docs/architecture/README_zh.md)
- [i18n](docs/i18n/README_zh.md)
- [光环与效果](docs/auras/README_zh.md)
- [客户端原生能力](docs/native-capabilities/README_zh.md)
- [内容与数据](docs/content-data/README_zh.md)
- [协议](docs/protocol/README_zh.md)
- [迁移计划](docs/migration-plan/README_zh.md)

## 许可

本仓库包含多个来源的代码，各部分保持自己的许可证：

| 目录 | 许可证 | 来源 |
| --- | --- | --- |
| `server/` | GPL-2.0 | VMaNGOS / hordes-of-azeroth-server |
| `client/` | MIT 或 Apache-2.0（二选一） | benilla / hordes-of-azeroth-client |
| `addon/`、`glue/`、`launcher/`、`config/`、`localization/` | GPL-3.0 | hordes-of-azeroth |
| `tools/` 中从上游导入的部分 | GPL-3.0 | hordes-of-azeroth |
| `shared/`、`scripts/`、`docs/`、`tools/` 中新写的部分 | GPL-2.0-or-later | 本仓库新代码 |

详见 [LICENSE-NOTICE.md](LICENSE-NOTICE.md)。World of Warcraft 是 Blizzard Entertainment 的商标；本项目不附带任何游戏资源。
