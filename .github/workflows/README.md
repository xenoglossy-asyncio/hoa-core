# CI

计划中的流水线：

1. **license-headers**：检查新文件的许可证头和生成物标记。
2. **content**：校验 `shared/content` schema，重新生成并检查 diff。
3. **i18n**：检查消息 ID 唯一、占位符一致、各语言缺失/未使用条目。
4. **protocol**：重新生成 C++/Rust 并检查 diff。
5. **server**：Linux（GCC/Clang）与 Windows（MSVC）构建。
6. **client**：`cargo build` / `cargo test`（至少 benilla-formats、hoa-protocol、benilla-app 的库测试）。
7. **launcher/lobby**：dotnet build/test。
8. **integration**：无头启动服务端 + 客户端，验证登录、语言切换、buff 显示。

导入代码后再落地具体 workflow 文件。
