# 构建

## 依赖

| 组件 | 需要 |
| --- | --- |
| `server/` | CMake 3.20+、Visual Studio 2022 Build Tools（MSVC x64）或 GCC/Clang、Boost/OpenSSL/MySQL 客户端依赖 |
| `client/` | Rust stable（`client/rust-toolchain.toml`）、Cargo |
| `launcher/` | .NET SDK 10 |
| `addon/`、`glue/` | LuaJIT（语法检查） |

## 命令

Windows（PowerShell）：

```powershell
pwsh scripts/build.ps1 -Component server     # CMake 配置 + 构建 mangosd
pwsh scripts/build.ps1 -Component client     # cargo build --release -p hoa
pwsh scripts/build.ps1 -Component launcher   # dotnet build
pwsh scripts/build.ps1 -Component addon      # LuaJIT 语法检查
pwsh scripts/build.ps1 -Component i18n       # 校验 i18n 目录并检查生成物
pwsh scripts/build.ps1 -Component check      # 客户端清单 + 插件语法 + i18n
pwsh scripts/build.ps1 -Component all
```

Linux/macOS：

```bash
scripts/build.sh server
scripts/build.sh client
scripts/build.sh launcher
scripts/build.sh addon
scripts/build.sh i18n
scripts/build.sh check
scripts/build.sh all
```

## 当前状态（0.1.0 / 阶段 1）

- `server/`：CMake 配置 + `mangosd` Release 构建通过。
- `launcher/`：`dotnet build` 通过（导入时把 `..\telegraphs` 引用修正为 `..\tools\telegraphs`）。
- `addon/` + `glue/`：70 个 Lua 文件语法检查通过。
- `client/`：workspace 清单校验通过；完整 `cargo build` 尚未在 monorepo 内跑过（源码与已构建的 0.6.3 客户端一致），放到 CI/下一阶段验证。

## CI

`.github/workflows/ci.yml` 在每次 pull request 和 push 到 `main` 时运行 `docs-check`、`i18n-check`、`addon-lua`、`launcher-build`、`client-check`、`server-build`。这六项是合并门槛。分支保护还没启用：GitHub 的私有仓库需要 GitHub Pro 才能使用分支保护，本仓库目前在免费计划下。升级 Pro 或把仓库改为公开后运行 `scripts/protect-main.sh`。

## 服务端构建细节

```powershell
cmake -S server -B server/build -G "Visual Studio 17 2022" -A x64 `
  -DSUPPORTED_CLIENT_BUILD=CLIENT_BUILD_1_12_1 `
  -DBUILD_EXTRACTORS=OFF -DENABLE_MAILSENDER=OFF
cmake --build server/build --config Release --target mangosd -- /m
```

产物在 `server/bin/Release/`。构建目录和产物已被 `.gitignore` 忽略。
