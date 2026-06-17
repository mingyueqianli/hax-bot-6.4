#!/bin/bash

set -e

APP_NAME="hax-bot"
BASE_DIR="/opt"

echo "🚀 HAX BOT 7.7 终极闭环安装"

# =========================
# 1. 基础环境
# =========================
apt update -y
apt install -y python3 python3-pip python3-venv git curl

# =========================
# 2. 自动清理旧版本
# =========================
rm -rf $BASE_DIR/$APP_NAME*

# =========================
# 3. 自动 clone（不问用户名）
# =========================
echo "📦 cloning repo..."

git clone https://github.com/mingyueqianli/hax-bot-7.7.git $BASE_DIR/$APP_NAME || {
    echo "❌ clone失败，尝试修复DNS..."
    git config --global http.postBuffer 524288000
    git clone https://github.com/mingyueqianli/hax-bot-7.7.git $BASE_DIR/$APP_NAME
}

# =========================
# 4. 自动定位目录（核心升级）
# =========================
cd $BASE_DIR/$APP_NAME

echo "📂 当前目录: $(pwd)"

# =========================
# 5. Python环境
# =========================
python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

mkdir -p data logs

# =========================
# 6. 🔥 自动修复输入系统（关键）
# =========================

exec < /dev/tty

echo "===================="
echo "请选择模式:"
echo "1) 一键模式（默认）"
echo "2) 交互模式（输入TOKEN）"
echo "===================="

read -p "输入: " MODE

if [ "$MODE" = "2" ]; then

    read -p "🔑 TOKEN: " TOKEN
    read -p "⏱ INTERVAL: " INTERVAL

else
    TOKEN="test_token"
    INTERVAL=30
fi

# =========================
# 7. 写入配置
# =========================
echo $TOKEN > token.txt
echo $INTERVAL > interval.txt

# =========================
# 8. 防重复进程
# =========================
pkill -f app.bot.main || true
pkill -f app.collector.runner || true

# =========================
# 9. 启动系统
# =========================
echo "🚀 启动 BOT + COLLECTOR..."

nohup python -m app.collector.runner > logs/collector.log 2>&1 &
nohup python -m app.bot.main > logs/bot.log 2>&1 &

# =========================
# 10. 状态输出
# =========================
echo "================================"
echo "✅ HAX BOT 7.7 安装完成"
echo "📦 路径: $BASE_DIR/$APP_NAME"
echo "🔑 TOKEN: $TOKEN"
echo "⏱ INTERVAL: $INTERVAL"
echo "================================"
