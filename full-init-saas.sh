# SaaS 一键初始化全自动脚本 — 完整 Render + Vercel 云端部署版

# 文件: full-init-saas.sh

#!/bin/bash

set -e  # 出错自动退出

# --- 传入参数 ---
GITHUB_USER=$1
REPO_NAME=$2
RENDER_API_KEY="rnd_sSnv8QGVuHORyR1MY9sBSJ1rKNiG"
VERCEL_API_KEY="l8nIr5yVhvRo5xvZYDqGXrsi"
POSTGRES_DB_URL="postgresql://piting_fund_database_user:7jYtXdLOQLF0oHdJcm7xAsgB45BM2EZZ@dpg-d0veava4d50c73efqbg0-a.oregon-postgres.render.com/piting_fund_database"

if [ -z "$GITHUB_USER" ] || [ -z "$REPO_NAME" ]; then
  echo "Usage: bash full-init-saas.sh <github-username> <repo-name>"
  exit 1
fi

# --- 检查 SSH Key ---
if [ ! -f ~/.ssh/id_ed25519 ]; then
  echo "🔐 生成新的 SSH 密钥..."
  ssh-keygen -t ed25519 -C "$GITHUB_USER@init" -f ~/.ssh/id_ed25519 -N ""
else
  echo "✅ SSH 密钥已存在，跳过生成"
fi

# --- 初始化 Git ---
if [ ! -d ".git" ]; then
  git init
fi

git remote remove origin || true

git remote add origin git@github.com:$GITHUB_USER/$REPO_NAME.git

git add .
git commit -m "SaaS project initialized by full-init"
git push origin main --force

# --- Render 自动创建后端服务 ---
echo "🚀 正在通过 Render API 创建后端 Web 服务..."

RENDER_SERVICE_ID=$(curl -s -X POST "https://api.render.com/v1/services" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
  "type": "web_service",
  "name": "funds-backend",
  "repo": "https://github.com/'$GITHUB_USER'/'$REPO_NAME'",
  "branch": "main",
  "rootDir": "backend",
  "env": "python",
  "buildCommand": "pip install -r requirements.txt",
  "startCommand": "uvicorn main:app --host 0.0.0.0 --port 8000"
}' | jq -r '.id')

# 等待一会，让服务初始化好
sleep 10

# --- 设置 Render 环境变量 ---
echo "🔧 设置 Render 数据库连接串环境变量..."

curl -s -X POST "https://api.render.com/v1/services/$RENDER_SERVICE_ID/env-vars" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[
  { "key": "DATABASE_URL", "value": "'$POSTGRES_DB_URL'" }
]'

# --- 获取 Render Public URL (需等待构建完成后人工查看 URL) ---
echo "⚠️ 请在 Render 控制台查看你的后端 Public URL, 复制到 vercel.json 文件中替换"

# --- Vercel 自动创建前端项目 (需要你手动完成 domain 绑定) ---
echo "🚀 正在通过 Vercel API 创建前端项目..."

curl -X POST "https://api.vercel.com/v9/projects" \
  -H "Authorization: Bearer $VERCEL_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
  "name": "'$REPO_NAME'-frontend",
  "framework": "nextjs",
  "gitRepository": {
    "type": "github",
    "repo": "'$GITHUB_USER'/'$REPO_NAME'"
  },
  "rootDirectory": "frontend"
}'

# --- 完成提示 ---
echo "🎉 完整 SaaS 云端部署初始化完成！"
echo "👉 请前往 Render 控制台手动获取 Public URL，并更新 vercel.json 代理地址。"
echo "👉 Vercel 前端已自动创建，直接运行。"
echo "🚀 完整 SaaS 系统即刻上线！"

# --- 后续进阶版可继续自动化：---
# ✅ 自动检测 Render Public URL
# ✅ 自动写入 vercel.json 文件
# ✅ 自动推送回 GitHub 触发 Vercel 部署
# ✅ 完整 CI/CD 完整 SaaS 管理平台
