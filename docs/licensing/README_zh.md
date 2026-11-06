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

**建议**：仓库原创代码用 **GPL-3.0**；插件、Glue、启动器、config 保持 GPL-3.0；服务端作为独立的 GPL-2.0 程序保留；客户端保持 MIT/Apache-2.0。如果服务端也要 GPL-3.0，需要把 MySQL 客户端换成 MariaDB Connector/C（LGPL-2.1），把 OpenSSL 1.0.2 换成 OpenSSL 3（Apache-2.0）或其他兼容 TLS 库；VMaNGOS 核心的源码头已经是“or later”。

只有在 GPL 部分全部拆成子模块、顶层仓库只放原创 MIT 代码时，顶层 MIT 才成立。这属于混合许可证聚合，不能让读者误以为 MIT 覆盖整个游戏。

## 建议结构

```
hoa-core                     GPL-3.0（原创代码 + GPL-3.0 目录）
  shared/ tools/ docs/ scripts/ config/
  addon/ glue/ launcher/      （GPL-3.0，可以继续留在 monorepo）
  server/ -> submodule hoa-server   GPL-2.0-or-later / 按分发实际为 GPL-2.0
  client/ -> submodule hoa-client   MIT 或 Apache-2.0
```

子模块 URL 用相对路径（`../hoa-server.git`），这样从 GitHub 或 Gitee 克隆时都会落到同一主机；两个平台都要镜像 fork 仓库。

如果希望所有上游都有独立来源，可以把 `addon/`、`glue/`、`launcher/` 也做成子模块，顶层只留 `shared/`、`tools/`、`docs/`、`scripts/`、`config/`。

## 步骤

1. 选定顶层许可证（建议 GPL-3.0；MIT 只用于原创独立代码）。
2. 为要变成子模块的部分创建 fork 仓库（`hoa-server`、`hoa-client`，可选 `hoa-addon`、`hoa-glue`、`hoa-launcher`），在 GitHub 和 Gitee 各推一份；用 `git filter-repo --subdirectory-filter` 或 `git subtree split` 保留历史。
3. `git submodule add ../hoa-server server`、`git submodule add ../hoa-client client`，提交 `.gitmodules`。
4. CI checkout 增加 `submodules: recursive`；Gitee 镜像也包含子模块仓库。
5. 发布工具：超级仓库的 `git archive` **不包含**子模块内容。`tools/release.ps1` 的 `Get-CommittedTree` 和包解析要改成逐个归档子模块或读取已 checkout 的工作树；如果 addon/glue/launcher 也变成子模块，同样处理。
6. 如果服务端要 GPL-3.0：替换 GPL-2.0-only 的 MySQL 客户端和 OpenSSL 1.0.2；否则让服务端作为独立的 GPL-2.0 程序。
7. 规范许可证文件：`LICENSES/` 放 GPL-2.0、GPL-3.0、MIT、Apache-2.0、OFL-1.1；更新 `LICENSE-NOTICE.md` 和 `THIRD-PARTY-NOTICES.md`。

在拆分完成前，各目录的许可证和 `LICENSE-NOTICE.md` 是唯一依据；不要把 GPL-2.0-only 的部分改标成 GPL-3.0 或 MIT。
