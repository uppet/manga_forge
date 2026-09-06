# GameAnalytics 公开 Beta 接入说明

## 目标与边界

Last Inkwarden / 墨卫残章的远程统计只用于改进免费公开 Beta，不替代现有的本地试玩记录器。发布构建必须使用独立的 `Last Inkwarden - Public Beta` GameAnalytics 项目；开发测试和未来正式发行分别使用不同项目，避免污染玩家、留存与漏斗数据。

游戏以“可选使用统计”呈现此功能。新玩家首次进入标题界面时必须看到独立说明并明确选择“不要发送”或“允许发送”，默认焦点是“不要发送”。在玩家明确允许前，不创建远程统计身份、不初始化 GameAnalytics、也不发送请求。之后可在“选项 → 数据与隐私”查看完整说明、修改选择；关闭时立即停止请求并删除本地身份和待发送队列。自动化测试与 JSON 调试启动状态始终禁用网络统计。

项目固定使用 Godot 4.5.2。当前继续使用已经过 HMAC、离线队列、撤回删除和事件白名单测试的 HTTPS Collection API v2 轻量客户端；引擎升级不与统计 SDK 迁移绑定。官方 Godot SDK 3.1.0 已支持 Godot 4.5+，若以后改用，必须保持本文件的同意时序、数据边界、退出刷新和测试契约。

官方参考：

- Godot SDK：https://github.com/GameAnalytics/GA-SDK-GODOT
- Collection API 设置：https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/api/setup/
- 事件类型：https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/api/event-types/

## 账号与构建配置

1. 在 GameAnalytics 中建立并选中独立项目 `Last Inkwarden - Public Beta`，平台为 Windows；不要复用开发项目或未来正式发行项目。
2. 执行 `cp tools/windows/gameanalytics.local.json.example tools/windows/gameanalytics.local.json`。
3. 在 Git 忽略的本机 JSON 中保留 `"profile": "public_beta"`，填写该 Beta 项目的 Game Key（32 位十六进制）和 Secret Key（40 位十六进制）。普通账号项目 keys 使用 `production` endpoint；仅官方 sandbox keys 使用 `sandbox`。
4. 执行 `python3 tools/windows/host_game.py gameanalytics-build-test` 验证注入器。
5. 执行 `python3 tools/windows/host_game.py export`。导出器仅在构建期间改写 Windows runtime 的 `scripts/gameanalytics_credentials.gd`，将凭据编译进内嵌 PCK，并在成功或失败后恢复空占位文件。本机 JSON 不会进入同步目录或发布包。
6. 检查 `build/windows/gameanalytics-build.json`：应为 `"embedded": true`、`"credential_profile": "public_beta"`，并包含不泄露 Key 的 16 位配置指纹。`export-boot.log` 必须出现相同 profile 和指纹。
7. 公开 Beta ZIP 构建器会拒绝非 `public_beta` profile。玩家正常双击 EXE 即可，不需要环境变量。
8. 用干净用户目录启动，确认首次同意页默认停在“不要发送”；分别验证拒绝、允许、撤回与再次允许。
9. 同意后开一局并完成升级、页面推进和结算，在该 Beta 项目的 Realtime / Live Events 中确认 `user`、`progression`、`design` 与聚合后的 `resource` 事件。

排查时确认仪表盘打开的是 Beta 项目，清空 Event Type / Build / User ID 过滤条件，并留意 Build 为 `0.25.0-beta.1`。Live Events 与普通报表可能有处理延迟；还应确认 Game Settings 没有禁用 Event Collection 或过滤此 Build。

真实 keys 禁止写入 Git、问题单、试玩日志或聊天记录。`*.local.json` 已加入 `.gitignore`，仓库中的 `gameanalytics_credentials.gd` 永远是空占位。Secret Key 最终位于客户端内，有能力逆向 EXE/PCK 的人仍可能提取；它只能作为客户端采集签名 key，绝不能与账号密码、管理 API key 或其他服务密钥复用。

以下变量仅用于开发覆盖与紧急停用，普通玩家不需要设置：

| 变量 | 值 | 说明 |
| --- | --- | --- |
| `INKBOUND_GA_GAME_KEY` | 32 位十六进制 | 临时覆盖 Windows Game Key |
| `INKBOUND_GA_SECRET_KEY` | 40 位十六进制 | 临时覆盖事件 HMAC key |
| `INKBOUND_GA_ENVIRONMENT` | `sandbox` / `production` | 临时覆盖 endpoint |
| `INKBOUND_GA_ENABLED` | `0` / `1` | `0` 是运维总开关，不能替代玩家同意 |
| `INKBOUND_GA_DEBUG` | `0` / `1` | 只输出重试原因，不输出 key 或事件正文 |

