# Last Inkwarden / 墨卫残章 — itch.io free Beta page copy

Status date: 2026-09-05. Replace every `REPLACE_*` value before publishing.
The itch.io download and Quark Drive mirror must contain the same audited ZIP.

## Suggested itch.io fields

| Field | Value |
| --- | --- |
| Title | Last Inkwarden / 墨卫残章 |
| Classification | Game |
| Kind | Downloadable |
| Release status | In development |
| Price | Free during Beta |
| Platforms | Windows |
| Languages | English, 简体中文 |
| Genre | Action, Roguelike |
| Tags | 2D, Action Roguelike, Roguelite, Pixel Art, Hack and Slash, Bullet Hell, Story Rich, Controller, Singleplayer |
| Input | Keyboard/mouse; Xbox/PlayStation/Switch-style controller layouts |

## 中文页面正文

# 《墨卫残章》免费公开 Beta

**在一部会自我改写的活体手稿中挥刀，夺回被历史抹去的记忆。**

《墨卫残章》（Last Inkwarden）是一款俯视角漫画像素风动作 Roguelike。你将扮演最后的墨卫 Nara，在十二个不断升级的页章中构筑刀刃、对抗面具怪物与三位首领，并决定大档案馆最终应当保留怎样的历史。

当前版本是**免费公开 Beta**。它已经具备完整通关流程，但仍处于玩法、平衡、手柄兼容性、性能和表现打磨阶段。我们通过 itch.io 与夸克网盘公开同一版本，希望收集来自不同玩家和 Windows 设备的真实反馈。

## 当前内容

- 三幕十二页、三个 Boss、七段漫画式剧情和两个可持续保存的结局；
- 五种武器形态，以及各自独立的攻击节奏、全屏墨术特写与起手演出；
- 36 个可叠加技巧、12 件遗物、15 类敌人和多种范围/恢复战斗补给；
- 三种基础难度、六个挑战契约、九条区域路线和通关后的 Proof 难度阶梯；
- 永久成长、每日挑战、图鉴、成就与剧情档案；
- New Game、Continue / Load、Save & Return 和损坏存档备份恢复；
- 完整键鼠操作，以及覆盖标题菜单、战斗、暂停和弹窗的默认手柄操作；
- 英文与简体中文界面，可在游戏内随时切换；
- 五首 AIGC 配乐、日文战斗语音和漫画式战斗演出。

## 下载与运行

1. 从本页面下载 Windows ZIP；国内玩家也可以使用下方夸克网盘镜像。
2. 将 ZIP 完整解压到可写目录，不要直接在压缩包内运行。
3. 双击 `LastInkwarden.exe` 开始游戏。
4. 如果愿意留下更完整的本地诊断记录，可改为运行
   `Start-Recorded-Playtest.cmd`。它会先显示记录范围并征求同意；拒绝不会影响普通游戏。

- itch.io 主下载：使用本页面的 Download 按钮
- 夸克网盘镜像：<https://pan.quark.cn/s/REPLACE_QUARK_SHARE>
- 当前版本：`0.25.0-beta.1` / `beta`
- Windows ZIP SHA-256：`REPLACE_PUBLIC_ZIP_SHA256`

本 Beta 暂未进行代码签名。Windows 可能显示“未知发布者”提醒。请只从本 itch.io 页面或上方官方夸克镜像下载，并在运行前核对公开的 SHA-256；如果来源或校验结果不一致，请不要运行。

## 请告诉我哪里需要改进

以下反馈尤其有帮助：

- 使用的 Windows 版本、显卡、分辨率和输入设备；
- 你到达的最远页章、选择的武器和难度；
- 哪个瞬间最爽，哪个规则最难理解；
- 哪次受伤或死亡让你觉得不公平；
- 手柄菜单、文字、颜色、音乐或音效是否让你疲劳；
- Save & Return、Continue、窗口失焦或手柄热插拔是否异常。

反馈时请附上游戏版本、预期行为、实际行为和复现步骤。截图或短视频会非常有帮助。

