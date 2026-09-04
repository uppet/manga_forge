# GameAnalytics 接入说明

## 目标与边界

Inkbound Rogue 的远程统计是可选能力，不替代现有的本地试玩记录器。游戏默认关闭统计；同时满足以下条件才会连接 GameAnalytics：

1. 玩家在“选项”中主动开启“匿名使用数据”；
2. 构建时已经向 EXE 的内嵌 PCK 注入有效的 Game Key 和 Secret Key；
3. `INKBOUND_GA_ENABLED` 没有被设为 `0`；
4. 当前不是自动化测试模式。

当前项目固定在 Godot 4.2.2，而 GameAnalytics 3.x 官方 Godot SDK 要求 Godot 4.5+。因此本分支使用官方 HTTPS Collection API v2，以纯 GDScript 实现最小客户端，避免为统计功能单独升级引擎。未来项目整体升级至 Godot 4.5+ 后，可以评估替换为官方 GDExtension。

官方参考：

- Godot SDK：https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/game-engine-sdks/godot/
- Collection API 设置：https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/api/setup/
- 事件类型：https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/api/event-types/

## 本机配置与首次验证

先在 GameAnalytics 账号中为 Windows 建立一个测试用游戏项目。测试项目与将来的正式项目分开，可以避免验证事件污染正式报表。

1. 在仓库根目录执行 `cp tools/windows/gameanalytics.local.json.example tools/windows/gameanalytics.local.json`。
2. 只在新建的 `gameanalytics.local.json` 中填写该 Windows 游戏的 Game Key（32 位十六进制）和 Secret Key（40 位十六进制）。账号项目的 keys 必须使用 `production` endpoint；只有官方 sandbox keys 才能使用 `sandbox`。
3. 执行 `python3 tools/windows/host_game.py gameanalytics-build-test` 验证注入器。
4. 执行 `python3 tools/windows/host_game.py export`。同步完成后，导出器只临时改写 `S:\\bld\\manga-forge-runtime\\games\\inkbound_rogue\\scripts\\gameanalytics_credentials.gd`，然后由 Godot 编译进 EXE；本机 JSON 不会被复制过去，导出成功或失败后 runtime 脚本都会恢复为空占位。
5. 检查 `build/windows/gameanalytics-build.json`：应为 `"embedded": true`，并包含不泄露 Key 的 16 位配置指纹。`export-boot.log` 也必须出现相同指纹，否则 export 会失败。
6. 直接双击 `InkboundRogue.exe`，不再需要 GameAnalytics 启动脚本或玩家环境变量。
7. 进入“选项”，将“匿名使用数据”切为“开”。若未开启，即便 EXE 内已有 keys 也不会创建匿名 ID 或发起请求。
8. 开一局并完成一次升级选择，然后在 GameAnalytics 的 Realtime / Live Events 中检查 `user`、`progression` 和 `design` 事件。

Live Events 通常在发送后数秒至约 30 秒内出现，只保留最近 50 条；普通 Realtime 指标和其他报表还需几分钟处理。排查时确认打开的是同一个游戏项目，清空 Event Type / Build / User ID 过滤条件，并留意本构建的 Build 值为 `0.23.3-alpha`。还应在 Game Settings → General → Danger Zone 确认 Event Collection 没有被禁用或用过滤器排除此 Build/事件类别。

不要把真实 keys 写进 Git、问题单、试玩日志或聊天记录。`*.local.json` 已加入 `.gitignore`，而 Git 中的 `gameanalytics_credentials.gd` 永远是空占位文件。这里的 Secret Key 会进入最终客户端，因此有能力逆向 EXE/PCK 的人仍可能提取它；这是客户端采集签名 key，不要把它与 GameAnalytics 账号密码、管理 API key 或其他服务密钥复用。

## 构建注入与开发覆盖

`host_game.py export` 每次都会先同步 Git 中的空占位文件，再读取未跟踪的 `tools/windows/gameanalytics.local.json` 并覆盖 Windows runtime 副本。如果本地配置不存在，仍可生成不含统计凭据的普通构建，但输出会明确标记 `gameanalytics_build_credentials=not_embedded`，构建清单中的 `embedded` 也会是 `false`。

