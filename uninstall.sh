#!/bin/bash
set -e
APP_DIR="/opt/hax-bot"
SERVICE_NAME="hax-bot"

echo "🧹 卸载 HAX BOT..."
systemctl stop ${SERVICE_NAME}.service ${SERVICE_NAME}-collector.service 2>/dev/null || true
systemctl disable ${SERVICE_NAME}.service ${SERVICE_NAME}-collector.service 2>/dev/null || true
rm -f /etc/systemd/system/${SERVICE_NAME}.service /etc/systemd/system/${SERVICE_NAME}-collector.service
systemctl daemon-reload

read -r -p "是否删除 $APP_DIR 目录？[y/N]: " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  rm -rf "$APP_DIR"
  echo "已删除 $APP_DIR"
else
  echo "已保留 $APP_DIR"
fi

echo "卸载完成。"
