# tools / tools

```
tools/
  content-compiler/   shared/content → SQL / client pack / addon Lua / text catalogue
  protocol-gen/       shared/protocol → C++ / Rust / Lua code
  translate/          translation workbench (start from the existing tools/translate, retargeted at shared/i18n)
  checks/             content schema, i18n completeness, generated-artifact diff, license-header checks
```

Principles:

- Tools are written in Rust or TypeScript and run cross-platform; they do not need the game running.
- Every check runs in CI and blocks merges on failure.
- Generated artifacts are produced by the tools before commit; never hand-edit them.
