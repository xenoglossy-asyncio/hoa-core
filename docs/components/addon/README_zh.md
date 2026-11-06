# addon / 插件

导入自主仓库 `Interface/AddOns/HordesOfAzeroth`（`3ca658b`，2026-11-04）；许可证 GPL-3.0。当前源码在 `addon/HordesOfAzeroth/`。

## 重构后的职责

插件只做**表现层**：

- 读取客户端原生接口（`UnitBuff`、`UnitLevel`、`GetTime`、战斗事件）来显示 HoA 界面。
- 不再维护 buff/效果的计时器、层数、状态机；这些全部在服务端光环里（见 [光环与效果](../../auras/README_zh.md)）。
- 不再自己计算物品等级、装备属性等服务器已经算好的数据；这些由内容包或协议下发。
- 语言文本全部从 `shared/i18n` 生成的 Lua 表读取，语言由服务端/客户端设置决定，不读取客户端安装语言。`VanillaBonkLocaleData.lua` 由 `shared/i18n/addon/addon.yaml` 生成，一个文件承载全部语言。

## 计划目录

```
addon/
  HordesOfAzeroth/
    *.lua            界面与交互
    generated/       由 shared/i18n 和 shared/content 生成（不手改）
    Fonts/           语言字体回退（Noto Sans SC / Noto Sans TC）
    HordesOfAzeroth.toc
```

## 保留

现有插件里的可用部分（窗口布局、卡牌/奖励界面、提示、绑定、GlueXML 语言机制）继续保留，逐步迁移到新数据源。
