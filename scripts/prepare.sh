#!/bin/bash
# YouTube 视频分析 - 数据准备脚本
# 只负责：下载字幕 + 获取元数据，生成 JSON 供 agent 使用
# 用法: ./prepare.sh "YOUTUBE_URL"
# 输出: video_dir 路径 + info.json（元数据 + 字幕文本路径）

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$HOME/Youtube"

if [[ -z "$1" ]]; then
  echo "用法: $0 <YOUTUBE_URL>"
  exit 1
fi

URL="$1"

# 提取视频 ID
if [[ "$URL" =~ youtube\.com/watch\?v=([^&]+) ]]; then
  VIDEO_ID="${BASH_REMATCH[1]}"
elif [[ "$URL" =~ youtu\.be/([^?]+) ]]; then
  VIDEO_ID="${BASH_REMATCH[1]}"
elif [[ "$URL" =~ youtube\.com/shorts/([^?]+) ]]; then
  VIDEO_ID="${BASH_REMATCH[1]}"
else
  echo "❌ 无法解析 YouTube URL"
  exit 1
fi

echo "📝 [1/3] 获取视频元数据..."

# 下载元数据
METADATA_FILE="/tmp/youtube_${VIDEO_ID}_metadata.json"
yt-dlp --cookies-from-browser chrome --dump-json "$URL" > "$METADATA_FILE" 2>&1 || \
yt-dlp --dump-json "$URL" > "$METADATA_FILE" 2>&1

if [[ ! -s "$METADATA_FILE" ]]; then
  echo "❌ 无法获取视频信息"
  exit 1
fi

# 提取信息
TITLE=$(node -e "const d=require('$METADATA_FILE');console.log(d.title||'Unknown')" 2>/dev/null || echo "Unknown")
CHANNEL=$(node -e "const d=require('$METADATA_FILE');console.log(d.channel||d.uploader||'Unknown')" 2>/dev/null || echo "Unknown")
DURATION=$(node -e "const d=require('$METADATA_FILE');console.log(d.duration_string||'N/A')" 2>/dev/null || echo "N/A")
UPLOAD_DATE=$(node -e "const d=require('$METADATA_FILE');console.log(d.upload_date||'N/A')" 2>/dev/null || echo "N/A")
VIEW_COUNT=$(node -e "const d=require('$METADATA_FILE');console.log(d.view_count||0)" 2>/dev/null || echo "0")

