#!/bin/bash
set -Eeuo pipefail
APP_DIR="/opt/hax-bot"
SERVICE_NAME="hax-bot"
cd "$APP_DIR"

echo "🔄 更新 HAX BOT..."
systemctl stop ${SERVICE_NAME}.service ${SERVICE_NAME}-collector.service 2>/dev/null || true

git fetch --all --prune
git pull --ff-only || {
  echo "git pull 失败，请检查是否有本地修改。"
  exit 1
}

source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
chmod 600 token.txt interval.txt config.env 2>/dev/null || true
systemctl daemon-reload
systemctl restart ${SERVICE_NAME}.service ${SERVICE_NAME}-collector.service
sleep 2
systemctl status ${SERVICE_NAME}.service ${SERVICE_NAME}-collector.service --no-pager
