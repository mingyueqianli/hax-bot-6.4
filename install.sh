#!/bin/bash

set -e

APP=/opt/hax-bot-7.0

echo "🚀 HAX BOT 7.0 企业双模式安装"

# =========================
# 1. 环境
# =========================
apt update -y
apt install -y python3 python3-pip python3-venv git curl

# =========================
# 2. 安装目录
# =========================
rm -rf $APP
git clone https://github.com/mingyueqianli/hax-bot-6.6.git $APP

cd $APP

# =========================
# 3. Python环境
# =========================
python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

mkdir -p data logs

# =========================
# 4. 模式选择（关键升级）
# =========================

echo "========================"
echo "请选择安装模式:"
echo "1) 一键模式（自动）"
echo "2) 交互模式（输入TOKEN）"
echo "========================"

read -p "输入选择 (1/2): " MODE

# =========================
# 5. 一键模式
# =========================
if [ "$MODE" = "1" ]; then

    echo "🚀 一键模式启动"

    TOKEN="test_token"
    INTERVAL=30

# =========================
# 6. 交互模式
# =========================
elif [ "$MODE" = "2" ]; then

    exec < /dev/tty

    echo "========================"
    read -p "🔑 请输入 TOKEN: " TOKEN

    echo "========================"
    read -p "⏱ 采集时间(秒): " INTERVAL

    INTERVAL=${INTERVAL:-30}

else
    echo "❌ 无效选择"
    exit 1
fi

# =========================
# 7. 写入配置
# =========================
echo $TOKEN > token.txt
echo $INTERVAL > interval.txt

# =========================
# 8. 启动服务
# =========================
echo "🚀 启动 BOT + COLLECTOR..."

nohup python -m app.collector.runner > logs/collector.log 2>&1 &
nohup python -m app.bot.main > logs/bot.log 2>&1 &

echo "========================"
echo "✅ HAX BOT 7.0 安装完成"
echo "📊 模式: $MODE"
echo "🔑 TOKEN: $TOKEN"
echo "⏱ INTERVAL: $INTERVAL"
echo "========================"