# 格式化日期
if [[ "$UPLOAD_DATE" != "N/A" ]] && [[ ${#UPLOAD_DATE} -eq 8 ]]; then
  UPLOAD_DATE_FORMATTED="${UPLOAD_DATE:0:4}-${UPLOAD_DATE:4:2}-${UPLOAD_DATE:6:2}"
else
  UPLOAD_DATE_FORMATTED=$(date +%Y-%m-%d)
fi

# 安全目录名
SAFE_TITLE_DIR=$(echo "$TITLE" | sed 's/[^a-zA-Z0-9\u4e00-\u9fa5]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)

VIDEO_DIR="$OUTPUT_DIR/${UPLOAD_DATE_FORMATTED}_${SAFE_TITLE_DIR}_${VIDEO_ID}"
mkdir -p "$VIDEO_DIR"

cp "$METADATA_FILE" "$VIDEO_DIR/metadata.json"

echo "📹 标题: $TITLE"
echo "📺 频道: $CHANNEL"
echo "⏱️ 时长: $DURATION"
echo "📅 发布: $UPLOAD_DATE_FORMATTED"
echo "👁️ 观看: $VIEW_COUNT"

echo ""
echo "📁 输出目录: $VIDEO_DIR"

echo ""
echo "📝 [2/3] 下载字幕..."

cd "$VIDEO_DIR"
rm -f transcript*.json3 transcript*.vtt 2>/dev/null || true

SUBTITLE_FILE=""
MAX_RETRIES=2

download_subs() {
  local lang="$1" format="$2" label="$3" try=0
  while [[ $try -lt $MAX_RETRIES ]]; do
    echo "  尝试 [$label] (尝试 $((try+1))/$MAX_RETRIES)..."
    if yt-dlp --cookies-from-browser chrome \
      --write-auto-subs --sub-lang "$lang" --sub-format "$format" \
      --skip-download -o "transcript" "$URL" 2>&1 | grep -q "Has no subtitles\|No subtitles"; then
      echo "    → 该格式不可用"
      ((try++))
      [[ $try -lt $MAX_RETRIES ]] && sleep 3
    else
      return 0
    fi
  done
  return 1
}

# 策略链: json3(en) → vtt(en) → 自动字幕 → 手动字幕 → zh-Hans
if download_subs "en" "json3" "json3(en)"; then
  SUBTITLE_FILE=$(ls transcript*.json3 2>/dev/null | head -1)
fi

if [[ -z "$SUBTITLE_FILE" ]] && download_subs "en" "vtt" "vtt(en)"; then
  SUBTITLE_FILE=$(ls transcript*.vtt 2>/dev/null | head -1)
fi

if [[ -z "$SUBTITLE_FILE" ]]; then
  echo "  尝试自动字幕..."
  yt-dlp --cookies-from-browser chrome --write-auto-subs \
    --sub-lang "en" --skip-download -o "transcript" "$URL" 2>&1 || true
  SUBTITLE_FILE=$(ls transcript*.vtt 2>/dev/null | head -1)
fi

if [[ -z "$SUBTITLE_FILE" ]]; then
  echo "  尝试手动字幕..."
  yt-dlp --cookies-from-browser chrome --write-subs \
    --sub-lang "en" --skip-download -o "transcript" "$URL" 2>&1 || true
  SUBTITLE_FILE=$(ls transcript*.vtt 2>/dev/null | head -1)
fi

if [[ -z "$SUBTITLE_FILE" ]]; then
  echo "⚠️ 英文全部失败，尝试中文（可能被限流）..."
  sleep 3
  if download_subs "zh-Hans" "vtt" "vtt(zh-Hans)"; then
    SUBTITLE_FILE=$(ls transcript*.vtt 2>/dev/null | head -1)
  fi
fi

if [[ -z "$SUBTITLE_FILE" ]]; then
  echo "❌ 字幕下载失败"
  exit 1
fi

echo "✅ 字幕: $SUBTITLE_FILE"

echo ""
echo "📝 [3/3] 解析字幕文本..."

# 解析字幕为纯文本，输出到 transcript.txt
TRANSCRIPT_TXT="$VIDEO_DIR/transcript.txt"

if [[ "$SUBTITLE_FILE" == *.json3 ]]; then
  node -e "
    const fs = require('fs');
    const d = JSON.parse(fs.readFileSync('$SUBTITLE_FILE', 'utf-8'));
    const lines = [];
    for (const e of (d.events || [])) {
      if (e.segs) {
        const t = e.segs.map(s => s.utf8 || '').join('').trim();
        if (t) lines.push(t);
      }
    }
    fs.writeFileSync('$TRANSCRIPT_TXT', lines.join('\n'));
    console.log('字幕行数: ' + lines.length);
  "
elif [[ "$SUBTITLE_FILE" == *.vtt ]]; then
  node -e "
    const fs = require('fs');
    const lines = fs.readFileSync('$SUBTITLE_FILE', 'utf-8').split('\n');
    const out = [];
    for (const l of lines) {
      const t = l.trim();
      if (t && !t.includes('-->') && !t.match(/^[0-9]/) && t !== 'WEBVTT' && !t.startsWith('Kind:') && !t.startsWith('Language:')) {
        out.push(t);
      }
    }
    fs.writeFileSync('$TRANSCRIPT_TXT', out.join('\n'));
    console.log('字幕行数: ' + out.length);
  "
fi

if [[ ! -s "$TRANSCRIPT_TXT" ]]; then
  echo "❌ 字幕解析为空"
  exit 1
fi

# 生成 info.json 供 agent 读取
node -e "
  const fs = require('fs');
  const info = {
    title: $(node -e "console.log(JSON.stringify('$TITLE'.replace(/'/g, \"'\")))"),
    channel: $(node -e "console.log(JSON.stringify('$CHANNEL'.replace(/'/g, \"'\")))"),
    duration: '$DURATION',
    uploadDate: '$UPLOAD_DATE_FORMATTED',
    viewCount: '$VIEW_COUNT',
    url: '$URL',
    videoId: '$VIDEO_ID',
    videoDir: '$VIDEO_DIR',
    transcriptFile: '$TRANSCRIPT_TXT',
    subtitleFile: '$SUBTITLE_FILE',
    charCount: fs.readFileSync('$TRANSCRIPT_TXT', 'utf-8').length
  };
  fs.writeFileSync('$VIDEO_DIR/info.json', JSON.stringify(info, null, 2));
  console.log(JSON.stringify(info, null, 2));
"

echo ""
echo "✅ 数据准备完成"
echo "📁 视频目录: $VIDEO_DIR"
echo "📄 info.json 已生成，agent 可读取 $VIDEO_DIR/info.json 和 $VIDEO_DIR/transcript.txt 开始分析"
