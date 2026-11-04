# shared/content / 内容源

游戏内容的唯一来源。建议按领域分目录：

```
content/
  items/          装备、消耗品、材料
  spells/         法术（含 HoA 自定义法术）
  auras/          HoA 效果/光环定义（见 docs/auras.md）
  creatures/      生物、NPC、Boss
  zones/          地图、区域、场景
  talents/        天赋、精通树
  cards/          暗月卡牌、卡牌效果
  gear/           装备池、品质、等级曲线、掉落表
  quests/         任务
  loot/           掉落表
  strings/        被内容引用的长文本（或直接写在条目里）
```

## 条目格式（草案）

每条内容有稳定 ID、英文原文、本地化字段、数值和关系。示例：

```yaml
id: hoa.item.darkmoon.ogre_slayer
kind: item
name_id: hoa.text.item.darkmoon.ogre_slayer.name
description_id: hoa.text.item.darkmoon.ogre_slayer.desc
icon: Interface/Icons/INV_Misc_Ticket_Darkmoon_01
quality: 3
stats: { strength: 12, stamina: 8 }
```

文本按语言放在条目旁或独立的 `i18n` 文件里，通过 `*_id` 关联；不要用英文句子当键。

## 编译器输出

`tools/content-compiler` 读取本目录并生成：

- `server/sql/content/*.sql`：可重复执行的建表/插入数据
- `server/src/game/Hoa/content/generated/`：ID 常量与静态表
- `client/assets/content/<version>/content.bin`：客户端内容包
- `addon/HordesOfAzeroth/generated/content.lua`：插件数据表
- `shared/i18n/generated/*.json`：文本目录（供 C++/Rust/Lua 共用）
- `content.hash`：内容版本哈希

## 当前试点：卡牌

第一组表已经端到端接通：

- `cards/cards.yaml` 是源文件（46 张卡，英文 + zhCN）。
- `tools/content/dump_cards.py` 从现有 `bonk_card`/`bonk_card_locale` 表一次性导入。
- `tools/content/compile.py` 生成 `server/sql/content/bonk_card.sql`；`--check` 在 CI 里保证 SQL 与源文件同步。

生成的 SQL 已应用到测试库，并和旧的 `bonk_card` 与 zhCN 语言行逐行对比，完全一致。后面的表按同一模式迁移。

## 迁移

先写一个 dump 工具，把现有 `bonk_*` 表、`item_template` 中的 HoA 自定义条目、`locales_*` 文本导出成上述源文件；确认生成结果与现有数据库一致后，再切换为生成流程。详见 [迁移计划](../../docs/migration-plan/README_zh.md)。