## 冻结的公开 Beta 事件字典

只有下列 12 种低频游戏语义可以进入远程统计。`record_game_event()` 会丢弃其他本地记录器事件；武器、升级、遗物、路线、事件与剧情 ID 必须存在于内容数据库，未知值统一折叠为 `other`，防止仪表盘维度无限增长。

| 本地事件 | 远程用途 | 最大预期频率 |
| --- | --- | --- |
| `run_started` | 难度/契约开局与初始武器 | 每局一次 |
| `run_continued` | Continue/Load 恢复页 | 每次续局一次 |
| `page_started` | 页进度与进入时生命值 | 每页一次 |
| `boss_page_started` | Boss 页到达 | 每个 Boss 页一次 |
| `route_selected` | 章节路线选择 | 每局最多三次 |
| `event_selected` | 页间事件与效果 | 每局最多三次 |
| `upgrade_selected` | 技巧选择与等级 | 每次升级一次 |
| `relic_selected` | 神器选择与所在页 | 每次神器一次 |
| `story_choice` | 非回放的结局选择 | 每个结局选择一次 |
| `save_return` | Save & Return 所在页 | 每次保存返回一次 |
| `manual_visibility` | 战地手册打开 | 仅打开时一次 |
| `run_finalized` | 胜负、时长、最远页、最终武器、击杀数、结局或粗粒度死因、Memory 总量 | 每局一次 |

客户端还会按 GameAnalytics 协议产生：启用后每会话一次 `user`、正常/恢复结束一次 `session_end`，以及每局一组 `progression` Start/Complete/Fail。Memory 只在整局结算时用一个 `resource` Source 事件聚合。

禁止上传：玩家姓名、账号、邮箱、Steam ID、试玩 participant code、自由文本、问卷备注、截图、麦克风、摄像头、存档内容、随机 seed、精确世界坐标、逐帧输入、每次攻击、每颗子弹、每次受伤、每次击杀或每个掉落物。请求 IP 可能由 GameAnalytics 用于网络传输、安全或粗略地区推导，因此玩家说明不得声称“完全不处理 IP”。

新增或修改事件必须同时更新：`EVENT_DICTIONARY`、内容 ID 限制、`gameanalytics_test.gd`、本文件和 `PRIVACY_NOTICE.txt`，并重新评估频率、必要性与玩家说明。公开 Beta 期间不要临时加入高频战斗流。

## 离线、失败与退出

- HTTP 使用 Godot `HTTPRequest` 异步提交，不阻塞主线程，也不改变暂停状态。
- 初始化失败或断网时采用 5–120 秒指数退避；约每 20 秒批量提交，单批最多 32 条。
- 事件不是只在退出时发送。初始化完成后会尝试首批发送，此后定时提交；标题、暂停和窗口关闭共用退出确认流程，确认后保存安全草稿、结束会话，并最多等待 2 秒完成最后一批。
- 队列最多 500 条，位于 `user://gameanalytics/queue.json`；随机安装 ID、会话号和未正常结束会话位于 `user://gameanalytics/state.json`。
- Alt+F4、断电或任务管理器强杀可能来不及刷新；未发送事件留在本地队列，下次在仍获同意的前提下补交，并补记上次会话结束。
- 撤回同意会取消在途请求并删除上述文件。
- 本地试玩记录器是另一套明确同意、永不自动上传的诊断流程，与远程统计选择互不改变。

## 验证与发布门禁

- `privacy_consent_test.gd`：首次独立选择、默认拒绝、标题按钮隔离、允许/拒绝、隐私页和中文文案。
- `gameanalytics_test.gd`：HMAC、12 项白名单、未知值折叠、禁止高频事件、聚合结算、队列上限、撤回删除。
- `test_gameanalytics_build.py`：Key 格式、`public_beta` profile、注入位置、非秘密指纹与输出清单。
- `test_public_beta_archive.py`：五文件发布白名单、隐私说明存在、profile 清单与错误 profile 拒绝。

发布前仍需账号持有人确认真实 keys 确实属于 `Last Inkwarden - Public Beta` 项目，并在仪表盘看到 Windows 真机事件；仓库无法替代这个账号侧检查。还需把 itch.io 上的公开隐私页面/联系渠道补成最终地址，审阅 GameAnalytics 数据处理条款及发行地区要求，并按 `PRIVACY_NOTICE.txt` 的承诺执行 Beta 原始数据保留与删除政策。
