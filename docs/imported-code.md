# 导入的代码与来源

本仓库的 0.1.0 不是从零写的，第一版代码是以下几个上游快照，导入时保留各自许可证和版权。之后的改动在新历史里进行，不再自动合并上游。

| 目录 | 来源仓库 | 分支/提交 | 许可证 |
| --- | --- | --- | --- |
| `server/` | `jonhaldors/hordes-of-azeroth-server`（VMaNGOS 分支） | `vanilla-bonk` 派生的 `zhcn-063`，`930628c2c` | GPL-2.0 |
| `client/` | `jonhaldors/hordes-of-azeroth-client`（benilla） | `zhcn-063`，`74a4e4e` | MIT 或 Apache-2.0 |
| `addon/HordesOfAzeroth/` | `jonhaldors/hordes-of-azeroth` | `main`/`zhcn-063`，`3ca658b` | GPL-3.0 |
| `glue/` | 同上，`Interface/GlueXML` | `3ca658b` | GPL-3.0 |
| `launcher/` | 同上，`tools/launcher` | `3ca658b` | GPL-3.0 |
| `tools/`（除 launcher） | 同上，`tools/` | `3ca658b` | GPL-3.0 |
| `config/` | 同上，`config/` | `3ca658b` | GPL-3.0 |
| `localization/` | 同上，`localization/` | `3ca658b` | GPL-3.0 |

导入日期：2026-11-04。本地快照来自 `C:\Users\hunau\Desktop\hordes-of-azeroth` 的三个工作树：
主仓库 `3ca658b`、`server/core` `930628c2c`、`client` `74a4e4e`。

## 没有导入的内容

- `tools/lobby-server/`：新方案只做局域网和 `ip/domain:port` 直连，不维护公网大厅/注册服务。
- `Interface/AddOns/BonkAuras/`：独立的 WA 风格插件，不属于 HoA 核心；继续放在它自己的仓库。
- 构建产物（`target/`、`build/`、`bin/`、`obj/`）、数据库文件、服务端运行目录、日志、截图、测试配置。
- 子模块的 git 历史：新仓库从 0.1.0 开始一条新历史；需要追溯旧改动时回到上表的来源仓库。

## 版本

- 上游 0.6.3 → 新仓库 **0.1.0**，表示架构重写的起点，不表示功能缩减。
- `VERSION` 在仓库根目录；各组件不再单独维护版本号，打包时由根版本派生。

## 许可证

导入的目录各自保留原许可证文件：

- `server/LICENSE`（GPL-2.0）
- `client/LICENSE-MIT`、`client/LICENSE-APACHE`
- 根目录 `LICENSE-GPL-3.0`、`THIRD-PARTY-NOTICES.md` 覆盖 addon/glue/launcher/tools 等来自主仓库的部分
- 新写的 `shared/`、`scripts/`、`docs/`、部分 `tools/` 使用 GPL-2.0-or-later

详见 [LICENSE-NOTICE.md](../LICENSE-NOTICE.md)。
