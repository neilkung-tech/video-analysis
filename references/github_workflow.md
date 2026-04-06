# GitHub 仓库操作流程

## Token 管理

Token 存储位置：
- `~/.openclaw/workspace/skills/browser-mcp-control/.git/config`
- 用户名：neilkung-tech

## 创建新仓库

```bash
# 1. 用 API 创建仓库
curl -X POST \
  -H "Authorization: token ghp_xxx" \
  https://api.github.com/user/repos \
  -d '{"name":"repo-name","public":true,"description":"描述"}'

# 2. 初始化本地仓库
cd /path/to/skill
git init
git add .
git commit -m "Initial commit"

# 3. 添加带 token 的 remote
git remote add origin https://ghp_xxx@github.com/USERNAME/repo.git

# 4. 推送到 main 分支
git branch -M main
git push -u origin main
```

## 更新仓库

```bash
cd /path/to/skill
git add .
git commit -m "Update message"
git push
```

## 常见问题

### Q: gh CLI 为什么不能用？
A: Token 缺少 `read:org` 权限，用 curl API 代替

### Q: 推送失败 "src refspec master does not match"？
A: 分支名是 `main`，不是 `master`，用 `git push -u origin main`

### Q: 仓库不存在？
A: 先用 curl API 创建仓库，再 push

## 敏感信息

- Token 不要提交到 GitHub
- Chat ID 用 `YOUR_CHAT_ID` 代替
- 服务器 IP 用 `YOUR_SERVER_IP` 代替
- 密码用 `YOUR_PASSWORD` 代替
