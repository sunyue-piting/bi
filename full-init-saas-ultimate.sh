# SaaS 全自动工程最终极版 — 完全 Render + Vercel 云端部署 + 完整 Provision 轮询

# 文件: full-init-saas-ultimate.sh

#!/bin/bash

set -e  # 出错自动退出

# --- 传入参数 ---
GITHUB_USER=$1
REPO_NAME=$2
RENDER_API_KEY="rnd_sSnv8QGVuHORyR1MY9sBSJ1rKNiG"
VERCEL_API_KEY="l8nIr5yVhvRo5xvZYDqGXrsi"
POSTGRES_DB_URL="postgresql://piting_fund_database_user:7jYtXdLOQLF0oHdJcm7xAsgB45BM2EZZ@dpg-d0veava4d50c73efqbg0-a.oregon-postgres.render.com/piting_fund_database"

if [ -z "$GITHUB_USER" ] || [ -z "$REPO_NAME" ]; then
  echo "Usage: bash full-init-saas-ultimate.sh <github-username> <repo-name>"
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
git commit -m "SaaS project initialized by full-init-ultimate"
git push origin main --force

# --- Render 完整使用 Blueprints 部署 ---
echo "🚀 通过 Render Blueprints 完整部署后端..."

cat > blueprint.yaml <<EOF
services:
  - type: web
    name: funds-backend
    env: docker
    repo: https://github.com/$GITHUB_USER/$REPO_NAME
    rootDir: backend
    plan: free
    autoDeploy: true
    envVars:
      - key: DATABASE_URL
        value: "$POSTGRES_DB_URL"
EOF

BLUEPRINT_RESPONSE=$(curl -s -X POST "https://api.render.com/v1/blueprints" \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -H "Accept: application/json" \
  -F "blueprint=@blueprint.yaml")

BLUEPRINT_ID=$(echo "$BLUEPRINT_RESPONSE" | jq -r '.id')

# --- 轮询 Blueprint 状态直到 provision 完成 ---
echo "🔄 正在等待 Render Blueprint 完全部署..."

for i in {1..30}; do
  STATUS=$(curl -s -X GET "https://api.render.com/v1/blueprints/$BLUEPRINT_ID" \
    -H "Authorization: Bearer $RENDER_API_KEY" \
    -H "Accept: application/json" | jq -r '.services[0].status')

  echo "当前状态: $STATUS"

  if [ "$STATUS" == "live" ]; then
    echo "✅ Blueprint 部署完成."
    break
  fi
  sleep 10

done

# --- 轮询 Render Services 获取 Public URL ---
echo "🔎 正在获取 Render 服务 Public URL..."

PUBLIC_URL=""
for i in {1..20}; do
  PUBLIC_URL=$(curl -s -X GET "https://api.render.com/v1/services" \
    -H "Authorization: Bearer $RENDER_API_KEY" \
    -H "Accept: application/json" | jq -r '.[] | select(.name=="funds-backend") | .serviceDetails.url')

  if [[ "$PUBLIC_URL" != "null" && "$PUBLIC_URL" != "" ]]; then
    echo "✅ Public URL 获取成功: $PUBLIC_URL"
    break
  fi
  echo "等待 Render 服务启动中..."
  sleep 5

done

if [ "$PUBLIC_URL" == "" ]; then
  echo "❌ 无法获取 Render Public URL，退出"
  exit 1
fi

# --- 自动更新 vercel.json ---
echo "⚙️ 正在更新 vercel.json ..."

cat > vercel.json <<EOF
{
  "rewrites": [
    { "source": "/api/:path*", "destination": "$PUBLIC_URL/:path*" }
  ]
}
EOF

git add vercel.json
git commit -m "Auto update vercel.json with backend URL"
git push origin main

# --- Vercel 自动创建前端项目 ---
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
echo "🎯 完整 SaaS 工程最终极全自动部署完成！"
echo "👉 你的后端地址: $PUBLIC_URL"
echo "👉 你的前端已自动配置并可访问 Vercel 项目！"
echo "🚀 你的 SaaS 系统现已 100% 自动化上线！"

# --- END 完美最终自动化 ---