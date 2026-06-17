#!/bin/bash

set -e

APP=/opt/hax-bot-7.2

echo "🚀 HAX BOT 7.2 ULTIMATE START"

# =========================
# 1. 环境准备
# =========================
apt update -y
apt install -y python3 python3-pip python3-venv git curl

# =========================
# 2. 清理旧版本
# =========================
rm -rf $APP

# =========================
# 3. clone项目
# =========================
git clone https://github.com/mingyueqianli/hax-bot-7.2.git $APP

cd $APP

# =========================
# 4. Python环境
# =========================
python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

mkdir -p data logs

# =========================
# 🔥 核心修复：强制交互（重点）
# =========================

# 防止 curl | bash 吞输入
if [ -t 0 ]; then
    echo "✔ 交互模式正常"
else
    echo "⚠️ 修复 stdin（curl | bash环境）"
    exec < /dev/tty
fi

echo "========================"
echo "请选择模式:"
echo "1) 一键模式（默认）"
echo "2) 手动输入TOKEN模式"
echo "========================"

read -p "输入选择: " MODE

if [ "$MODE" = "2" ]; then

    echo "========================"
    read -p "🔑 请输入 TOKEN: " TOKEN

    echo "========================"
    read -p "⏱ 请输入采集时间(秒): " INTERVAL

else
    TOKEN="test_token"
    INTERVAL=30
fi

# 默认保护
INTERVAL=${INTERVAL:-30}

# =========================
# 写入配置
# =========================
echo $TOKEN > token.txt
echo $INTERVAL > interval.txt

# =========================
# 启动系统
# =========================
echo "🚀 启动 BOT + COLLECTOR..."

pkill -f app.bot.main || true
pkill -f app.collector.runner || true

nohup python -m app.collector.runner > logs/collector.log 2>&1 &
nohup python -m app.bot.main > logs/bot.log 2>&1 &

echo "========================"
echo "✅ HAX BOT 7.2 完成"
echo "🔑 TOKEN: $TOKEN"
echo "⏱ INTERVAL: $INTERVAL"
echo "========================"