以下环境变量只保留给开发者临时覆盖和紧急停用；正常玩家启动 EXE 不需要设置它们：

| 变量 | 值 | 说明 |
| --- | --- | --- |
| `INKBOUND_GA_GAME_KEY` | 32 位小写/大写十六进制 | Windows 游戏的 Game Key |
| `INKBOUND_GA_SECRET_KEY` | 40 位小写/大写十六进制 | 事件 HMAC 签名 key |
| `INKBOUND_GA_ENVIRONMENT` | `sandbox` / `production` | 临时覆盖内嵌 endpoint；账号项目 keys 使用 `production` |
| `INKBOUND_GA_ENABLED` | `0` / `1` | `0` 是运维总开关，不能代替玩家同意 |
| `INKBOUND_GA_DEBUG` | `0` / `1` | 仅输出重试原因，从不输出 key 或事件正文 |

## 采集内容

| 游戏语义 | GameAnalytics 类别 | 示例 |
| --- | --- | --- |
| 启动统计会话 | `user` | 每次启用后的游戏会话一次 |
| 开局、胜利、失败、续局 | `progression` | `Start:Run:standard:open-draft` |
| 页进度、Boss 页 | `design` | `run:page:3` |
| 武器开局配置 | `design` | `run:loadout:marginalia` |
| 路线、事件、升级、神器、剧情选择 | `design` | `choice:upgrade:arc-sweep` |
| 一局结算所得 Memory | `resource` | `Source:Memory:run:completion`，按整局聚合 |
| 正常会话结束 | `session_end` | 记录会话秒数；意外退出在下次启动补记 |

不会上传：玩家姓名、账号、邮箱、试玩 participant code、自由文本、调查备注、截图、存档内容、随机 seed、世界坐标、逐帧输入、每次攻击、每颗子弹、每次受伤、每次击杀或每个掉落物。GameAnalytics collector 会用请求 IP 推导国家/地区；其官方 Collection API 文档声明 IP 不会被存储，但发布前仍应把这一处理写进玩家可见的隐私说明。

## 离线、失败与删除

- HTTP 使用 Godot `HTTPRequest` 异步提交，不阻塞主线程，也不改变暂停状态。
- 初始化失败或断网时采用 5–120 秒指数退避；每约 20 秒批量提交，单批最多 32 条。
- 事件并非只在退出时发送：初始化完成后会立即尝试首批发送，之后约每 20 秒提交。标题页、暂停菜单和窗口关闭请求共用退出确认流程；确认后保存安全草稿、结束统计会话，并最多等待 2 秒完成最后一批发送。
- 队列上限 500 条，位于 `user://gameanalytics/queue.json`；匿名安装 ID、会话号和未正常结束会话位于 `user://gameanalytics/state.json`。
- 操作系统强杀、断电或任务管理器结束进程无法等待网络；未发送事件仍保留在本地队列，并在下次启动时补交。
- 关闭“匿名使用数据”会停止在途请求，并删除上述两个文件。
- 自动化测试强制关闭网络；`gameanalytics_test.gd` 使用独立 dry-run 目录验证 HMAC、事件白名单、队列上限和 opt-out 删除。
- `test_gameanalytics_build.py` 使用临时目录验证 Key 长度、注入位置、配置指纹及清单不泄露原始 Key。

## 发布前仍需完成

- 已用本机 Production keys 验证 Windows 客户端收到 HTTP 200 后清空本地队列；仍需由账号持有人在 Realtime → Live Events 确认仪表盘可见性。当前仓库不含账号 keys，CI 继续只验证本地协议契约。
- 审核面向玩家的隐私说明、GameAnalytics 数据处理条款和各发行地区要求。
- 为未来新增的平台分别准备本机 keys，并确认发行流水线选择了对应平台配置。
- 在正式仪表盘确认事件 ID 的基数和漏斗价值，再决定是否增加事件。禁止为了“数据更多”加入高频战斗流。
