# 许可证说明

本仓库不是单一许可证项目。它把几个独立程序放在同一个仓库里（aggregate），每个部分继续使用自己的许可证；合并本身不改变任何一方的许可证。

| 路径 | 许可证 | 版权/来源 |
| --- | --- | --- |
| `server/` | GNU GPL v2.0 | VMaNGOS 及其贡献者；hordes-of-azeroth-server 的改动 |
| `client/` | MIT 或 Apache License 2.0，任选其一 | benilla 及其贡献者；hordes-of-azeroth-client 的改动 |
| `addon/`、`glue/`、`launcher/`、`config/`、`localization/` | GNU GPL v3.0 | Hordes of Azeroth 及其贡献者 |
| `tools/` 中从上游导入的部分 | GNU GPL v3.0 | Hordes of Azeroth 及其贡献者 |
| `shared/`、`scripts/`、`docs/`、`tools/` 中新写的部分 | GNU GPL v2.0 或更高版本 | 本仓库的新代码 |

## 为什么这样分

- VMaNGOS 是 GPL-2.0-only，不能整体升级到 GPL-3.0。
- benilla 是 MIT / Apache-2.0，可以放进 GPL 项目，但保留原许可证更清楚。
- Hordes of Azeroth 主仓库是 GPL-3.0。
- `shared/` 和 `tools/` 会被服务端（GPL-2.0）和插件（GPL-3.0）同时使用，所以采用 GPL-2.0-or-later：两边都能用。
- `shared/content` 的**数据**（不是代码）同样按 GPL-2.0-or-later 提供；生成出来的 SQL/JSON/Lua 数据不改变各程序的许可证。

## 导入代码时的要求

导入 `server/`、`client/`、`addon/`、`glue/`、`launcher/`、`config/`、`localization/` 时必须保留各目录原有的 `LICENSE`、`LICENSE-MIT`、`LICENSE-APACHE`、`THIRD-PARTY-NOTICES.md` 和文件头版权声明。新增文件在文件头或目录 README 中注明许可证。

World of Warcraft 是 Blizzard Entertainment, Inc. 的商标。本仓库不包含、也不分发任何暴雪游戏资源；客户端仍然读取用户自己的 1.12.1 安装。
