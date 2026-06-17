#!/bin/bash

set -e

APP=/opt/hax-bot-6.4

echo "🚀 一键安装 HAX BOT 6.4"

# ✔ 1. 自动装依赖
apt update -y
apt install -y python3 python3-pip python3-venv git

# ✔ 2. 自动创建目录（关键）
rm -rf $APP
mkdir -p $APP

# ✔ 3. 自动下载代码
git clone https://github.com/mingyueqianli/hax-bot-6.4.git $APP

cd $APP

# ✔ 4. 自动环境
python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

# ✔ 5. 自动创建配置
mkdir -p data logs

# ✔ 6. 交互输入（必须）
read -p "请输入TOKEN: " TOKEN
echo $TOKEN > token.txt

read -p "采集时间(秒默认30): " INTERVAL
INTERVAL=${INTERVAL:-30}
echo $INTERVAL > interval.txt

# ✔ 7. 自动启动
nohup python -m app.collector.runner > logs/collector.log 2>&1 &
nohup python -m app.bot.main > logs/bot.log 2>&1 &

echo "✅ 安装完成"
