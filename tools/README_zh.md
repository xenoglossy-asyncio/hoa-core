# tools / 工具

```
tools/
  content-compiler/    shared/content → SQL / 客户端包 / 插件 Lua / 文本目录
  protocol-gen/        shared/protocol → C++ / Rust / Lua 代码
  translate/           翻译工作台（基于现有 tools/translate，改造为读写 shared/i18n）
  checks/              内容 schema、i18n 完整性、生成物 diff、许可证头检查
```

原则：

- 工具本身用 Rust 或 TypeScript 写，跨平台；不依赖游戏运行。
- 所有检查进 CI，失败即阻断合并。
- 生成物在提交前由工具产出，禁止手工编辑。
