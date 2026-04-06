# Video Analysis Skill

🔍 **YouTube 视频深度分析技能**

自动下载字幕、生成 HTML 分析报告、推送到 Telegram。

## 快速开始

```bash
# 分析视频
./scripts/analyze.sh "https://www.youtube.com/watch?v=xxx" "视频名称" "YOUR_CHAT_ID"
```

## 前置要求

1. **Chrome 已登录 YouTube** ⚠️ 必须先登录！
2. **yt-dlp** 已安装
3. **Telegram Bot** 已配置

## 文档

- [SKILL.md](SKILL.md) - 完整文档
- [references/analysis_framework.md](references/analysis_framework.md) - 分析框架
- [references/html_template.html](references/html_template.html) - HTML 模板

## 功能

- ✅ 下载 YouTube 字幕（支持多语言）
- ✅ 获取视频元数据
- ✅ 生成 HTML 分析报告
- ✅ 推送到 Telegram

## 目录结构

```
video-analysis/
├── SKILL.md                    # 完整文档
├── README.md                   # 本文件
├── scripts/
│   └── analyze.sh              # 主脚本
└── references/
    ├── analysis_framework.md   # 分析框架
    └── html_template.html      # HTML 模板
```

## 常见问题

### yt-dlp 被检测为机器人？
→ 在 Chrome 中登录 YouTube

### Telegram 发送失败？
→ 使用数字格式的 Chat ID，不要用 @username

### 文件无法发送？
→ 复制到 `~/.openclaw/workspace/`

## 许可证

MIT

## 作者

OpenClaw Community
