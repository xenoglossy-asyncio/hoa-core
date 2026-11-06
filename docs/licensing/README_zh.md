# 许可证与仓库结构

本页记录许可证盘点和 monorepo/submodule 方案。它是工程文档，不是法律意见；正式分发前应请律师复核。

## 仓库里实际有什么

| 路径 | 许可证 | 说明 |
| --- | --- | --- |
| `server/` | GPL-2.0 | VMaNGOS 分支。`server/LICENSE` 是 GPL-2.0；815 个 GPL 源码头中有 736 个写“either version 2 ... or later”。但 `server/dep/windows/include/mysql` 里的 MySQL 客户端头是 GPL-2.0（仅第 2 版），随附的 OpenSSL 1.0.2 使用 OpenSSL/SSLeay 许可证，FSF 认为它与 GPL 不兼容。gSOAP、libmpq 是 GPL-2.0-or-later；recastnavigation 是 zlib；cpptrace 是 MIT；utf8cpp 是 Boost；g3dlite 含 BSD/LGPL 部分。 |
| `client/` | MIT 或 Apache-2.0 | benilla 分支；所有 workspace crate 都声明 `MIT OR Apache-2.0`。Cargo 依赖为 MIT、Apache-2.0、MPL-2.0、zlib、BSD 等（发行包里的 `CLIENT-LICENSES.md` 会逐条列出）。 |
| `addon/`、`glue/`、`launcher/`、`config/`、`localization/` | GPL-3.0 | Hordes of Azeroth 的衍生物。启动器依赖的 Avalonia、Mono.Nat 是 MIT。 |
| `shared/`、`scripts/`、`docs/`、新写的 `tools/` | GPL-2.0-or-later | 本仓库自己的代码。 |
| 插件字体 | OFL-1.1 | Barlow、Noto Sans SC、Noto Sans TC；字体旁有许可证文件。 |
| MariaDB Server / world 数据库 | GPL-2.0 | 单独下载或随包分发，不链接进我们的二进制。 |

## 兼容性

- GPL-3.0 可以与 MIT、Apache-2.0、BSD、zlib、Boost、LGPL 组合。
- GPL-3.0 不能与 GPL-2.0-only 合并成一个作品；GPLv2 和 GPLv3 程序可以作为**独立程序聚合**在同一介质上（客户端、服务端、启动器、插件）。
- 当前服务端二进制受 GPL-2.0-only 的 MySQL 客户端和 OpenSSL 1.0.2 约束；除非替换这两个依赖，否则应按 GPL-2.0 分发。
- MIT 不能作为整个仓库的许可证：插件、Glue、启动器都是 GPL-3.0 衍生物。MIT 只能覆盖原创且独立的代码。

**决定（2026-11-06）**：仓库原创代码采用 **GPL-3.0**；`shared/` 和 `shared/content` 保持
**GPL-2.0-or-later**，因为 GPL-2.0 服务端和 GPL-3.0 插件都要用；服务端保持 **GPL-2.0**，
客户端保持 **MIT 或 Apache-2.0**，插件、Glue、启动器、config、localization 保持 **GPL-3.0**。

**仓库继续使用 monorepo，不引入 submodule。** 许可证义务靠保留许可证和版权声明、标明来源与本地修改、提供对应源码来满足，Git 结构不是许可证要求。submodule 只是可选的来源追踪工具，会增加贡献、跨目录原子修改、CI 和 Gitee 镜像的成本。每个导入目录保留 `LICENSE` 和 `UPSTREAM.md`；`LICENSE-NOTICE.md` 与 `provenance.yaml` 记录其余信息，发布 tag 就是对应源码。

## 建议结构

```
hoa-core                     GPL-3.0（顶层 LICENSE 覆盖原创代码）
  LICENSES/                  GPL-2.0、GPL-3.0、MIT、Apache-2.0、OFL-1.1 全文
  shared/                    GPL-2.0-or-later（服务端和插件共用）
  server/                    GPL-2.0 + LICENSE + UPSTREAM.md
  client/                    MIT 或 Apache-2.0 + LICENSE-MIT/LICENSE-APACHE + UPSTREAM.md
  addon/ glue/ launcher/     GPL-3.0 + UPSTREAM.md
  config/ localization/      GPL-3.0 + UPSTREAM.md
  tools/ docs/ scripts/      GPL-3.0 原创代码（导入的工具保留原声明）
```

如果以后上游追踪成本太高，可以把 `server/`、`client/` 改成各自 fork 仓库的子模块；那是维护选择，不是许可证要求。届时用相对 URL（`../hoa-server.git`），让 GitHub 和 Gitee 克隆都落到同一主机；同时镜像 fork 仓库，并先修发布工具——`git archive` 不包含子模块内容。

## 步骤

1. 保留顶层 `LICENSE`（GPL-3.0）和各目录许可证；决定记录在本页和 `LICENSE-NOTICE.md`。
2. 每个导入目录保留 `LICENSE`/`LICENSE-MIT`/`LICENSE-APACHE` 和 `UPSTREAM.md`，写明上游 URL、提交、基准和本地修改。
3. 保留 `LICENSES/` 全文和 `THIRD-PARTY-NOTICES.md` 依赖清单。
4. 如果服务端要 GPL-3.0：替换 GPL-2.0-only 的 MySQL 客户端和 OpenSSL 1.0.2；否则服务端按 GPL-2.0 作为独立程序。
5. 不要把 GPL-2.0-only 的部分改标成 GPL-3.0 或 MIT。以后若引入 submodule，必须同轮更新 CI（`submodules: recursive`）和发布打包。
