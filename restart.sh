#!/bin/bash
set -e
systemctl restart hax-bot.service hax-bot-collector.service
sleep 2
systemctl status hax-bot.service hax-bot-collector.service --no-pager