- itch.io：欢迎直接在本页面评论区留言
- 反馈表单：<https://example.com/REPLACE_WITH_FEEDBACK_FORM>
- B 站实况与演示：<https://www.bilibili.com/video/BVREPLACE_ME>

### 可选本地试玩记录

记录型启动器只在本机保存语义游戏事件、粗粒度性能数据、由玩家主动按下 F6–F9 创建的时刻标记、可选游戏截图和退出问卷。它不记录麦克风、摄像头、账户信息、逐键输入或游戏外窗口，也不会自动上传文件。

- `F6`：Bug
- `F7`：困惑
- `F8`：不公平或难以辨认
- `F9`：高光时刻

游戏退出后会打开 `playtest-logs` 文件夹。只有在你愿意时，才需要压缩对应的匿名会话目录并通过反馈表单提交。请不要在玩家代号或问卷中填写姓名、邮箱等身份信息。

首次启动时，游戏会单独询问是否允许“可选使用统计”；默认选择“不发送”，明确同意前不会连接 GameAnalytics。玩家之后可以在“选项 → 数据与隐私”查看完整说明、修改选择或关闭并清除本地待发送队列。这套通道与本地记录器互不影响；随包的 `PRIVACY_NOTICE.txt` 提供同一份中英文说明。

## Beta 阶段已知边界

- 当前仅提供 Windows x86_64 构建；
- 建议 Windows 10/11、支持 OpenGL 3.3 的显卡、4 GB RAM 和 200 MB 可用空间；
- 已设计 Xbox、PlayStation 和 Switch 风格的位置映射，但仍在征集更多实体手柄兼容报告；
- 较旧或集成显卡的正式最低配置验证尚未完成；
- Beta 更新可能调整平衡、内容和存档结构；项目会尽量迁移旧档，但请不要把当前进度视为永久承诺；
- 这不是已经完成 Steam 平台接入的正式版本。

## 关于 AI 辅助内容

本游戏含有在开发阶段预先生成并由项目作者筛选、整合的 AI 辅助图像、音乐和日文语音。开发工具包括 OpenAI 图像生成、OpenAI Realtime、IndexTTS 2.5、海绵音乐、ComfyUI、Stable Diffusion、MiniMax H3 和 OpenAI Codex。游戏运行时不会调用生成式 AI，也不会实时生成玩家内容。更完整的制作名单、来源与第三方声明随下载包提供。

## 制作与鸣谢

- 主创、创意指导与资源制作：Joyer Huang
- 开发协作、程序与工具链：OpenAI Codex（GPT-5）
- 试玩玩家：Andrew Huang
- 引擎：Godot Engine 4.5.2

感谢你愿意成为下一位在页边留下批注的人。

---

## English page copy

# Last Inkwarden — Free Public Beta

**Cut through a living manuscript and recover the memories erased from history.**

Last Inkwarden is a top-down manga-pixel action roguelike. Play as Nara, the last Ink Warden, forge a blade build across twelve escalating pages, confront masked memories and three bosses, and decide what history the Grand Archive deserves to keep.

This is a **free public Beta** with a complete run and two endings. Gameplay, balance, controller coverage, performance, and presentation are still being refined. The same audited Windows build is distributed through itch.io and a Quark Drive mirror so feedback can be collected from more players and hardware configurations.

## Current features

- A complete three-act, twelve-page run with three bosses, seven manga story sequences, and two persistent endings;
- Five weapon forms with distinct attack rhythms, full-screen Ink Art cut-ins, and battle startup animations;
- 36 stackable techniques, 12 relics, 15 enemy archetypes, and AOE/recovery combat supplies;
- Three base difficulties, six challenge contracts, nine routes, and a post-ending Proof ladder;
- Persistent progression, Daily Chronicle, bestiary, achievements, and replayable Story Archive;
- New Game, Continue / Load, Save & Return, and rotated checkpoint backup recovery;
- Keyboard/mouse and default controller navigation across the title, combat, pause menu, and modal choices;
- Complete English and Simplified Chinese presentation;
- Five AIGC music tracks, Japanese combat voices, and manga-style combat presentation.

