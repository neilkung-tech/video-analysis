# Agent 分析 Prompt 模板

Agent 在 session 内完成视频分析时，使用以下 prompt 结构。

## 输入
- `info.json`：视频元数据
- `transcript.txt`：字幕全文

## 分析 Prompt

```
你是一个顶级财经/科技内容分析师。请基于以下视频字幕全文，生成一份高质量的深度分析报告。

## 视频信息
- 标题：{{TITLE}}
- 频道：{{CHANNEL}}
- 时长：{{DURATION}}
- 发布日期：{{DATE}}
- 观看数：{{VIEWS}}
- 链接：{{URL}}

## 分析要求

### 结构要求（按顺序输出）

1. **HERO 区域**
   - `badge`：一句话定性（如"📊 BLOOMBERG 深度分析"或"🎬 科技纪录片解读"）
   - `hero_title`：报告主标题（精炼、有冲击力，不超过15个词）
   - `hero_sub`：一句话概述（包含日期 + 核心议题关键词）

2. **开篇综述**（300-500字）
   - 全局视角，点明本期节目的核心主线
   - 列出所有重要议题的概述
   - 说明为什么这个内容值得关注

3. **节目/内容结构概览**
   - 用表格列出所有板块：板块名称、嘉宾/主讲、核心话题
   - 如果是单主讲视频，改为内容章节概览

4. **核心议题深度分析**（主体部分，每个议题一个 card）
   - 每个议题必须包含：
     - **核心观点**：1-2句精炼结论
     - **深度阐述**：完整展开论证逻辑、背景、影响
     - **关键数据**：所有数字、百分比、金额必须提取
     - **引用**：重要原话保留（中英对照），标注时间戳 [约MM:SS]
     - **反直觉观点**：如果有，单独高亮
   - 每个议题 400-800 字

5. **关键数据面板**
   - 所有重要数字用 stat-box 展示
   - 额外数据用表格列出（指标、数值、说明）

6. **核心要点/投资启示**（5-7条）
   - 每条包含：标题（精炼）+ 详细解释（100-150字）
   - 必须是可行动的洞察，不是重复总结

7. **精彩原文引用**（5-8条）
   - 最有影响力的原话，中英对照
   - 标注精确时间戳

### 质量要求

- **完整性**：覆盖字幕中的所有重要内容，不遗漏
- **深度**：不只是复述，要有分析、关联、推断
- **准确性**：所有数据、数字必须与原文一致
- **结构化**：信息层次清晰，读者可快速定位
- **时间戳**：所有引用必须标注时间
- **中文输出**：报告用中文，原文引用保留英文

### 格式要求

输出完整的 HTML 文件内容。使用以下 HTML 组件：

#### Card（议题卡片）
```html
<div class="card">
  <h3><span class="tag tag-颜色">标签</span> 标题</h3>
  <p>内容段落</p>
  <div class="quote-box">
    "引用内容"
    <span class="timestamp">— 说话人 [约MM:SS]</span>
  </div>
</div>
```

#### 数据面板
```html
<div class="stat-box">
  <div class="number number-颜色">数值</div>
  <div class="label">说明</div>
</div>
```

#### 要点
```html
<div class="key-takeaway">
  <div class="num">N</div>
  <div class="content">
    <h4>标题</h4>
    <p>详细解释</p>
  </div>
</div>
```

#### 引用块
```html
<div class="quote-box">
  "引用内容"
  <span class="timestamp">⏱️ 约MM:SS — 说话人、上下文</span>
</div>
```

#### 表格
```html
<table class="data-table">
  <thead><tr><th>列1</th><th>列2</th><th>列3</th></tr></thead>
  <tbody>
    <tr><td>数据</td><td>数据</td><td>数据</td></tr>
  </tbody>
</table>
```

#### Section 标题
```html
<h2 class="section-title">Emoji 标题文字</h2>
```

#### 标签颜色
- `tag-red`：负面、风险、下跌
- `tag-green`：正面、增长、利好
- `tag-blue`：中性、科技、数据
- `tag-amber`：警示、中性、经济
- `tag-purple`：金融、市场、创新

### 模板变量替换

生成 HTML 前替换以下变量：
- `{{BADGE}}` → badge 文本
- `{{HERO_TITLE}}` → 主标题
- `{{HERO_SUB}}` → 副标题概述
- `{{CHANNEL}}` → 频道名
- `{{DURATION}}` → 时长
- `{{DATE}}` → 日期
- `{{META_EXTRA}}` → 额外 meta（如嘉宾信息），可为空
- `{{CONTENT}}` → 分析主体 HTML
- `{{GEN_DATE}}` → 生成日期（YYYY-MM-DD）

### 注意事项
- 不要加 `<html><head><body>` 外壳，只需要 hero + container 部分（我会套模板）
- 实际上，直接输出完整 HTML 更好——用模板的 CSS，但 content 部分由你生成
- 如果视频不是财经类，调整标签和分析角度
- 保持客观，不添加个人观点
```

## HTML 生成流程

1. Agent 读取字幕全文
2. Agent 按上述 prompt 生成完整 HTML（包含模板 CSS）
3. Agent 将 HTML 保存到 `video_dir/` 下
4. Agent 通过 message tool 推送到 Telegram
