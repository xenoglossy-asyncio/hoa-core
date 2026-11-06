# 许可证说明

本仓库的原创代码采用 **GPL-3.0**；服务端现在也按 **GPL-3.0** 分发。仓库仍把几个独立程序放在一起（aggregate），导入的上游代码和第三方组件保留自己的许可证与版权声明，但这些许可证都与 GPL-3.0 兼容。顶层 `LICENSE` 是 GPL-3.0，完整许可证文本在 `LICENSES/`，逐目录来源在各自的 `UPSTREAM.md` 和 `provenance.yaml`。

| 路径/组件 | 许可证 | 版权/来源 |
| --- | --- | --- |
| `server/`（VMaNGOS 分支，整体分发） | GNU GPL v3.0；源码头为 GPL-2.0-or-later，可按 GPL-3.0 分发 | VMaNGOS 及其贡献者；hordes-of-azeroth-server 的改动 |
| `server/dep/windows` 的 MariaDB Connector/C 3.4.10 | GNU LGPL v2.1-or-later（动态链接） | MariaDB Foundation / MariaDB Corporation |
| `server/dep/windows` 的 OpenSSL 3.5.9 LTS | Apache License 2.0 | OpenSSL Project；Windows 构建来自 Shining Light Productions |
| `client/` | MIT 或 Apache License 2.0，任选其一 | benilla 及其贡献者；hordes-of-azeroth-client 的改动 |
| `addon/`、`glue/`、`launcher/`、`config/`、`localization/` | GNU GPL v3.0 | Hordes of Azeroth 及其贡献者 |
| `shared/`、`scripts/`、`docs/`、`tools/` 的原创部分 | GNU GPL v3.0 | 本仓库的新代码 |
| 插件字体 | SIL Open Font License 1.1 | Barlow、Noto Sans SC/TC |
| MariaDB Server（启动器下载，单独运行） | GNU GPL v2.0-only | MariaDB；作为独立程序聚合，不链接进服务端 |

## 为什么这样分

- VMaNGOS 的 748 个 GPL 源码头都是 GPL-2.0-or-later；其余第三方依赖（gSOAP、libmpq、G3D、recastnavigation、cpptrace、utf8cpp、zlib、bzip2 等）的许可证也都与 GPL-3.0 兼容。原来的两个阻塞已经移除：GPL-2.0-only 的 MySQL 客户端换成 LGPL-2.1-or-later 的 MariaDB Connector/C，GPL 不兼容的 OpenSSL 1.0.2 换成 Apache-2.0 的 OpenSSL 3.5.9。因此服务端可以整体按 GPL-3.0 分发。
- MariaDB Connector/C 以 DLL 动态链接，LGPL-2.1-or-later 允许与 GPL-3.0 程序组合；它使用 Windows Schannel，不依赖 OpenSSL。
- OpenSSL 3.5.9 只使用 `libcrypto`；RC4 需要的 legacy provider 以 `legacy.dll` 随服务端分发。
- benilla 是 MIT / Apache-2.0，可以放进 GPL 项目；保留原许可证更清楚，客户端仍可按任一上游许可证使用。
- MariaDB Server 是 GPL-2.0-only，但它是启动器单独下载、单独运行的程序，不和我们的 GPL-3.0 代码链接；GPLv2 与 GPLv3 程序可以作为独立程序聚合在同一发行版中。
- `shared/`、`tools/` 现在只被 GPL-3.0 服务端和 GPL-3.0 插件使用，因此统一为 GPL-3.0，不再需要 GPL-2.0-or-later 的双向兼容。`shared/content` 的数据同样按 GPL-3.0 提供。
- 完整依赖盘点和兼容性说明见 [docs/licensing](docs/licensing/README_zh.md)。

## 许可证选择与仓库结构（2026-11-06）

- 仓库原创代码、服务端、插件、Glue、启动器、config、localization、`shared/`、`scripts/`、`docs/`、`tools/` 统一采用 **GPL-3.0**。
- 导入的上游代码和第三方组件保留各自许可证；所有许可证都与 GPL-3.0 兼容，服务端不再受 GPL-2.0-only 依赖限制。
- 仓库继续使用 **monorepo，不引入 submodule**。每个导入目录保留自己的 `LICENSE` 和 `UPSTREAM.md`；`LICENSE-NOTICE.md` 与 `provenance.yaml` 记录来源、上游提交和本地修改；发布 tag 就是对应源码。许可证义务靠这些声明和对应源码满足，不靠 Git 结构。
- submodule 只是可选的来源管理工具，不是许可证要求。硬分支、跨目录 PR 和 Gitee 镜像下，它反而增加贡献和发布成本；以后需要更细的上游追踪再考虑，并同步修改发布工具（`git archive` 不包含子模块内容）。

## 导入代码时的要求

导入 `server/`、`client/`、`addon/`、`glue/`、`launcher/`、`config/`、`localization/` 时必须保留各目录原有的 `LICENSE`、`LICENSE-MIT`、`LICENSE-APACHE`、`UPSTREAM.md`、`THIRD-PARTY-NOTICES.md` 和文件头版权声明。新增文件在文件头或目录 README 中注明许可证。

World of Warcraft 是 Blizzard Entertainment, Inc. 的商标。本仓库不包含、也不分发任何暴雪游戏资源；客户端仍然读取用户自己的 1.12.1 安装。
