# shared/i18n / 国际化

语言是**会话/账号属性**，由服务端在登录时确定；客户端安装数据的语言只用于解析资源，不决定显示语言。

## 文本分类

| 类别 | 存放位置 | 运行时来源 |
| --- | --- | --- |
| 游戏内容文本（物品/法术/光环/地图/生物/天赋/卡牌） | `shared/content` 条目内 | 服务端本地化查询响应 + 客户端内容包 |
| 服务端运行时文本（通知、奖励、战斗提示） | `shared/i18n/messages` | 服务端按消息 ID + 参数发送 |
| 客户端界面文本（选项、菜单、Glue、错误） | `shared/i18n/ui` | 客户端语言包 |
| 插件文本 | `shared/i18n/addon` | 插件 Lua 语言表 |

## 消息目录（草案）

```yaml
- id: hoa.notice.stage_unlocked
  enUS: "Stage {stage} unlocked."
  zhCN: "第{stage}阶段已解锁。"
  placeholders:
    stage: number
```

- 用**稳定 ID**，不用英文句子当键；改英文不会让旧翻译失效。
- 占位符统一 `{name}`，编译期检查类型和缺失；复数用 `_one` / `_other` 变体。
- 缺翻译时回退 enUS；CI 在缺条目、占位符不一致、未使用条目时报错。
- 首发语言：enUS、zhCN、zhTW，格式为以后加语言留好。
- zhTW 优先使用官方 1.12.1 繁中名称；没有的条目由 zhCN 转换后人工校对，字体使用 Noto Sans TC。

## 当前种子

目录现在有 995 条服务端消息（`messages/server.yaml`）和 1451 条插件文本（`addon/addon.yaml`），都包含 enUS 和 zhCN。`BonkStrings.h/.cpp` 与 `addon/HordesOfAzeroth/VanillaBonkLocaleZhCN.lua` 都由它生成；服务端构建通过，插件表内容逐条往返一致。zhTW 还没有翻译，目前只报警告、不阻断。旧消息里的数字占位符（`{1}`、`{2}`）暂时保留，等服务器调用点迁移为命名参数后再改。

```bash
python tools/i18n/gen_server_strings.py       # 从目录生成 BonkStrings.h/.cpp
python tools/i18n/check.py                    # 校验 ID、占位符和必需语言
python tools/i18n/build.py                    # 生成 shared/i18n/generated
python tools/i18n/build.py --check            # 生成物过期时失败
python tools/i18n/gen_server_strings.py --check  # BonkStrings.h/.cpp 过期时失败
```

## 生成物

- `server/src/game/Bonk/BonkStrings.h/.cpp`：枚举 + 英文源，由目录生成
- `shared/i18n/generated/`：JSON 目录（翻译工具/导出）
- `client/assets/i18n/<locale>.json`：客户端界面语言包
- `addon/HordesOfAzeroth/VanillaBonkLocaleZhCN.lua`：生成的插件语言表（文件名由 TOC 固定）

## 客户端与缓存

- 登录握手携带账号语言和内容版本；客户端据此加载语言包。
- WDB/模板缓存键加入 `(locale, content version)`；语言切换或内容更新时自动丢弃旧缓存，避免“切换中文后装备还是英文”的问题。
- 字体：各语言自带回退字体（zhCN 使用 Noto Sans SC），客户端统一按语言选择。
- 客户端 UI 语言变更后重载界面，不要求重启整个游戏。

## 翻译流程

1. 开发只改英文源和 ID。
2. `tools/translate` 增量列出缺失/变更条目。
3. 翻译写入 `shared/i18n/messages/<locale>.yaml`（或按领域拆分）。
4. CI 校验后由内容编译器生成各端产物。
