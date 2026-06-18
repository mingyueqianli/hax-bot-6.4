#!/bin/bash
set -e
echo "===== systemd ====="
systemctl status hax-bot.service hax-bot-collector.service --no-pager || true
echo ""
echo "===== logs ====="
echo "Bot log:       /opt/hax-bot/logs/bot.log"
echo "Collector log: /opt/hax-bot/logs/collector.log"
echo ""
echo "最近 collector 日志："
tail -n 30 /opt/hax-bot/logs/collector.log 2>/dev/null || true
