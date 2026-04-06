# Video Analysis Skill

🔍 **YouTube 视频深度分析技能**

下载字幕 → 后台 Sub-agent 生成深度分析 HTML → 自动推送 Telegram。

## 核心流程

```
用户发 YouTube 链接
  ↓
主 Agent 执行 prepare.sh（~30s，前台）
  ↓
主 Agent 启动 Sub-agent（sessions_spawn, background）
  ↓
用户可继续正常对话，不受影响
  ↓
Sub-agent 读取字幕 → 生成 HTML → 通知主 Agent
  ↓
主 Agent 推送 HTML 到 Telegram → 告知用户完成
```

**关键设计：数据准备在前台（快），AI 分析在后台（慢），不阻塞对话。**

## 前置要求

### 系统依赖
```bash
pip install yt-dlp
node --version  # >= 16
```

### Chrome 配置
**必须先在 Chrome 中登录 YouTube 账户**（VNC 远程桌面或本地）。

### Telegram Bot 配置
1. BotFather 创建 Bot → 获取 Token
2. 获取 Chat ID（数字格式，如 `YOUR_CHAT_ID`）

## Agent 操作步骤

### Step 1: 数据准备（前台，~30s）

```bash
cd ~/.openclaw/workspace/skills/video-analysis
./scripts/prepare.sh "YOUTUBE_URL"
```

脚本完成后输出 `info.json` 和 `transcript.txt`。

**告诉用户**："字幕已下载，后台分析已启动，预计 X 分钟完成。你可以继续聊别的。"

### Step 2: 启动 Sub-agent（后台）

```python
sessions_spawn(
    mode="run",
    task="<SUB_AGENT_TASK>",
    streamTo="parent"  # 进度自动回传
)
```

Sub-agent 的 task 内容：

```
你是视频分析 Agent。请完成以下任务：

1. 读取 ~/Youtube/<video_dir>/info.json 获取视频元数据
2. 读取 ~/Youtube/<video_dir>/transcript.txt 获取字幕全文（完整读取，不要截断）
3. 读取 ~/.openclaw/workspace/skills/video-analysis/references/agent_prompt.md 获取分析 prompt 模板
4. 读取 ~/.openclaw/workspace/skills/video-analysis/references/html_template.html 获取 HTML CSS 模板
5. 按照 agent_prompt.md 的要求，生成完整 HTML 分析报告
6. 将 HTML 保存到 ~/Youtube/<video_dir>/<YYYY-MM-DD_标题前30字符_Analysis.html>
7. 完成后输出：DONE:<html文件绝对路径>

进度要求：
- 每完成一个步骤输出一行进度
- 开始分析时输出预计时间
- 完成时输出 DONE:<路径>
```

### Step 3: 用户继续对话

Sub-agent 在后台运行，主 session 正常响应其他消息。
Sub-agent 的进度输出通过 `streamTo="parent"` 回传。

### Step 4: 推送结果

当 Sub-agent 完成后（输出 `DONE:<路径>`）：
1. 读取生成的 HTML 文件
2. 用 message tool 发送文件到 Telegram
3. 告诉用户："分析完成"，附 3-5 句关键发现摘要

## 输出目录结构

```
~/Youtube/
├── YYYY-MM-DD_标题_VIDEO_ID/
│   ├── metadata.json          # 原始 yt-dlp 元数据
│   ├── info.json              # 结构化元数据（agent 可读）
│   ├── transcript.txt         # 纯文本字幕
│   ├── transcript.en.json3    # 原始字幕文件
│   └── YYYY-MM-DD_标题_Analysis.html  # 分析报告
```

## 命名规则

| 文件 | 规则 | 示例 |
|------|------|------|
| 目录 | `YYYY-MM-DD_标题前50字符_VIDEO_ID` | `2026-04-06_Bloomberg_China_Show_dEfGhIj` |
| 报告 | `YYYY-MM-DD_标题前30字符_Analysis.html` | `2026-04-06_Bloomberg_China_Analysis.html` |

## 目录结构

```
video-analysis/
├── SKILL.md                          # 本文件
├── README.md                         # GitHub 首页
├── scripts/
│   └── prepare.sh                    # 数据准备（下载字幕 + 元数据）
└── references/
    ├── html_template.html            # HTML 模板（深色主题 CSS）
    └── agent_prompt.md               # Agent 分析 prompt 模板
```

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| No captions available | Chrome 未登录 YouTube | VNC 登录 YouTube |
| Robot detected | 同上 | 同上 |
| HTTP 429 (zh-Hans) | 中文翻译限流 | 脚本自动降级到英文 |
| 字幕为空 | YouTube 无字幕 | 检查视频是否有 CC |

## 更新日志

### v3.1.0 (2026-04-06)
- 🔄 **后台分析**：Sub-agent 生成 HTML，不阻塞对话
- 📊 **进度回传**：`streamTo="parent"` 实时回传分析进度
- 📤 **自动推送**：完成后主 Agent 推送 HTML 到 Telegram

### v3.0.0 (2026-04-06)
- 架构重构：分析由 Agent session 内完成
- 升级 HTML 模板（深色主题、卡片布局、数据面板）

### v2.0.0 (2026-04-06)
- AI 深度分析（已废弃）

### v1.0.0 (2026-04-05)
- 初始版本

## 作者
OpenClaw Community
