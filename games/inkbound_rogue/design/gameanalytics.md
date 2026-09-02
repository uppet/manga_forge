# GameAnalytics 接入说明

## 目标与边界

Inkbound Rogue 的远程统计是可选能力，不替代现有的本地试玩记录器。游戏默认关闭统计；同时满足以下条件才会连接 GameAnalytics：

1. 玩家在“选项”中主动开启“匿名使用数据”；
2. 启动进程具有有效的 `INKBOUND_GA_GAME_KEY` 和 `INKBOUND_GA_SECRET_KEY`；
3. `INKBOUND_GA_ENABLED` 没有被设为 `0`；
4. 当前不是自动化测试模式。

当前项目固定在 Godot 4.2.2，而 GameAnalytics 3.x 官方 Godot SDK 要求 Godot 4.5+。因此本分支使用官方 HTTPS Collection API v2，以纯 GDScript 实现最小客户端，避免为统计功能单独升级引擎。未来项目整体升级至 Godot 4.5+ 后，可以评估替换为官方 GDExtension。

官方参考：

- Godot SDK：https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/game-engine-sdks/godot/
- Collection API 设置：https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/api/setup/
- 事件类型：https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/api/event-types/

## 本机配置与首次验证

先在 GameAnalytics 账号中为 Windows 建立一个测试用游戏项目。测试项目与将来的正式项目分开，可以避免验证事件污染正式报表。

1. 导出游戏：`python3 tools/windows/host_game.py export`。导出流程会把示例启动器放进 `build/windows/`。
2. 将 `Start-GameAnalytics.local.cmd.example` 改名为 `Start-GameAnalytics.local.cmd`。
3. 填入该 Windows 游戏的 Game Key（32 位十六进制）和 Secret Key（40 位十六进制）。账号项目的 keys 必须使用 `production` endpoint；只有官方 sandbox keys 才能使用 `sandbox`。
4. 双击这个本地启动器。它只给本次游戏进程设置环境变量，不修改 Windows 的永久环境。
5. 进入“选项”，将“匿名使用数据”切为“开”。若未开启，即便 keys 存在也不会创建匿名 ID 或发起请求。
6. 开一局并完成一次升级选择，然后在 GameAnalytics 的 Realtime / Live Events 中检查 `user`、`progression` 和 `design` 事件。
7. 验证完成后可先在选项中关闭；本地队列和匿名 ID 会立即删除。

不要把真实 keys 写进 Git、问题单、试玩日志或聊天记录。`*.local.cmd` 已加入 `.gitignore`。这里的 Secret Key 是游戏采集签名 key，仍会存在于最终客户端的运行环境中；不要把它与 GameAnalytics 账号密码或其他服务密钥复用。

## 环境变量

| 变量 | 值 | 说明 |
| --- | --- | --- |
| `INKBOUND_GA_GAME_KEY` | 32 位小写/大写十六进制 | Windows 游戏的 Game Key |
| `INKBOUND_GA_SECRET_KEY` | 40 位小写/大写十六进制 | 事件 HMAC 签名 key |
| `INKBOUND_GA_ENVIRONMENT` | `sandbox` / `production` | 默认 `sandbox`；账号项目 keys 使用 `production` |
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
- 队列上限 500 条，位于 `user://gameanalytics/queue.json`；匿名安装 ID、会话号和未正常结束会话位于 `user://gameanalytics/state.json`。
- 关闭“匿名使用数据”会停止在途请求，并删除上述两个文件。
- 自动化测试强制关闭网络；`gameanalytics_test.gd` 使用独立 dry-run 目录验证 HMAC、事件白名单、队列上限和 opt-out 删除。

## 发布前仍需完成

- 用测试项目的真实 keys 做一次 Windows 客户端到 Live Events 的闭环；当前仓库不含账号 keys，因此 CI 只能验证本地协议契约。
- 审核面向玩家的隐私说明、GameAnalytics 数据处理条款和各发行地区要求。
- 决定正式构建如何注入每个平台的 keys。当前 `.local.cmd` 适合内部测试，不是最终商店启动方式。
- 在正式仪表盘确认事件 ID 的基数和漏斗价值，再决定是否增加事件。禁止为了“数据更多”加入高频战斗流。
