# CI

`.github/workflows/ci.yml` 在每次 pull request 和 push 到 `main` 时运行：

| Job | 内容 |
| --- | --- |
| `docs-check` | 检查中英文 README 配对、相对链接，以及 `provenance.yaml` / `UPSTREAM.md` 记录 |
| `addon-lua` | 用 LuaJIT 解析插件和 GlueXML 的所有 Lua 文件 |
| `launcher-build` | Avalonia 启动器 `dotnet build` |
| `client-check` | 客户端 workspace `cargo check -p hoa` |
| `server-build` | Ubuntu 24.04 上 CMake 配置 + `mangosd` 构建 |

`main` 已配置分支保护，合并前必须通过这五项检查；任何一项失败都不能合并。本地可以用 `scripts/build.ps1`/`build.sh`（addon、launcher、client、server）和 `python scripts/check-docs.py` 跑同一组检查。