## Download and run

1. Download the Windows ZIP from this page or the Quark Drive mirror below.
2. Extract the complete ZIP to a writable folder; do not run it from inside the archive.
3. Launch `LastInkwarden.exe`.
4. To create an optional local diagnostic session, launch
   `Start-Recorded-Playtest.cmd` instead. It explains the data boundary and asks for consent first.

- itch.io: use the Download button on this page
- Quark Drive mirror: <https://pan.quark.cn/s/REPLACE_QUARK_SHARE>
- Build: `0.25.0-beta.1` / `beta`
- Windows ZIP SHA-256: `REPLACE_PUBLIC_ZIP_SHA256`

This Beta is not code-signed yet, so Windows may show an unknown-publisher warning. Download only from this itch.io page or the official mirror above, verify the published SHA-256, and do not run a file whose source or checksum does not match.

## Feedback wanted

Please include the build version, Windows/GPU/controller information, input method, furthest page, expected behavior, observed behavior, and reproduction steps. Screenshots or short videos are especially useful.

I would particularly like to know which moment felt best, which rule was hardest to understand, which hit or death felt unfair, and whether controller navigation, text, color, music, or effects caused fatigue.

- itch.io: leave a comment on this page
- Feedback form: <https://example.com/REPLACE_WITH_FEEDBACK_FORM>
- Bilibili gameplay/development video: <https://www.bilibili.com/video/BVREPLACE_ME>

The recorded-playtest launcher saves only pseudonymous semantic gameplay events, coarse performance data, deliberate F6–F9 markers, optional game screenshots, and the exit survey. It does not record microphone, camera, account data, raw keystrokes, or other windows, and it does not upload anything. Share a session folder only if you choose to do so. On first launch, the separate “Optional Usage Statistics” choice defaults to “Don't Send”; no GameAnalytics connection is made before explicit consent. Players can review the full notice or withdraw consent under Options → Data & Privacy, which also erases the local pending queue. The same bilingual notice ships as `PRIVACY_NOTICE.txt`.

## Beta limitations

- Windows x86_64 only;
- Provisional target: Windows 10/11, OpenGL 3.3-capable GPU, 4 GB RAM, and 200 MB free storage;
- Xbox-, PlayStation-, and Switch-style positional mappings are implemented, but broader physical-controller reports are still needed;
- The older/integrated-GPU minimum-spec pass is not complete;
- Beta updates may rebalance content or evolve save data. Migration is attempted, but current progress is not a permanent compatibility promise;
- This is not a completed Steam-integrated release.

## AI-assisted content

The game contains AI-assisted images, music, and Japanese voices that were generated during development, selected by the project owner, and shipped as fixed files. The production workflow includes OpenAI image generation, OpenAI Realtime, IndexTTS 2.5, Hai Mian Music, ComfyUI, Stable Diffusion, MiniMax H3, and OpenAI Codex. The game does not call generative AI or generate player-facing content at runtime. Full credits, provenance notes, and third-party notices are included with the download.

## Credits

- Creator, creative direction, and asset production: Joyer Huang
- Development collaboration, code, and tooling: OpenAI Codex (GPT-5)
- Playtester: Andrew Huang
- Engine: Godot Engine 4.5.2

Thank you for leaving a note in the margin.

## Publication checklist

- Replace `REPLACE_QUARK_SHARE` with the public Quark share ID.
- Replace `REPLACE_PUBLIC_ZIP_SHA256` after creating the final ZIP; hash the ZIP,
  not only the EXE.
- Replace `REPLACE_WITH_FEEDBACK_FORM` with a form or contact route that accepts
  optional logs/screenshots and has a visible privacy notice.
- Replace `BVREPLACE_ME` when the Bilibili video is available.
- Upload one byte-identical audited ZIP to itch.io and Quark Drive.
- Complete and record the public-Beta rights review in
  `ai-content-disclosure.md` before enabling downloads.
