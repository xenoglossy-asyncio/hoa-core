# 许可证说明

本仓库不是单一许可证项目。它把几个独立程序放在同一个仓库里（aggregate），每个部分继续使用自己的许可证；合并本身不改变任何一方的许可证。顶层 `LICENSE` 是 GPL-3.0，覆盖本仓库的原创代码；第三方目录以各自目录里的许可证为准。

| 路径 | 许可证 | 版权/来源 |
| --- | --- | --- |
| `server/` | GNU GPL v2.0（源码头多为 v2-or-later；Windows 的 MySQL/OpenSSL 依赖见下） | VMaNGOS 及其贡献者；hordes-of-azeroth-server 的改动 |
| `client/` | MIT 或 Apache License 2.0，任选其一 | benilla 及其贡献者；hordes-of-azeroth-client 的改动 |
| `addon/`、`glue/`、`launcher/`、`config/`、`localization/` | GNU GPL v3.0 | Hordes of Azeroth 及其贡献者 |
| `tools/` 中从上游导入的部分 | GNU GPL v3.0 | Hordes of Azeroth 及其贡献者 |
| `shared/`、`scripts/`、`docs/`、`tools/` 中新写的部分 | GNU GPL v3.0（`shared/` 等与服务端共用的部分保持 GPL-2.0-or-later） | 本仓库的新代码 |

## 为什么这样分

- VMaNGOS 的源码头多数是 GPL-2.0-or-later，但 `server/dep/windows` 里的 MySQL 客户端头是 GPL-2.0-only，随附的 OpenSSL 1.0.2 使用与 GPL 不兼容的 OpenSSL/SSLeay 许可证；因此服务端实际按 GPL-2.0 单独分发，不能整体改成 GPL-3.0，除非替换这些依赖。完整盘点见 [docs/licensing](docs/licensing/README_zh.md)。
- benilla 是 MIT / Apache-2.0，可以放进 GPL 项目，但保留原许可证更清楚。
- Hordes of Azeroth 主仓库是 GPL-3.0。
- `shared/` 和 `tools/` 会被服务端（GPL-2.0）和插件（GPL-3.0）同时使用，所以采用 GPL-2.0-or-later：两边都能用。`shared/` 不能改成 GPL-3.0，否则 GPL-2.0 服务端无法使用。
- `shared/content` 的**数据**（不是代码）同样按 GPL-2.0-or-later 提供；生成出来的 SQL/JSON/Lua 数据不改变各程序的许可证。

## 许可证选择与仓库结构（2026-11-06）

- 原创代码采用 **GPL-3.0**；顶层 `LICENSE` 是 GPL-3.0。
- `shared/`、`shared/content` 以及其他被服务端和插件共用的代码/数据保持 **GPL-2.0-or-later**。
- 仓库继续使用 **monorepo，不引入 submodule**。每个导入目录保留自己的 `LICENSE` 和 `UPSTREAM.md`；`LICENSE-NOTICE.md` 与 `provenance.yaml` 记录来源、上游提交和本地修改；发布 tag 就是对应源码。许可证义务靠这些声明和对应源码满足，不靠 Git 结构。
- submodule 只是可选的来源管理工具，不是许可证要求。硬分支、跨目录 PR 和 Gitee 镜像下，它反而增加贡献和发布成本；以后需要更细的上游追踪再考虑，并同步修改发布工具（`git archive` 不包含子模块内容）。

## 导入代码时的要求

导入 `server/`、`client/`、`addon/`、`glue/`、`launcher/`、`config/`、`localization/` 时必须保留各目录原有的 `LICENSE`、`LICENSE-MIT`、`LICENSE-APACHE`、`UPSTREAM.md`、`THIRD-PARTY-NOTICES.md` 和文件头版权声明。新增文件在文件头或目录 README 中注明许可证。

World of Warcraft 是 Blizzard Entertainment, Inc. 的商标。本仓库不包含、也不分发任何暴雪游戏资源；客户端仍然读取用户自己的 1.12.1 安装。
