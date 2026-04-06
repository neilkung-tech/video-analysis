# Video Analysis Skill

🔍 **YouTube 视频深度分析技能**

下载字幕 → Agent 生成深度分析 HTML 报告 → 推送到 Telegram。

## 核心流程

```
用户发 YouTube 链接
  ↓
Agent 执行 prepare.sh（下载字幕 + 元数据）
  ↓
Agent 读取 transcript.txt + info.json
  ↓
Agent 在 session 内一次性生成完整分析（HTML）
  ↓
Agent 保存 HTML + 推送 Telegram
```

**关键设计：AI 分析由 Agent 在 session 内完成，不外包给脚本。**

## 前置要求

### 系统依赖
```bash
# yt-dlp
pip install yt-dlp
# Node.js >= 16
node --version
```

### Chrome 配置
**必须先在 Chrome 中登录 YouTube 账户**（VNC 远程桌面或本地）。

### Telegram Bot 配置
1. BotFather 创建 Bot → 获取 Token
2. 获取 Chat ID（数字格式，如 `YOUR_CHAT_ID`）

## Agent 操作步骤

### Step 1: 数据准备
```bash
cd ~/.openclaw/workspace/skills/video-analysis
./scripts/prepare.sh "YOUTUBE_URL"
```

脚本完成后输出 `info.json` 和 `transcript.txt`。

### Step 2: 读取数据
```bash
# 读取元数据
cat ~/Youtube/<video_dir>/info.json

# 读取字幕全文
cat ~/Youtube/<video_dir>/transcript.txt
```

字幕可能很长（2小时节目约 30000-50000 字符），完整读取。

### Step 3: 生成分析 HTML

按照 `references/agent_prompt.md` 的 prompt 模板，基于完整字幕生成 HTML 报告。

**HTML 模板 CSS 参考**：`references/html_template.html`

**质量标准**：
- 覆盖字幕中所有重要内容
- 数据准确、引用带时间戳
- 结构化输出（card、stat-box、quote-box、data-table）
- 深色主题（与模板一致）

### Step 4: 保存 + 推送
```bash
# 保存 HTML（命名规则：YYYY-MM-DD_标题前30字符_Analysis.html）
# 保存到 video_dir 下

# 推送到 Telegram（用 message tool 发送文件）
```

### Step 5: 完成通知
告知用户分析完成，附上关键发现摘要（3-5句话）。

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

### v3.0.0 (2026-04-06)
- 🔄 **架构重构**：分析由 Agent 在 session 内完成
- ✂️ 移除 `analyze_video.js` / `analyze_video_bg.js`（不再需要）
- ✨ 升级 HTML 模板（深色主题、卡片布局、数据面板）
- 📝 新增 `agent_prompt.md`（结构化分析 prompt）
- 🛠️ `prepare.sh` 替代 `analyze.sh`（只做数据准备）

### v2.0.0 (2026-04-06)
- AI 深度分析（已废弃，改为 agent 内置）

### v1.0.0 (2026-04-05)
- 初始版本

## 作者
OpenClaw Community
