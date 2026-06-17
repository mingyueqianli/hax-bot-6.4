#!/bin/bash

set -e

APP=/opt/hax-bot-6.4

echo "🚀 HAX BOT 6.4 FULL AUTO INSTALL"

# =========================
# 1. 安装依赖环境
# =========================
apt update -y
apt install -y python3 python3-pip python3-venv git

# =========================
# 2. 创建完整目录（关键）
# =========================
rm -rf $APP
mkdir -p $APP
cd $APP

mkdir -p app/bot
mkdir -p app/collector
mkdir -p data
mkdir -p logs

# =========================
# 3. 自动生成 requirements.txt
# =========================
cat > requirements.txt << EOF
python-telegram-bot
requests
beautifulsoup4
lxml
EOF

# =========================
# 4. 自动生成 collector
# =========================
cat > app/collector/hax.py << EOF
from datetime import datetime

def fetch():
    return [f"采集时间: {datetime.now()}\n"]
EOF

cat > app/collector/runner.py << EOF
import time
from app.collector.hax import fetch

def get_interval():
    try:
        return int(open("interval.txt").read().strip())
    except:
        return 30

while True:
    data = fetch()
    with open("data/test.txt","w",encoding="utf-8") as f:
        f.writelines(data)
    time.sleep(get_interval())
EOF

# =========================
# 5. 自动生成 bot
# =========================
cat > app/bot/main.py << EOF
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

def read():
    try:
        return open("data/test.txt","r",encoding="utf-8").read()
    except:
        return "no data"

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("🚀 HAX BOT 6.4 STARTED")

async def stats(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(read())

def main():
    token = open("token.txt").read().strip()
    app = Application.builder().token(token).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("stats", stats))

    app.run_polling()

if __name__ == "__main__":
    main()
EOF

# =========================
# 6. 初始化 token + interval（关键）
# =========================
echo "========================"
read -p "请输入 BOT TOKEN: " TOKEN
echo $TOKEN > token.txt

echo "========================"
read -p "采集间隔(秒，默认30): " INTERVAL
INTERVAL=${INTERVAL:-30}
echo $INTERVAL > interval.txt

# =========================
# 7. 创建虚拟环境
# =========================
python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt

# =========================
# 8. 启动系统
# =========================
echo "🚀 启动服务..."

nohup python -m app.collector.runner > logs/collector.log 2>&1 &
nohup python -m app.bot.main > logs/bot.log 2>&1 &

echo "✅ HAX BOT 6.4 完整安装成功"
echo "📊 bot + collector 已运行"
